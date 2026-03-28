import 'dart:io' show Platform, File;
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

import '../helpers/reaction_helper.dart';
import '../l10n/app_localizations.dart';
import '../utils/platform_info.dart';

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
  }

  AppLocalizations get _l10n => lookupAppLocalizations(_locale);

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
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
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
      return granted ?? false;
    }

    return true;
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

  Future<void> _showMessageNotificationImpl({
    required String contactName,
    required String message,
    String? contactId,
    int? badgeCount,
  }) async {
    if (!await _ensureInitialized()) return;

    final androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      number: badgeCount,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: badgeCount,
    );

    final macDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: badgeCount,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macDetails,
    );

    try {
      await _notifications.show(
        id: contactId?.hashCode ?? 0,
        title: contactName,
        body: formatNotificationText(message),
        notificationDetails: notificationDetails,
        payload: 'message:$contactId',
      );
    } catch (e) {
      debugPrint('Failed to show message notification: $e');
    }
  }

  Future<void> _showAdvertNotificationImpl({
    required String contactName,
    required String contactType,
    String? contactId,
  }) async {
    if (!await _ensureInitialized()) return;

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
            : DateTime.now().millisecondsSinceEpoch,
        title: _l10n.notification_newTypeDiscovered(contactType),
        body: contactName,
        notificationDetails: notificationDetails,
        payload: 'advert:$contactId',
      );
    } catch (e) {
      debugPrint('Failed to show advert notification: $e');
    }
  }

  Future<void> _showChannelMessageNotificationImpl({
    required String channelName,
    required String message,
    int? channelIndex,
    int? badgeCount,
  }) async {
    if (!await _ensureInitialized()) return;

    final androidDetails = AndroidNotificationDetails(
      'channel_messages',
      'Channel Messages',
      channelDescription: 'New channel message notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      number: badgeCount,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: badgeCount,
    );

    final macDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: badgeCount,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macDetails,
    );

    final preview = formatNotificationText(message.trim());
    final body = preview.isEmpty
        ? _l10n.notification_receivedNewMessage
        : preview;

    try {
      await _notifications.show(
        id: channelIndex?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        title: channelName,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'channel:$channelIndex',
      );
    } catch (e) {
      debugPrint('Failed to show channel notification: $e');
    }
  }

  /// Returns a privacy-safe identifier for debug logging.
  /// - advert: shows device name (body contains contactName)
  /// - message: shows "from: sender" (avoids logging message content)
  /// - channelMessage: shows "in: channel" (avoids logging message content)
  String _getNotificationIdentifier(_PendingNotification n) {
    switch (n.type) {
      case _NotificationType.advert:
        return n.body;
      case _NotificationType.message:
        return 'from: ${n.title}';
      case _NotificationType.channelMessage:
        return 'in: ${n.title}';
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
    await _notifications.cancel(id: contactId.hashCode);
    await _updateBadge(totalUnreadCount);
  }

  /// Cancel the notification for a specific channel and update the app badge.
  Future<void> clearChannelNotification(
    int channelIndex,
    int totalUnreadCount,
  ) async {
    if (!await _ensureInitialized()) return;
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
    String? contactId,
    int? badgeCount,
  }) async {
    if (_suppressNotifications) return;

    _queueNotification(
      _PendingNotification(
        type: _NotificationType.message,
        title: contactName,
        body: message,
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
    int? channelIndex,
    int? badgeCount,
  }) async {
    if (_suppressNotifications) return;

    _queueNotification(
      _PendingNotification(
        type: _NotificationType.channelMessage,
        title: channelName,
        body: '$senderName: $message',
        id: channelIndex?.toString(),
        badgeCount: badgeCount,
      ),
    );
  }

  void _queueNotification(_PendingNotification notification) {
    final now = DateTime.now();

    // If we recently showed a notification, start batching
    if (_lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) < _minNotificationInterval) {
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
    _PendingNotification notification,
  ) async {
    try {
      switch (notification.type) {
        case _NotificationType.message:
          await _showMessageNotificationImpl(
            contactName: notification.title,
            message: notification.body,
            contactId: notification.id,
            badgeCount: notification.badgeCount,
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
          await _showChannelMessageNotificationImpl(
            channelName: notification.title,
            message: notification.body,
            channelIndex: int.tryParse(notification.id ?? ''),
            badgeCount: notification.badgeCount,
          );
          break;
      }
    } catch (e) {
      debugPrint('Failed to show immediate notification: $e');
    }
  }

  Future<void> _showBatchSummary(List<_PendingNotification> batch) async {
    if (!await _ensureInitialized()) return;

    // Group by type
    final messages = batch
        .where((n) => n.type == _NotificationType.message)
        .toList();
    final adverts = batch
        .where((n) => n.type == _NotificationType.advert)
        .toList();
    final channelMsgs = batch
        .where((n) => n.type == _NotificationType.channelMessage)
        .toList();

    // Build summary text using localized plurals
    final parts = <String>[];
    if (messages.isNotEmpty) {
      parts.add(_l10n.notification_messagesCount(messages.length));
    }
    if (channelMsgs.isNotEmpty) {
      parts.add(_l10n.notification_channelMessagesCount(channelMsgs.length));
    }
    if (adverts.isNotEmpty) {
      parts.add(_l10n.notification_newNodesCount(adverts.length));
    }

    if (parts.isEmpty) return;

    // Show first few device names in batch summary for debugging (only if adverts exist)
    final deviceInfo = adverts.isNotEmpty
        ? ' (${adverts.take(5).map((n) => n.body).join(', ')}${adverts.length > 5 ? ', ...' : ''})'
        : '';
    debugPrint('[Notification] batch summary: ${parts.join(", ")}$deviceInfo');

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
        body: parts.join(', '),
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
  final String? id;
  final int? badgeCount;

  _PendingNotification({
    required this.type,
    required this.title,
    required this.body,
    this.id,
    this.badgeCount,
  });
}
