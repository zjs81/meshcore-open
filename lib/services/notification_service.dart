import 'dart:async';
import 'dart:io' show Platform, File;
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../helpers/message_url_image_helper.dart';
import '../helpers/reaction_helper.dart';
import '../l10n/app_localizations.dart';
import '../storage/prefs_manager.dart';
import '../utils/platform_info.dart';
import 'notification_reply.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Locale for localized notification strings
  Locale _locale = const Locale('en');

  /// Set the locale for notification strings (call when app locale changes)
  void setLocale(Locale locale) {
    _locale = locale;
    // The background action isolate reads this to localize its notices.
    try {
      PrefsManager.instance.setString(
        notificationLanguagePrefsKey,
        locale.languageCode,
      );
    } catch (_) {}
  }

  AppLocalizations get _l10n => lookupAppLocalizations(_locale);

  String? _selfName;

  /// Name of the connected radio, shown as the sender of your own replies.
  void setSelfName(String? name) {
    _selfName = name;
  }

  // Recent messages per conversation notification id, so each notification
  // shows the conversation (Android MessagingStyle, used by Android Auto).
  static const _maxConversationMessages = 6;
  final Map<int, _Conversation> _conversations = {};

  // Single-subscription so actions that arrive before the connector listens
  // (e.g. during startup) are buffered instead of dropped.
  final StreamController<NotificationReply> _replies =
      StreamController<NotificationReply>();
  ReceivePort? _replyPort;

  /// Reply, mark-as-read and mute actions taken on message notifications.
  /// Has a single listener (the connector).
  Stream<NotificationReply> get replies => _replies.stream;

  /// Stops receiving notification actions. The background handler then tells
  /// the user the app isn't running instead of forwarding to nobody.
  void releaseReplyPort() {
    if (_replyPort == null) return;
    IsolateNameServer.removePortNameMapping(notificationReplyPortName);
    _replyPort!.close();
    _replyPort = null;
  }

  String _logSafe(String value) {
    final sanitized = value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ');
    return Uri.encodeComponent(sanitized);
  }

  // Rate limiting to prevent notification storms
  // (Added after getting notification-flooded while evaluating RF flood management. The irony.)
  static const _minNotificationInterval = Duration(seconds: 3);
  static const _batchWindow = Duration(seconds: 5);

  DateTime? _lastNotificationTime;
  final List<_PendingNotification> _pendingNotifications = [];
  bool _isBatchingActive = false;
  bool _suppressNotifications = false;

  /// Temporarily suppress all notifications (e.g., during sync)
  void suppressNotifications(bool suppress) {
    _suppressNotifications = suppress;
    if (suppress) {
      _pendingNotifications.clear();
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'MeshCore Open',
      appUserModelId: 'org.meshcore.open.app',
      guid: 'e7ea8f85-72f5-4f36-91f6-038f740ccf86',
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macSettings,
      windows: windowsSettings,
      linux: linuxSettings,
    );

    // On Linux, the notifications plugin opens a D-Bus session bus
    // connection whose async subscription can throw an unhandled
    // SocketException when the bus socket is missing (e.g. running as
    // root or inside a container without a session bus).
    if (PlatformInfo.isLinux && !_isDbusSessionAvailable()) {
      debugPrint('Skipping notification init: D-Bus session bus unavailable');
      return;
    }

    try {
      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse:
            notificationActionBackgroundHandler,
      );
      _registerReplyPort();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  void _registerReplyPort() {
    if (kIsWeb || _replyPort != null) return;
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(notificationReplyPortName);
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      notificationReplyPortName,
    );
    port.listen((dynamic message) {
      if (message is! Map) return;
      _dispatchAction(
        actionId: message['actionId'] as String?,
        payload: message['payload'] as String?,
        input: message['input'] as String?,
      );
    });
    _replyPort = port;
  }

  void _dispatchAction({
    required String? actionId,
    required String? payload,
    String? input,
  }) {
    final reply = NotificationReply.parse(
      actionId: actionId,
      payload: payload,
      input: input,
    );
    if (reply != null) _replies.add(reply);
  }

  static bool _isDbusSessionAvailable() {
    final addr = Platform.environment['DBUS_SESSION_BUS_ADDRESS'];
    if (addr != null && addr.isNotEmpty) return true;
    // Fallback: check the default socket for the current user.
    final uid = Platform.environment['UID'] ?? Platform.environment['EUID'];
    final path = '/run/user/${uid ?? '1000'}/bus';
    return File(path).existsSync();
  }

  Future<bool> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  // Cached "are we allowed to post notifications" result. Null = not yet
  // determined. Avoids calling _notifications.show() when it would only throw
  // "You must request notifications permissions first" (every web build).
  // Android denials are never cached so a later grant in system settings is
  // picked up without restarting the app.
  bool? _canNotify;
  static const _permissionRequestedKey = 'notification_permission_requested';

  Future<bool> _ensureCanNotify() async {
    if (!await _ensureInitialized()) return false;
    final cached = _canNotify;
    if (cached != null) return cached;

    // flutter_local_notifications has no web backend, so show() always throws.
    // Skip silently instead of logging an error per incoming message.
    if (kIsWeb) return _canNotify = false;

    // On Android 13+ notifications require an explicit grant; reflect the real
    // OS state so we don't spam failed show() calls when denied.
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final enabled = await androidPlugin.areNotificationsEnabled() ?? false;
      if (enabled) _canNotify = true;
      return enabled;
    }

    // iOS/macOS request permission during initialize(); desktop has no gate.
    return _canNotify = true;
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Request Android 13+ notification permission
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted == true) _canNotify = true;
      return granted ?? false;
    }

    // iOS permissions are requested during initialization
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == true) _canNotify = true;
      return granted ?? false;
    }

    return true;
  }

  /// Asks for the Android 13+ notification permission the first time it is
  /// needed. Never re-prompts after the user has answered once; iOS/macOS
  /// already prompt during [initialize].
  Future<void> requestPermissionsOnce() async {
    if (!PlatformInfo.isAndroid || !await _ensureInitialized()) return;
    final prefs = PrefsManager.instance;
    if (prefs.getBool(_permissionRequestedKey) ?? false) return;
    if (await _ensureCanNotify()) return;
    await prefs.setBool(_permissionRequestedKey, true);
    await requestPermissions();
  }

  /// Format special message types for human-readable notifications.
  static String formatNotificationText(String text) {
    final trimmed = text.trim();
    final reaction = ReactionHelper.parseReaction(trimmed);
    if (reaction != null) {
      return 'Reacted ${reaction.emoji}';
    }
    if (RegExp(r'^g:[A-Za-z0-9_-]+$').hasMatch(trimmed)) {
      return 'Sent a GIF';
    }
    return text;
  }

  Future<String?> _resolveNotificationImagePath(
    String text, {
    required bool urlImagesEnabled,
  }) async {
    if (!urlImagesEnabled) return null;

    final imageUrl = await MessageUrlImageHelper.parseVerified(text);
    if (imageUrl == null) return null;

    try {
      // Cache the image so notification platforms can read it from disk.
      final imageFile = await DefaultCacheManager().getSingleFile(imageUrl);
      if (!imageFile.existsSync()) return null;
      return imageFile.path;
    } catch (e) {
      debugPrint('Failed to resolve notification image: $e');
      return null;
    }
  }

  List<AndroidNotificationAction> _conversationActions(bool isChannel) => [
    AndroidNotificationAction(
      notificationReplyActionId,
      _l10n.notification_actionReply,
      inputs: [
        AndroidNotificationActionInput(label: _l10n.notification_replyHint),
      ],
      semanticAction: SemanticAction.reply,
      allowGeneratedReplies: true,
      cancelNotification: false,
    ),
    AndroidNotificationAction(
      notificationMarkReadActionId,
      _l10n.notification_actionMarkRead,
      semanticAction: SemanticAction.markAsRead,
      invisible: true,
    ),
    if (isChannel)
      AndroidNotificationAction(
        notificationMuteActionId,
        _l10n.notification_actionMuteChannel,
        semanticAction: SemanticAction.mute,
      ),
  ];

  // Always MessagingStyle: Android Auto only handles messaging notifications
  // in that style, so an image preview is shown as the large icon instead.
  AndroidNotificationDetails _androidConversationDetails(
    _Conversation conversation, {
    int? badgeCount,
    bool silent = false,
  }) {
    final imagePath = conversation.imagePath;
    return AndroidNotificationDetails(
      conversation.isChannel ? 'channel_messages' : 'messages',
      conversation.isChannel ? 'Channel Messages' : 'Messages',
      channelDescription: conversation.isChannel
          ? 'New channel message notifications'
          : 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      number: badgeCount,
      silent: silent,
      category: AndroidNotificationCategory.message,
      largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
      styleInformation: MessagingStyleInformation(
        Person(key: 'self', name: _selfName ?? _l10n.notification_you),
        conversationTitle: conversation.isChannel ? conversation.title : null,
        groupConversation: conversation.isChannel,
        messages: List<Message>.of(conversation.messages),
      ),
      actions: _conversationActions(conversation.isChannel),
    );
  }

  DarwinNotificationDetails _darwinDetails(String? imagePath, int? badge) =>
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: badge,
        attachments: imagePath != null
            ? <DarwinNotificationAttachment>[
                DarwinNotificationAttachment(imagePath),
              ]
            : null,
      );

  Future<void> _showConversationNotificationImpl({
    required int id,
    required String payload,
    required String title,
    required bool isChannel,
    required String message,
    required bool urlImagesEnabled,
    String? senderName,
    int? badgeCount,
    bool silent = false,
  }) async {
    if (!await _ensureCanNotify()) return;

    final imagePath = await _resolveNotificationImagePath(
      message,
      urlImagesEnabled: urlImagesEnabled,
    );
    final preview = formatNotificationText(message.trim());
    final body = preview.isEmpty
        ? _l10n.notification_receivedNewMessage
        : preview;

    final conversation =
        _conversations.putIfAbsent(
            id,
            () => _Conversation(
              title: title,
              payload: payload,
              isChannel: isChannel,
            ),
          )
          ..title = title
          ..badgeCount = badgeCount
          ..imagePath = imagePath;
    final sender = isChannel ? (senderName ?? title) : title;
    conversation.add(
      Message(
        body,
        DateTime.now(),
        Person(key: isChannel ? 'sender:$sender' : payload, name: sender),
      ),
      _maxConversationMessages,
    );

    final notificationDetails = NotificationDetails(
      android: _androidConversationDetails(
        conversation,
        badgeCount: badgeCount,
        silent: silent,
      ),
      iOS: _darwinDetails(imagePath, badgeCount),
      macOS: _darwinDetails(imagePath, badgeCount),
    );

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: _collapsedBody(conversation),
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show message notification: $e');
    }
  }

  /// Text shown when the notification is collapsed. Channel messages keep
  /// the sender prefix, including after your own reply.
  String _collapsedBody(_Conversation conversation) {
    final last = conversation.messages.last;
    if (!conversation.isChannel) return last.text;
    final sender = last.person?.name ?? _selfName ?? _l10n.notification_you;
    return '$sender: ${last.text}';
  }

  int _conversationId(NotificationReply reply) => reply.isChannel
      ? reply.channelIndex!.hashCode
      : reply.contactKeyHex!.hashCode;

  /// Adds the user's reply to the conversation notification. Android keeps
  /// showing a progress spinner on a replied notification until it is updated.
  /// Pass the current [badgeCount]: an update replaces the whole notification,
  /// and the Android launcher badge comes from the notification number.
  Future<void> showOwnReply(
    NotificationReply reply,
    String text, {
    int? badgeCount,
  }) async {
    if (!await _ensureInitialized()) return;
    final id = _conversationId(reply);
    final conversation = _conversations[id];
    if (conversation == null) {
      await _notifications.cancel(id: id);
      return;
    }
    conversation.badgeCount = badgeCount ?? conversation.badgeCount;
    conversation.add(
      Message(text, DateTime.now(), null),
      _maxConversationMessages,
    );
    await _repostConversation(id, conversation);
  }

  /// Tells the user a notification reply could not be sent.
  Future<void> showReplyFailed(
    NotificationReply reply,
    NotificationReplyFailure failure, {
    int? badgeCount,
  }) async {
    if (!await _ensureInitialized()) return;
    final reason = switch (failure) {
      NotificationReplyFailure.notConnected =>
        _l10n.notification_replyNotConnected,
      NotificationReplyFailure.unavailable =>
        _l10n.notification_replyUnavailable,
      NotificationReplyFailure.tooLong => _l10n.notification_replyTooLong,
      NotificationReplyFailure.sendFailed => _l10n.notification_replySendFailed,
    };
    final id = _conversationId(reply);
    final conversation = _conversations[id];
    if (conversation != null) {
      conversation.badgeCount = badgeCount ?? conversation.badgeCount;
      await _repostConversation(id, conversation);
    } else {
      await _notifications.cancel(id: id);
    }
    try {
      await _notifications.show(
        id: 'reply_failed:$id'.hashCode,
        title: _l10n.notification_replyFailedTitle,
        body: reason,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'messages',
            'Messages',
            channelDescription: 'New message notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: conversation?.payload,
      );
    } catch (e) {
      debugPrint('Failed to show reply failure notification: $e');
    }
  }

  Future<void> _repostConversation(int id, _Conversation conversation) async {
    try {
      await _notifications.show(
        id: id,
        title: conversation.title,
        body: _collapsedBody(conversation),
        notificationDetails: NotificationDetails(
          android: _androidConversationDetails(
            conversation,
            badgeCount: conversation.badgeCount,
            silent: true,
          ),
        ),
        payload: conversation.payload,
      );
    } catch (e) {
      debugPrint('Failed to update message notification: $e');
    }
  }

  Future<void> _showAdvertNotificationImpl({
    required String contactName,
    required String contactType,
    String? contactId,
  }) async {
    if (!await _ensureCanNotify()) return;

    const androidDetails = AndroidNotificationDetails(
      'adverts',
      'Advertisements',
      channelDescription: 'New node advertisement notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const macDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macDetails,
    );

    try {
      await _notifications.show(
        id: contactId != null
            ? 'advert:$contactId'.hashCode
            : DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
        title: _l10n.notification_newTypeDiscovered(contactType),
        body: contactName,
        notificationDetails: notificationDetails,
        payload: 'advert:$contactId',
      );
    } catch (e) {
      debugPrint('Failed to show advert notification: $e');
    }
  }

  /// Posts a low-battery alert for the connected device.
  ///
  /// Uses a per-threshold notification id so each alert level updates its own
  /// notification instead of stacking. Bypasses the rate-limit queue, which
  /// only handles message and advert notifications.
  Future<void> showLowBatteryNotification({
    required int batteryPercent,
    required int threshold,
  }) async {
    if (!await _ensureCanNotify()) return;

    const androidDetails = AndroidNotificationDetails(
      'low_battery',
      'Low Battery',
      channelDescription: 'Low battery alerts for the connected device',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _notifications.show(
        id: 'low_battery:$threshold'.hashCode,
        title: _l10n.notification_lowBatteryTitle,
        body: _l10n.notification_lowBatteryBody(batteryPercent),
        notificationDetails: notificationDetails,
        payload: 'low_battery',
      );
    } catch (e) {
      debugPrint('Failed to show low battery notification: $e');
    }
  }

  /// Returns a privacy-safe identifier for debug logging.
  /// - advert: shows device name (body contains contactName)
  /// - message: shows "from: sender" (avoids logging message content)
  /// - channelMessage: shows "in: channel" (avoids logging message content)
  String _getNotificationIdentifier(_PendingNotification n) {
    switch (n.type) {
      case _NotificationType.advert:
        return _logSafe(n.body);
      case _NotificationType.message:
        return 'from: ${_logSafe(n.title)}';
      case _NotificationType.channelMessage:
        return 'in: ${_logSafe(n.title)}';
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      debugPrint('Notification tapped: $payload');
      // Handle navigation based on payload
      // This can be extended to navigate to specific screens
    }
  }

  Future<void> cancelAll() async {
    _conversations.clear();
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id: id);
  }

  /// Cancel the notification for a specific contact and update the app badge.
  Future<void> clearContactNotification(
    String contactId,
    int totalUnreadCount,
  ) async {
    if (!await _ensureInitialized()) return;
    _conversations.remove(contactId.hashCode);
    await _notifications.cancel(id: contactId.hashCode);
    await _updateBadge(totalUnreadCount);
  }

  /// Cancel the notification for a specific channel and update the app badge.
  Future<void> clearChannelNotification(
    int channelIndex,
    int totalUnreadCount,
  ) async {
    if (!await _ensureInitialized()) return;
    _conversations.remove(channelIndex.hashCode);
    await _notifications.cancel(id: channelIndex.hashCode);
    await _updateBadge(totalUnreadCount);
  }

  /// Cancel advert notifications for the given contact public key hexes.
  Future<void> clearAdvertNotifications(List<String> contactIds) async {
    if (!await _ensureInitialized()) return;
    for (final id in contactIds) {
      await _notifications.cancel(id: 'advert:$id'.hashCode);
    }
  }

  Future<void> _updateBadge(int count) async {
    if (PlatformInfo.isIOS || PlatformInfo.isMacOS) {
      // On Apple platforms, set the badge number directly via a silent update.
      final darwinDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentSound: false,
        presentBadge: true,
        badgeNumber: count,
      );
      final details = NotificationDetails(
        iOS: darwinDetails,
        macOS: darwinDetails,
      );
      // Use a fixed ID so each update replaces the previous one.
      await _notifications.show(
        id: 'badge_update'.hashCode,
        title: null,
        body: null,
        notificationDetails: details,
      );
      // Immediately cancel the silent notification so it doesn't appear in tray.
      await _notifications.cancel(id: 'badge_update'.hashCode);
    }
    // On Android, badge count is derived from active notifications,
    // so cancelling the specific notification above is sufficient.
  }

  // ─────────────────────────────────────────────────────────────────
  // Public notification methods (rate limiting is enforced automatically)
  // ─────────────────────────────────────────────────────────────────

  Future<void> showMessageNotification({
    required String contactName,
    required String message,
    required bool urlImagesEnabled,
    String? contactId,
    int? badgeCount,
  }) async {
    if (_suppressNotifications) return;

    _queueNotification(
      _PendingNotification(
        type: _NotificationType.message,
        title: contactName,
        body: message,
        urlImagesEnabled: urlImagesEnabled,
        id: contactId,
        badgeCount: badgeCount,
      ),
    );
  }

  Future<void> showAdvertNotification({
    required String contactName,
    required String contactType,
    String? contactId,
  }) async {
    if (_suppressNotifications) return;

    _queueNotification(
      _PendingNotification(
        type: _NotificationType.advert,
        title: contactType,
        body: contactName,
        id: contactId,
      ),
    );
  }

  Future<void> showChannelMessageNotification({
    required String channelName,
    required String senderName,
    required String message,
    required bool urlImagesEnabled,
    int? channelIndex,
    int? badgeCount,
  }) async {
    if (_suppressNotifications) return;

    _queueNotification(
      _PendingNotification(
        type: _NotificationType.channelMessage,
        title: channelName,
        body: message,
        senderName: senderName,
        urlImagesEnabled: urlImagesEnabled,
        id: channelIndex?.toString(),
        badgeCount: badgeCount,
      ),
    );
  }

  void _queueNotification(_PendingNotification notification) {
    final now = DateTime.now();
    final throttled =
        _lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) < _minNotificationInterval;

    // Messages always update their conversation notification so the reply
    // action stays available; during a burst they update silently.
    if (notification.type != _NotificationType.advert) {
      _showNotificationImmediately(notification, silent: throttled);
      if (!throttled) _lastNotificationTime = now;
      return;
    }

    // If we recently showed a notification, start batching
    if (throttled) {
      _pendingNotifications.add(notification);
      debugPrint(
        '[Notification] queued: ${notification.type.name} (${_getNotificationIdentifier(notification)})',
      );

      // Start batch timer if not already running
      if (!_isBatchingActive) {
        _isBatchingActive = true;
        Future.delayed(_batchWindow, _processBatch);
      }
      return;
    }

    // Show immediately if enough time has passed
    debugPrint(
      '[Notification] sent immediately: ${notification.type.name} (${_getNotificationIdentifier(notification)})',
    );
    _showNotificationImmediately(notification);
    _lastNotificationTime = now;
  }

  Future<void> _processBatch() async {
    _isBatchingActive = false;

    if (_pendingNotifications.isEmpty) return;

    final batch = List<_PendingNotification>.from(_pendingNotifications);
    _pendingNotifications.clear();

    if (batch.length == 1) {
      // Single notification, show normally
      _showNotificationImmediately(batch.first);
    } else {
      // Multiple notifications, show summary
      await _showBatchSummary(batch);
    }

    _lastNotificationTime = DateTime.now();
  }

  Future<void> _showNotificationImmediately(
    _PendingNotification notification, {
    bool silent = false,
  }) async {
    try {
      switch (notification.type) {
        case _NotificationType.message:
          await _showConversationNotificationImpl(
            id: notification.id?.hashCode ?? 0,
            payload: 'message:${notification.id}',
            title: notification.title,
            isChannel: false,
            message: notification.body,
            urlImagesEnabled: notification.urlImagesEnabled,
            badgeCount: notification.badgeCount,
            silent: silent,
          );
          break;
        case _NotificationType.advert:
          await _showAdvertNotificationImpl(
            contactName: notification.body,
            contactType: notification.title,
            contactId: notification.id,
          );
          break;
        case _NotificationType.channelMessage:
          final channelIndex = int.tryParse(notification.id ?? '');
          await _showConversationNotificationImpl(
            id:
                channelIndex?.hashCode ??
                DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
            payload: 'channel:$channelIndex',
            title: notification.title,
            isChannel: true,
            message: notification.body,
            senderName: notification.senderName,
            urlImagesEnabled: notification.urlImagesEnabled,
            badgeCount: notification.badgeCount,
            silent: silent,
          );
          break;
      }
    } catch (e) {
      debugPrint('Failed to show immediate notification: $e');
    }
  }

  /// Only adverts are batched; messages always update their conversation
  /// notification instead.
  Future<void> _showBatchSummary(List<_PendingNotification> adverts) async {
    if (adverts.isEmpty || !await _ensureCanNotify()) return;

    final summary = _l10n.notification_newNodesCount(adverts.length);
    final deviceInfo =
        ' (${adverts.take(5).map((n) => _logSafe(n.body)).join(', ')}${adverts.length > 5 ? ', ...' : ''})';
    debugPrint('[Notification] batch summary: $summary$deviceInfo');

    const androidDetails = AndroidNotificationDetails(
      'batch_summary',
      'Activity Summary',
      channelDescription: 'Batched notification summaries',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(
        id: 'batch_summary'.hashCode,
        title: _l10n.notification_activityTitle,
        body: summary,
        notificationDetails: notificationDetails,
        payload: 'batch',
      );
    } catch (e) {
      debugPrint('Failed to show batch summary notification: $e');
    }
  }
}

// Helper class for pending notifications
enum _NotificationType { message, advert, channelMessage }

class _PendingNotification {
  final _NotificationType type;
  final String title;
  final String body;
  final String? senderName;
  final bool urlImagesEnabled;
  final String? id;
  final int? badgeCount;

  _PendingNotification({
    required this.type,
    required this.title,
    required this.body,
    this.senderName,
    this.urlImagesEnabled = false,
    this.id,
    this.badgeCount,
  });
}

class _Conversation {
  String title;
  int? badgeCount;
  String? imagePath;
  final String payload;
  final bool isChannel;
  final List<Message> messages = [];

  _Conversation({
    required this.title,
    required this.payload,
    required this.isChannel,
  });

  void add(Message message, int max) {
    messages.add(message);
    if (messages.length > max) messages.removeRange(0, messages.length - max);
  }
}
