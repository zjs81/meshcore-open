import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_blue_plus_platform_interface/flutter_blue_plus_platform_interface.dart';

import '../models/channel.dart';
import '../models/channel_message.dart';
import '../models/companion_radio_stats.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/path_selection.dart';
import '../models/translation_support.dart';
import '../helpers/reaction_helper.dart';
import '../helpers/smaz.dart';
import '../services/app_debug_log_service.dart';
import '../services/ble_debug_log_service.dart';
import '../services/linux_ble_error_classifier.dart';
import '../services/linux_ble_pairing_service_stub.dart'
    if (dart.library.io) '../services/linux_ble_pairing_service.dart';
import '../services/message_retry_service.dart';
import '../services/path_history_service.dart';
import '../services/app_settings_service.dart';
import '../services/background_service.dart';
import '../services/timeout_prediction_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';
import 'meshcore_connector_usb.dart';
import 'meshcore_connector_tcp.dart';
import '../storage/channel_message_store.dart';
import '../storage/channel_order_store.dart';
import '../storage/channel_settings_store.dart';
import '../storage/channel_store.dart';
import '../storage/contact_discovery_store.dart';
import '../storage/contact_settings_store.dart';
import '../storage/contact_store.dart';
import '../storage/message_store.dart';
import '../storage/unread_store.dart';
import '../utils/app_logger.dart';
import '../utils/battery_utils.dart';
import '../utils/platform_info.dart';
import 'meshcore_uuids.dart';
import 'meshcore_protocol.dart';

class DirectRepeater {
  static const int maxAgeMinutes = 30; // Max age for direct repeater info
  final int pubkeyFirstByte;
  double snr;
  DateTime lastUpdated;

  DirectRepeater({
    required this.pubkeyFirstByte,
    required this.snr,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  void update(double newSNR) {
    snr = newSNR;
    lastUpdated = DateTime.now();
  }

  int get ranking {
    if (isStale()) {
      return -1; // Stale repeaters get lowest rank
    }
    // Higher SNR gets higher rank and recency within maxAgeMinutes breaks ties.
    final ageMs =
        DateTime.now().millisecondsSinceEpoch -
        lastUpdated.millisecondsSinceEpoch;
    final maxAgeMs = maxAgeMinutes * 60 * 1000;
    final recencyScore = (maxAgeMs - ageMs).clamp(0, maxAgeMs);
    return ((snr - 31.75) * 1000).round() + recencyScore;
  }

  bool isStale() {
    return DateTime.now().difference(lastUpdated) >
        const Duration(minutes: maxAgeMinutes);
  }
}

enum MeshCoreConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
}

enum MeshCoreTransportType { bluetooth, usb, tcp }

class RepeaterBatterySnapshot {
  final int millivolts;
  final DateTime updatedAt;
  final String source;

  const RepeaterBatterySnapshot({
    required this.millivolts,
    required this.updatedAt,
    required this.source,
  });
}

class MeshCoreRadioStateSnapshot {
  final int freqHz;
  final int bwHz;
  final int sf;
  final int cr;
  final int txPowerDbm;

  const MeshCoreRadioStateSnapshot({
    required this.freqHz,
    required this.bwHz,
    required this.sf,
    required this.cr,
    required this.txPowerDbm,
  });
}

class MeshCoreConnector extends ChangeNotifier {
  // Message windowing to limit memory usage
  static const int _messageWindowSize = 200;

  MeshCoreConnectionState _state = MeshCoreConnectionState.disconnected;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  String? _deviceDisplayName;
  String? _deviceId;
  BluetoothDevice? _lastDevice;
  String? _lastDeviceId;
  String? _lastDeviceDisplayName;
  bool _manualDisconnect = false;
  final MeshCoreUsbManager _usbManager = MeshCoreUsbManager();
  final LinuxBlePairingService _linuxBlePairingService =
      LinuxBlePairingService();
  StreamSubscription<Uint8List>? _usbFrameSubscription;
  final MeshCoreTcpConnector _tcpConnector = MeshCoreTcpConnector();
  MeshCoreTransportType _activeTransport = MeshCoreTransportType.bluetooth;

  final List<ScanResult> _scanResults = [];
  final List<ScanResult> _linuxSystemScanResults = [];
  final List<Contact> _contacts = [];
  final List<Contact> _discoveredContacts = [];
  final List<Channel> _channels = [];
  final Map<String, List<Message>> _conversations = {};
  final Map<int, List<ChannelMessage>> _channelMessages = {};
  final List<String> _pendingChannelSentQueue = [];
  final List<_PendingCommandAck> _pendingGenericAckQueue = [];
  static const String _reactionSendQueuePrefix = '__reaction_send__';
  int _reactionSendQueueSequence = 0;
  final Set<String> _loadedConversationKeys = {};
  final Map<int, Set<String>> _processedChannelReactions =
      {}; // channelIndex -> Set of "targetHash_emoji"
  final Map<String, Set<String>> _processedContactReactions =
      {}; // contactPubKeyHex -> Set of "targetHash_emoji"

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  Timer? _notifyListenersTimer;
  Timer? _selfInfoRetryTimer;
  Timer? _reconnectTimer;
  Timer? _batteryPollTimer;
  Timer? _radioStatsPollTimer;
  int _radioStatsPollRefCount = 0;
  final ValueNotifier<CompanionRadioStats?> radioStatsNotifier =
      ValueNotifier<CompanionRadioStats?>(null);
  int _reconnectAttempts = 0;
  bool _notifyListenersDirty = false;
  static const Duration _notifyListenersDebounce = Duration(milliseconds: 50);

  final StreamController<Uint8List> _receivedFramesController =
      StreamController<Uint8List>.broadcast();

  Uint8List? _selfPublicKey;
  String? _selfName;
  int? _currentTxPower;
  int? _maxTxPower;
  int? _currentFreqHz;
  int? _currentBwHz;
  int? _currentSf;
  int? _currentCr;
  bool? _clientRepeat;
  MeshCoreRadioStateSnapshot? _rememberedNonRepeatRadioState;
  int? _firmwareVerCode;
  int _pathHashByteWidth = 1;
  CompanionRadioStats? _latestRadioStats;
  Stopwatch? _airtimeBumpStopwatch;
  int _prevTotalAirSecs = 0;
  int? _batteryMillivolts;
  double? _selfLatitude;
  double? _selfLongitude;
  final List<DirectRepeater> _directRepeaters = List.empty(growable: true);
  bool _isLoadingContacts = false;
  bool _isLoadingChannels = false;
  bool _hasLoadedChannels = false;
  TimeoutPredictionService? _timeoutPredictionService;
  TranslationService? _translationService;
  // Intentionally global (not per-contact): tracks overall network activity.
  // Frequent RX from any source indicates a busy network with more collisions.
  DateTime _lastRxTime = DateTime.now();
  DateTime _lastRadioRxTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastContactMsgRxTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastChannelMsgRxTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _radioQuietMs = 3000;
  static const int _radioQuietMaxWaitMs = 3000;

  /// When companion radio stats are unavailable, keep the legacy fixed backoff.
  static const int _contactMsgBackoffFallbackMs = 5000;
  static const int _contactMsgBackoffMinMs = 500;
  static const int _contactMsgBackoffMaxMs = 15000;
  int _pollingInterval = 30;
  bool _batteryRequested = false;
  bool _awaitingSelfInfo = false;
  bool _hasReceivedDeviceInfo = false;
  bool _pendingInitialChannelSync = false;
  bool _pendingInitialContactsSync = false;
  bool _bleInitialSyncStarted = false;
  bool _pendingDeferredChannelSyncAfterContacts = false;
  bool _webInitialHandshakeRequestSent = false;
  bool _preserveContactsOnRefresh = false;
  bool _autoAddUsers = false;
  bool _autoAddRepeaters = false;
  bool _autoAddRoomServers = false;
  bool _autoAddSensors = false;
  bool _overwriteOldest = false;
  bool _manualAddContacts = false;
  int _telemetryModeBase = 0;
  int _telemetryModeLoc = 0;
  int _telemetryModeEnv = 0;
  int _advertLocPolicy = 0;
  int _multiAcks = 0;

  static const int _defaultMaxContacts = 32;
  static const int _defaultMaxChannels = 8;
  int _maxContacts = _defaultMaxContacts;
  int _maxChannels = _defaultMaxChannels;
  bool _isSyncingQueuedMessages = false;
  bool _queuedMessageSyncInFlight = false;
  bool _didInitialQueueSync = false;
  bool _pendingQueueSync = false;
  Timer? _queueSyncTimeout;
  int _queueSyncRetries = 0;
  static const int _maxQueueSyncRetries = 3;
  static const int _queueSyncTimeoutMs = 5000; // 5 second timeout
  // Serializes path operations (setContactPath/clearContactPath) to prevent
  // interleaved async calls from leaving in-memory state inconsistent with device.
  Future<void> _pathOpLock = Future.value();
  Map<String, String>? _currentCustomVars;

  // Channel syncing state (sequential pattern)
  bool _isSyncingChannels = false;
  bool _channelSyncInFlight = false;
  Timer? _channelSyncTimeout;
  int _channelSyncRetries = 0;
  int _nextChannelIndexToRequest = 0;
  int _totalChannelsToRequest = 0;
  List<Channel> _previousChannelsCache = [];
  static const int _maxChannelSyncRetries = 3;
  static const int _channelSyncTimeoutMs = 2000; // 2 second timeout per channel
  static const Duration _batteryPollInterval = Duration(seconds: 120);

  // Services
  MessageRetryService? _retryService;
  PathHistoryService? _pathHistoryService;
  AppSettingsService? _appSettingsService;
  BackgroundService? _backgroundService;
  final NotificationService _notificationService = NotificationService();
  BleDebugLogService? _bleDebugLogService;
  AppDebugLogService? _appDebugLogService;
  final ChannelMessageStore _channelMessageStore = ChannelMessageStore();
  final MessageStore _messageStore = MessageStore();
  final ChannelOrderStore _channelOrderStore = ChannelOrderStore();
  final ChannelSettingsStore _channelSettingsStore = ChannelSettingsStore();
  final ContactSettingsStore _contactSettingsStore = ContactSettingsStore();
  final ContactStore _contactStore = ContactStore();
  final ContactDiscoveryStore _discoveryContactStore = ContactDiscoveryStore();
  final ChannelStore _channelStore = ChannelStore();
  final UnreadStore _unreadStore = UnreadStore();
  List<Channel> _cachedChannels = [];
  final Map<int, bool> _channelSmazEnabled = {};
  bool _lastSentWasCliCommand =
      false; // Track if last sent message was a CLI command
  final Map<String, bool> _contactSmazEnabled = {};
  final Set<String> _knownContactKeys = {};
  final Map<String, int> _contactUnreadCount = {};
  final Map<String, RepeaterBatterySnapshot> _repeaterBatterySnapshots = {};
  bool _unreadStateLoaded = false;
  final Map<String, _RepeaterAckContext> _pendingRepeaterAcks = {};
  String? _activeContactKey;
  int? _activeChannelIndex;
  List<int> _channelOrder = [];

  int _storageUsedKb = -1;
  int _storageTotalKb = -1;

  // Getters
  MeshCoreConnectionState get state => _state;
  BluetoothDevice? get device => _device;
  String? get deviceId => _deviceId;
  String get deviceIdLabel => _deviceId ?? 'Unknown';

  MeshCoreTransportType get activeTransport => _activeTransport;
  String? get activeUsbPort => _usbManager.activePortKey;
  String? get activeUsbPortDisplayLabel => _usbManager.activePortDisplayLabel;
  bool get isUsbTransportConnected =>
      _state == MeshCoreConnectionState.connected &&
      _activeTransport == MeshCoreTransportType.usb;
  bool get isAutoReconnectScheduled =>
      _shouldAutoReconnect && (_reconnectTimer?.isActive ?? false);
  String? get activeTcpEndpoint => _tcpConnector.activeEndpoint;
  bool get isTcpTransportConnected =>
      _state == MeshCoreConnectionState.connected &&
      _activeTransport == MeshCoreTransportType.tcp;

  String get deviceDisplayName {
    if (_selfName != null && _selfName!.isNotEmpty) {
      return _selfName!;
    }
    final platformName = _device?.platformName;
    if (platformName != null && platformName.isNotEmpty) {
      return platformName;
    }
    if (_deviceDisplayName != null && _deviceDisplayName!.isNotEmpty) {
      return _deviceDisplayName!;
    }
    return 'Unknown Device';
  }

  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  List<Contact> get contacts {
    final selfKey = _selfPublicKey;
    if (selfKey == null) {
      return List.unmodifiable(_contacts);
    }
    return List.unmodifiable(
      _contacts.where((contact) => !listEquals(contact.publicKey, selfKey)),
    );
  }

  List<Contact> get allContacts => List.unmodifiable([
    ..._contacts,
    ..._discoveredContacts.where(
      (c) => !c.isActive && c.publicKeyHex != selfPublicKeyHex,
    ),
  ]);

  List<Contact> get allContactsUnfiltered =>
      List.unmodifiable([..._contacts, ..._discoveredContacts]);

  List<Contact> get discoveredContacts {
    return List.unmodifiable(_discoveredContacts);
  }

  List<Channel> get channels => List.unmodifiable(_channels);
  bool get isConnected => _state == MeshCoreConnectionState.connected;
  bool get isLoadingContacts => _isLoadingContacts;
  bool get isLoadingChannels => _isLoadingChannels;
  Stream<Uint8List> get receivedFrames => _receivedFramesController.stream;
  Uint8List? get selfPublicKey => _selfPublicKey;
  String get selfPublicKeyHex => pubKeyToHex(_selfPublicKey ?? Uint8List(0));
  String? get selfName => _selfName;
  double? get selfLatitude => _selfLatitude;
  double? get selfLongitude => _selfLongitude;
  List<DirectRepeater> get directRepeaters => _directRepeaters;
  int? get currentTxPower => _currentTxPower;
  int? get maxTxPower => _maxTxPower;

  int get pathHashByteWidth => _pathHashByteWidth;

  CompanionRadioStats? get latestRadioStats => _latestRadioStats;

  bool get supportsCompanionRadioStats => (_firmwareVerCode ?? 0) >= 8;

  bool get radioStatsAirActivityPulse {
    final sw = _airtimeBumpStopwatch;
    if (sw == null || !sw.isRunning) return false;
    return sw.elapsed < const Duration(seconds: 2);
  }

  int? get currentFreqHz => _currentFreqHz;
  int? get currentBwHz => _currentBwHz;
  int? get currentSf => _currentSf;
  int? get currentCr => _currentCr;
  MeshCoreRadioStateSnapshot? get rememberedNonRepeatRadioState =>
      _rememberedNonRepeatRadioState;
  bool? get autoAddUsers => _autoAddUsers;
  bool? get autoAddRepeaters => _autoAddRepeaters;
  bool? get autoAddRoomServers => _autoAddRoomServers;
  bool? get autoAddSensors => _autoAddSensors;
  bool? get autoAddOverwriteOldest => _overwriteOldest;
  int get telemetryModeBase => _telemetryModeBase;
  int get telemetryModeLoc => _telemetryModeLoc;
  int get telemetryModeEnv => _telemetryModeEnv;
  int get advertLocationPolicy => _advertLocPolicy;
  int get multiAcks => _multiAcks;
  bool? get clientRepeat => _clientRepeat;
  void rememberNonRepeatRadioState(MeshCoreRadioStateSnapshot snapshot) {
    _rememberedNonRepeatRadioState = snapshot;
  }

  int? get firmwareVerCode => _firmwareVerCode;
  Map<String, String>? get currentCustomVars => _currentCustomVars;
  int? get batteryMillivolts => _batteryMillivolts;
  int? get storageUsedKb => _storageUsedKb;
  int? get storageTotalKb => _storageTotalKb;
  int get maxContacts => _maxContacts;
  int get maxChannels => _maxChannels;
  Set<String> get knownContactKeys => Set.unmodifiable(_knownContactKeys);
  bool get isSyncingQueuedMessages => _isSyncingQueuedMessages;
  bool get isSyncingChannels => _isSyncingChannels;
  int get channelSyncProgress =>
      _isSyncingChannels && _totalChannelsToRequest > 0
      ? ((_nextChannelIndexToRequest / _totalChannelsToRequest) * 100).round()
      : 0;
  int? get batteryPercent => _batteryMillivolts == null
      ? null
      : estimateBatteryPercentFromMillivolts(
          _batteryMillivolts!,
          _batteryChemistryForDevice(),
        );
  RepeaterBatterySnapshot? getRepeaterBatterySnapshot(String contactKeyHex) =>
      _repeaterBatterySnapshots[contactKeyHex];
  int? getRepeaterBatteryMillivolts(String contactKeyHex) =>
      _repeaterBatterySnapshots[contactKeyHex]?.millivolts;

  void updateRepeaterBatterySnapshot(
    String contactKeyHex,
    int millivolts, {
    String source = 'unknown',
  }) {
    if (contactKeyHex.isEmpty || millivolts <= 0) return;
    final previous = _repeaterBatterySnapshots[contactKeyHex];
    final snapshot = RepeaterBatterySnapshot(
      millivolts: millivolts,
      updatedAt: DateTime.now(),
      source: source,
    );
    _repeaterBatterySnapshots[contactKeyHex] = snapshot;
    if (previous?.millivolts != millivolts) {
      notifyListeners();
    }
  }

  String _batteryChemistryForDevice() {
    final deviceId = _device?.remoteId.toString();
    if (deviceId == null || _appSettingsService == null) return 'nmc';
    return _appSettingsService!.batteryChemistryForDevice(deviceId);
  }

  List<Message> getMessages(Contact contact) {
    return _conversations[contact.publicKeyHex] ?? [];
  }

  Future<void> deleteMessage(Message message) async {
    final contactKeyHex = message.senderKeyHex;
    final messages = _conversations[contactKeyHex];
    if (messages == null) return;
    final removed = messages.remove(message);
    if (!removed) return;
    await _messageStore.saveMessages(contactKeyHex, messages);
    notifyListeners();
  }

  Future<void> _loadMessagesForContact(String contactKeyHex) async {
    if (_loadedConversationKeys.contains(contactKeyHex)) return;
    _loadedConversationKeys.add(contactKeyHex);

    final allMessages = await _messageStore.loadMessages(contactKeyHex);
    if (allMessages.isNotEmpty) {
      // Keep only the most recent N messages in memory to bound memory usage
      final windowedMessages = allMessages.length > _messageWindowSize
          ? allMessages.sublist(allMessages.length - _messageWindowSize)
          : allMessages;

      final currentMessages =
          _conversations[contactKeyHex] ?? const <Message>[];
      final mergedMessages = <Message>[...windowedMessages];
      final persistedKeyCounts = <String, int>{};
      for (final message in windowedMessages) {
        final key = _messageMergeKey(message);
        persistedKeyCounts[key] = (persistedKeyCounts[key] ?? 0) + 1;
      }
      final currentKeyCounts = <String, int>{};

      for (final message in currentMessages) {
        final key = _messageMergeKey(message);
        final currentCount = (currentKeyCounts[key] ?? 0) + 1;
        currentKeyCounts[key] = currentCount;
        final persistedCount = persistedKeyCounts[key] ?? 0;

        // Preserve distinct duplicates without IDs (for example same text
        // received multiple times in the same second) by only skipping the
        // overlapping occurrences that already exist in persisted storage.
        if (currentCount > persistedCount) {
          mergedMessages.add(message);
        }
      }

      // Re-sort after merging persisted and in-memory messages so the
      // conversation window remains stable after optimistic inserts.
      mergedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final windowedMergedMessages = mergedMessages.length > _messageWindowSize
          ? mergedMessages.sublist(mergedMessages.length - _messageWindowSize)
          : mergedMessages;

      _conversations[contactKeyHex] = windowedMergedMessages;
      notifyListeners();
    }
  }

  String _messageMergeKey(Message message) {
    final messageId = message.messageId;
    if (messageId.isNotEmpty) {
      return 'id:$messageId';
    }
    return 'fallback:${message.senderKeyHex}:${message.isOutgoing}:${message.isCli}:${message.timestamp.millisecondsSinceEpoch}:${message.text}';
  }

  /// Load older messages for a contact (pagination)
  Future<List<Message>> loadOlderMessages(
    String contactKeyHex, {
    int count = 50,
  }) async {
    final allMessages = await _messageStore.loadMessages(contactKeyHex);
    final currentMessages = _conversations[contactKeyHex] ?? [];

    if (allMessages.length <= currentMessages.length) {
      return []; // No more messages to load
    }

    final currentOffset = allMessages.length - currentMessages.length;
    final fetchCount = count.clamp(0, currentOffset);
    final startIndex = currentOffset - fetchCount;

    final olderMessages = allMessages.sublist(startIndex, currentOffset);

    // Prepend to current conversation
    _conversations[contactKeyHex] = [...olderMessages, ...currentMessages];
    notifyListeners();

    return olderMessages;
  }

  List<ChannelMessage> getChannelMessages(Channel channel) {
    return _channelMessages[channel.index] ?? [];
  }

  Future<void> deleteChannelMessage(ChannelMessage message) async {
    final channelIndex = message.channelIndex;
    if (channelIndex == null) return;
    final messages = _channelMessages[channelIndex];
    if (messages == null) return;
    final removed = messages.remove(message);
    if (!removed) return;
    await _channelMessageStore.saveChannelMessages(channelIndex, messages);
    notifyListeners();
  }

  int getUnreadCountForContact(Contact contact) {
    if (contact.type == advTypeRepeater) return 0;
    return getUnreadCountForContactKey(contact.publicKeyHex);
  }

  int getUnreadCountForContactKey(String contactKeyHex) {
    if (!_unreadStateLoaded) return 0;
    if (!_shouldTrackUnreadForContactKey(contactKeyHex)) return 0;
    return _contactUnreadCount[contactKeyHex] ?? 0;
  }

  int getUnreadCountForChannel(Channel channel) {
    return getUnreadCountForChannelIndex(channel.index);
  }

  int getUnreadCountForChannelIndex(int channelIndex) {
    if (!_unreadStateLoaded) return 0;
    return _findChannelByIndex(channelIndex)?.unreadCount ?? 0;
  }

  int getTotalUnreadCount() {
    if (!_unreadStateLoaded) return 0;
    var total = 0;
    // Count unread contact messages
    for (final contact in _contacts) {
      total += getUnreadCountForContact(contact);
    }
    // Count unread channel messages
    for (final channelIndex in _channelMessages.keys) {
      total += getUnreadCountForChannelIndex(channelIndex);
    }
    return total;
  }

  bool isChannelSmazEnabled(int channelIndex) {
    return _channelSmazEnabled[channelIndex] ?? false;
  }

  bool isContactSmazEnabled(String contactKeyHex) {
    return _contactSmazEnabled[contactKeyHex] ?? false;
  }

  void ensureContactSmazSettingLoaded(String contactKeyHex) {
    _ensureContactSmazSettingLoaded(contactKeyHex);
  }

  Future<void> loadUnreadState() async {
    _contactUnreadCount
      ..clear()
      ..addAll(await _unreadStore.loadContactUnreadCount());
    _unreadStateLoaded = true;
    notifyListeners();
  }

  Future<void> loadCachedChannels() async {
    _cachedChannels = await _channelStore.loadChannels();
  }

  void setActiveContact(String? contactKeyHex) {
    if (contactKeyHex != null &&
        !_shouldTrackUnreadForContactKey(contactKeyHex)) {
      _activeContactKey = null;
      return;
    }
    _activeContactKey = contactKeyHex;
    if (contactKeyHex != null) {
      markContactRead(contactKeyHex);
    }
  }

  void setActiveChannel(int? channelIndex) {
    _activeChannelIndex = channelIndex;
    if (channelIndex != null) {
      markChannelRead(channelIndex);
    }
  }

  void markContactRead(String contactKeyHex) {
    if (!_shouldTrackUnreadForContactKey(contactKeyHex)) return;
    final previousCount = _contactUnreadCount[contactKeyHex] ?? 0;
    if (previousCount > 0) {
      _contactUnreadCount[contactKeyHex] = 0;
      _appDebugLogService?.info(
        'Contact $contactKeyHex marked as read (was $previousCount unread)',
        tag: 'Unread',
      );
      _unreadStore.saveContactUnreadCount(
        Map<String, int>.from(_contactUnreadCount),
      );
      _notificationService.clearContactNotification(
        contactKeyHex,
        getTotalUnreadCount(),
      );
      notifyListeners();
    }
  }

  void markChannelRead(int channelIndex) {
    final channel = _findChannelByIndex(channelIndex);
    if (channel != null && channel.unreadCount > 0) {
      final previousCount = channel.unreadCount;
      channel.unreadCount = 0;
      _appDebugLogService?.info(
        'Channel ${channel.name.isNotEmpty ? channel.name : channelIndex} marked as read (was $previousCount unread)',
        tag: 'Unread',
      );
      unawaited(
        _channelStore.saveChannels(
          _channels.isNotEmpty ? _channels : _cachedChannels,
        ),
      );
      _notificationService.clearChannelNotification(
        channelIndex,
        getTotalUnreadCount(),
      );
      notifyListeners();
    }
  }

  Future<void> setChannelSmazEnabled(int channelIndex, bool enabled) async {
    _channelSmazEnabled[channelIndex] = enabled;
    await _channelSettingsStore.saveSmazEnabled(channelIndex, enabled);
    notifyListeners();
  }

  Future<void> setContactSmazEnabled(String contactKeyHex, bool enabled) async {
    _contactSmazEnabled[contactKeyHex] = enabled;
    await _contactSettingsStore.saveSmazEnabled(contactKeyHex, enabled);
    notifyListeners();
  }

  Future<void> _loadChannelOrder() async {
    _channelOrder = await _channelOrderStore.loadChannelOrder();
    _applyChannelOrder();
    notifyListeners();
  }

  /// Load persisted channel messages for a specific channel
  Future<void> _loadChannelMessages(int channelIndex) async {
    final allMessages = await _channelMessageStore.loadChannelMessages(
      channelIndex,
    );
    if (allMessages.isNotEmpty) {
      // Keep only the most recent N messages in memory to bound memory usage
      final windowedMessages = allMessages.length > _messageWindowSize
          ? allMessages.sublist(allMessages.length - _messageWindowSize)
          : allMessages;

      _channelMessages[channelIndex] = windowedMessages;
      notifyListeners();
    }
  }

  /// Load older channel messages (pagination)
  Future<List<ChannelMessage>> loadOlderChannelMessages(
    int channelIndex, {
    int count = 50,
  }) async {
    final allMessages = await _channelMessageStore.loadChannelMessages(
      channelIndex,
    );
    final currentMessages = _channelMessages[channelIndex] ?? [];

    if (allMessages.length <= currentMessages.length) {
      return []; // No more messages to load
    }

    final currentOffset = allMessages.length - currentMessages.length;
    final fetchCount = count.clamp(0, currentOffset);
    final startIndex = currentOffset - fetchCount;

    final olderMessages = allMessages.sublist(startIndex, currentOffset);

    // Prepend to current conversation
    _channelMessages[channelIndex] = [...olderMessages, ...currentMessages];
    notifyListeners();

    return olderMessages;
  }

  /// Load all persisted channel messages on startup
  Future<void> loadAllChannelMessages({int? maxChannels}) async {
    final channelCount = maxChannels ?? _maxChannels;
    // Load messages for all known channels (0-7 by default)
    for (int i = 0; i < channelCount; i++) {
      await _loadChannelMessages(i);
    }
  }

  void initialize({
    required MessageRetryService retryService,
    required PathHistoryService pathHistoryService,
    AppSettingsService? appSettingsService,
    TranslationService? translationService,
    BleDebugLogService? bleDebugLogService,
    AppDebugLogService? appDebugLogService,
    BackgroundService? backgroundService,
    TimeoutPredictionService? timeoutPredictionService,
  }) {
    _retryService = retryService;
    _pathHistoryService = pathHistoryService;
    _appSettingsService = appSettingsService;
    _translationService = translationService;
    _bleDebugLogService = bleDebugLogService;
    _appDebugLogService = appDebugLogService;
    _backgroundService = backgroundService;
    _timeoutPredictionService = timeoutPredictionService;
    _usbManager.setDebugLogService(_appDebugLogService);
    _tcpConnector.setDebugLogService(_appDebugLogService);

    // Initialize notification service
    _notificationService.initialize();
    _loadChannelOrder();

    // Initialize retry service callbacks
    _retryService?.initialize(
      RetryServiceConfig(
        sendMessage: _sendMessageDirect,
        addMessage: _addMessage,
        updateMessage: _updateMessage,
        clearContactPath: clearContactPath,
        setContactPath: setContactPath,
        calculateTimeout: (pathLength, messageBytes, {String? contactKey}) =>
            calculateTimeout(
              pathLength: pathLength,
              messageBytes: messageBytes,
              contactKey: contactKey,
            ),
        getSelfPublicKey: () => _selfPublicKey,
        prepareContactOutboundText: prepareContactOutboundText,
        appSettingsService: appSettingsService,
        debugLogService: _appDebugLogService,
        recordPathResult: _recordPathResult,
        selectRetryPath:
            (contactKey, attemptIndex, maxRetries, recentSelections) =>
                _selectAutoPathForAttempt(
                  contactKey,
                  attemptIndex: attemptIndex,
                  maxRetries: maxRetries,
                  recentSelections: recentSelections,
                ),
        onDeliveryObserved: (contactKey, pathLength, messageBytes, tripTimeMs) {
          final secSinceRx = DateTime.now().difference(_lastRxTime).inSeconds;
          _timeoutPredictionService?.recordObservation(
            contactKey: contactKey,
            pathLength: pathLength,
            messageBytes: messageBytes,
            tripTimeMs: tripTimeMs,
            secondsSinceLastRx: secSinceRx,
          );
        },
      ),
    );
    final maxRetries = _appSettingsService?.settings.maxMessageRetries ?? 5;
    _retryService?.setMaxRetries(maxRetries);
  }

  Future<void> loadContactCache() async {
    final cached = await _contactStore.loadContacts();
    _knownContactKeys
      ..clear()
      ..addAll(cached.map((c) => c.publicKeyHex));
    _contacts
      ..clear()
      ..addAll(cached);
    for (final contact in cached) {
      _ensureContactSmazSettingLoaded(contact.publicKeyHex);
    }
  }

  Future<void> _loadDiscoveredContactCache() async {
    final cached = await _discoveryContactStore.loadContacts();
    _discoveredContacts
      ..clear()
      ..addAll(cached);
  }

  Future<void> loadChannelSettings({int? maxChannels}) async {
    _channelSmazEnabled.clear();
    final channelCount = maxChannels ?? _maxChannels;
    for (int i = 0; i < channelCount; i++) {
      _channelSmazEnabled[i] = await _channelSettingsStore.loadSmazEnabled(i);
    }
  }

  /// After an incoming DM or channel message, wait before TX so we do not
  /// collide with mesh propagation. With companion stats, scale wait by RF
  /// conditions (up to [_contactMsgBackoffMaxMs]); otherwise use
  /// [_contactMsgBackoffFallbackMs].
  int _contactMessageBackoffTargetMs() {
    if (!supportsCompanionRadioStats || _latestRadioStats == null) {
      return _contactMsgBackoffFallbackMs;
    }
    final stats = _latestRadioStats!;
    final nf = stats.noiseFloorDbm.toDouble();
    // Quieter (more negative) → lower score; noisier → higher.
    const noiseQuietDbm = -118.0;
    const noiseNoisyDbm = -88.0;
    final noiseT = ((nf - noiseQuietDbm) / (noiseNoisyDbm - noiseQuietDbm))
        .clamp(0.0, 1.0);

    final snr = stats.lastSnrDb;
    const snrGood = 12.0;
    const snrBad = -2.0;
    final snrT = (1.0 - ((snr - snrBad) / (snrGood - snrBad))).clamp(0.0, 1.0);

    final airBusy = _recentAirtimeBusyFraction();
    final severity = (math.max(noiseT, snrT) * 0.82 + airBusy * 0.18).clamp(
      0.0,
      1.0,
    );

    return (_contactMsgBackoffMinMs +
            severity * (_contactMsgBackoffMaxMs - _contactMsgBackoffMinMs))
        .round();
  }

  /// 1.0 shortly after TX/RX airtime counters increase, decaying to 0 over ~8s.
  double _recentAirtimeBusyFraction() {
    final sw = _airtimeBumpStopwatch;
    if (sw == null || !sw.isRunning) return 0;
    final ms = sw.elapsedMilliseconds;
    const windowMs = 8000;
    if (ms >= windowMs) return 0;
    return 1.0 - (ms / windowMs);
  }

  /// Start of the post-inbound cool-down: the later of BLE message RX time and
  /// companion airtime bump ([_airtimeBumpStopwatch], same as the activity dot).
  DateTime _postTxBackoffAnchor(DateTime lastInboundRxTime) {
    if (!supportsCompanionRadioStats) return lastInboundRxTime;
    final sw = _airtimeBumpStopwatch;
    if (sw == null || !sw.isRunning) return lastInboundRxTime;
    final bumpAt = DateTime.now().subtract(sw.elapsed);
    return bumpAt.isAfter(lastInboundRxTime) ? bumpAt : lastInboundRxTime;
  }

  Future<void> _waitForRadioQuiet({required DateTime lastInboundRxTime}) async {
    // Wait for backoff after inbound traffic / RF airtime (avoid collision with
    // mesh propagation). Elapsed time uses the dot's airtime bump when newer.
    final backoffTargetMs = _contactMessageBackoffTargetMs();
    final anchor = _postTxBackoffAnchor(lastInboundRxTime);
    final msSinceAnchor = DateTime.now().difference(anchor).inMilliseconds;
    if (msSinceAnchor < backoffTargetMs) {
      final waitMs = backoffTargetMs - msSinceAnchor;
      debugPrint(
        'Post-inbound backoff: waiting ${waitMs}ms '
        '(target=${backoffTargetMs}ms, anchorAge=${msSinceAnchor}ms)',
      );
      await Future<void>.delayed(Duration(milliseconds: waitMs));
    }

    // Then wait for radio silence (no RF activity for 3s)
    final msSinceRx = DateTime.now()
        .difference(_lastRadioRxTime)
        .inMilliseconds;
    if (msSinceRx >= _radioQuietMs) return;

    final deadline = DateTime.now().add(
      const Duration(milliseconds: _radioQuietMaxWaitMs),
    );
    while (DateTime.now().isBefore(deadline)) {
      final quiet = DateTime.now().difference(_lastRadioRxTime).inMilliseconds;
      if (quiet >= _radioQuietMs) {
        debugPrint('Radio quiet for ${quiet}ms, proceeding with send');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    debugPrint(
      'Radio quiet wait exceeded ${_radioQuietMaxWaitMs}ms, sending anyway',
    );
  }

  Future<void> _sendMessageDirect(
    Contact contact,
    String text,
    int attempt,
    int timestampSeconds,
  ) async {
    if (!isConnected || text.isEmpty) return;
    try {
      await _waitForRadioQuiet(lastInboundRxTime: _lastContactMsgRxTime);
      final outboundText = prepareContactOutboundText(contact, text);
      await sendFrame(
        buildSendTextMsgFrame(
          contact.publicKey,
          outboundText,
          attempt: attempt,
          timestampSeconds: timestampSeconds,
        ),
      );
    } catch (e) {
      appLogger.error('Failed to send message: $e', tag: 'Connector');
    }
  }

  void _updateMessage(Message message) {
    final contactKey = pubKeyToHex(message.senderKey);
    final messages = _conversations[contactKey];
    if (messages != null) {
      final index = messages.indexWhere(
        (m) => m.messageId == message.messageId,
      );
      if (index != -1) {
        messages[index] = message;
        _messageStore.saveMessages(contactKey, messages);
        notifyListeners();
      }
    }

    // If this is a reaction message, update the target message's reaction status
    final reactionInfo = ReactionHelper.parseReaction(message.text);
    if (reactionInfo != null &&
        (message.status == MessageStatus.delivered ||
            message.status == MessageStatus.failed)) {
      final contactKey2 = pubKeyToHex(message.senderKey);
      _setReactionStatus(contactKey2, reactionInfo, message.status);
      _messageStore.saveMessages(
        contactKey2,
        _conversations[contactKey2] ?? [],
      );
      notifyListeners();
    }
  }

  Future<void> _translateIncomingContactMessage(
    String contactKeyHex,
    Message message,
  ) async {
    try {
      final service = _translationService;
      if (service == null ||
          !service.shouldTranslateIncoming(
            text: message.text,
            isCli: message.isCli,
            isOutgoing: message.isOutgoing,
          )) {
        return;
      }
      final targetLanguageCode = service.resolvedIncomingLanguageCode(
        _appSettingsService?.settings.languageOverride,
      );
      final result = await service.translateIncomingText(
        text: message.text,
        targetLanguageCode: targetLanguageCode,
      );
      if (result == null) {
        return;
      }
      final translated = result.status == MessageTranslationStatus.completed
          ? result.translatedText
          : null;
      _updateStoredContactMessage(
        contactKeyHex,
        message.messageId,
        (current) => current.copyWith(
          translatedText: translated,
          translatedLanguageCode: result.detectedLanguageCode,
          translationStatus: result.status,
          translationModelId: result.modelId,
        ),
      );
    } catch (error) {
      appLogger.warn('Translation failed for contact message: $error');
    }
  }

  Future<void> _translateIncomingChannelMessage(
    int channelIndex,
    ChannelMessage message,
  ) async {
    try {
      final service = _translationService;
      if (service == null ||
          !service.shouldTranslateIncoming(
            text: message.text,
            isCli: false,
            isOutgoing: message.isOutgoing,
          )) {
        return;
      }
      final targetLanguageCode = service.resolvedIncomingLanguageCode(
        _appSettingsService?.settings.languageOverride,
      );
      final result = await service.translateIncomingText(
        text: message.text,
        targetLanguageCode: targetLanguageCode,
      );
      if (result == null) {
        return;
      }
      final translated = result.status == MessageTranslationStatus.completed
          ? result.translatedText
          : null;
      _updateStoredChannelMessage(
        channelIndex,
        message.messageId,
        (current) => current.copyWith(
          translatedText: translated,
          translatedLanguageCode: result.detectedLanguageCode,
          translationStatus: result.status,
          translationModelId: result.modelId,
        ),
      );
    } catch (error) {
      appLogger.warn('Translation failed for channel message: $error');
    }
  }

  void _updateStoredContactMessage(
    String contactKeyHex,
    String messageId,
    Message Function(Message current) update,
  ) {
    final messages = _conversations[contactKeyHex];
    if (messages == null) {
      return;
    }
    final index = messages.indexWhere((entry) => entry.messageId == messageId);
    if (index < 0) {
      return;
    }
    messages[index] = update(messages[index]);
    _messageStore.saveMessages(contactKeyHex, messages);
    notifyListeners();
  }

  void _updateStoredChannelMessage(
    int channelIndex,
    String messageId,
    ChannelMessage Function(ChannelMessage current) update,
  ) {
    final messages = _channelMessages[channelIndex];
    if (messages == null) {
      return;
    }
    final index = messages.indexWhere((entry) => entry.messageId == messageId);
    if (index < 0) {
      return;
    }
    messages[index] = update(messages[index]);
    _channelMessageStore.saveChannelMessages(channelIndex, messages);
    notifyListeners();
  }

  void _recordPathResult(
    String contactPubKeyHex,
    PathSelection selection,
    bool success,
    int? tripTimeMs,
  ) {
    if (_pathHistoryService == null) return;
    final settings = _appSettingsService?.settings;
    _pathHistoryService!.recordPathResult(
      contactPubKeyHex,
      selection,
      success: success,
      tripTimeMs: tripTimeMs,
      successIncrement: settings?.routeWeightSuccessIncrement ?? 0.2,
      failureDecrement: settings?.routeWeightFailureDecrement ?? 0.2,
      maxWeight: settings?.maxRouteWeight ?? 5.0,
    );

    // Flood path attribution: when a flood delivery succeeds, credit the
    // contact's current device path so the route the ACK traveled back
    // through gets a weight boost in the path history.
    if (selection.useFlood && success) {
      final contact = _contacts.cast<Contact?>().firstWhere(
        (c) => c?.publicKeyHex == contactPubKeyHex,
        orElse: () => null,
      );
      if (contact != null &&
          contact.pathLength >= 0 &&
          contact.path.isNotEmpty) {
        _pathHistoryService!.recordFloodPathAttribution(
          contactPubKeyHex: contactPubKeyHex,
          pathBytes: contact.path,
          hopCount: contact.pathLength,
          tripTimeMs: tripTimeMs,
          successIncrement: settings?.routeWeightSuccessIncrement ?? 0.2,
          maxWeight: settings?.maxRouteWeight ?? 5.0,
        );
      }

      // Request a fresh contact from the device so the next flood
      // attribution uses the most up-to-date path.
      if (contact != null) {
        unawaited(getContactByKey(contact.publicKey));
      }
    }
  }

  PathSelection? _selectAutoPathForAttempt(
    String contactPubKeyHex, {
    required int attemptIndex,
    required int maxRetries,
    List<PathSelection> recentSelections = const [],
  }) {
    final hasKnownPaths =
        _pathHistoryService?.getRecentPaths(contactPubKeyHex).isNotEmpty ??
        false;
    if (!hasKnownPaths) {
      return null;
    }

    final selection = _pathHistoryService?.selectPathForAttempt(
      contactPubKeyHex,
      attemptIndex: attemptIndex,
      maxRetries: maxRetries,
      recentSelections: recentSelections,
    );
    if (selection != null) {
      _pathHistoryService?.recordPathAttempt(contactPubKeyHex, selection);
    }
    return selection;
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_state == MeshCoreConnectionState.scanning) return;

    _scanResults.clear();
    _linuxSystemScanResults.clear();
    _setState(MeshCoreConnectionState.scanning);

    // Ensure any previous scan is fully stopped. Guard with isScanningNow to
    // avoid triggering stale native callbacks when no scan is active.
    if (FlutterBluePlus.isScanningNow) {
      try {
        await FlutterBluePlus.stopScan();
      } catch (e) {
        _appDebugLogService?.warn(
          'stopScan error in startScan (ignored): $e',
          tag: 'BLE Scan',
        );
      }
    }
    await _scanSubscription?.cancel();

    // On iOS/macOS, wait for Bluetooth to be powered on before scanning
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // Wait for adapter state to be powered on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        // Wait for the adapter to turn on, with timeout
        await FlutterBluePlus.adapterState
            .firstWhere((state) => state == BluetoothAdapterState.on)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                _setState(MeshCoreConnectionState.disconnected);
                throw Exception('Bluetooth adapter not available');
              },
            );
      }

      // Add a small delay to allow BLE stack to fully initialize
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (PlatformInfo.isLinux) {
      await _loadLinuxSystemDevicesForScan();
    }

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults
        ..clear()
        ..addAll(results);
      _mergeLinuxSystemScanResults();
      notifyListeners();
    });

    try {
      await FlutterBluePlus.startScan(
        withKeywords: MeshCoreUuids.deviceNamePrefixes,
        webOptionalServices: [Guid(MeshCoreUuids.service)],
        timeout: timeout,
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (error) {
      _appDebugLogService?.warn('Scan/picker failure: $error', tag: 'BLE Scan');
      _setState(MeshCoreConnectionState.disconnected);
      rethrow;
    }

    await Future.delayed(timeout);
    await stopScan();
  }

  Future<void> _loadLinuxSystemDevicesForScan() async {
    try {
      final systemDevices = await FlutterBluePlus.systemDevices([
        Guid(MeshCoreUuids.service),
      ]);
      _linuxSystemScanResults
        ..clear()
        ..addAll(
          systemDevices
              .where(
                (device) => MeshCoreUuids.deviceNamePrefixes.any(
                  device.platformName.startsWith,
                ),
              )
              .map(
                (device) => ScanResult(
                  device: device,
                  advertisementData: AdvertisementData(
                    advName: device.platformName,
                    txPowerLevel: null,
                    appearance: null,
                    connectable: true,
                    manufacturerData: const <int, List<int>>{},
                    serviceData: const <Guid, List<int>>{},
                    serviceUuids: <Guid>[Guid(MeshCoreUuids.service)],
                  ),
                  rssi: 0,
                  timeStamp: DateTime.now(),
                ),
              ),
        );
      _mergeLinuxSystemScanResults();
      notifyListeners();
    } catch (error) {
      _appDebugLogService?.warn(
        'Failed loading Linux paired/system BLE devices: $error',
        tag: 'BLE Scan',
      );
    }
  }

  void _mergeLinuxSystemScanResults() {
    if (!PlatformInfo.isLinux || _linuxSystemScanResults.isEmpty) {
      return;
    }
    final existingIds = _scanResults
        .map((result) => result.device.remoteId.str)
        .toSet();
    for (final result in _linuxSystemScanResults) {
      if (existingIds.contains(result.device.remoteId.str)) {
        continue;
      }
      _scanResults.add(result);
    }
  }

  Future<void> stopScan() async {
    // Only call FlutterBluePlus.stopScan() when a scan is actually running.
    // Calling it when idle triggers a native BLE completion callback even
    // though no scan was started. After a hot restart Dart has already freed
    // those callback handles, so the callback crashes with
    // "Callback invoked after it has been deleted".
    if (FlutterBluePlus.isScanningNow) {
      try {
        await FlutterBluePlus.stopScan();
      } catch (e) {
        _appDebugLogService?.warn(
          'stopScan error (ignored): $e',
          tag: 'BLE Scan',
        );
      }
    }
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (_state == MeshCoreConnectionState.scanning) {
      _setState(MeshCoreConnectionState.disconnected);
    }
  }

  Future<List<String>> listUsbPorts() => _usbManager.listPorts();

  void setUsbRequestPortLabel(String label) {
    _usbManager.setRequestPortLabel(label);
  }

  void setUsbFallbackDeviceName(String label) {
    _usbManager.setFallbackDeviceName(label);
  }

  Future<void> connectUsb({
    required String portName,
    int baudRate = 115200,
  }) async {
    if (_state == MeshCoreConnectionState.connecting ||
        _state == MeshCoreConnectionState.connected) {
      _appDebugLogService?.warn(
        'connectUsb ignored: already $_state',
        tag: 'USB',
      );
      return;
    }

    _appDebugLogService?.info(
      'connectUsb: port=$portName baud=$baudRate',
      tag: 'USB',
    );

    await stopScan();
    _cancelReconnectTimer();
    _manualDisconnect = false;
    _resetConnectionHandshakeState();
    _activeTransport = MeshCoreTransportType.usb;
    _setState(MeshCoreConnectionState.connecting);

    try {
      await _usbFrameSubscription?.cancel();
      _usbFrameSubscription = null;
      _appDebugLogService?.info('connectUsb: opening serial port…', tag: 'USB');
      await _usbManager.connect(portName: portName, baudRate: baudRate);
      _appDebugLogService?.info(
        'connectUsb: serial port opened, label=${_usbManager.activePortDisplayLabel}',
        tag: 'USB',
      );
      notifyListeners();
      if (PlatformInfo.isWeb) {
        await stopScan();
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _usbFrameSubscription = _usbManager.frameStream.listen(
        _handleFrame,
        onError: (error, stackTrace) {
          _appDebugLogService?.error('USB transport error: $error', tag: 'USB');
          unawaited(disconnect(manual: false));
        },
        onDone: () {
          _appDebugLogService?.warn('USB frame stream ended', tag: 'USB');
          unawaited(disconnect(manual: false));
        },
      );

      _setState(MeshCoreConnectionState.connected);
      _pendingInitialChannelSync = true;
      _appDebugLogService?.info(
        'connectUsb: requesting device info…',
        tag: 'USB',
      );
      await _requestDeviceInfo();
      _startBatteryPolling();
      if (_radioStatsPollRefCount > 0) _startRadioStatsPolling();
      var gotSelfInfo = await _waitForSelfInfo(
        timeout: const Duration(seconds: 3),
      );
      if (!gotSelfInfo) {
        _appDebugLogService?.warn(
          'connectUsb: SELF_INFO timeout, retrying…',
          tag: 'USB',
        );
        await refreshDeviceInfo();
        gotSelfInfo = await _waitForSelfInfo(
          timeout: const Duration(seconds: 3),
        );
      }
      if (!gotSelfInfo) {
        throw StateError('Timed out waiting for SELF_INFO during connect');
      }

      _appDebugLogService?.info('connectUsb: syncing time…', tag: 'USB');
      await syncTime();
      _appDebugLogService?.info('connectUsb: complete', tag: 'USB');
    } catch (error) {
      _appDebugLogService?.error('USB connection error: $error', tag: 'USB');
      await disconnect(manual: false);
      rethrow;
    }
  }

  Future<void> connectTcp({required String host, required int port}) async {
    if (_state == MeshCoreConnectionState.connecting ||
        _state == MeshCoreConnectionState.connected) {
      _appDebugLogService?.warn(
        'connectTcp ignored: already $_state',
        tag: 'TCP',
      );
      return;
    }

    _appDebugLogService?.info('connectTcp: endpoint=$host:$port', tag: 'TCP');

    await stopScan();
    _cancelReconnectTimer();
    _manualDisconnect = false;
    _resetConnectionHandshakeState();
    _activeTransport = MeshCoreTransportType.tcp;
    _setState(MeshCoreConnectionState.connecting);

    try {
      Future<void> handleTcpConnectAbort({required String message}) async {
        _appDebugLogService?.warn(message, tag: 'TCP');
        final shouldResetState = shouldResetStateAfterTcpConnectAbort(
          state: _state,
          activeTransport: _activeTransport,
        );
        if (shouldResetState) {
          await disconnect(manual: false);
          return;
        }
        if (_tcpConnector.isConnected) {
          await _tcpConnector.disconnect();
        }
      }

      await _tcpConnector.cancelFrameSubscription();
      await _tcpConnector.connect(host: host, port: port);
      final isTcpConnectCancelled =
          _activeTransport != MeshCoreTransportType.tcp ||
          _state != MeshCoreConnectionState.connecting ||
          !_tcpConnector.isConnected;
      if (isTcpConnectCancelled) {
        await handleTcpConnectAbort(
          message:
              'connectTcp aborted before handshake: state=$_state transport=$_activeTransport connected=${_tcpConnector.isConnected}',
        );
        return;
      }
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final isTcpConnectCancelledAfterDelay =
          _activeTransport != MeshCoreTransportType.tcp ||
          _state != MeshCoreConnectionState.connecting ||
          !_tcpConnector.isConnected;
      if (isTcpConnectCancelledAfterDelay) {
        await handleTcpConnectAbort(
          message:
              'connectTcp aborted after connect delay: state=$_state transport=$_activeTransport connected=${_tcpConnector.isConnected}',
        );
        return;
      }
      _tcpConnector.listenFrames(
        onFrame: _handleFrame,
        onError: (error, stackTrace) {
          _appDebugLogService?.error('TCP transport error: $error', tag: 'TCP');
          unawaited(disconnect(manual: false));
        },
        onDone: () {
          _appDebugLogService?.warn('TCP frame stream ended', tag: 'TCP');
          unawaited(disconnect(manual: false));
        },
      );

      _setState(MeshCoreConnectionState.connected);
      _pendingInitialChannelSync = true;
      await _requestDeviceInfo();
      _startBatteryPolling();
      if (_radioStatsPollRefCount > 0) _startRadioStatsPolling();

      var gotSelfInfo = await _waitForSelfInfo(
        timeout: const Duration(seconds: 3),
      );
      if (!gotSelfInfo) {
        await refreshDeviceInfo();
        gotSelfInfo = await _waitForSelfInfo(
          timeout: const Duration(seconds: 3),
        );
      }
      if (!gotSelfInfo) {
        throw StateError('Timed out waiting for SELF_INFO during TCP connect');
      }

      await syncTime();
    } catch (error) {
      _appDebugLogService?.error('TCP connection error: $error', tag: 'TCP');
      final tcpConnectCancelledBeforeHandshake =
          shouldIgnoreLateTcpConnectError(
            manualDisconnect: _manualDisconnect,
            state: _state,
            activeTransport: _activeTransport,
            tcpManagerConnected: _tcpConnector.isConnected,
          );
      if (tcpConnectCancelledBeforeHandshake) {
        _appDebugLogService?.info(
          'Ignoring late TCP connect error after cancellation/switch: state=$_state transport=$_activeTransport',
          tag: 'TCP',
        );
        return;
      }
      await disconnect(manual: false);
      rethrow;
    }
  }

  @visibleForTesting
  static bool shouldIgnoreLateTcpConnectError({
    required bool manualDisconnect,
    required MeshCoreConnectionState state,
    required MeshCoreTransportType activeTransport,
    required bool tcpManagerConnected,
  }) {
    return manualDisconnect &&
        (state == MeshCoreConnectionState.disconnected ||
            state == MeshCoreConnectionState.disconnecting) &&
        (activeTransport != MeshCoreTransportType.tcp || !tcpManagerConnected);
  }

  @visibleForTesting
  static bool shouldResetStateAfterTcpConnectAbort({
    required MeshCoreConnectionState state,
    required MeshCoreTransportType activeTransport,
  }) {
    return state == MeshCoreConnectionState.connecting &&
        activeTransport == MeshCoreTransportType.tcp;
  }

  Future<void> connect(
    BluetoothDevice device, {
    String? displayName,
    Future<String?> Function()? linuxPairingPinProvider,
  }) async {
    if (_state == MeshCoreConnectionState.connecting ||
        _state == MeshCoreConnectionState.connected) {
      return;
    }

    _activeTransport = MeshCoreTransportType.bluetooth;

    await stopScan();
    _setState(MeshCoreConnectionState.connecting);
    _device = device;
    _deviceId = device.remoteId.toString();
    if (displayName != null && displayName.trim().isNotEmpty) {
      _deviceDisplayName = displayName.trim();
    } else if (device.platformName.isNotEmpty) {
      _deviceDisplayName = device.platformName;
    }
    _lastDevice = device;
    _lastDeviceId = _deviceId;
    _lastDeviceDisplayName = _deviceDisplayName;
    _manualDisconnect = false;
    _cancelReconnectTimer();
    _bleInitialSyncStarted = false;
    if (PlatformInfo.isWeb) {
      _resetConnectionHandshakeState();
    }
    unawaited(_backgroundService?.start());
    notifyListeners();

    try {
      final connectLabel = _deviceDisplayName ?? _deviceId;
      _appDebugLogService?.info(
        'Starting connect to $connectLabel',
        tag: 'BLE Connect',
      );
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      await _notifySubscription?.cancel();
      _notifySubscription = null;
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && isConnected) {
          _handleDisconnection();
        }
      });

      if (PlatformInfo.isLinux) {
        final remoteId = device.remoteId.str;
        _appDebugLogService?.info(
          'Linux pre-connect BlueZ disconnect for $remoteId',
          tag: 'BLE Connect',
        );
        await _linuxBlePairingService.disconnectDevice(
          remoteId,
          onLog: (message) {
            _appDebugLogService?.info(message, tag: 'BLE Pair');
          },
        );
      }

      final connectTimeout = PlatformInfo.isLinux
          ? const Duration(seconds: 6)
          : const Duration(seconds: 15);
      _appDebugLogService?.info(
        'device.connect timeout set to ${connectTimeout.inSeconds}s',
        tag: 'BLE Connect',
      );
      if (PlatformInfo.isLinux) {
        Future<void> attemptConnect() {
          return device
              .connect(
                timeout: connectTimeout,
                mtu: null,
                license: License.free,
              )
              .timeout(
                connectTimeout + const Duration(seconds: 2),
                onTimeout: () {
                  throw TimeoutException(
                    'Linux connect hard-timeout after ${connectTimeout.inSeconds + 2}s',
                  );
                },
              );
        }

        try {
          await attemptConnect();
        } catch (error) {
          _appDebugLogService?.error(
            'device.connect() failure: $error',
            tag: 'BLE Connect',
          );
          final remoteId = device.remoteId.str;
          _appDebugLogService?.warn(
            'Linux immediate retry: forcing BlueZ disconnect before second connect attempt',
            tag: 'BLE Connect',
          );
          await _linuxBlePairingService.disconnectDevice(
            remoteId,
            onLog: (message) {
              _appDebugLogService?.info(message, tag: 'BLE Pair');
            },
          );
          await Future<void>.delayed(const Duration(milliseconds: 700));
          try {
            await attemptConnect();
            _appDebugLogService?.info(
              'Linux immediate retry connect succeeded',
              tag: 'BLE Connect',
            );
          } catch (retryError, retryStackTrace) {
            Object finalConnectError = retryError;
            StackTrace finalConnectStackTrace = retryStackTrace;
            final retryErrorText = retryError.toString().toLowerCase();
            final isAbortByLocal = retryErrorText.contains(
              'le-connection-abort-by-local',
            );
            var recoveredOnThirdAttempt = false;
            if (isAbortByLocal) {
              _appDebugLogService?.warn(
                'Linux immediate retry aborted by local stack; waiting and retrying once more',
                tag: 'BLE Connect',
              );
              await Future<void>.delayed(const Duration(milliseconds: 1200));
              try {
                await attemptConnect();
                _appDebugLogService?.info(
                  'Linux third-attempt connect succeeded after local abort',
                  tag: 'BLE Connect',
                );
                recoveredOnThirdAttempt = true;
              } catch (thirdError, thirdStackTrace) {
                finalConnectError = thirdError;
                finalConnectStackTrace = thirdStackTrace;
                _appDebugLogService?.error(
                  'device.connect() third-attempt failure: $thirdError',
                  tag: 'BLE Connect',
                );
              }
            }
            if (!recoveredOnThirdAttempt) {
              final recoveredByPairing = await _recoverLinuxConnectFailure(
                device,
                attemptConnect: attemptConnect,
                onRequestPin: linuxPairingPinProvider,
              );
              if (recoveredByPairing) {
                _appDebugLogService?.info(
                  'Linux connect succeeded after pairing/trust recovery',
                  tag: 'BLE Connect',
                );
              } else {
                _appDebugLogService?.error(
                  'device.connect() retry failure: $finalConnectError',
                  tag: 'BLE Connect',
                );
                Error.throwWithStackTrace(
                  _wrapLinuxConnectStageError(finalConnectError),
                  finalConnectStackTrace,
                );
              }
            }
          }
        }
      } else {
        try {
          await device.connect(
            timeout: connectTimeout,
            mtu: null,
            license: License.free,
          );
        } catch (error) {
          _appDebugLogService?.error(
            'device.connect() failure: $error',
            tag: 'BLE Connect',
          );
          rethrow;
        }
      }

      if (PlatformInfo.isLinux) {
        await _ensureLinuxBleBond(
          device,
          onRequestPin: linuxPairingPinProvider,
        );
      }

      // Request larger MTU only where the platform path supports it.
      if (!PlatformInfo.isWeb && !PlatformInfo.isLinux) {
        try {
          final mtu = await device.requestMtu(185);
          _appDebugLogService?.info('MTU set to: $mtu', tag: 'BLE Connect');
        } catch (e) {
          _appDebugLogService?.warn(
            'MTU request failed: $e, using default',
            tag: 'BLE Connect',
          );
        }
      } else if (PlatformInfo.isLinux) {
        _appDebugLogService?.info(
          'Skipping MTU request on Linux; flutter_blue_plus only supports requestMtu on Android',
          tag: 'BLE Connect',
        );
      }

      late final List<BluetoothService> services;
      try {
        services = await device.discoverServices();
      } catch (error) {
        _appDebugLogService?.error(
          'service discovery failure: $error',
          tag: 'BLE Connect',
        );
        if (PlatformInfo.isWeb &&
            error.toString().contains('GATT Server is disconnected')) {
          // Chrome Web Bluetooth intermittently disconnects between connect()
          // and service discovery; retry once to recover that transient state.
          _appDebugLogService?.warn(
            'retrying service discovery after transient web disconnect',
            tag: 'BLE Connect',
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await device.connect(
            timeout: const Duration(seconds: 15),
            mtu: null,
            license: License.free,
          );
          services = await device.discoverServices();
        } else {
          rethrow;
        }
      }

      BluetoothService? uartService;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == MeshCoreUuids.service) {
          uartService = service;
          break;
        }
      }

      if (uartService == null) {
        throw Exception("MeshCore UART service not found");
      }

      for (var characteristic in uartService.characteristics) {
        String uuid = characteristic.uuid.toString().toLowerCase();
        if (uuid == MeshCoreUuids.rxCharacteristic) {
          _rxCharacteristic = characteristic;
        } else if (uuid == MeshCoreUuids.txCharacteristic) {
          _txCharacteristic = characteristic;
        }
      }

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        throw Exception("MeshCore characteristics not found");
      }

      if (PlatformInfo.isWeb) {
        _appDebugLogService?.info(
          'Starting setNotifyValue(true)',
          tag: 'BLE Connect',
        );
        _appDebugLogService?.info(
          'Web: Calling setNotifyValue(true) without awaiting',
          tag: 'BLE Connect',
        );
        unawaited(() async {
          try {
            await _txCharacteristic!.setNotifyValue(true);
          } catch (error) {
            _appDebugLogService?.warn(
              'notify failure (web, ignored): $error',
              tag: 'BLE Connect',
            );
            _appDebugLogService?.warn(
              'Web setNotifyValue error (ignoring): $error',
              tag: 'BLE Connect',
            );
          }
        }());
        _appDebugLogService?.info(
          'setNotifyValue(true) configuration completed',
          tag: 'BLE Connect',
        );
      } else {
        bool notifySet = false;
        for (int attempt = 0; attempt < 3 && !notifySet; attempt++) {
          try {
            if (attempt > 0) {
              await Future.delayed(Duration(milliseconds: 500 * attempt));
            }
            await _txCharacteristic!.setNotifyValue(true);
            notifySet = true;
          } catch (e) {
            _appDebugLogService?.warn('notify failure: $e', tag: 'BLE Connect');
            _appDebugLogService?.warn(
              'setNotifyValue attempt ${attempt + 1}/3 failed: $e',
              tag: 'BLE Connect',
            );
            if (attempt == 2) rethrow;
          }
        }
      }
      _notifySubscription = _txCharacteristic!.onValueReceived.listen(
        _handleFrame,
      );

      _setState(MeshCoreConnectionState.connected);
      if (_shouldGateInitialChannelSync) {
        _hasReceivedDeviceInfo = false;
        _pendingInitialChannelSync = true;
      }
      await _startBleInitialSync();
    } catch (e) {
      _appDebugLogService?.error('Connection error: $e', tag: 'BLE Connect');
      final errorText = e.toString();
      final lowerErrorText = errorText.toLowerCase();
      final isLinuxPairingFailure =
          PlatformInfo.isLinux && isLinuxBlePairingFailureText(errorText);
      final isLikelyPairingTimeout = isLikelyLinuxBlePairingTimeoutText(
        errorText,
      );
      final isConnectFailure = isLinuxBleConnectFailureText(errorText);
      final isConnectTimeoutFailure =
          isConnectFailure && lowerErrorText.contains('timed out');
      final isLinuxConnectFailure = PlatformInfo.isLinux && isConnectFailure;
      // Linux pairing failures should not enter auto-reconnect loops; user
      // needs to retry manually so they can re-enter PIN / resolve pairing.
      if (isLinuxPairingFailure) {
        _appDebugLogService?.warn(
          isLikelyPairingTimeout
              ? 'Linux pairing timed out: stopping reconnect until user retries manually'
              : 'Linux pairing failure: stopping reconnect until user retries manually',
          tag: 'BLE Connect',
        );
        await disconnect(manual: true);
      } else if (isLinuxConnectFailure) {
        _appDebugLogService?.warn(
          isConnectTimeoutFailure
              ? 'Linux connect timeout: issuing BlueZ disconnect before reconnect'
              : 'Linux connect failure: issuing BlueZ disconnect before reconnect',
          tag: 'BLE Connect',
        );
        final remoteId = _device?.remoteId.str;
        if (remoteId != null) {
          await _linuxBlePairingService.disconnectDevice(
            remoteId,
            onLog: (message) {
              _appDebugLogService?.info(message, tag: 'BLE Pair');
            },
          );
        }
        await disconnect(manual: false, skipBleDeviceDisconnect: true);
      } else {
        await disconnect(manual: false);
      }
      rethrow;
    }
  }

  Future<bool> _recoverLinuxConnectFailure(
    BluetoothDevice device, {
    required Future<void> Function() attemptConnect,
    Future<String?> Function()? onRequestPin,
  }) async {
    if (!PlatformInfo.isLinux ||
        !await _linuxBlePairingService.isBluetoothctlAvailable()) {
      return false;
    }
    final remoteId = device.remoteId.str;
    final pluginBondState = await _getLinuxPluginBondState(device);
    final trustedByBluez = await _linuxBlePairingService.isPairedAndTrusted(
      remoteId,
    );
    final needsBondRecovery =
        (pluginBondState != null &&
            pluginBondState != BmBondStateEnum.bonded) ||
        !trustedByBluez;
    if (!needsBondRecovery) {
      return false;
    }
    _appDebugLogService?.warn(
      pluginBondState == BmBondStateEnum.bonded
          ? 'Linux connect failed with an untrusted bond; attempting trust/pair recovery'
          : 'Linux connect failed before bond completed; attempting pairing fallback',
      tag: 'BLE Connect',
    );
    await _ensureLinuxBleBond(device, onRequestPin: onRequestPin);
    _appDebugLogService?.info(
      'Resetting BlueZ connection after Linux pairing/trust recovery',
      tag: 'BLE Connect',
    );
    await _linuxBlePairingService.disconnectDevice(
      remoteId,
      onLog: (message) {
        _appDebugLogService?.info(message, tag: 'BLE Pair');
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    try {
      await attemptConnect();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(_wrapLinuxConnectStageError(error), stackTrace);
    }
    return true;
  }

  Object _wrapLinuxConnectStageError(Object error) {
    final errorText = error.toString();
    if (errorText.toLowerCase().contains(linuxConnectStageFailureMarker)) {
      return error;
    }
    return StateError('Linux connect stage failure: $error');
  }

  Future<BmBondStateEnum?> _getLinuxPluginBondState(
    BluetoothDevice device,
  ) async {
    try {
      final response = await FlutterBluePlusPlatform.instance.getBondState(
        BmBondStateRequest(remoteId: device.remoteId),
      );
      return response.bondState;
    } catch (error) {
      _appDebugLogService?.warn(
        'Linux getBondState unavailable for ${device.remoteId.str}: $error',
        tag: 'BLE Connect',
      );
      return null;
    }
  }

  Future<void> _ensureLinuxBleBond(
    BluetoothDevice device, {
    Future<String?> Function()? onRequestPin,
  }) async {
    final remoteId = device.remoteId.str;
    final bluetoothctlAvailable = await _linuxBlePairingService
        .isBluetoothctlAvailable();
    final beforeBondState = await _getLinuxPluginBondState(device);
    if (!bluetoothctlAvailable) {
      if (beforeBondState == BmBondStateEnum.bonded) {
        _appDebugLogService?.warn(
          'bluetoothctl unavailable; continuing with plugin bonded state',
          tag: 'BLE Connect',
        );
      } else if (beforeBondState == null) {
        _appDebugLogService?.warn(
          'bluetoothctl unavailable and plugin bond state is unknown; skipping Linux pairing fallback',
          tag: 'BLE Connect',
        );
      } else {
        _appDebugLogService?.warn(
          'bluetoothctl unavailable and device is not bonded; skipping Linux pairing fallback',
          tag: 'BLE Connect',
        );
      }
      return;
    }

    final trustedByBluez = await _linuxBlePairingService.isPairedAndTrusted(
      remoteId,
    );
    if (trustedByBluez) {
      _appDebugLogService?.info(
        'Linux BLE device already paired/trusted, skipping pairing flow',
        tag: 'BLE Connect',
      );
      return;
    }

    if (beforeBondState == BmBondStateEnum.bonded && !trustedByBluez) {
      _appDebugLogService?.warn(
        'Linux BLE device is bonded but not trusted in BlueZ; repairing trust',
        tag: 'BLE Connect',
      );
      final trustRepaired = await _linuxBlePairingService.trustDevice(
        remoteId,
        onLog: (message) {
          _appDebugLogService?.info(message, tag: 'BLE Pair');
        },
      );
      if (trustRepaired) {
        _appDebugLogService?.info(
          'Linux BLE trust repair succeeded without re-pairing',
          tag: 'BLE Connect',
        );
        return;
      }
      _appDebugLogService?.warn(
        'Linux BLE trust repair did not stick; retrying pairing flow',
        tag: 'BLE Connect',
      );
    }

    _appDebugLogService?.info(
      beforeBondState == BmBondStateEnum.bonded
          ? 'Linux BLE device still untrusted after repair; requesting pair'
          : beforeBondState == null
          ? 'Linux BLE device bond state unknown; requesting pair'
          : 'Linux BLE device not bonded, requesting pair',
      tag: 'BLE Connect',
    );
    final paired = await _linuxBlePairingService.pairAndTrust(
      remoteId: remoteId,
      onLog: (message) {
        _appDebugLogService?.info(message, tag: 'BLE Pair');
      },
      onRequestPin: onRequestPin,
    );
    if (!paired) {
      throw StateError('Linux pairing fallback failed');
    }

    final afterBondState = await _getLinuxPluginBondState(device);
    if (afterBondState != null && afterBondState != BmBondStateEnum.bonded) {
      throw StateError('Linux BLE pairing did not complete');
    } else if (afterBondState == null) {
      _appDebugLogService?.warn(
        'Linux plugin bond state unavailable after pairing; relying on BlueZ trust verification',
        tag: 'BLE Connect',
      );
    }
    final trustedAfter = await _linuxBlePairingService.isPairedAndTrusted(
      remoteId,
    );
    if (!trustedAfter) {
      throw StateError('Linux BLE trust repair did not complete');
    }
  }

  Future<bool> _waitForSelfInfo({required Duration timeout}) async {
    if (_selfPublicKey != null) return true;
    if (!isConnected) return false;

    final completer = Completer<bool>();
    late final VoidCallback listener;
    listener = () {
      if (_selfPublicKey != null) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      } else if (!isConnected) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
    };
    addListener(listener);

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    final result = await completer.future;
    timer.cancel();
    removeListener(listener);
    return result;
  }

  Future<void> _startBleInitialSync() async {
    if (_bleInitialSyncStarted ||
        !isConnected ||
        _activeTransport != MeshCoreTransportType.bluetooth) {
      return;
    }
    _bleInitialSyncStarted = true;

    await _requestDeviceInfo();
    _startBatteryPolling();
    if (_radioStatsPollRefCount > 0) _startRadioStatsPolling();

    final gotSelfInfo = await _waitForSelfInfo(
      timeout: const Duration(seconds: 3),
    );
    if (!gotSelfInfo) {
      await refreshDeviceInfo();
      await _waitForSelfInfo(timeout: const Duration(seconds: 3));
    }

    await syncTime();
    unawaited(getChannels());
  }

  void _resetConnectionHandshakeState() {
    _selfPublicKey = null;
    _selfName = null;
    _selfLatitude = null;
    _selfLongitude = null;
    _awaitingSelfInfo = false;
    _webInitialHandshakeRequestSent = false;
    _selfInfoRetryTimer?.cancel();
    _selfInfoRetryTimer = null;
    _hasReceivedDeviceInfo = false;
    _pendingInitialChannelSync = false;
    _pendingInitialContactsSync = false;
    _bleInitialSyncStarted = false;
    _pendingDeferredChannelSyncAfterContacts = false;
    _pathHashByteWidth = 1;
  }

  bool get _shouldAutoReconnect =>
      !_manualDisconnect &&
      _lastDeviceId != null &&
      _activeTransport == MeshCoreTransportType.bluetooth;

  bool get _shouldGateInitialChannelSync =>
      _activeTransport == MeshCoreTransportType.usb ||
      _activeTransport == MeshCoreTransportType.tcp ||
      (_activeTransport == MeshCoreTransportType.bluetooth &&
          PlatformInfo.isWeb);

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  int _nextReconnectDelayMs() {
    final attempt = _reconnectAttempts < 6 ? _reconnectAttempts : 6;
    _reconnectAttempts += 1;
    final delayMs = 1000 * (1 << attempt);
    return delayMs > 30000 ? 30000 : delayMs;
  }

  void _scheduleReconnect() {
    if (!_shouldAutoReconnect) return;
    if (_reconnectTimer?.isActive == true) return;

    final delayMs = _nextReconnectDelayMs();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (!_shouldAutoReconnect) return;
      if (_state == MeshCoreConnectionState.connecting ||
          _state == MeshCoreConnectionState.connected) {
        return;
      }

      final device =
          _lastDevice ??
          (_lastDeviceId == null
              ? null
              : BluetoothDevice.fromId(_lastDeviceId!));
      if (device == null) return;

      try {
        await connect(device, displayName: _lastDeviceDisplayName);
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  Future<void> disconnect({
    bool manual = true,
    bool skipBleDeviceDisconnect = false,
  }) async {
    if (_state == MeshCoreConnectionState.disconnecting) return;
    final transportAtDisconnect = _activeTransport;
    final transportLabel = switch (transportAtDisconnect) {
      MeshCoreTransportType.bluetooth => 'BLE',
      MeshCoreTransportType.usb => 'USB',
      MeshCoreTransportType.tcp => 'TCP',
    };

    _appDebugLogService?.info(
      'Starting disconnect transport=$transportLabel manual=$manual',
      tag: 'Connection',
    );

    if (manual) {
      _manualDisconnect = true;
      _cancelReconnectTimer();
      unawaited(_backgroundService?.stop());
    } else {
      _manualDisconnect = false;
    }
    _setState(MeshCoreConnectionState.disconnecting);
    _stopBatteryPolling();
    _stopRadioStatsPolling();

    await _usbFrameSubscription?.cancel();
    _usbFrameSubscription = null;
    await _usbManager.disconnect();
    await _tcpConnector.disconnect();

    await _notifySubscription?.cancel();
    _notifySubscription = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _selfInfoRetryTimer?.cancel();
    _selfInfoRetryTimer = null;
    _queueSyncTimeout?.cancel();
    _queueSyncTimeout = null;
    _queueSyncRetries = 0;
    _channelSyncTimeout?.cancel();
    _channelSyncTimeout = null;
    _channelSyncRetries = 0;
    await _translationService?.releaseModel();

    if (!skipBleDeviceDisconnect) {
      try {
        // Skip queued BLE operations so disconnect doesn't get stuck behind them.
        await _device?.disconnect(queue: false);
      } catch (e) {
        _appDebugLogService?.warn('Disconnect error: $e', tag: 'BLE Connect');
      }
    } else {
      _appDebugLogService?.info(
        'Skipping plugin BLE disconnect and continuing cleanup',
        tag: 'BLE Connect',
      );
    }

    _device = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _deviceDisplayName = null;
    _deviceId = null;
    _contacts.clear();
    _discoveredContacts.clear();
    _conversations.clear();
    _loadedConversationKeys.clear();
    _selfPublicKey = null;
    _selfName = null;
    _selfLatitude = null;
    _selfLongitude = null;
    _clientRepeat = null;
    _rememberedNonRepeatRadioState = null;
    _firmwareVerCode = null;
    _batteryMillivolts = null;
    _repeaterBatterySnapshots.clear();
    _batteryRequested = false;
    _awaitingSelfInfo = false;
    _hasReceivedDeviceInfo = false;
    _pendingInitialChannelSync = false;
    _pendingInitialContactsSync = false;
    _maxContacts = _defaultMaxContacts;
    _maxChannels = _defaultMaxChannels;
    _isSyncingQueuedMessages = false;
    _queuedMessageSyncInFlight = false;
    _didInitialQueueSync = false;
    _pendingQueueSync = false;
    _isSyncingChannels = false;
    _channelSyncInFlight = false;
    _hasLoadedChannels = false;
    _pendingChannelSentQueue.clear();
    _pendingGenericAckQueue.clear();
    _reactionSendQueueSequence = 0;

    _activeTransport = MeshCoreTransportType.bluetooth;

    _setState(MeshCoreConnectionState.disconnected);
    _appDebugLogService?.info(
      'Disconnect complete transport=$transportLabel manual=$manual',
      tag: 'Connection',
    );
    if (!manual && transportAtDisconnect == MeshCoreTransportType.bluetooth) {
      _scheduleReconnect();
    }
  }

  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    if (!isConnected) {
      throw Exception("Not connected to a MeshCore device");
    }
    _bleDebugLogService?.logFrame(data, outgoing: true);

    if (_activeTransport == MeshCoreTransportType.usb) {
      await _usbManager.write(data);
      // Brief pause so the device firmware can process each frame before the
      // next arrives. Without this, rapid-fire frames over USB can cause the
      // device to miss responses (especially on reconnect).
      await Future<void>.delayed(const Duration(milliseconds: 10));
    } else if (_activeTransport == MeshCoreTransportType.tcp) {
      await _tcpConnector.write(data);
    } else {
      if (_rxCharacteristic == null) {
        throw Exception("MeshCore RX characteristic not available");
      }
      // Prefer write without response when supported; fall back to write with response.
      final properties = _rxCharacteristic!.properties;
      final canWriteWithoutResponse = properties.writeWithoutResponse;
      final canWriteWithResponse = properties.write;
      if (!canWriteWithoutResponse && !canWriteWithResponse) {
        throw Exception("MeshCore RX characteristic does not support write");
      }
      await _rxCharacteristic!.write(
        data.toList(),
        withoutResponse: canWriteWithoutResponse,
      );
    }
    _trackPendingGenericAck(
      data,
      channelSendQueueId: channelSendQueueId,
      expectsGenericAck: expectsGenericAck,
    );
  }

  Future<void> requestBatteryStatus({bool force = false}) async {
    if (!isConnected) return;
    if (_batteryRequested && !force) return;
    _batteryRequested = true;
    await sendFrame(buildGetBattAndStorageFrame());
  }

  void _startBatteryPolling() {
    _batteryPollTimer?.cancel();
    _batteryPollTimer = Timer.periodic(_batteryPollInterval, (timer) {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      unawaited(requestBatteryStatus(force: true));
    });
  }

  void _stopBatteryPolling() {
    _batteryPollTimer?.cancel();
    _batteryPollTimer = null;
  }

  void setPollingInterval(int i) {
    _pollingInterval = i.clamp(1, 60);
    if (isConnected) {
      _startRadioStatsPolling();
    }
  }

  void _startRadioStatsPolling() {
    _radioStatsPollTimer?.cancel();
    _radioStatsPollTimer = Timer.periodic(Duration(seconds: _pollingInterval), (
      _,
    ) {
      if (!isConnected) {
        _stopRadioStatsPolling();
        return;
      }
      unawaited(requestRadioStats());
    });
  }

  void _stopRadioStatsPolling() {
    _radioStatsPollTimer?.cancel();
    _radioStatsPollTimer = null;
  }

  void acquireRadioStatsPolling() {
    _radioStatsPollRefCount++;
    if (_radioStatsPollRefCount == 1 && isConnected) {
      _startRadioStatsPolling();
    }
  }

  void releaseRadioStatsPolling() {
    _radioStatsPollRefCount = (_radioStatsPollRefCount - 1).clamp(0, 999);
    if (_radioStatsPollRefCount == 0) {
      _stopRadioStatsPolling();
    }
  }

  Future<void> requestRadioStats() async {
    if (!isConnected) return;
    if (!supportsCompanionRadioStats) return;
    try {
      await sendFrame(buildGetStatsFrame(statsTypeRadio));
    } catch (_) {}
  }

  Future<void> setPathHashMode(int mode) async {
    if (!isConnected) return;
    await sendFrame(buildSetPathHashModeFrame(mode.clamp(0, 2)));
  }

  Future<void> refreshDeviceInfo() async {
    if (!isConnected) return;
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth &&
        _webInitialHandshakeRequestSent &&
        _selfPublicKey == null) {
      return;
    }
    _awaitingSelfInfo = true;
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth &&
        _selfPublicKey == null) {
      _webInitialHandshakeRequestSent = true;
    }
    await sendFrame(buildDeviceQueryFrame());
    await sendFrame(buildAppStartFrame());
    await requestBatteryStatus(force: true);
    await sendFrame(buildGetCustomVarsFrame());
    await sendFrame(buildGetAutoAddFlagsFrame());

    _scheduleSelfInfoRetry();
  }

  Future<void> _requestDeviceInfo() async {
    if (!isConnected || _awaitingSelfInfo) return;
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth &&
        _webInitialHandshakeRequestSent &&
        _selfPublicKey == null) {
      return;
    }
    _awaitingSelfInfo = true;
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth &&
        _selfPublicKey == null) {
      _webInitialHandshakeRequestSent = true;
    }
    await sendFrame(buildDeviceQueryFrame());
    await sendFrame(buildAppStartFrame());
    await sendFrame(buildGetCustomVarsFrame());
    await requestBatteryStatus();
    await sendFrame(buildGetAutoAddFlagsFrame());
    _scheduleSelfInfoRetry();
  }

  void _scheduleSelfInfoRetry() {
    _selfInfoRetryTimer?.cancel();
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth) {
      var attempts = 0;
      const maxAttempts = 3;
      _selfInfoRetryTimer = Timer.periodic(const Duration(seconds: 10), (
        timer,
      ) {
        if (!isConnected || !_awaitingSelfInfo) {
          timer.cancel();
          return;
        }
        if (_isLoadingContacts || _isSyncingChannels || _channelSyncInFlight) {
          return;
        }
        attempts += 1;
        unawaited(sendFrame(buildAppStartFrame()));
        if (attempts >= maxAttempts) {
          timer.cancel();
        }
      });
      return;
    }
    _selfInfoRetryTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      timer,
    ) {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      if (!_awaitingSelfInfo) {
        timer.cancel();
        return;
      }
      unawaited(sendFrame(buildAppStartFrame()));
    });
  }

  Contact getFromDiscovered(Contact contact) {
    final tmp = _discoveredContacts.firstWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
      orElse: () => contact,
    );
    return contact.copyWith(
      rawPacket: tmp.rawPacket,
      latitude: tmp.latitude,
      longitude: tmp.longitude,
    );
  }

  Future<void> getContacts({int? since, bool preserveExisting = false}) async {
    if (!isConnected) return;

    _isLoadingContacts = true;
    _preserveContactsOnRefresh = preserveExisting;
    if (!preserveExisting) {
      _contacts.clear();
      notifyListeners();
    }

    await sendFrame(buildGetContactsFrame(since: since));
  }

  Future<void> refreshContacts() async {
    await getContacts(preserveExisting: true);
  }

  Future<void> refreshContactsSinceLastmod() async {
    await getContacts(since: _latestContactLastmod(), preserveExisting: true);
  }

  Future<void> getContactByKey(Uint8List pubKey) async {
    if (!isConnected) return;
    await sendFrame(buildGetContactByKeyFrame(pubKey));
  }

  Future<void> sendMessage(
    Contact contact,
    String text, {
    String? originalText,
    String? translatedLanguageCode,
    String? translationModelId,
  }) async {
    if (!isConnected || text.isEmpty) return;

    // Check if this is a reaction - apply locally with pending status and route through retry service
    final reactionInfo = ReactionHelper.parseReaction(text);
    if (reactionInfo != null) {
      _conversations.putIfAbsent(contact.publicKeyHex, () => []);
      final messages = _conversations[contact.publicKeyHex]!;

      // Apply reaction locally with pending status
      _processOutgoingContactReaction(messages, reactionInfo, contact);
      _setReactionStatus(
        contact.publicKeyHex,
        reactionInfo,
        MessageStatus.pending,
      );
      _messageStore.saveMessages(contact.publicKeyHex, messages);
      notifyListeners();

      // Route through retry service (same as normal messages)
      // Don't use auto-rotation for reactions — just send directly
      if (_retryService != null) {
        _retryService!.sendMessageWithRetry(contact: contact, text: text);
      } else {
        final outboundText = prepareContactOutboundText(contact, text);
        await sendFrame(buildSendTextMsgFrame(contact.publicKey, outboundText));
      }
      return;
    }

    if (_retryService != null) {
      await _retryService!.sendMessageWithRetry(
        contact: contact,
        text: text,
        originalText: originalText,
        translatedLanguageCode: translatedLanguageCode,
        translationModelId: translationModelId,
      );
    } else {
      // Fallback to old behavior if retry service not initialized
      final resolved = resolvePathSelection(contact);
      final message = Message.outgoing(
        contact.publicKey,
        text,
        pathLength: resolved.useFlood ? -1 : resolved.hopCount,
        pathBytes: Uint8List.fromList(resolved.pathBytes),
        originalText: originalText,
        translatedLanguageCode: translatedLanguageCode,
        translationModelId: translationModelId,
      );
      _addMessage(contact.publicKeyHex, message);
      notifyListeners();
      final outboundText = prepareContactOutboundText(contact, text);
      await sendFrame(buildSendTextMsgFrame(contact.publicKey, outboundText));
    }
  }

  Future<void> setContactPath(
    Contact contact,
    Uint8List customPath,
    int pathLen,
  ) async {
    // Serialize path operations to prevent interleaved async calls from
    // leaving in-memory state inconsistent with the device.
    final prev = _pathOpLock;
    final completer = Completer<void>();
    _pathOpLock = completer.future;
    await prev;
    try {
      if (!isConnected) return;

      await sendFrame(
        buildUpdateContactPathFrame(
          contact.publicKey,
          customPath,
          pathLen,
          type: contact.type,
          flags: contact.flags,
          name: contact.name,
        ),
      );
      // USB writes return instantly (no BLE flow control), so give the firmware
      // time to persist the path change before subsequent commands.
      if (_activeTransport == MeshCoreTransportType.usb) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      final idx = _contacts.indexWhere(
        (c) => c.publicKeyHex == contact.publicKeyHex,
      );
      if (idx != -1) {
        _contacts[idx] = _contacts[idx].copyWith(
          pathLength: customPath.length,
          path: customPath,
        );
        notifyListeners();
      }
    } finally {
      completer.complete();
    }
  }

  Future<void> setContactFlags(
    Contact contact, {
    bool? isFavorite,
    bool? teleBase,
    bool? teleLoc,
    bool? teleEnv,
  }) async {
    if (!isConnected) return;
    final latestContact =
        await _fetchContactSnapshotFromDevice(contact.publicKey) ?? contact;
    int updatedFlags = isFavorite != null
        ? (isFavorite
              ? (latestContact.flags | contactFlagFavorite)
              : (latestContact.flags & ~contactFlagFavorite))
        : latestContact.flags;
    updatedFlags = teleBase != null
        ? (teleBase
              ? (updatedFlags | contactFlagTeleBase)
              : (updatedFlags & ~contactFlagTeleBase))
        : updatedFlags;
    updatedFlags = teleLoc != null
        ? (teleLoc
              ? (updatedFlags | contactFlagTeleLoc)
              : (updatedFlags & ~contactFlagTeleLoc))
        : updatedFlags;
    updatedFlags = teleEnv != null
        ? (teleEnv
              ? (updatedFlags | contactFlagTeleEnv)
              : (updatedFlags & ~contactFlagTeleEnv))
        : updatedFlags;

    await sendFrame(
      buildUpdateContactPathFrame(
        latestContact.publicKey,
        latestContact.path,
        latestContact.pathLength,
        type: latestContact.type,
        flags: updatedFlags,
        name: latestContact.name,
      ),
    );

    final index = _contacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    if (index >= 0) {
      _contacts[index] = _contacts[index].copyWith(
        type: latestContact.type,
        name: latestContact.name,
        pathLength: latestContact.pathLength,
        path: latestContact.path,
        flags: updatedFlags,
      );
      notifyListeners();
      unawaited(_persistContacts());
    }
  }

  Future<Contact?> _fetchContactSnapshotFromDevice(
    Uint8List pubKey, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!isConnected) return null;
    final expectedKeyHex = pubKeyToHex(pubKey);
    final completer = Completer<Contact?>();

    void finish(Contact? result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    final subscription = receivedFrames.listen((frame) {
      if (frame.isEmpty || frame[0] != respCodeContact) return;
      final parsed = Contact.fromFrame(frame);
      if (parsed == null || parsed.publicKeyHex != expectedKeyHex) return;
      finish(parsed);
    });

    final timer = Timer(timeout, () => finish(null));
    try {
      await getContactByKey(pubKey);
      return await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
    }
  }

  /// Set path override for a contact (persists across contact refreshes)
  /// pathLen: -1 = force flood, null = auto (use device path), >= 0 = specific path
  Future<void> setPathOverride(
    Contact contact, {
    int? pathLen,
    Uint8List? pathBytes,
  }) async {
    appLogger.info(
      'setPathOverride called for ${contact.name}: pathLen=$pathLen, bytesLen=${pathBytes?.length ?? 0}',
      tag: 'Connector',
    );

    // Find contact in list
    final index = _contacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    if (index == -1) {
      appLogger.warn(
        'setPathOverride: Contact not found in list: ${contact.name}',
        tag: 'Connector',
      );
      return;
    }

    appLogger.info(
      'Found contact at index $index. Current override: ${_contacts[index].pathOverride}',
      tag: 'Connector',
    );

    // Update contact with new path override
    _contacts[index] = _contacts[index].copyWith(
      pathOverride: pathLen,
      pathOverrideBytes: pathBytes,
      clearPathOverride: pathLen == null, // Clear if pathLen is null
    );

    appLogger.info(
      'Updated contact. New override: ${_contacts[index].pathOverride}, bytesLen: ${_contacts[index].pathOverrideBytes?.length}',
      tag: 'Connector',
    );

    // Save to storage
    await _contactStore.saveContacts(_contacts);
    appLogger.info('Saved contacts to storage', tag: 'Connector');

    // Update any in-flight retries so they use the new path override
    _retryService?.updatePendingContact(_contacts[index]);

    // If setting a specific path (not flood, not auto), also sync with device
    if (pathLen != null && pathLen >= 0 && pathBytes != null) {
      appLogger.info('Sending path to device...', tag: 'Connector');
      await setContactPath(contact, pathBytes, pathLen);
      appLogger.info('Path sent to device', tag: 'Connector');
    }

    debugPrint(
      'Set path override for ${contact.name}: pathLen=$pathLen, bytes=${pathBytes?.length ?? 0}',
    );
    notifyListeners();
  }

  Future<PathSelection> preparePathForContactSend(Contact contact) async {
    PathSelection? autoSelection;
    final autoRotationEnabled =
        _appSettingsService?.settings.autoRouteRotationEnabled == true;
    if (autoRotationEnabled && contact.pathOverride == null) {
      final maxRetries = _appSettingsService?.settings.maxMessageRetries ?? 5;
      autoSelection = _selectAutoPathForAttempt(
        contact.publicKeyHex,
        attemptIndex: 0,
        maxRetries: maxRetries,
      );
    }

    final resolved = resolvePathSelection(contact, selection: autoSelection);

    if (resolved.useFlood) {
      await clearContactPath(contact);
    } else {
      await setContactPath(
        contact,
        Uint8List.fromList(resolved.pathBytes),
        resolved.hopCount,
      );
    }

    return resolved;
  }

  void trackRepeaterAck({
    required Contact contact,
    required PathSelection selection,
    required String text,
    required int timestampSeconds,
    int attempt = 0,
  }) {
    final selfKey = _selfPublicKey;
    if (selfKey == null) return;
    // Use transformed text to match device's ACK hash computation
    final outboundText = prepareContactOutboundText(contact, text);
    final ackHash = MessageRetryService.computeExpectedAckHash(
      timestampSeconds,
      attempt,
      outboundText,
      selfKey,
    );
    final ackHashHex = ackHashToHex(ackHash);
    final messageBytes = utf8.encode(outboundText).length;
    _pendingRepeaterAcks[ackHashHex]?.timeout?.cancel();
    _pendingRepeaterAcks[ackHashHex] = _RepeaterAckContext(
      contactKeyHex: contact.publicKeyHex,
      selection: selection,
      pathLength: selection.useFlood ? -1 : selection.hopCount,
      messageBytes: messageBytes,
    );
  }

  void recordRepeaterPathResult(
    Contact contact,
    PathSelection selection,
    bool success,
    int? tripTimeMs,
  ) {
    _recordPathResult(contact.publicKeyHex, selection, success, tripTimeMs);
  }

  Future<bool> verifyContactPathOnDevice(
    Contact contact,
    Uint8List expectedPath, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!isConnected) return false;

    final expectedLength = expectedPath.length;
    final completer = Completer<bool>();

    void finish(bool result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    final subscription = receivedFrames.listen((frame) {
      if (frame.isEmpty || frame[0] != respCodeContact) return;
      final updated = Contact.fromFrame(frame);
      if (updated == null) return;
      if (updated.publicKeyHex != contact.publicKeyHex) return;
      final matchesLength = updated.pathLength == expectedLength;
      final matchesBytes = _pathsEqual(updated.path, expectedPath);
      if (matchesLength && matchesBytes) {
        finish(true);
      }
    });

    final timer = Timer(timeout, () => finish(false));
    try {
      await getContactByKey(contact.publicKey);
      return await completer.future;
    } finally {
      await subscription.cancel();
      timer.cancel();
    }
  }

  Future<void> sendChannelMessage(
    Channel channel,
    String text, {
    String? originalText,
    String? translatedLanguageCode,
    String? translationModelId,
  }) async {
    if (!isConnected || text.isEmpty) return;

    // Check if this is a reaction - if so, process it immediately instead of adding as a message
    final reactionInfo = ReactionHelper.parseReaction(text);
    if (reactionInfo != null) {
      // Check if we've already processed this reaction
      _processedChannelReactions.putIfAbsent(channel.index, () => {});
      final reactionIdentifier =
          '${reactionInfo.targetHash}_${reactionInfo.emoji}';

      if (_processedChannelReactions[channel.index]!.contains(
        reactionIdentifier,
      )) {
        // Already processed, don't process again
        return;
      }

      // Get the in-memory messages list (same as _addChannelMessage uses)
      _channelMessages.putIfAbsent(channel.index, () => []);
      final messages = _channelMessages[channel.index]!;

      // Process reaction locally to update the UI immediately
      _processReaction(messages, reactionInfo);
      await _channelMessageStore.saveChannelMessages(channel.index, messages);

      // Mark this reaction as processed
      _processedChannelReactions[channel.index]!.add(reactionIdentifier);

      notifyListeners();

      // Send the reaction to the device (don't add as a visible message)
      final reactionQueueId = _nextReactionSendQueueId();
      _pendingChannelSentQueue.add(reactionQueueId);
      await _waitForRadioQuiet(lastInboundRxTime: _lastChannelMsgRxTime);
      await sendFrame(
        buildSendChannelTextMsgFrame(channel.index, text),
        channelSendQueueId: reactionQueueId,
        expectsGenericAck: true,
      );
      return;
    }

    final message = ChannelMessage.outgoing(
      text,
      _selfName ?? 'Me',
      channel.index,
      originalText: originalText,
      translatedLanguageCode: translatedLanguageCode,
      translationModelId: translationModelId,
    );
    _addChannelMessage(channel.index, message);
    _pendingChannelSentQueue.add(message.messageId);
    notifyListeners();

    final outboundText = prepareChannelOutboundText(channel.index, text);
    await _waitForRadioQuiet(lastInboundRxTime: _lastChannelMsgRxTime);
    await sendFrame(
      buildSendChannelTextMsgFrame(channel.index, outboundText),
      channelSendQueueId: message.messageId,
      expectsGenericAck: true,
    );
  }

  Future<void> removeContact(Contact contact) async {
    if (!isConnected) return;

    _handleDiscovery(
      contact,
      contact.rawPacket ?? Uint8List(0),
      noNotify: true,
    );

    await sendFrame(buildRemoveContactFrame(contact.publicKey));
    _contacts.removeWhere((c) => c.publicKeyHex == contact.publicKeyHex);
    _knownContactKeys.remove(contact.publicKeyHex);
    unawaited(_persistContacts());
    _conversations.remove(contact.publicKeyHex);
    _loadedConversationKeys.remove(contact.publicKeyHex);
    _contactUnreadCount.remove(contact.publicKeyHex);
    _unreadStore.saveContactUnreadCount(
      Map<String, int>.from(_contactUnreadCount),
    );
    _messageStore.clearMessages(contact.publicKeyHex);
    notifyListeners();
  }

  Future<void> updateKnownDiscovered() async {
    if (!isConnected) return;
    for (int i = 0; i < _discoveredContacts.length; i++) {
      _discoveredContacts[i] = _discoveredContacts[i].copyWith(
        isActive: _knownContactKeys.contains(
          _discoveredContacts[i].publicKeyHex,
        ),
      );
    }
    unawaited(_persistDiscoveredContacts());
    notifyListeners();
  }

  Future<void> removeDiscoveredContact(Contact contact) async {
    if (!isConnected) return;
    _discoveredContacts.removeWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    unawaited(_persistDiscoveredContacts());
    notifyListeners();
  }

  Future<void> importDiscoveredContact(Contact contact) async {
    if (!isConnected) return;

    await sendFrame(
      buildUpdateContactPathFrame(
        contact.publicKey,
        contact.path,
        contact.pathLength,
        type: contact.type,
        flags: contact.flags,
        name: contact.name,
        lat: contact.latitude,
        lon: contact.longitude,
        lastModified: contact.lastSeen,
      ),
    );

    // Update the discovered contact to mark it as active (imported)
    final discoveredIndex = _discoveredContacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    if (discoveredIndex >= 0) {
      _discoveredContacts[discoveredIndex] =
          _discoveredContacts[discoveredIndex].copyWith(isActive: true);
    }

    _handleContactAdvert(
      Contact(
        publicKey: contact.publicKey,
        name: contact.name,
        type: contact.type,
        pathLength: contact.pathLength,
        path: contact.path,
        latitude: contact.latitude,
        longitude: contact.longitude,
        lastSeen: DateTime.now(),
        flags: contact.flags,
      ),
    );
    notifyListeners();
  }

  Future<void> clearContactPath(Contact contact) async {
    // Serialize path operations to prevent interleaved async calls.
    final prev = _pathOpLock;
    final completer = Completer<void>();
    _pathOpLock = completer.future;
    await prev;
    try {
      if (!isConnected) return;

      await sendFrame(buildResetPathFrame(contact.publicKey));
      if (_activeTransport == MeshCoreTransportType.usb) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      final existingIndex = _contacts.indexWhere(
        (c) => c.publicKeyHex == contact.publicKeyHex,
      );
      if (existingIndex >= 0) {
        final existing = _contacts[existingIndex];
        // Preserve pathOverride and pathOverrideBytes — only reset device path
        _contacts[existingIndex] = existing.copyWith(
          pathLength: -1,
          path: Uint8List(0),
        );
        notifyListeners();
        unawaited(_persistContacts());
      }
    } finally {
      completer.complete();
    }
  }

  void updateContactInMemory(
    String publicKeyHex, {
    Uint8List? pathBytes,
    int? pathLength,
  }) {
    final existingIndex = _contacts.indexWhere(
      (c) => c.publicKeyHex == publicKeyHex,
    );
    if (existingIndex >= 0) {
      final existing = _contacts[existingIndex];
      _contacts[existingIndex] = existing.copyWith(
        pathLength: pathLength,
        path: pathBytes,
      );
      notifyListeners();
      unawaited(_persistContacts());
    }
  }

  Future<void> syncTime() async {
    if (!isConnected) return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await sendFrame(buildSetDeviceTimeFrame(now));
  }

  Future<void> syncQueuedMessages({bool force = false}) async {
    if (!isConnected) return;
    if (!force && _isSyncingQueuedMessages) return;
    if (_awaitingSelfInfo || _isLoadingContacts) {
      _pendingQueueSync = true;
      return;
    }
    _isSyncingQueuedMessages = true;
    await _requestNextQueuedMessage();
  }

  Future<void> _requestNextQueuedMessage() async {
    if (!isConnected) {
      _isSyncingQueuedMessages = false;
      _queuedMessageSyncInFlight = false;
      _queueSyncRetries = 0;
      return;
    }
    if (_queuedMessageSyncInFlight) return;
    _queuedMessageSyncInFlight = true;

    // Cancel any existing timeout
    _queueSyncTimeout?.cancel();

    // Set up timeout for this request
    _queueSyncTimeout = Timer(Duration(milliseconds: _queueSyncTimeoutMs), () {
      _handleQueueSyncTimeout();
    });

    debugPrint(
      '[QueueSync] Requesting next message (retry: $_queueSyncRetries/$_maxQueueSyncRetries)',
    );

    try {
      await sendFrame(buildSyncNextMessageFrame());
    } catch (e) {
      debugPrint('[QueueSync] Error sending sync request: $e');
      _queuedMessageSyncInFlight = false;
      _isSyncingQueuedMessages = false;
      _queueSyncTimeout?.cancel();
      _queueSyncRetries = 0;
    }
  }

  void _handleQueueSyncTimeout() {
    debugPrint(
      '[QueueSync] Timeout waiting for message (retry: $_queueSyncRetries/$_maxQueueSyncRetries)',
    );

    if (_queueSyncRetries < _maxQueueSyncRetries) {
      // Retry
      _queueSyncRetries++;
      _queuedMessageSyncInFlight = false;
      _requestNextQueuedMessage();
    } else {
      // Max retries reached, give up
      debugPrint('[QueueSync] Max retries reached, stopping sync');
      _queuedMessageSyncInFlight = false;
      _isSyncingQueuedMessages = false;
      _queueSyncRetries = 0;
    }
  }

  Future<void> sendCliCommand(String command) async {
    if (!isConnected) return;

    // CLI commands are sent as UTF-8 text with a special prefix
    final commandBytes = utf8.encode(command);
    final bytes = Uint8List.fromList([0x01, ...commandBytes, 0x00]);
    _lastSentWasCliCommand = true;
    await sendFrame(bytes);
  }

  Future<void> setNodeName(String name) async {
    if (!isConnected) return;
    await sendFrame(buildSetAdvertNameFrame(name));
  }

  Future<void> setNodeLocation({
    required double lat,
    required double lon,
  }) async {
    if (!isConnected) return;
    await sendFrame(buildSetAdvertLatLonFrame(lat, lon));
  }

  Future<void> setCustomVar(String value) async {
    if (!isConnected) return;
    await sendFrame(buildSetCustomVarFrame(value));
  }

  Future<void> sendSelfAdvert({bool flood = true}) async {
    if (!isConnected) return;
    await sendFrame(buildSendSelfAdvertFrame(flood: flood));
  }

  Future<void> rebootDevice() async {
    if (!isConnected) return;
    await sendFrame(buildRebootFrame());
  }

  Future<void> setPrivacyMode(bool enabled) async {
    await sendCliCommand('set privacy ${enabled ? 'on' : 'off'}');
  }

  Future<void> setTelemetryModeBase(
    int base,
    int location,
    int env,
    int advert,
    int multiAcks,
  ) async {
    if (!isConnected) return;
    _telemetryModeBase = base.clamp(teleModeDeny, teleModeAllowAll).toInt();
    _telemetryModeLoc = location.clamp(teleModeDeny, teleModeAllowAll).toInt();
    _telemetryModeEnv = env.clamp(teleModeDeny, teleModeAllowAll).toInt();
    _advertLocPolicy = advert.clamp(0, 1).toInt();
    _multiAcks = multiAcks.clamp(0, 2).toInt();
    await sendFrame(
      buildSetOtherParamsFrame(
        (_telemetryModeEnv << 4) |
            (_telemetryModeLoc << 2) |
            _telemetryModeBase,
        _advertLocPolicy,
        _multiAcks,
      ),
    );
    notifyListeners();
  }

  Future<void> getChannels({int? maxChannels, bool force = false}) async {
    if (!isConnected) return;
    if (_isSyncingChannels) {
      debugPrint('[ChannelSync] Already syncing channels, ignoring request');
      return;
    }

    // Skip fetching if already loaded and not forced
    if (_hasLoadedChannels && !force) {
      debugPrint(
        '[ChannelSync] Channels already loaded, skipping fetch (use force=true to reload)',
      );
      return;
    }

    _isLoadingChannels = true;
    _isSyncingChannels = true;
    _previousChannelsCache = List<Channel>.from(_channels);
    _channels.clear();
    _nextChannelIndexToRequest = 0;
    _totalChannelsToRequest = maxChannels ?? _maxChannels;
    _channelSyncRetries = 0;
    notifyListeners();

    debugPrint(
      '[ChannelSync] Starting sync for $_totalChannelsToRequest channels',
    );

    // Start sequential sync
    await _requestNextChannel();
  }

  Future<void> _requestNextChannel() async {
    if (!isConnected) {
      _cleanupChannelSync(completed: false);
      return;
    }

    if (_channelSyncInFlight) return;

    // Check if we've requested all channels
    if (_nextChannelIndexToRequest >= _totalChannelsToRequest) {
      _completeChannelSync();
      return;
    }

    _channelSyncInFlight = true;
    final channelIndex = _nextChannelIndexToRequest;

    // Cancel any existing timeout
    _channelSyncTimeout?.cancel();

    // Set up timeout for this channel request
    _channelSyncTimeout = Timer(
      Duration(milliseconds: _channelSyncTimeoutMs),
      () => _handleChannelSyncTimeout(channelIndex),
    );

    debugPrint(
      '[ChannelSync] Requesting channel $channelIndex/$_totalChannelsToRequest (retry: $_channelSyncRetries/$_maxChannelSyncRetries)',
    );

    try {
      await sendFrame(buildGetChannelFrame(channelIndex));
    } catch (e) {
      debugPrint('[ChannelSync] Error sending channel request: $e');
      _channelSyncInFlight = false;
      _cleanupChannelSync(completed: false);
    }
  }

  void _handleChannelSyncTimeout(int channelIndex) {
    debugPrint(
      '[ChannelSync] Timeout waiting for channel $channelIndex (retry: $_channelSyncRetries/$_maxChannelSyncRetries)',
    );

    if (_channelSyncRetries < _maxChannelSyncRetries) {
      // Retry the same channel
      _channelSyncRetries++;
      _channelSyncInFlight = false;
      unawaited(_requestNextChannel());
    } else {
      // Max retries reached for this channel, restore from cache and move to next
      debugPrint(
        '[ChannelSync] Max retries reached for channel $channelIndex, attempting cache restore',
      );

      // Try to restore this channel from cache
      try {
        final cachedChannel = _previousChannelsCache.firstWhere(
          (c) => c.index == channelIndex,
        );
        if (!cachedChannel.isEmpty) {
          _channels.add(cachedChannel);
          debugPrint(
            '[ChannelSync] Restored channel $channelIndex (${cachedChannel.name}) from cache',
          );
        }
      } catch (e) {
        // No cached channel found, that's okay
      }

      // Move to next channel
      _nextChannelIndexToRequest++;
      _channelSyncRetries = 0;
      _channelSyncInFlight = false;
      unawaited(_requestNextChannel());
    }
  }

  void _completeChannelSync() {
    _channelSyncTimeout?.cancel();

    debugPrint(
      '[ChannelSync] Sync complete: received ${_channels.length}/$_totalChannelsToRequest channels',
    );

    _cleanupChannelSync(completed: true);

    // Cache channels for offline use
    _cachedChannels = List<Channel>.from(_channels);
    unawaited(_channelStore.saveChannels(_channels));

    // Apply ordering and notify UI
    _applyChannelOrder();
    notifyListeners();
  }

  void _cleanupChannelSync({required bool completed}) {
    _isSyncingChannels = false;
    _channelSyncInFlight = false;
    _isLoadingChannels = false;
    _channelSyncTimeout?.cancel();
    _channelSyncRetries = 0;
    _nextChannelIndexToRequest = 0;
    _totalChannelsToRequest = 0;

    if (completed) {
      _hasLoadedChannels = true;
      _previousChannelsCache.clear();
    }

    // Fallback: if contact sync was deferred waiting for channel 0 but
    // channel sync finished without triggering it, start contacts now.
    if (_pendingInitialContactsSync && isConnected) {
      _pendingInitialContactsSync = false;
      unawaited(getContacts());
    }

    // Keep cache on failure/disconnection for future attempts
  }

  Future<void> setChannel(int index, String name, Uint8List psk) async {
    if (!isConnected) return;

    await sendFrame(buildSetChannelFrame(index, name, psk));
    // Refresh channels after setting
    await getChannels(force: true);
  }

  Future<void> deleteChannel(int index) async {
    if (!isConnected) return;

    // Delete by setting empty name and zero PSK
    await sendFrame(buildSetChannelFrame(index, '', Uint8List(16)));
    // Clear stored messages for this channel
    await _channelMessageStore.clearChannelMessages(index);
    // Clear in-memory messages for this channel
    _channelMessages.remove(index);
    // Refresh channels after deleting
    await getChannels(force: true);
  }

  void _handleFrame(List<int> data) {
    if (data.isEmpty) return;
    _lastRxTime = DateTime.now();

    final frame = Uint8List.fromList(data);
    _receivedFramesController.add(frame);
    _bleDebugLogService?.logFrame(frame, outgoing: false);

    final code = frame[0];
    // debugPrint('RX frame: code=$code len=${frame.length}');

    switch (code) {
      case respCodeOk:
        _handleOk();
        break;
      case respCodeDeviceInfo:
        _handleDeviceInfo(frame);
        break;
      case respCodeSelfInfo:
        debugPrint('Got SELF_INFO');
        _handleSelfInfo(frame);
        break;
      case respCodeContactsStart:
        debugPrint('Got CONTACTS_START');
        if (!_preserveContactsOnRefresh) {
          _contacts.clear();
        }
        _isLoadingContacts = true;
        notifyListeners();
        break;
      case pushCodeAdvert:
        // Known contact was seen again - just a pub key, no action needed
        break;
      case pushCodeNewAdvert:
        debugPrint('Got New CONTACT');
        // It's the same format as respCodeContact, so we can reuse the handler
        _handleContact(frame, isContact: false);
        break;
      case respCodeContact:
        debugPrint('Got CONTACT');
        _handleContact(frame);
        break;
      case respCodeEndOfContacts:
        debugPrint('Got END_OF_CONTACTS');
        _isLoadingContacts = false;
        _preserveContactsOnRefresh = false;
        unawaited(updateKnownDiscovered());
        notifyListeners();
        unawaited(_persistContacts());
        if (PlatformInfo.isWeb &&
            _activeTransport == MeshCoreTransportType.bluetooth &&
            _isSyncingChannels &&
            !_channelSyncInFlight) {
          unawaited(_requestNextChannel());
        }
        if (!_didInitialQueueSync || _pendingQueueSync) {
          _didInitialQueueSync = true;
          _pendingQueueSync = false;
          unawaited(syncQueuedMessages(force: true));
        }
        if (_pendingDeferredChannelSyncAfterContacts &&
            (_activeTransport == MeshCoreTransportType.bluetooth ||
                _activeTransport == MeshCoreTransportType.usb ||
                _activeTransport == MeshCoreTransportType.tcp)) {
          _pendingDeferredChannelSyncAfterContacts = false;
          _pendingInitialChannelSync = false;
          unawaited(getChannels());
        }
        break;
      case respCodeContactMsgRecv:
      case respCodeContactMsgRecvV3:
        _handleIncomingMessage(frame);
        break;
      case respCodeChannelMsgRecv:
      case respCodeChannelMsgRecvV3:
        _handleIncomingChannelMessage(frame);
        break;
      case respCodeSent:
        _handleMessageSent(frame);
        break;
      case respCodeNoMoreMessages:
        _handleNoMoreMessages();
        break;
      case pushCodeMsgWaiting:
        unawaited(syncQueuedMessages(force: true));
        break;
      case pushCodeSendConfirmed:
        _handleSendConfirmed(frame);
        break;
      case pushCodePathUpdated:
        _handlePathUpdated(frame);
        break;
      case pushCodeLoginSuccess:
      case pushCodeLoginFail:
      case pushCodeStatusResponse:
        break;
      case pushCodeLogRxData:
        _lastRadioRxTime = DateTime.now();
        _handleRxData(frame);
        _handleLogRxData(frame);
        break;
      case respCodeChannelInfo:
        _handleChannelInfo(frame);
        break;
      case respCodeAutoAddConfig:
        _handleAutoAddConfig(frame);
        _checkManualAddContacts();
        break;
      case respCodeBattAndStorage:
        _handleBatteryAndStorage(frame);
        break;
      case respCodeStats:
        _handleStatsFrame(frame);
        break;
      case respCodeCustomVars:
        _handleCustomVars(frame);
        break;
      // RESP_CODE_ERR is a defined firmware response (code 1), not an unknown frame.
      case respCodeErr:
        _handleErrorFrame(frame);
        break;
      default:
        debugPrint('Unknown frame code: $code');
    }
  }

  void _handleErrorFrame(Uint8List frame) {
    final errCode = frame.length > 1 ? frame[1] : -1;
    _appDebugLogService?.warn(
      'Firmware responded with error code: $errCode',
      tag: 'Protocol',
    );

    if (_pendingGenericAckQueue.isEmpty) {
      return;
    }

    final failedAck = _pendingGenericAckQueue.removeAt(0);
    if (failedAck.commandCode != cmdSendChannelTxtMsg ||
        failedAck.channelSendQueueId == null) {
      return;
    }
    _pendingChannelSentQueue.remove(failedAck.channelSendQueueId);
  }

  void _handlePathUpdated(Uint8List frame) {
    // Frame format: [0]=code, [1-32]=pub_key
    if (frame.length >= 33 && _pathHistoryService != null) {
      final pubKey = Uint8List.fromList(frame.sublist(1, 33));
      final contact = _contacts.cast<Contact?>().firstWhere(
        (c) => c != null && listEquals(c.publicKey, pubKey),
        orElse: () => null,
      );

      if (contact != null) {
        _pathHistoryService!.handlePathUpdated(contact);
        // Refresh just this specific contact instead of all contacts.
        // This avoids race conditions with _preserveContactsOnRefresh flag
        // that can occur when using refreshContactsSinceLastmod().
        getContactByKey(pubKey);
      }
    }
  }

  void _handleSelfInfo(Uint8List frame) {
    // SELF_INFO format:
    // [0] = RESP_CODE_SELF_INFO
    // [1] = ADV_TYPE
    // [2] = tx_power_dbm
    // [3] = MAX_LORA_TX_POWER
    // [4-35] = pub_key (32 bytes)
    // [36-39] = lat (int32 LE)
    // [40-43] = lon (int32 LE)
    // [44] = multi_acks
    // [45] = advert_loc_policy
    // [46] = telemetry modes
    // [47] = manual_add_contacts
    // [48-51] = freq (uint32 LE, in Hz)
    // [52-55] = bw (uint32 LE, in Hz)
    // [56] = sf
    // [57] = cr
    // [58+] = node_name
    final wasAwaitingSelfInfo = _awaitingSelfInfo;
    final reader = BufferReader(frame);
    try {
      reader.skipBytes(2);
      _currentTxPower = reader.readInt8();
      _maxTxPower = reader.readInt8();
      _selfPublicKey = reader.readBytes(pubKeySize);
      _selfLatitude = reader.readInt32LE() / 1000000.0;
      _selfLongitude = reader.readInt32LE() / 1000000.0;
      _multiAcks = reader.readByte();
      _advertLocPolicy = reader.readByte();
      final telemetryFlag = reader.readByte();
      _telemetryModeBase = telemetryFlag & 0x03;
      _telemetryModeEnv = telemetryFlag >> 2 & 0x03;
      _telemetryModeLoc = telemetryFlag >> 4 & 0x03;

      _manualAddContacts = reader.readByte() & 0x01 == 0x00;

      _currentFreqHz = reader.readUInt32LE();
      _currentBwHz = reader.readUInt32LE();
      _currentSf = reader.readByte();
      _currentCr = reader.readByte();

      _selfName = reader.readCString();
    } catch (e) {
      _appDebugLogService?.error(
        'Error parsing SELF_INFO frame: $e',
        tag: 'Connector',
      );
    }
    final selfName = _selfName?.trim();
    if (_activeTransport == MeshCoreTransportType.usb &&
        selfName != null &&
        selfName.isNotEmpty) {
      _usbManager.updateConnectedLabel(selfName);
    }

    //set all the stores' public key so they can load the correct data
    _channelMessageStore.setPublicKeyHex = selfPublicKeyHex;
    _messageStore.setPublicKeyHex = selfPublicKeyHex;
    _channelOrderStore.setPublicKeyHex = selfPublicKeyHex;
    _channelSettingsStore.setPublicKeyHex = selfPublicKeyHex;
    _contactSettingsStore.setPublicKeyHex = selfPublicKeyHex;
    _contactStore.setPublicKeyHex = selfPublicKeyHex;
    _channelStore.setPublicKeyHex = selfPublicKeyHex;
    _unreadStore.setPublicKeyHex = selfPublicKeyHex;

    // Now that we have self info, we can load all the persisted data for this node
    _loadChannelOrder();
    loadContactCache();
    loadChannelSettings();
    loadCachedChannels();

    // Load persisted channel messages
    loadAllChannelMessages();
    loadUnreadState();
    _loadDiscoveredContactCache();

    _awaitingSelfInfo = false;
    _selfInfoRetryTimer?.cancel();
    _selfInfoRetryTimer = null;
    notifyListeners();

    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth &&
        !wasAwaitingSelfInfo) {
      return;
    }

    // Auto-fetch contacts after getting self info. On web BLE, defer this
    // until after channel 0 so startup writes stay serialized.
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth) {
      _pendingInitialContactsSync = true;
    } else if (_activeTransport == MeshCoreTransportType.usb ||
        _activeTransport == MeshCoreTransportType.tcp) {
      _pendingDeferredChannelSyncAfterContacts = true;
      getContacts();
    } else {
      getContacts();
    }
    if (_shouldGateInitialChannelSync &&
        _activeTransport != MeshCoreTransportType.usb &&
        _activeTransport != MeshCoreTransportType.tcp) {
      _maybeStartInitialChannelSync();
    }
  }

  void _handleDeviceInfo(Uint8List frame) {
    if (frame.length < 4) return;
    if (_shouldGateInitialChannelSync) {
      _hasReceivedDeviceInfo = true;
    }
    _firmwareVerCode = frame[1];

    // Parse client_repeat from firmware v9+ (byte 80)
    if (frame.length >= 81) {
      _clientRepeat = frame[80] != 0;
    }
    // Path hash mode v10+ (byte 81): width = mode + 1 byte(s) per hop
    if (frame.length >= 82) {
      final mode = (frame[81] & 0xFF).clamp(0, 2);
      _pathHashByteWidth = mode + 1;
    } else {
      _pathHashByteWidth = 1;
    }

    // Firmware reports MAX_CONTACTS / 2 for v3+ device info.
    final reportedContacts = frame[2];
    final reportedChannels = frame[3];
    final nextMaxContacts = reportedContacts > 0
        ? reportedContacts * 2
        : _maxContacts;
    final nextMaxChannels = reportedChannels > 0
        ? reportedChannels
        : _maxChannels;
    final previousMaxChannels = _maxChannels;
    if (nextMaxContacts != _maxContacts || nextMaxChannels != _maxChannels) {
      _maxContacts = nextMaxContacts;
      _maxChannels = nextMaxChannels;
      if (nextMaxChannels > previousMaxChannels) {
        unawaited(loadChannelSettings(maxChannels: nextMaxChannels));
        unawaited(loadAllChannelMessages(maxChannels: nextMaxChannels));
        if (isConnected &&
            _selfPublicKey != null &&
            (!_shouldGateInitialChannelSync || !_pendingInitialChannelSync)) {
          unawaited(getChannels(maxChannels: nextMaxChannels));
        }
      }
    }
    notifyListeners();
    if (_shouldGateInitialChannelSync) {
      _maybeStartInitialChannelSync();
    }
  }

  void _maybeStartInitialChannelSync() {
    if (!_pendingInitialChannelSync || !isConnected) {
      return;
    }
    if (_selfPublicKey == null || !_hasReceivedDeviceInfo) {
      return;
    }

    _pendingInitialChannelSync = false;
    unawaited(getChannels(maxChannels: _maxChannels));
  }

  void _handleNoMoreMessages() {
    debugPrint('[QueueSync] No more messages, sync complete');
    _queueSyncTimeout?.cancel();
    _isSyncingQueuedMessages = false;
    _queuedMessageSyncInFlight = false;
    _queueSyncRetries = 0; // Reset retry counter on successful completion
  }

  void _handleQueuedMessageReceived() {
    if (!_isSyncingQueuedMessages) return;
    debugPrint('[QueueSync] Message received, requesting next');
    _queueSyncTimeout?.cancel(); // Cancel timeout - message arrived
    _queuedMessageSyncInFlight = false;
    _queueSyncRetries = 0; // Reset retry counter on successful message
    unawaited(_requestNextQueuedMessage());
  }

  void _handleStatsFrame(Uint8List frame) {
    final stats = CompanionRadioStats.tryParse(frame);
    if (stats == null) return;
    final total = stats.txAirSecs + stats.rxAirSecs;
    if (total > _prevTotalAirSecs) {
      (_airtimeBumpStopwatch ??= Stopwatch()).reset();
      _airtimeBumpStopwatch!.start();
    }
    _prevTotalAirSecs = total;
    _latestRadioStats = stats;
    radioStatsNotifier.value = stats;
  }

  void _handleBatteryAndStorage(Uint8List frame) {
    // Frame format from C++:
    // [0] = RESP_CODE_BATT_AND_STORAGE
    // [1-2] = battery_mv (uint16 LE)
    // [3-6] = storage_used_kb (uint32 LE)
    // [7-10] = storage_total_kb (uint32 LE)
    try {
      final reader = BufferReader(frame);
      reader.skipBytes(1);
      _batteryMillivolts = reader.readUInt16LE();
      _storageUsedKb = reader.readUInt32LE();
      _storageTotalKb = reader.readUInt32LE();
      final volts = (_batteryMillivolts! / 1000.0).toStringAsFixed(2);
      _appDebugLogService?.info(
        'Pulled battery: $volts V ($_batteryMillivolts mV)',
        tag: 'Battery',
      );
      notifyListeners();
    } catch (e) {
      _appDebugLogService?.error(
        'Error parsing battery and storage frame: $e',
        tag: 'Connector',
      );
    }
  }

  void _checkManualAddContacts() async {
    // If manual add contacts is enabled, set auto add config and other params.
    // and disable it after
    if (_manualAddContacts) {
      await sendFrame(
        buildSetAutoAddConfigFrame(
          autoAddChat: true,
          autoAddRepeater: true,
          autoAddRoomServer: true,
          autoAddSensor: true,
          overwriteOldest: _overwriteOldest,
        ),
      );
      await sendFrame(
        buildSetOtherParamsFrame(
          (_telemetryModeEnv << 4) |
              (_telemetryModeLoc << 2) |
              (_telemetryModeBase),
          _advertLocPolicy,
          _multiAcks,
        ),
      );
      _manualAddContacts = false;
    }
  }

  /// Estimate single-packet airtime in ms from radio settings, or a fallback.
  int _estimateAirtimeMs(int messageBytes) {
    if (_currentFreqHz != null &&
        _currentBwHz != null &&
        _currentSf != null &&
        _currentCr != null) {
      final cr = _currentCr! <= 4 ? _currentCr! : _currentCr! - 4;
      return calculateLoRaAirtime(
        payloadBytes: messageBytes,
        spreadingFactor: _currentSf!,
        bandwidthHz: _currentBwHz!,
        codingRate: cr,
        lowDataRateOptimize: _currentSf! >= 11,
      );
    }
    return 50; // fallback: ~SF7/BW125 for 100 bytes
  }

  /// Physics-based worst-case timeout (ceiling).
  int _physicsMaxTimeout(int pathLength, int airtime) {
    if (pathLength < 0) {
      // Match firmware: SEND_TIMEOUT_BASE_MILLIS + (FLOOD_SEND_TIMEOUT_FACTOR * airtime)
      return 500 + (16 * airtime);
    } else {
      return 500 + ((airtime * 6 + 250) * (pathLength + 1));
    }
  }

  int _physicsMinTimeout(int pathLength, int airtime) {
    if (pathLength < 0) {
      // Same as max for flood — firmware uses a single formula
      return 500 + (16 * airtime);
    } else {
      return airtime * (pathLength + 1);
    }
  }

  /// Calculate timeout for a message based on radio settings and path length.
  /// Returns timeout in milliseconds, considering number of hops.
  int calculateTimeout({
    required int pathLength,
    int messageBytes = 100,
    String? contactKey,
  }) {
    final airtime = _estimateAirtimeMs(messageBytes);
    final physicsMin = _physicsMinTimeout(pathLength, airtime);
    final physicsMax = _physicsMaxTimeout(pathLength, airtime);

    // Try ML-based prediction
    final secSinceRx = DateTime.now().difference(_lastRxTime).inSeconds;
    final mlTimeout = _timeoutPredictionService?.predictTimeout(
      contactKey: contactKey,
      pathLength: pathLength,
      messageBytes: messageBytes,
      secondsSinceLastRx: secSinceRx,
    );
    if (mlTimeout != null) {
      if (pathLength < 0) {
        // Flood: trust ML, only enforce firmware formula as floor
        if (mlTimeout < physicsMin) {
          return physicsMin;
        }
      }
      return mlTimeout.clamp(physicsMin, physicsMax);
    }

    // No ML data — use firmware formula
    return physicsMax;
  }

  void _handleContact(Uint8List frame, {bool isContact = true}) {
    final contactTmp = Contact.fromFrame(frame);
    if (contactTmp != null) {
      if (listEquals(contactTmp.publicKey, _selfPublicKey)) {
        appLogger.info(
          'Ignoring contact with self public key: ${contactTmp.name}',
          tag: 'Connector',
        );
        removeContact(contactTmp);
        return;
      }
      final contact = getFromDiscovered(contactTmp);
      _handleDiscovery(contact, frame, noNotify: true, addActive: true);

      if (contact.type == advTypeRepeater) {
        _contactUnreadCount.remove(contact.publicKeyHex);
        _unreadStore.saveContactUnreadCount(
          Map<String, int>.from(_contactUnreadCount),
        );
      }
      // Check if this is a new contact
      final isNewContact = !_knownContactKeys.contains(contact.publicKeyHex);
      final existingIndex = _contacts.indexWhere(
        (c) => c.publicKeyHex == contact.publicKeyHex,
      );

      if (existingIndex >= 0) {
        final existing = _contacts[existingIndex];
        final mergedLastMessageAt =
            existing.lastMessageAt.isAfter(contact.lastMessageAt)
            ? existing.lastMessageAt
            : contact.lastMessageAt;

        appLogger.info(
          'Refreshing contact ${contact.name}: devicePath=${contact.pathLength}, existingOverride=${existing.pathOverride}',
          tag: 'Connector',
        );

        // Preserve user-selected path settings and previously known GPS when
        // refreshed frames omit coordinates (lat/lon encoded as 0,0).
        _contacts[existingIndex] = contact.copyWith(
          lastMessageAt: mergedLastMessageAt,
          pathOverride: existing.pathOverride, // Preserve user's path choice
          pathOverrideBytes: existing.pathOverrideBytes,
          latitude: contact.latitude ?? existing.latitude,
          longitude: contact.longitude ?? existing.longitude,
        );

        appLogger.info(
          'After merge: pathOverride=${_contacts[existingIndex].pathOverride}, devicePath=${_contacts[existingIndex].pathLength}',
          tag: 'Connector',
        );
      } else {
        if ((_autoAddUsers && contact.type == advTypeChat) ||
            (_autoAddRepeaters && contact.type == advTypeRepeater) ||
            (_autoAddRoomServers && contact.type == advTypeRoom) ||
            (_autoAddSensors && contact.type == advTypeSensor) ||
            isContact) {
          _contacts.add(contact);
          appLogger.info(
            'Added new contact ${contact.name}: pathLen=${contact.pathLength}',
            tag: 'Connector',
          );
        } else {
          appLogger.info(
            "Discovered contact ${contact.name} (type ${contact.typeLabel}) not added due to auto-add settings",
            tag: 'Connector',
          );
          return;
        }
      }
      _knownContactKeys.add(contact.publicKeyHex);
      _loadMessagesForContact(contact.publicKeyHex);

      // Add path to history if we have a valid path
      if (_pathHistoryService != null && contact.pathLength >= 0) {
        _pathHistoryService!.handlePathUpdated(contact);
      }

      notifyListeners();

      // Show notification for new contact (advertisement)
      if (isNewContact && _appSettingsService != null) {
        final settings = _appSettingsService!.settings;
        if (settings.notificationsEnabled && settings.notifyOnNewAdvert) {
          _notificationService.showAdvertNotification(
            contactName: contact.name,
            contactType: contact.typeLabel,
            contactId: contact.publicKeyHex,
          );
        }
      }

      if (!_isLoadingContacts) {
        unawaited(_persistContacts());
      }
    }
  }

  void _handleContactAdvert(Contact contact) {
    if (listEquals(contact.publicKey, _selfPublicKey)) {
      return;
    }

    if (contact.type == advTypeRepeater) {
      _contactUnreadCount.remove(contact.publicKeyHex);
      _unreadStore.saveContactUnreadCount(
        Map<String, int>.from(_contactUnreadCount),
      );
    }
    // Check if this is a new contact
    final isNewContact = !_knownContactKeys.contains(contact.publicKeyHex);
    final existingIndex = _contacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );

    if (existingIndex >= 0) {
      final existing = _contacts[existingIndex];
      final mergedLastMessageAt =
          existing.lastMessageAt.isAfter(contact.lastMessageAt)
          ? existing.lastMessageAt
          : contact.lastMessageAt;

      appLogger.info(
        'Refreshing contact ${contact.name}: devicePath=${contact.pathLength}, existingOverride=${existing.pathOverride}',
        tag: 'Connector',
      );

      // CRITICAL: Preserve user's path override when contact is refreshed from device
      _contacts[existingIndex] = contact.copyWith(
        lastMessageAt: mergedLastMessageAt,
        pathOverride: existing.pathOverride, // Preserve user's path choice
        pathOverrideBytes: existing.pathOverrideBytes,
      );

      appLogger.info(
        'After merge: pathOverride=${_contacts[existingIndex].pathOverride}, devicePath=${_contacts[existingIndex].pathLength}',
        tag: 'Connector',
      );
    } else {
      _contacts.add(contact);
      appLogger.info(
        'Added new contact ${contact.name}: pathLen=${contact.pathLength}',
        tag: 'Connector',
      );
    }
    _knownContactKeys.add(contact.publicKeyHex);
    _loadMessagesForContact(contact.publicKeyHex);

    // Add path to history if we have a valid path
    if (_pathHistoryService != null && contact.pathLength >= 0) {
      _pathHistoryService!.handlePathUpdated(contact);
    }

    notifyListeners();

    // Show notification for new contact (advertisement)
    if (isNewContact && _appSettingsService != null) {
      final settings = _appSettingsService!.settings;
      if (settings.notificationsEnabled && settings.notifyOnNewAdvert) {
        _notificationService.showAdvertNotification(
          contactName: contact.name,
          contactType: contact.typeLabel,
          contactId: contact.publicKeyHex,
        );
      }
    }

    if (!_isLoadingContacts) {
      unawaited(_persistContacts());
    }
  }

  Future<void> _persistContacts() async {
    await _contactStore.saveContacts(_contacts);
  }

  Future<void> _persistDiscoveredContacts() async {
    await _discoveryContactStore.saveContacts(_discoveredContacts);
  }

  int _latestContactLastmod() {
    if (_contacts.isEmpty) return 0;
    var latest = 0;
    for (final contact in _contacts) {
      final seconds = contact.lastSeen.millisecondsSinceEpoch ~/ 1000;
      if (seconds > latest) {
        latest = seconds;
      }
    }
    return latest;
  }

  bool _setContactLastMessageAt(int index, DateTime timestamp) {
    final contact = _contacts[index];
    if (contact.type != advTypeChat) return false;
    if (!timestamp.isAfter(contact.lastMessageAt)) return false;
    _contacts[index] = contact.copyWith(lastMessageAt: timestamp);
    return true;
  }

  void _updateContactLastMessageAt(
    String contactKeyHex,
    DateTime timestamp, {
    bool notify = false,
  }) {
    final index = _contacts.indexWhere((c) => c.publicKeyHex == contactKeyHex);
    if (index < 0) return;
    if (!_setContactLastMessageAt(index, timestamp)) return;
    unawaited(_persistContacts());
    if (notify) {
      notifyListeners();
    }
  }

  void _updateContactLastMessageAtByName(
    String senderName,
    DateTime timestamp, {
    Uint8List? pathBytes,
    bool notify = false,
  }) {
    final normalized = senderName.trim().toLowerCase();
    final hasName = normalized.isNotEmpty && normalized != 'unknown';
    var updated = false;
    var matchedByName = false;

    if (hasName) {
      for (var i = 0; i < _contacts.length; i++) {
        final contact = _contacts[i];
        if (contact.type != advTypeChat) continue;
        if (contact.name.trim().toLowerCase() == normalized) {
          matchedByName = true;
          updated = _setContactLastMessageAt(i, timestamp) || updated;
        }
      }
    }

    if (!matchedByName && pathBytes != null && pathBytes.isNotEmpty) {
      final matches = <int>[];
      for (var i = 0; i < _contacts.length; i++) {
        final contact = _contacts[i];
        if (contact.type != advTypeChat) continue;
        if (_pathMatchesContact(pathBytes, contact.publicKey)) {
          matches.add(i);
        }
      }
      if (matches.length == 1) {
        updated = _setContactLastMessageAt(matches.first, timestamp) || updated;
      }
    }

    if (updated) {
      unawaited(_persistContacts());
      if (notify) {
        notifyListeners();
      }
    }
  }

  bool _pathMatchesContact(Uint8List pathBytes, Uint8List publicKey) {
    final w = _pathHashByteWidth;
    if (pathBytes.isEmpty || publicKey.length < w) return false;
    for (int i = 0; i + w <= pathBytes.length; i += w) {
      final prefix = pathBytes.sublist(i, i + w);
      if (_matchesPrefix(publicKey, prefix)) {
        return true;
      }
    }
    return false;
  }

  void _handleIncomingMessage(Uint8List frame) async {
    if (_selfPublicKey == null) return;

    var message = _parseContactMessage(frame);

    // If message parsing failed due to unknown contact, refresh contacts and retry
    if (message == null && !_isLoadingContacts) {
      final senderPrefix = _extractSenderPrefix(frame);
      if (senderPrefix != null) {
        final hasContact = _contacts.any(
          (c) => _matchesPrefix(c.publicKey, senderPrefix),
        );
        if (!hasContact) {
          debugPrint(
            'Received message from unknown contact, refreshing contacts...',
          );
          await refreshContactsSinceLastmod();
          // Retry parsing after refresh
          message = _parseContactMessage(frame);
          if (message != null) {
            debugPrint('Successfully parsed message after contact refresh');
          }
        }
      }
    }

    if (message != null) {
      if (!message.isOutgoing) {
        _lastContactMsgRxTime = DateTime.now();
      }
      // Ignore messages from self (device hearing its own broadcast)
      // BUT allow repeated messages (pathLength indicates it went through repeater)
      if (_selfPublicKey != null &&
          message.senderKeyHex == pubKeyToHex(_selfPublicKey!) &&
          (message.pathLength == null || message.pathLength == 0)) {
        debugPrint('Ignoring direct message from self');
        return;
      }

      final contact = _contacts.cast<Contact?>().firstWhere(
        (c) => c?.publicKeyHex == message!.senderKeyHex,
        orElse: () => null,
      );
      if (contact != null) {
        message = message.copyWith(
          pathLength: contact.pathLength < 0 ? -1 : contact.pathLength,
          pathBytes: contact.pathLength < 0 ? Uint8List(0) : contact.path,
        );
      }
      if (contact != null) {
        _updateContactLastMessageAt(contact.publicKeyHex, message.timestamp);
      }
      if (!message.isOutgoing) {
        final existing = _conversations[message.senderKeyHex];
        final incomingTimestamp = message.timestamp.millisecondsSinceEpoch;
        if (existing != null && existing.isNotEmpty) {
          final startIndex = existing.length > 10 ? existing.length - 10 : 0;
          for (int i = existing.length - 1; i >= startIndex; i--) {
            final recent = existing[i];
            if (!recent.isOutgoing &&
                recent.timestamp.millisecondsSinceEpoch == incomingTimestamp &&
                recent.text == message.text) {
              return;
            }
          }
        }
      }
      _addMessage(message.senderKeyHex, message);
      if (!message.isOutgoing) {
        unawaited(
          _translateIncomingContactMessage(message.senderKeyHex, message),
        );
      }
      _maybeIncrementContactUnread(message);
      notifyListeners();

      // Show notification for new incoming message
      if (!message.isOutgoing &&
          !message.isCli &&
          _appSettingsService != null) {
        final settings = _appSettingsService!.settings;
        if (settings.notificationsEnabled && settings.notifyOnNewMessage) {
          if (contact?.type == advTypeChat) {
            _notificationService.showMessageNotification(
              contactName: contact?.name ?? 'Unknown',
              message: message.text,
              contactId: message.senderKeyHex,
              badgeCount: getTotalUnreadCount(),
            );
          } else if (contact?.type == advTypeRoom) {
            _notificationService.showMessageNotification(
              contactName: contact?.name ?? 'Unknown Room',
              message: message.text.length > 4
                  ? message.text.substring(4)
                  : message.text,
              contactId: message.senderKeyHex,
              badgeCount: getTotalUnreadCount(),
            );
          }
        }
      }
      _handleQueuedMessageReceived();
    } else if (_isSyncingQueuedMessages) {
      _handleQueuedMessageReceived();
    }
  }

  Message? _parseContactMessage(Uint8List frame) {
    if (frame.isEmpty) {
      appLogger.warn('Received empty frame, ignoring');
      return null;
    }
    final reader = BufferReader(frame);

    try {
      final code = reader.readByte();
      if (code != respCodeContactMsgRecv && code != respCodeContactMsgRecvV3) {
        appLogger.warn(
          'Unexpected message code: $code, expected contact message receive codes',
        );
        return null;
      }

      // Companion radio layout:
      // [code][snr?][res?][res?][prefix x6][path_len][txt_type][timestamp x4][extra?][text...]
      // double snr = 0;
      if (code == respCodeContactMsgRecvV3) {
        // Older firmware layout with SNR as a signed byte after the code
        // snr = reader.readInt8().toDouble() * 4; // SNR in dB, scaled by 4
        reader.skipBytes(1); // Skip SNR byte
        reader.skipBytes(2); // Skip reserved bytes
      }

      final senderPrefix = reader.readBytes(6);
      final pathLength = reader.readByte();
      final txtType = reader.readByte();
      final timestampRaw = reader.readUInt32LE();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        timestampRaw * 1000,
      );

      if (txtType == 2) {
        reader.skipBytes(4); // Skip extra 4 bytes for signed/plain variants
      }

      final msgText = reader.readCString();

      final flags = txtType;
      final shiftedType = flags >> 2;
      final rawType = flags;
      final isPlain = shiftedType == txtTypePlain || rawType == txtTypePlain;
      final isCli = shiftedType == txtTypeCliData || rawType == txtTypeCliData;
      if (!isPlain && !isCli) {
        appLogger.warn(
          'Unknown message type received: txtType=$txtType, shifted=$shiftedType, raw=$rawType',
        );
        return null;
      }

      if (msgText.isEmpty) {
        appLogger.warn('Received message with empty text, ignoring');
        return null;
      }
      final decodedText = isCli
          ? msgText
          : (Smaz.tryDecodePrefixed(msgText) ?? msgText);

      final contact = _contacts.cast<Contact?>().firstWhere(
        (c) => c != null && _matchesPrefix(c.publicKey, senderPrefix),
        orElse: () => null,
      );
      if (contact == null) {
        appLogger.warn(
          'Received message from unknown contact with prefix: ${senderPrefix.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join('')}',
        );
        return null;
      }

      return Message(
        senderKey: contact.publicKey,
        text: decodedText,
        timestamp: timestamp,
        isOutgoing: false,
        isCli: isCli,
        status: MessageStatus.delivered,
        pathLength: pathLength == 0xFF ? 0 : pathLength,
        pathBytes: Uint8List(0),
        fourByteRoomContactKey: msgText.length >= 4
            ? Uint8List.fromList(msgText.substring(0, 4).codeUnits)
            : null,
      );
    } catch (e) {
      appLogger.warn('Error parsing contact direct message: $e');
      return null;
    }
  }

  bool _matchesPrefix(Uint8List fullKey, Uint8List prefix) {
    if (fullKey.length < prefix.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (fullKey[i] != prefix[i]) return false;
    }
    return true;
  }

  Uint8List? _extractSenderPrefix(Uint8List frame) {
    if (frame.isEmpty) return null;
    final code = frame[0];
    if (code != respCodeContactMsgRecv && code != respCodeContactMsgRecvV3) {
      return null;
    }

    final prefixOffset = code == respCodeContactMsgRecvV3 ? 4 : 1;
    const prefixLen = 6;

    if (frame.length < prefixOffset + prefixLen) return null;

    return frame.sublist(prefixOffset, prefixOffset + prefixLen);
  }

  void _ensureContactSmazSettingLoaded(String contactKeyHex) {
    if (_contactSmazEnabled.containsKey(contactKeyHex)) return;
    _contactSettingsStore.loadSmazEnabled(contactKeyHex).then((enabled) {
      if (_contactSmazEnabled[contactKeyHex] == enabled) return;
      _contactSmazEnabled[contactKeyHex] = enabled;
      notifyListeners();
    });
  }

  /// Prepares contact outbound text by applying SMAZ encoding if enabled.
  /// This should be used to transform text before computing ACK hashes.
  String prepareContactOutboundText(Contact contact, String text) {
    final trimmed = text.trim();
    final isStructuredPayload =
        trimmed.startsWith('g:') ||
        trimmed.startsWith('m:') ||
        trimmed.startsWith('V1|');
    if (!isStructuredPayload && isContactSmazEnabled(contact.publicKeyHex)) {
      return Smaz.encodeIfSmaller(text);
    }
    return text;
  }

  String prepareChannelOutboundText(int channelIndex, String text) {
    final trimmed = text.trim();
    final isStructuredPayload =
        trimmed.startsWith('g:') || trimmed.startsWith('m:');
    if (!isStructuredPayload && isChannelSmazEnabled(channelIndex)) {
      return Smaz.encodeIfSmaller(text);
    }
    return text;
  }

  String _channelDisplayName(int channelIndex) {
    for (final channel in _channels) {
      if (channel.index != channelIndex) continue;
      return channel.name.isEmpty ? 'Channel $channelIndex' : channel.name;
    }
    return 'Channel $channelIndex';
  }

  void _maybeNotifyChannelMessage(
    ChannelMessage message, {
    String? channelName,
  }) {
    if (message.isOutgoing || _appSettingsService == null) return;
    final channelIndex = message.channelIndex;
    if (channelIndex == null) return;

    final settings = _appSettingsService!.settings;
    if (!settings.notificationsEnabled || !settings.notifyOnNewChannelMessage) {
      return;
    }

    final label = channelName ?? _channelDisplayName(channelIndex);
    if (_appSettingsService!.isChannelMuted(label)) return;

    _notificationService.showChannelMessageNotification(
      channelName: label,
      senderName: message.senderName,
      message: message.text,
      channelIndex: channelIndex,
      badgeCount: getTotalUnreadCount(),
    );
  }

  void _handleIncomingChannelMessage(Uint8List frame) {
    final parsed = ChannelMessage.fromFrame(frame);
    if (parsed != null && parsed.channelIndex != null) {
      if (_shouldDropSelfChannelMessage(parsed.senderName, parsed.pathBytes)) {
        return;
      }
      _lastChannelMsgRxTime = DateTime.now();
      final contentHash = _computeContentHash(
        parsed.channelIndex!,
        parsed.timestamp.millisecondsSinceEpoch ~/ 1000,
        '${parsed.senderName}: ${parsed.text}',
      );
      final message = parsed.copyWith(packetHash: contentHash);
      _updateContactLastMessageAtByName(
        message.senderName,
        message.timestamp,
        pathBytes: message.pathBytes,
      );
      final isNew = _addChannelMessage(message.channelIndex!, message);
      if (isNew && !message.isOutgoing) {
        unawaited(
          _translateIncomingChannelMessage(message.channelIndex!, message),
        );
      }
      _maybeIncrementChannelUnread(message, isNew: isNew);
      notifyListeners();
      if (isNew) {
        _maybeNotifyChannelMessage(message);
      }
      _handleQueuedMessageReceived();
    } else if (_isSyncingQueuedMessages) {
      _handleQueuedMessageReceived();
    }
  }

  void _handleLogRxData(Uint8List frame) {
    if (frame.length < 4) return;
    try {
      final reader = BufferReader(frame);
      reader.skipBytes(3); // Skip header

      final raw = reader.readRemainingBytes();
      final packet = _parseRawPacket(raw);
      if (packet == null || packet.payloadType != _payloadTypeGroupText) return;

      final payload = BufferReader(packet.payload);
      final channelHash = payload.readByte();
      final encrypted = Uint8List.fromList(payload.readRemainingBytes());

      // Use cached channels as fallback if live channels not yet loaded
      final channelsToSearch = _channels.isNotEmpty
          ? _channels
          : _cachedChannels;
      for (final channel in channelsToSearch) {
        if (channel.isEmpty) continue;
        final hash = _computeChannelHash(channel.psk);
        if (hash != channelHash) continue;
        try {
          final decryptedBytes = _decryptPayload(channel.psk, encrypted);
          if (decryptedBytes == null || decryptedBytes.length < 6) return;
          final decrypted = BufferReader(decryptedBytes);

          final timestampRaw = decrypted.readUInt32LE();
          final txtType = decrypted.readByte();
          if ((txtType >> 2) != 0) {
            return;
          }

          final text = decrypted.readCString();
          final parsed = _splitSenderText(text);
          final decodedText =
              Smaz.tryDecodePrefixed(parsed.text) ?? parsed.text;
          if (_shouldDropSelfChannelMessage(
            parsed.senderName,
            packet.pathBytes,
          )) {
            return;
          }

          final pktHash = _computePacketHash(
            packet.payloadType,
            packet.payload,
          );

          final message = ChannelMessage(
            senderKey: null,
            senderName: parsed.senderName,
            text: decodedText,
            timestamp: DateTime.fromMillisecondsSinceEpoch(timestampRaw * 1000),
            isOutgoing: false,
            status: ChannelMessageStatus.sent,
            pathLength: packet.isFlood ? packet.hopCount : 0,
            pathBytes: packet.pathBytes,
            channelIndex: channel.index,
            packetHash: pktHash,
          );

          _updateContactLastMessageAtByName(
            parsed.senderName,
            message.timestamp,
            pathBytes: message.pathBytes,
          );
          final isNew = _addChannelMessage(channel.index, message);
          if (isNew && !message.isOutgoing) {
            unawaited(_translateIncomingChannelMessage(channel.index, message));
          }
          _maybeIncrementChannelUnread(message, isNew: isNew);
          notifyListeners();
          if (isNew) {
            final label = channel.name.isEmpty
                ? 'Channel ${channel.index}'
                : channel.name;
            _maybeNotifyChannelMessage(message, channelName: label);
          }
          return;
        } catch (e) {
          appLogger.warn('Decryption failed for channel ${channel.index}: $e');
        }
      }
    } catch (e) {
      appLogger.warn('Error handling log RX data frame: $e');
    }
  }

  void _handleMessageSent(Uint8List frame) {
    // Frame format from C++:
    // [0] = RESP_CODE_SENT
    // [1] = is_flood (1 or 0)
    // [2-5] = expected_ack_hash (uint32)
    // [6-9] = estimated_timeout_ms (uint32)

    try {
      final reader = BufferReader(frame);
      reader.skipBytes(2); //Skip code and is_flood
      final ackHash = reader.readUInt32LE();
      final timeoutMs = reader.readUInt32LE();

      // Check if this is a CLI command ACK - if so, ignore it
      if (_lastSentWasCliCommand) {
        final ackHashHex = ackHashToHex(ackHash);
        debugPrint('Ignoring CLI command ACK (sent): $ackHashHex');
        _lastSentWasCliCommand = false;
        return;
      }

      if (_handleRepeaterCommandSent(ackHash, timeoutMs)) {
        return;
      }

      final retryService = _retryService;
      if (retryService != null &&
          retryService.updateMessageFromSent(ackHash, timeoutMs)) {
        return;
      }

      if (_markNextPendingChannelMessageSent()) {
        return;
      }
    } catch (e) {
      appLogger.warn('Error handling message sent frame: $e');
      // Fallback to old behavior
      for (var messages in _conversations.values) {
        for (int i = messages.length - 1; i >= 0; i--) {
          if (messages[i].isOutgoing &&
              messages[i].status == MessageStatus.pending) {
            messages[i] = messages[i].copyWith(status: MessageStatus.sent);
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  bool _markNextPendingChannelMessageSent() {
    while (_pendingChannelSentQueue.isNotEmpty) {
      final queuedMessageId = _pendingChannelSentQueue.removeAt(0);
      if (_isReactionSendQueueId(queuedMessageId)) {
        return true;
      }
      if (_markPendingChannelMessageSentById(queuedMessageId)) {
        return true;
      }
    }
    return false;
  }

  bool _markPendingChannelMessageSentById(String messageId) {
    for (final entry in _channelMessages.entries) {
      final channelMessages = entry.value;
      for (int i = channelMessages.length - 1; i >= 0; i--) {
        final message = channelMessages[i];
        if (message.messageId != messageId) {
          continue;
        }
        if (!message.isOutgoing ||
            message.status != ChannelMessageStatus.pending) {
          return false;
        }
        channelMessages[i] = message.copyWith(
          status: ChannelMessageStatus.sent,
        );
        _pendingChannelSentQueue.remove(messageId);
        unawaited(
          _channelMessageStore.saveChannelMessages(entry.key, channelMessages),
        );
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void _handleOk() {
    if (_pendingGenericAckQueue.isEmpty) {
      return;
    }

    final pendingAck = _pendingGenericAckQueue.removeAt(0);
    if (pendingAck.commandCode != cmdSendChannelTxtMsg ||
        pendingAck.channelSendQueueId == null) {
      return;
    }

    final queueId = pendingAck.channelSendQueueId!;
    _pendingChannelSentQueue.remove(queueId);
    if (_isReactionSendQueueId(queueId)) {
      return;
    }
    _markPendingChannelMessageSentById(queueId);
  }

  void _handleSendConfirmed(Uint8List frame) {
    // Frame format from C++:
    // [0] = PUSH_CODE_SEND_CONFIRMED
    // [1-4] = ack_hash (uint32)
    // [5-8] = trip_time_ms (uint32)

    try {
      final reader = BufferReader(frame);
      reader.skipBytes(1); // Skip code
      final ackHash = reader.readUInt32LE();
      final tripTimeMs = reader.readUInt32LE();

      // CLI command ACKs are already filtered in _handleMessageSent, so this should only see real messages

      if (_handleRepeaterCommandAck(ackHash, tripTimeMs)) {
        return;
      }

      // Handle ACK in retry service
      if (_retryService != null) {
        _retryService!.handleAckReceived(ackHash, tripTimeMs);
      }
    } catch (e) {
      appLogger.warn('Error handling send confirmed frame: $e');
      // Fallback to old behavior
      for (var messages in _conversations.values) {
        for (int i = messages.length - 1; i >= 0; i--) {
          if (messages[i].isOutgoing &&
              messages[i].status == MessageStatus.sent) {
            messages[i] = messages[i].copyWith(status: MessageStatus.delivered);
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  bool _handleRepeaterCommandSent(int ackHash, int timeoutMs) {
    final ackHashHex = ackHashToHex(ackHash);
    final entry = _pendingRepeaterAcks[ackHashHex];
    if (entry == null) return false;

    entry.timeout?.cancel();
    final effectiveTimeoutMs = timeoutMs > 0
        ? timeoutMs
        : calculateTimeout(
            pathLength: entry.pathLength,
            messageBytes: entry.messageBytes,
          );
    entry.timeout = Timer(Duration(milliseconds: effectiveTimeoutMs), () {
      _recordPathResult(entry.contactKeyHex, entry.selection, false, null);
      _pendingRepeaterAcks.remove(ackHashHex);
    });
    return true;
  }

  bool _handleRepeaterCommandAck(int ackHash, int tripTimeMs) {
    final ackHashHex = ackHashToHex(ackHash);
    final entry = _pendingRepeaterAcks.remove(ackHashHex);
    if (entry == null) return false;
    entry.timeout?.cancel();
    _recordPathResult(entry.contactKeyHex, entry.selection, true, tripTimeMs);
    return true;
  }

  void _handleChannelInfo(Uint8List frame) {
    final channel = Channel.fromFrame(frame);
    if (channel == null) return;

    debugPrint(
      '[ChannelSync] Received channel ${channel.index}: ${channel.isEmpty ? "empty" : channel.name}',
    );

    // Preserve unread count from cached channel
    final cachedChannel = _cachedChannels.cast<Channel?>().firstWhere(
      (c) => c?.index == channel.index,
      orElse: () => null,
    );
    if (cachedChannel != null) {
      channel.unreadCount = cachedChannel.unreadCount;
    }

    // If we're syncing and this is the channel we're waiting for
    if (_isSyncingChannels && _channelSyncInFlight) {
      if (channel.index == _nextChannelIndexToRequest) {
        // Expected channel arrived
        _channelSyncTimeout?.cancel();
        _channelSyncInFlight = false;
        _channelSyncRetries = 0; // Reset retry counter on success

        // Only add non-empty channels
        if (!channel.isEmpty) {
          _channels.add(channel);
        }

        // Move to next channel
        _nextChannelIndexToRequest++;
        if (PlatformInfo.isWeb &&
            _activeTransport == MeshCoreTransportType.bluetooth &&
            channel.index == 0 &&
            _pendingInitialContactsSync) {
          _pendingInitialContactsSync = false;
          unawaited(getContacts());
          return;
        }
        unawaited(_requestNextChannel());
        return;
      } else {
        // Received a channel but not the one we're waiting for
        // This can happen if device sends unsolicited updates
        debugPrint(
          '[ChannelSync] Received unexpected channel ${channel.index}, expected $_nextChannelIndexToRequest',
        );
        // Add it anyway but don't advance sync
        if (!channel.isEmpty &&
            !_channels.any((c) => c.index == channel.index)) {
          _channels.add(channel);
        }
        return;
      }
    }

    // Not syncing, or received unsolicited update - handle normally
    if (!channel.isEmpty) {
      // Update or add channel
      final existingIndex = _channels.indexWhere(
        (c) => c.index == channel.index,
      );
      if (existingIndex >= 0) {
        // Preserve unread count from existing channel
        channel.unreadCount = _channels[existingIndex].unreadCount;
        _channels[existingIndex] = channel;
      } else {
        _channels.add(channel);
      }
    }

    // Only notify if not in loading state
    if (!_isLoadingChannels) {
      _applyChannelOrder();
      notifyListeners();
    }
  }

  void _applyChannelOrder() {
    if (_channelOrder.isEmpty) {
      _channels.sort((a, b) => a.index.compareTo(b.index));
      return;
    }

    final orderIndex = <int, int>{};
    for (int i = 0; i < _channelOrder.length; i++) {
      orderIndex[_channelOrder[i]] = i;
    }

    _channels.sort((a, b) {
      final aPos = orderIndex[a.index];
      final bPos = orderIndex[b.index];
      if (aPos != null && bPos != null) return aPos.compareTo(bPos);
      if (aPos != null) return -1;
      if (bPos != null) return 1;
      return a.index.compareTo(b.index);
    });
  }

  Future<void> setChannelOrder(List<int> order) async {
    _channelOrder = List<int>.from(order);
    _applyChannelOrder();
    notifyListeners();
    await _channelOrderStore.saveChannelOrder(_channelOrder);
  }

  bool _shouldTrackUnreadForContactKey(String contactKeyHex) {
    final contact = _contacts.cast<Contact?>().firstWhere(
      (c) => c?.publicKeyHex == contactKeyHex,
      orElse: () => null,
    );
    if (contact == null) return true;
    return contact.type != advTypeRepeater;
  }

  Channel? _findChannelByIndex(int index) {
    return _channels.cast<Channel?>().firstWhere(
          (c) => c?.index == index,
          orElse: () => null,
        ) ??
        _cachedChannels.cast<Channel?>().firstWhere(
          (c) => c?.index == index,
          orElse: () => null,
        );
  }

  void _maybeIncrementChannelUnread(
    ChannelMessage message, {
    required bool isNew,
  }) {
    if (!isNew || message.isOutgoing) {
      _appDebugLogService?.info(
        'Skip unread increment: isNew=$isNew, isOutgoing=${message.isOutgoing}',
        tag: 'Unread',
      );
      return;
    }
    final channelIndex = message.channelIndex;
    if (channelIndex == null) {
      _appDebugLogService?.info(
        'Skip unread increment: channelIndex is null',
        tag: 'Unread',
      );
      return;
    }
    // Don't increment if user is viewing this channel
    if (_activeChannelIndex == channelIndex) {
      _appDebugLogService?.info(
        'Skip unread increment: channel $channelIndex is active',
        tag: 'Unread',
      );
      return;
    }

    final channel = _findChannelByIndex(channelIndex);
    if (channel != null) {
      channel.unreadCount++;
      _appDebugLogService?.info(
        'Channel ${channel.name.isNotEmpty ? channel.name : channelIndex} unread count incremented to ${channel.unreadCount}',
        tag: 'Unread',
      );
      unawaited(
        _channelStore.saveChannels(
          _channels.isNotEmpty ? _channels : _cachedChannels,
        ),
      );
    } else {
      _appDebugLogService?.info(
        'Channel $channelIndex not found in _channels (${_channels.length}) or _cachedChannels (${_cachedChannels.length})',
        tag: 'Unread',
      );
    }
  }

  void _maybeIncrementContactUnread(Message message) {
    if (message.isOutgoing || message.isCli) {
      _appDebugLogService?.info(
        'Skip contact unread increment: isOutgoing=${message.isOutgoing}, isCli=${message.isCli}',
        tag: 'Unread',
      );
      return;
    }
    final contactKey = message.senderKeyHex;
    if (!_shouldTrackUnreadForContactKey(contactKey)) {
      _appDebugLogService?.info(
        'Skip contact unread increment: should not track for $contactKey',
        tag: 'Unread',
      );
      return;
    }
    // Don't increment if user is viewing this contact
    if (_activeContactKey == contactKey) {
      _appDebugLogService?.info(
        'Skip contact unread increment: contact $contactKey is active',
        tag: 'Unread',
      );
      return;
    }

    final currentCount = _contactUnreadCount[contactKey] ?? 0;
    _contactUnreadCount[contactKey] = currentCount + 1;
    _appDebugLogService?.info(
      'Contact $contactKey unread count incremented to ${currentCount + 1}',
      tag: 'Unread',
    );
    _unreadStore.saveContactUnreadCount(
      Map<String, int>.from(_contactUnreadCount),
    );
  }

  void _addMessage(String pubKeyHex, Message message) {
    _conversations.putIfAbsent(pubKeyHex, () => []);
    final messages = _conversations[pubKeyHex]!;

    // Parse reaction info
    final reactionInfo = Message.parseReaction(message.text);
    if (reactionInfo != null) {
      // Check if we've already processed this exact reaction
      _processedContactReactions.putIfAbsent(pubKeyHex, () => {});
      final reactionIdentifier =
          '${reactionInfo.targetHash}_${reactionInfo.emoji}';

      final isDuplicate = _processedContactReactions[pubKeyHex]!.contains(
        reactionIdentifier,
      );

      if (!isDuplicate) {
        // New reaction - process it
        _processContactReaction(messages, reactionInfo, pubKeyHex);
        _messageStore.saveMessages(pubKeyHex, messages);

        // Mark as processed
        _processedContactReactions[pubKeyHex]!.add(reactionIdentifier);

        notifyListeners();
      }
      return; // Don't add reaction as a visible message
    }

    messages.add(message);
    _messageStore.saveMessages(pubKeyHex, messages);
    notifyListeners();
  }

  void _processContactReaction(
    List<Message> messages,
    ReactionInfo reactionInfo,
    String contactPubKeyHex,
  ) {
    final contact = _contacts.cast<Contact?>().firstWhere(
      (c) => c?.publicKeyHex == contactPubKeyHex,
      orElse: () => null,
    );
    final isRoomServer = contact?.type == advTypeRoom;

    ReactionHelper.applyReaction<Message>(
      messages: messages,
      reactionInfo: reactionInfo,
      // Incoming reactions in 1:1: match against outgoing messages only
      shouldSkip: (msg) => isRoomServer != true && !msg.isOutgoing,
      getTimestampSecs: (msg) => msg.timestamp.millisecondsSinceEpoch ~/ 1000,
      getSenderName: (msg) =>
          _resolveContactSenderName(msg, contact, isRoomServer == true),
      getMessageText: (msg) => msg.text,
      getReactions: (msg) => msg.reactions,
      updateMessage: (i, reactions) {
        messages[i] = messages[i].copyWith(reactions: reactions);
      },
    );
  }

  void _processOutgoingContactReaction(
    List<Message> messages,
    ReactionInfo reactionInfo,
    Contact contact,
  ) {
    final isRoomServer = contact.type == advTypeRoom;

    ReactionHelper.applyReaction<Message>(
      messages: messages,
      reactionInfo: reactionInfo,
      // Outgoing reactions in 1:1: match against incoming messages
      shouldSkip: (msg) => !isRoomServer && msg.isOutgoing,
      getTimestampSecs: (msg) => msg.timestamp.millisecondsSinceEpoch ~/ 1000,
      getSenderName: (msg) =>
          _resolveContactSenderName(msg, contact, isRoomServer),
      getMessageText: (msg) => msg.text,
      getReactions: (msg) => msg.reactions,
      updateMessage: (i, reactions) {
        messages[i] = messages[i].copyWith(reactions: reactions);
      },
    );
  }

  void _setReactionStatus(
    String pubKeyHex,
    ReactionInfo reactionInfo,
    MessageStatus status,
  ) {
    final messages = _conversations[pubKeyHex];
    if (messages == null) return;
    final contact = _contacts.cast<Contact?>().firstWhere(
      (c) => c?.publicKeyHex == pubKeyHex,
      orElse: () => null,
    );
    final isRoomServer = contact?.type == advTypeRoom;
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      final timestampSecs = msg.timestamp.millisecondsSinceEpoch ~/ 1000;
      final msgHash = ReactionHelper.computeReactionHash(
        timestampSecs,
        _resolveContactSenderName(msg, contact, isRoomServer == true),
        msg.text,
      );
      if (msgHash == reactionInfo.targetHash) {
        final statuses = Map<String, MessageStatus>.from(msg.reactionStatuses);
        statuses[reactionInfo.emoji] = status;
        messages[i] = msg.copyWith(reactionStatuses: statuses);
        break;
      }
    }
  }

  String? _resolveContactSenderName(
    Message msg,
    Contact? contact,
    bool isRoomServer,
  ) {
    if (!isRoomServer) return null;
    if (!msg.isOutgoing) {
      final senderContact = _contacts.cast<Contact?>().firstWhere(
        (c) =>
            c != null &&
            _matchesPrefix(c.publicKey, msg.fourByteRoomContactKey),
        orElse: () => null,
      );
      return senderContact?.name;
    }
    return selfName;
  }

  _RawPacket? _parseRawPacket(Uint8List raw) {
    try {
      final reader = BufferReader(raw);
      final header = reader.readByte();
      final routeType = header & _phRouteMask;
      final hasTransport =
          routeType == _routeTransportFlood ||
          routeType == _routeTransportDirect;
      if (hasTransport) {
        // Skip reserved bytes in transport header made up of two u16 fields
        reader.skipBytes(4);
      }
      final pathLenRaw = reader.readByte();
      final pathByteLen = _decodePathByteLen(pathLenRaw);
      final pathBytes = reader.readBytes(pathByteLen);
      final payload = reader.readBytes(reader.remaining);

      return _RawPacket(
        header: header,
        routeType: routeType,
        payloadType: (header >> _phTypeShift) & _phTypeMask,
        payloadVer: (header >> _phVerShift) & _phVerMask,
        pathLenRaw: pathLenRaw,
        pathBytes: pathBytes,
        payload: payload,
      );
    } catch (e) {
      appLogger.warn('Error parsing raw packet: $e');
      return null;
    }
  }

  int _computeChannelHash(Uint8List psk) {
    final digest = crypto.sha256.convert(psk).bytes;
    return digest[0];
  }

  /// Firmware-compatible packet hash: SHA256(payloadType + payload) -> first 8 bytes as hex.
  String _computePacketHash(int payloadType, Uint8List payload) {
    final input = Uint8List(1 + payload.length);
    input[0] = payloadType;
    input.setRange(1, input.length, payload);
    final digest = crypto.sha256.convert(input).bytes;
    return digest
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Content-based dedup hash for sync queue messages (no raw payload available).
  /// Prefixed with 'c:' to avoid collisions with packet hashes.
  String _computeContentHash(
    int channelIdx,
    int timestampSecs,
    String fullText,
  ) {
    final textBytes = utf8.encode(fullText);
    final input = Uint8List(5 + textBytes.length);
    input[0] = channelIdx;
    input[1] = timestampSecs & 0xFF;
    input[2] = (timestampSecs >> 8) & 0xFF;
    input[3] = (timestampSecs >> 16) & 0xFF;
    input[4] = (timestampSecs >> 24) & 0xFF;
    input.setRange(5, 5 + textBytes.length, textBytes);
    final digest = crypto.sha256.convert(input).bytes;
    return 'c:${digest.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  Uint8List? _decryptPayload(Uint8List psk, Uint8List encrypted) {
    if (encrypted.length <= _cipherMacSize) return null;
    final mac = encrypted.sublist(0, _cipherMacSize);
    final cipherText = encrypted.sublist(_cipherMacSize);

    final key32 = Uint8List(32);
    final copyLen = psk.length < 32 ? psk.length : 32;
    key32.setRange(0, copyLen, psk);

    final hmac = crypto.Hmac(crypto.sha256, key32).convert(cipherText).bytes;
    if (hmac[0] != mac[0] || hmac[1] != mac[1]) {
      return null;
    }

    if (cipherText.isEmpty || cipherText.length % 16 != 0) return null;
    final key16 = Uint8List(16);
    final keyLen = psk.length < 16 ? psk.length : 16;
    key16.setRange(0, keyLen, psk);

    final cipher = ECBBlockCipher(AESEngine());
    cipher.init(false, KeyParameter(key16));
    final out = Uint8List(cipherText.length);
    for (var i = 0; i < cipherText.length; i += 16) {
      cipher.processBlock(cipherText, i, out, i);
    }
    return out;
  }

  _ParsedText _splitSenderText(String text) {
    final colonIndex = text.indexOf(':');
    if (colonIndex > 0 && colonIndex < text.length - 1 && colonIndex < 50) {
      final potentialSender = text.substring(0, colonIndex);
      if (RegExp(r'[:\[\]]').hasMatch(potentialSender)) {
        return _ParsedText(senderName: 'Unknown', text: text);
      }
      final offset =
          (colonIndex + 1 < text.length && text[colonIndex + 1] == ' ')
          ? colonIndex + 2
          : colonIndex + 1;
      return _ParsedText(
        senderName: potentialSender,
        text: text.substring(offset),
      );
    }
    return _ParsedText(senderName: 'Unknown', text: text);
  }

  bool _addChannelMessage(int channelIndex, ChannelMessage message) {
    _channelMessages.putIfAbsent(channelIndex, () => []);
    final messages = _channelMessages[channelIndex]!;

    // Parse reaction info
    final reactionInfo = ChannelMessage.parseReaction(message.text);
    if (reactionInfo != null) {
      // Check if we've already processed this exact reaction
      _processedChannelReactions.putIfAbsent(channelIndex, () => {});
      final reactionIdentifier =
          '${reactionInfo.targetHash}_${reactionInfo.emoji}';

      final isDuplicate = _processedChannelReactions[channelIndex]!.contains(
        reactionIdentifier,
      );

      if (!isDuplicate) {
        // New reaction - process it
        _processReaction(messages, reactionInfo);
        // Save updated messages
        _channelMessageStore.saveChannelMessages(channelIndex, messages);

        // Mark as processed
        _processedChannelReactions[channelIndex]!.add(reactionIdentifier);
      }
      return false; // Don't add reaction as a visible message
    }

    // Parse reply info from message text
    final replyInfo = ChannelMessage.parseReplyMention(message.text);
    ChannelMessage processedMessage = message;

    if (replyInfo != null) {
      // Find original message by sender name (most recent match)
      final originalMessage = _findMessageBySender(
        messages,
        replyInfo.mentionedNode,
      );

      if (originalMessage != null) {
        // Create new message with reply metadata
        processedMessage = ChannelMessage(
          senderKey: message.senderKey,
          senderName: message.senderName,
          text: replyInfo.actualMessage,
          originalText: message.originalText,
          translatedText: message.translatedText,
          translatedLanguageCode: message.translatedLanguageCode,
          translationStatus: message.translationStatus,
          translationModelId: message.translationModelId,
          timestamp: message.timestamp,
          isOutgoing: message.isOutgoing,
          status: message.status,
          repeats: message.repeats,
          repeatCount: message.repeatCount,
          pathLength: message.pathLength,
          pathBytes: message.pathBytes,
          pathVariants: message.pathVariants,
          channelIndex: message.channelIndex,
          messageId: message.messageId,
          replyToMessageId: originalMessage.messageId,
          replyToSenderName: originalMessage.senderName,
          replyToText: originalMessage.text,
        );
      }
    }

    final existingIndex = _findChannelRepeatIndex(messages, processedMessage);
    var isNew = true;
    if (existingIndex >= 0) {
      isNew = false;
      final existing = messages[existingIndex];
      final mergedPathBytes = _selectPreferredPathBytes(
        existing.pathBytes,
        processedMessage.pathBytes,
      );
      final mergedPathVariants = _mergePathVariants(
        existing.pathVariants,
        processedMessage.pathVariants,
      );
      final mergedPathLength = _mergePathLength(
        existing.pathLength,
        processedMessage.pathLength,
        mergedPathBytes.length,
      );
      final newRepeatCount = existing.repeatCount + 1;
      final promotedFromPending =
          newRepeatCount == 1 &&
          existing.status == ChannelMessageStatus.pending;
      messages[existingIndex] = existing.copyWith(
        repeatCount: newRepeatCount,
        pathLength: mergedPathLength,
        pathBytes: mergedPathBytes,
        pathVariants: mergedPathVariants,
        packetHash: existing.packetHash ?? processedMessage.packetHash,
        // Mark as sent when first repeat is heard
        status: promotedFromPending
            ? ChannelMessageStatus.sent
            : existing.status,
      );
      if (promotedFromPending) {
        _pendingChannelSentQueue.remove(existing.messageId);
      }
    } else {
      messages.add(processedMessage);
    }

    // Save to persistent storage
    _channelMessageStore.saveChannelMessages(channelIndex, messages);
    return isNew;
  }

  ChannelMessage? _findMessageBySender(
    List<ChannelMessage> messages,
    String mentionedNode,
  ) {
    // Search backwards for most recent message from this sender
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].senderName == mentionedNode && !messages[i].isOutgoing) {
        return messages[i];
      }
    }
    return null;
  }

  void _processReaction(
    List<ChannelMessage> messages,
    ReactionInfo reactionInfo,
  ) {
    ReactionHelper.applyReaction<ChannelMessage>(
      messages: messages,
      reactionInfo: reactionInfo,
      shouldSkip: (_) => false,
      getTimestampSecs: (msg) => msg.timestamp.millisecondsSinceEpoch ~/ 1000,
      getSenderName: (msg) => msg.senderName,
      getMessageText: (msg) => msg.text,
      getReactions: (msg) => msg.reactions,
      updateMessage: (i, reactions) {
        messages[i] = messages[i].copyWith(reactions: reactions);
        notifyListeners();
      },
    );
  }

  int _findChannelRepeatIndex(
    List<ChannelMessage> messages,
    ChannelMessage incoming,
  ) {
    // First pass: match by packet hash (exact dedup)
    final incomingHash = incoming.packetHash;
    if (incomingHash != null) {
      for (int i = messages.length - 1; i >= 0; i--) {
        final existingHash = messages[i].packetHash;
        if (existingHash != null && existingHash == incomingHash) {
          return i;
        }
      }
    }
    // Second pass: heuristic fallback (outgoing echo, old messages without hash)
    for (int i = messages.length - 1; i >= 0; i--) {
      if (_isChannelRepeat(messages[i], incoming)) {
        return i;
      }
    }
    return -1;
  }

  bool _isChannelRepeat(ChannelMessage existing, ChannelMessage incoming) {
    if (existing.text != incoming.text) return false;

    final diffMs =
        (existing.timestamp.millisecondsSinceEpoch -
                incoming.timestamp.millisecondsSinceEpoch)
            .abs();
    if (diffMs > 30000) return false;

    if (existing.senderName == incoming.senderName) return true;

    if (existing.isOutgoing && !incoming.isOutgoing) {
      final selfName = _selfName ?? 'Me';
      if (incoming.senderName == selfName || existing.senderName == selfName) {
        return true;
      }
    }

    return false;
  }

  bool _shouldDropSelfChannelMessage(String senderName, Uint8List pathBytes) {
    final trimmed = senderName.trim();
    if (trimmed.isEmpty) return false;

    final selfName = _selfName?.trim();
    if (selfName == null || selfName.isEmpty) return false;

    // If sender name doesn't match, keep the message
    if (trimmed != selfName) return false;

    // Name matches - this is from self
    // Drop only if pathBytes is empty (direct broadcast)
    // Keep if pathBytes has data (repeated through another node)
    return pathBytes.isEmpty;
  }

  Uint8List _selectPreferredPathBytes(Uint8List existing, Uint8List incoming) {
    if (incoming.isEmpty) return existing;
    if (existing.isEmpty) return incoming;
    if (incoming.length > existing.length) return incoming;
    return existing;
  }

  int? _mergePathLength(int? existing, int? incoming, int observedLength) {
    if (existing == null) {
      if (incoming == null) return observedLength > 0 ? observedLength : null;
      return incoming >= observedLength ? incoming : observedLength;
    }
    if (incoming == null) {
      return existing >= observedLength ? existing : observedLength;
    }
    final merged = existing >= incoming ? existing : incoming;
    return merged >= observedLength ? merged : observedLength;
  }

  List<Uint8List> _mergePathVariants(
    List<Uint8List> existing,
    List<Uint8List> incoming,
  ) {
    if (incoming.isEmpty) return existing;
    if (existing.isEmpty) return incoming;

    final merged = <Uint8List>[...existing];
    for (final candidate in incoming) {
      var already = false;
      for (final current in merged) {
        if (_pathsEqual(current, candidate)) {
          already = true;
          break;
        }
      }
      if (!already && candidate.isNotEmpty) {
        merged.add(candidate);
      }
    }
    return merged;
  }

  bool _pathsEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _handleDisconnection() {
    _stopBatteryPolling();
    _stopRadioStatsPolling();
    _latestRadioStats = null;
    radioStatsNotifier.value = null;
    _prevTotalAirSecs = 0;
    _airtimeBumpStopwatch?.stop();
    _airtimeBumpStopwatch = null;

    for (final entry in _pendingRepeaterAcks.values) {
      entry.timeout?.cancel();
    }
    _pendingRepeaterAcks.clear();

    _notifySubscription?.cancel();
    _notifySubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;

    _device = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    // Preserve deviceId and displayName for UI display during reconnection
    // They're only cleared on manual disconnect via disconnect() method
    _hasReceivedDeviceInfo = false;
    _pendingInitialChannelSync = false;
    _pendingInitialContactsSync = false;
    _maxContacts = _defaultMaxContacts;
    _maxChannels = _defaultMaxChannels;
    _isSyncingQueuedMessages = false;
    _queuedMessageSyncInFlight = false;
    _isSyncingChannels = false;
    _channelSyncInFlight = false;
    _pendingChannelSentQueue.clear();
    _pendingGenericAckQueue.clear();
    _reactionSendQueueSequence = 0;

    _setState(MeshCoreConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _trackPendingGenericAck(
    Uint8List data, {
    String? channelSendQueueId,
    required bool expectsGenericAck,
  }) {
    if (!expectsGenericAck || data.isEmpty) return;
    _pendingGenericAckQueue.add(
      _PendingCommandAck(
        commandCode: data[0],
        channelSendQueueId: channelSendQueueId,
      ),
    );
  }

  String _nextReactionSendQueueId() {
    _reactionSendQueueSequence++;
    return '$_reactionSendQueuePrefix$_reactionSendQueueSequence';
  }

  bool _isReactionSendQueueId(String queueId) {
    return queueId.startsWith(_reactionSendQueuePrefix);
  }

  Map<String, String> _parseKeyValueString(String input) {
    final result = <String, String>{};

    // Split on commas first – empty entries are ignored.
    for (final pair in input.split(',')) {
      final trimmedPair = pair.trim();
      if (trimmedPair.isEmpty) continue;

      // Each pair must contain exactly one ':'.
      final separatorIndex = trimmedPair.indexOf(':');
      if (separatorIndex == -1) continue; // malformed, skip

      final key = trimmedPair.substring(0, separatorIndex).trim();
      final value = trimmedPair.substring(separatorIndex + 1).trim();

      if (key.isNotEmpty) {
        result[key] = value;
      }
    }

    return result;
  }

  void _handleCustomVars(Uint8List frame) {
    final buf = BufferReader(frame.sublist(1));
    try {
      _currentCustomVars = _parseKeyValueString(buf.readCString());
    } catch (e) {
      appLogger.warn('Malformed custom vars frame: $e', tag: 'Connector');
    }
  }

  void _setState(MeshCoreConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void markNotifyDirty() {
    if (_notifyListenersDirty && _notifyListenersTimer != null) {
      return;
    }

    _notifyListenersDirty = true;
    _notifyListenersTimer ??= Timer(
      _notifyListenersDebounce,
      _flushBatchedNotify,
    );
  }

  void _flushBatchedNotify() {
    _notifyListenersTimer = null;
    if (!_notifyListenersDirty) {
      return;
    }

    _notifyListenersDirty = false;
    super.notifyListeners();

    if (_notifyListenersDirty && _notifyListenersTimer == null) {
      _notifyListenersTimer = Timer(
        _notifyListenersDebounce,
        _flushBatchedNotify,
      );
    }
  }

  @override
  void notifyListeners() {
    markNotifyDirty();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _usbFrameSubscription?.cancel();
    _notifySubscription?.cancel();
    _notifyListenersTimer?.cancel();
    _reconnectTimer?.cancel();
    _batteryPollTimer?.cancel();
    _radioStatsPollTimer?.cancel();
    radioStatsNotifier.dispose();
    _receivedFramesController.close();
    _usbManager.dispose();
    _tcpConnector.dispose();

    // Flush pending unread writes before disposal
    _unreadStore.flush();

    super.dispose();
  }

  void _handleRxData(Uint8List frame) {
    final packet = BufferReader(frame);
    try {
      packet.skipBytes(1); // Skip frame type byte
      final snr = packet.readInt8() / 4.0;
      packet.skipBytes(1); // Skip RSSI byte
      //final rssi = packet.readByte();
      final header = packet.readByte();
      final routeType = header & 0x03;
      final payloadType = (header >> 2) & 0x0F;
      if (routeType == _routeTransportFlood ||
          routeType == _routeTransportDirect) {
        packet.skipBytes(4); // Skip transport-specific bytes
      }
      //final payloadVer = (header >> 6) & 0x03;
      final pathLenRaw = packet.readByte();
      final pathByteLen = _decodePathByteLen(pathLenRaw);
      final pathBytes = packet.readBytes(pathByteLen);
      final payload = packet.readBytes(packet.remaining);

      final rawPacket = frame.sublist(3);
      switch (payloadType) {
        case payloadTypeADVERT:
          _handlePayloadAdvertReceived(
            rawPacket,
            payload,
            pathBytes,
            routeType,
            snr,
          );
          break;
        default:
      }
    } catch (e) {
      appLogger.warn('Malformed RX frame: $e', tag: 'Connector');
      return;
    }
  }

  void importContact(Uint8List frame) {
    final packet = BufferReader(frame);
    int payloadType = 0;
    Uint8List pathBytes = Uint8List(0);
    try {
      packet.skipBytes(1); // Skip frame type byte
      packet.skipBytes(1); // Skip SNR byte
      packet.skipBytes(1); // Skip RSSI byte
      final header = packet.readByte();
      final routeType = header & 0x03;
      payloadType = (header >> 2) & 0x0F;
      if (routeType == _routeTransportFlood ||
          routeType == _routeTransportDirect) {
        packet.skipBytes(4); // Skip transport-specific bytes
      }
      //final payloadVer = (header >> 6) & 0x03;
      final pathLenRaw = packet.readByte();
      final pathByteLen = _decodePathByteLen(pathLenRaw);
      pathBytes = packet.readBytes(pathByteLen);
    } catch (e) {
      appLogger.warn('Malformed RX frame: $e', tag: 'Connector');
      return;
    }
    double? latitude;
    double? longitude;
    String name = '';
    Uint8List publicKey = Uint8List(0);
    int type = 0;
    int timestamp = 0;
    bool hasLocation = false;
    bool hasName = false;
    if (payloadType != payloadTypeADVERT) {
      appLogger.warn('Unexpected payload type: $payloadType', tag: 'Connector');
      return;
    }
    try {
      publicKey = packet.readBytes(32);
      timestamp = packet.readInt32LE();
      //TODO add signature verification
      packet.skipBytes(64); // Skip signature for now
      final flags = packet.readByte();
      type = flags & 0x0F;
      hasLocation = (flags & 0x10) != 0;
      // For future use:
      //final hasFeature1 = (flags & 0x20) != 0;
      //final hasFeature2 = (flags & 0x40) != 0;
      hasName = (flags & 0x80) != 0;
      if (hasLocation && packet.remaining >= 8) {
        latitude = packet.readInt32LE() / 1e6;
        longitude = packet.readInt32LE() / 1e6;
      }
      if (hasName && packet.remaining > 0) {
        name = packet.readCString();
      }
    } catch (e) {
      appLogger.warn('Malformed advert frame: $e', tag: 'Connector');
      return;
    }

    importDiscoveredContact(
      Contact(
        rawPacket: frame,
        publicKey: publicKey,
        name: name,
        type: type,
        pathLength: pathBytes.isEmpty ? -1 : pathBytes.length,
        path: Uint8List.fromList(
          pathBytes.reversed.toList(),
        ), // Store path in reverse for easier use in outgoing messages
        latitude: latitude,
        longitude: longitude,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
      ),
    );
  }

  bool hasValidLocation(double? latitude, double? longitude) {
    const double epsilon = 1e-6;
    final lat = latitude ?? 0.0;
    final lon = longitude ?? 0.0;
    return (lat.abs() > epsilon || lon.abs() > epsilon) &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lon >= -180.0 &&
        lon <= 180.0;
  }

  void _handlePayloadAdvertReceived(
    Uint8List rawPacket,
    Uint8List payload,
    Uint8List path,
    int routeType,
    double snr,
  ) {
    final advert = BufferReader(payload);
    double? latitude;
    double? longitude;
    String name = '';
    String contactKeyHex = '';
    Uint8List publicKey = Uint8List(0);
    int type = 0;
    int timestamp = 0;
    bool hasLocation = false;
    bool hasName = false;
    try {
      publicKey = advert.readBytes(32);
      contactKeyHex = publicKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      timestamp = advert.readInt32LE();
      //TODO add signature verification
      advert.skipBytes(64); // Skip signature for now
      final flags = advert.readByte();
      type = flags & 0x0F;
      hasLocation = (flags & 0x10) != 0;
      // For future use:
      //final hasFeature1 = (flags & 0x20) != 0;
      //final hasFeature2 = (flags & 0x40) != 0;
      hasName = (flags & 0x80) != 0;
      if (hasLocation && advert.remaining >= 8) {
        latitude = advert.readInt32LE() / 1e6;
        longitude = advert.readInt32LE() / 1e6;
      }
      // Validate location values if present
      hasLocation = hasValidLocation(latitude, longitude);

      if (hasName && advert.remaining > 0) {
        name = advert.readCString();
      }
    } catch (e) {
      appLogger.warn('Malformed advert frame: $e', tag: 'Connector');
      return;
    }

    //We ignore our own adverts
    if (listEquals(publicKey, _selfPublicKey)) {
      return;
    }

    // Check if this is a new contact
    final isNewContact = !_knownContactKeys.contains(contactKeyHex);

    if (isNewContact) {
      final newContact = Contact(
        rawPacket: rawPacket,
        publicKey: publicKey,
        name: name,
        type: type,
        pathLength: path.length,
        path: Uint8List.fromList(
          path.reversed.toList(),
        ), // Store path in reverse for easier use in outgoing messages
        latitude: latitude,
        longitude: longitude,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
      );
      if ((_autoAddUsers && type == advTypeChat) ||
          (_autoAddRepeaters && type == advTypeRepeater) ||
          (_autoAddRoomServers && type == advTypeRoom) ||
          (_autoAddSensors && type == advTypeSensor)) {
        _handleContactAdvert(newContact);
        _handleDiscovery(
          newContact,
          rawPacket,
          noNotify: true,
          addActive: true,
        );
      } else {
        _handleDiscovery(newContact, rawPacket);
      }
      _updateDirectRepeater(newContact, snr, path);
      return;
    }

    final existingIndex = _contacts.indexWhere(
      (c) => c.publicKeyHex == contactKeyHex,
    );

    if (existingIndex >= 0) {
      final existing = _contacts[existingIndex];
      final mergedLastMessageAt = existing.lastMessageAt.isAfter(DateTime.now())
          ? DateTime.now()
          : existing.lastMessageAt;

      appLogger.info(
        'Refreshing contact ${existing.name}: devicePath=${existing.pathLength}, existingOverride=${existing.pathOverride}',
        tag: 'Connector',
      );

      // CRITICAL: Preserve user's path override when contact is refreshed from device
      _contacts[existingIndex] = existing.copyWith(
        latitude: hasLocation ? latitude : existing.latitude,
        longitude: hasLocation ? longitude : existing.longitude,
        name: hasName ? name : existing.name,
        path: Uint8List.fromList(path.reversed.toList()),
        pathLength: path.length,
        lastMessageAt: mergedLastMessageAt,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
        pathOverride: existing.pathOverride, // Preserve user's path choice
        pathOverrideBytes: existing.pathOverrideBytes,
      );

      // Add path to history if we have a valid path
      if (_pathHistoryService != null &&
          _contacts[existingIndex].pathLength >= 0) {
        _pathHistoryService!.handlePathUpdated(_contacts[existingIndex]);
      }

      _updateDirectRepeater(_contacts[existingIndex], snr, path);

      appLogger.info(
        'After merge: pathOverride=${_contacts[existingIndex].pathOverride}, devicePath=${_contacts[existingIndex].pathLength}',
        tag: 'Connector',
      );
    }
  }

  void _updateDirectRepeater(Contact contact, double snr, Uint8List path) {
    final pubkeyFirstByte = path.isNotEmpty
        ? path.last
        : contact.publicKey.first;

    _directRepeaters.removeWhere((r) => r.isStale());

    //We can use adverts from chat and sensor nodes, but only if the advert has a path to get the last hop.
    if ((contact.type == advTypeChat || contact.type == advTypeSensor) &&
        path.isEmpty) {
      notifyListeners();
      return;
    }

    final isTracked = _directRepeaters.where(
      (r) => r.pubkeyFirstByte == pubkeyFirstByte,
    );

    final sortedRepeaters = List<DirectRepeater>.from(_directRepeaters)
      ..sort((a, b) => b.snr.compareTo(a.snr));
    final weakestRepeater = sortedRepeaters.isNotEmpty
        ? sortedRepeaters.last
        : null;

    if (_directRepeaters.length >= 5 &&
        weakestRepeater != null &&
        isTracked.isEmpty) {
      _directRepeaters.remove(weakestRepeater);
    }

    if (isTracked.isNotEmpty) {
      final repeater = isTracked.first;
      repeater.update(snr);
    } else if (_directRepeaters.length < 5) {
      _directRepeaters.add(
        DirectRepeater(pubkeyFirstByte: pubkeyFirstByte, snr: snr),
      );
    }
    notifyListeners();
  }

  void _handleAutoAddConfig(Uint8List frame) {
    final reader = BufferReader(frame);
    try {
      reader.skipBytes(1); // Skip the response code byte
      final flags = reader.readByte();
      _autoAddUsers = (flags & autoAddChatFlag) != 0;
      _autoAddRepeaters = (flags & autoAddRepeaterFlag) != 0;
      _autoAddRoomServers = (flags & autoAddRoomServerFlag) != 0;
      _autoAddSensors = (flags & autoAddSensorFlag) != 0;
      _overwriteOldest = (flags & autoAddOverwriteOldestFlag) != 0;
    } catch (e) {
      appLogger.error('Failed to parse auto-add config: $e', tag: 'Connector');
    }
  }

  void _handleDiscovery(
    Contact contact,
    Uint8List rawPacket, {
    bool noNotify = false,
    bool addActive = false,
  }) {
    appLogger.info('Discovered new contact: ${contact.name}', tag: 'Connector');

    final existingIndex = _discoveredContacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );

    // Update existing contact
    if (existingIndex >= 0) {
      _discoveredContacts[existingIndex] = _discoveredContacts[existingIndex]
          .copyWith(
            rawPacket: rawPacket,
            name: contact.name,
            type: contact.type,
            pathLength: contact.pathLength,
            path: contact.path,
            latitude: contact.latitude,
            longitude: contact.longitude,
            lastSeen: contact.lastSeen,
            flags: 0,
            isActive: addActive,
          );
      notifyListeners();
      unawaited(_persistDiscoveredContacts());
      return;
    }

    final disContact = Contact(
      rawPacket: rawPacket,
      publicKey: contact.publicKey,
      name: contact.name,
      type: contact.type,
      pathLength: contact.pathLength,
      path: contact.path,
      latitude: contact.latitude,
      longitude: contact.longitude,
      lastSeen: contact.lastSeen,
      lastMessageAt: contact.lastMessageAt,
      isActive: addActive,
      flags: 0,
    );
    _discoveredContacts.add(disContact);

    unawaited(_persistDiscoveredContacts());

    // Show notification for new contact (advertisement)
    if (_appSettingsService != null && !noNotify) {
      final settings = _appSettingsService!.settings;
      if (settings.notificationsEnabled && settings.notifyOnNewAdvert) {
        _notificationService.showAdvertNotification(
          contactName: contact.name,
          contactType: contact.typeLabel,
          contactId: contact.publicKeyHex,
        );
      }
    }
  }

  void removeAllDiscoveredContacts() {
    _discoveredContacts.clear();
    unawaited(_persistDiscoveredContacts());
    notifyListeners();
  }

  void clearMessagesForContact(Contact contact) {
    final contactKeyHex = contact.publicKeyHex;
    final messages = _conversations[contactKeyHex];
    if (messages == null) return;
    messages.clear();
    unawaited(_messageStore.saveMessages(contactKeyHex, messages));
    markContactRead(contactKeyHex);
    notifyListeners();
  }

  void clearMessagesForChannel(int channelIndex) {
    final messages = _channelMessages[channelIndex];
    if (messages == null) return;
    messages.clear();
    unawaited(_channelMessageStore.saveChannelMessages(channelIndex, messages));
    markChannelRead(channelIndex);
    notifyListeners();
  }

  void deleteAllPaths() {
    _pathHistoryService?.clearAllHistories();
  }
}

const int _phRouteMask = 0x03;
const int _phTypeShift = 2;
const int _phTypeMask = 0x0F;
const int _phVerShift = 6;
const int _phVerMask = 0x03;

const int _routeTransportFlood = 0x00;
const int _routeFlood = 0x01;
const int _routeTransportDirect = 0x03;

const int _payloadTypeGroupText = 0x05;
const int _cipherMacSize = 2;

/// Decodes the firmware's encoded path_len byte into actual byte length.
/// Bits 0-5: hash count (0-63), Bits 6-7: hash size code (0=1byte, 1=2bytes, 2=3bytes).
int _decodePathByteLen(int pathLenRaw) {
  final hashCount = pathLenRaw & 63;
  final hashSize = ((pathLenRaw >> 6) & 0x03) + 1;
  return hashCount * hashSize;
}

class _RawPacket {
  final int header;
  final int routeType;
  final int payloadType;
  final int payloadVer;
  final int pathLenRaw;
  final Uint8List pathBytes;
  final Uint8List payload;

  _RawPacket({
    required this.header,
    required this.routeType,
    required this.payloadType,
    required this.payloadVer,
    required this.pathLenRaw,
    required this.pathBytes,
    required this.payload,
  });

  bool get isFlood =>
      routeType == _routeFlood || routeType == _routeTransportFlood;

  int get hopCount => pathLenRaw & 63;
}

class _ParsedText {
  final String senderName;
  final String text;

  _ParsedText({required this.senderName, required this.text});
}

class _RepeaterAckContext {
  final String contactKeyHex;
  final PathSelection selection;
  final int pathLength;
  final int messageBytes;
  Timer? timeout;

  _RepeaterAckContext({
    required this.contactKeyHex,
    required this.selection,
    required this.pathLength,
    required this.messageBytes,
  });
}

class _PendingCommandAck {
  final int commandCode;
  final String? channelSendQueueId;

  _PendingCommandAck({required this.commandCode, this.channelSendQueueId});
}
