import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/channel.dart';
import '../models/channel_message.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/path_selection.dart';
import '../helpers/reaction_helper.dart';
import '../helpers/smaz.dart';
import '../services/app_debug_log_service.dart';
import '../services/ble_debug_log_service.dart';
import '../services/message_retry_service.dart';
import '../services/path_history_service.dart';
import '../services/app_settings_service.dart';
import '../services/background_service.dart';
import '../services/notification_service.dart';
import '../storage/channel_message_store.dart';
import '../storage/channel_order_store.dart';
import '../storage/channel_settings_store.dart';
import '../storage/contact_settings_store.dart';
import '../storage/contact_store.dart';
import '../storage/message_store.dart';
import '../storage/unread_store.dart';
import '../utils/app_logger.dart';
import 'meshcore_protocol.dart';

class MeshCoreUuids {
  static const String service = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String rxCharacteristic = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  static const String txCharacteristic = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
}

enum MeshCoreConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
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

  final List<ScanResult> _scanResults = [];
  final List<Contact> _contacts = [];
  final List<Channel> _channels = [];
  final Map<String, List<Message>> _conversations = {};
  final Map<int, List<ChannelMessage>> _channelMessages = {};
  final Set<String> _loadedConversationKeys = {};
  final Map<int, Set<String>> _processedChannelReactions = {}; // channelIndex -> Set of "reactionKey_emoji"
  final Map<String, Set<String>> _processedContactReactions = {}; // contactPubKeyHex -> Set of "reactionKey_emoji"

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  Timer? _selfInfoRetryTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

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
  int? _batteryMillivolts;
  double? _selfLatitude;
  double? _selfLongitude;
  bool _isLoadingContacts = false;
  bool _isLoadingChannels = false;
  bool _batteryRequested = false;
  bool _awaitingSelfInfo = false;
  bool _preserveContactsOnRefresh = false;
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
  final UnreadStore _unreadStore = UnreadStore();
  final Map<int, bool> _channelSmazEnabled = {};
  bool _lastSentWasCliCommand = false; // Track if last sent message was a CLI command
  final Map<String, bool> _contactSmazEnabled = {};
  final Set<String> _knownContactKeys = {};
  final Map<String, int> _contactLastReadMs = {};
  final Map<int, int> _channelLastReadMs = {};
  final Map<String, _RepeaterAckContext> _pendingRepeaterAcks = {};
  String? _activeContactKey;
  int? _activeChannelIndex;
  List<int> _channelOrder = [];

  // Getters
  MeshCoreConnectionState get state => _state;
  BluetoothDevice? get device => _device;
  String? get deviceId => _deviceId;
  String get deviceIdLabel => _deviceId ?? 'Unknown';

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
  List<Channel> get channels => List.unmodifiable(_channels);
  bool get isConnected => _state == MeshCoreConnectionState.connected;
  bool get isLoadingContacts => _isLoadingContacts;
  bool get isLoadingChannels => _isLoadingChannels;
  Stream<Uint8List> get receivedFrames => _receivedFramesController.stream;
  Uint8List? get selfPublicKey => _selfPublicKey;
  String? get selfName => _selfName;
  double? get selfLatitude => _selfLatitude;
  double? get selfLongitude => _selfLongitude;
  int? get currentTxPower => _currentTxPower;
  int? get maxTxPower => _maxTxPower;
  int? get currentFreqHz => _currentFreqHz;
  int? get currentBwHz => _currentBwHz;
  int? get currentSf => _currentSf;
  int? get currentCr => _currentCr;
  int? get batteryMillivolts => _batteryMillivolts;
  int get maxContacts => _maxContacts;
  int get maxChannels => _maxChannels;
  bool get isSyncingQueuedMessages => _isSyncingQueuedMessages;
  bool get isSyncingChannels => _isSyncingChannels;
  int get channelSyncProgress => _isSyncingChannels && _totalChannelsToRequest > 0
      ? ((_nextChannelIndexToRequest / _totalChannelsToRequest) * 100).round()
      : 0;
  int? get batteryPercent => _batteryMillivolts == null
      ? null
      : _estimateBatteryPercent(
          _batteryMillivolts!,
          _batteryChemistryForDevice(),
        );

  String _batteryChemistryForDevice() {
    final deviceId = _device?.remoteId.toString();
    if (deviceId == null || _appSettingsService == null) return 'nmc';
    return _appSettingsService!.batteryChemistryForDevice(deviceId);
  }

  int _estimateBatteryPercent(int millivolts, String chemistry) {
    final range = _batteryVoltageRange(chemistry);
    final minMv = range.$1;
    final maxMv = range.$2;
    if (millivolts <= minMv) return 0;
    if (millivolts >= maxMv) return 100;
    return (((millivolts - minMv) * 100) / (maxMv - minMv)).round();
  }

  (int, int) _batteryVoltageRange(String chemistry) {
    switch (chemistry) {
      case 'lifepo4':
        return (2600, 3650);
      case 'lipo':
        return (3000, 4200);
      case 'nmc':
      default:
        return (3000, 4200);
    }
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

      _conversations[contactKeyHex] = windowedMessages;
      notifyListeners();
    }
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
    if (!_shouldTrackUnreadForContactKey(contactKeyHex)) return 0;
    final messages = _conversations[contactKeyHex];
    if (messages == null || messages.isEmpty) return 0;
    final lastReadMs = _contactLastReadMs[contactKeyHex] ?? 0;
    var count = 0;
    for (final message in messages) {
      if (message.isOutgoing || message.isCli) continue;
      if (message.timestamp.millisecondsSinceEpoch > lastReadMs) {
        count++;
      }
    }
    return count;
  }

  int getUnreadCountForChannel(Channel channel) {
    return getUnreadCountForChannelIndex(channel.index);
  }

  int getUnreadCountForChannelIndex(int channelIndex) {
    final messages = _channelMessages[channelIndex];
    if (messages == null || messages.isEmpty) return 0;
    final lastReadMs = _channelLastReadMs[channelIndex] ?? 0;
    var count = 0;
    for (final message in messages) {
      if (message.isOutgoing) continue;
      if (message.timestamp.millisecondsSinceEpoch > lastReadMs) {
        count++;
      }
    }
    return count;
  }

  int getTotalUnreadCount() {
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
    _contactLastReadMs
      ..clear()
      ..addAll(await _unreadStore.loadContactLastRead());
    _channelLastReadMs
      ..clear()
      ..addAll(await _unreadStore.loadChannelLastRead());
    notifyListeners();
  }

  void setActiveContact(String? contactKeyHex) {
    if (contactKeyHex != null && !_shouldTrackUnreadForContactKey(contactKeyHex)) {
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
    final markMs = _calculateReadTimestampMs(
      _conversations[contactKeyHex]?.map((m) => m.timestamp),
    );
    _setContactLastReadMs(contactKeyHex, markMs);
  }

  void markChannelRead(int channelIndex) {
    final markMs = _calculateReadTimestampMs(
      _channelMessages[channelIndex]?.map((m) => m.timestamp),
    );
    _setChannelLastReadMs(channelIndex, markMs);
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
    final allMessages = await _channelMessageStore.loadChannelMessages(channelIndex);
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
    final allMessages = await _channelMessageStore.loadChannelMessages(channelIndex);
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
    BleDebugLogService? bleDebugLogService,
    AppDebugLogService? appDebugLogService,
    BackgroundService? backgroundService,
  }) {
    _retryService = retryService;
    _pathHistoryService = pathHistoryService;
    _appSettingsService = appSettingsService;
    _bleDebugLogService = bleDebugLogService;
    _appDebugLogService = appDebugLogService;
    _backgroundService = backgroundService;

    // Initialize notification service
    _notificationService.initialize();
    _loadChannelOrder();

    // Initialize retry service callbacks
    _retryService?.initialize(
      sendMessageCallback: _sendMessageDirect,
      addMessageCallback: _addMessage,
      updateMessageCallback: _updateMessage,
      clearContactPathCallback: clearContactPath,
      setContactPathCallback: setContactPath,
      calculateTimeoutCallback: (pathLength, messageBytes) =>
          calculateTimeout(pathLength: pathLength, messageBytes: messageBytes),
      getSelfPublicKeyCallback: () => _selfPublicKey,
      prepareContactOutboundTextCallback: prepareContactOutboundText,
      appSettingsService: appSettingsService,
      debugLogService: _appDebugLogService,
      recordPathResultCallback: _recordPathResult,
    );
  }

  Future<void> loadContactCache() async {
    final cached = await _contactStore.loadContacts();
    _knownContactKeys
      ..clear()
      ..addAll(cached.map((c) => c.publicKeyHex));
    for (final contact in cached) {
      _ensureContactSmazSettingLoaded(contact.publicKeyHex);
    }
  }

  Future<void> loadChannelSettings({int? maxChannels}) async {
    _channelSmazEnabled.clear();
    final channelCount = maxChannels ?? _maxChannels;
    for (int i = 0; i < channelCount; i++) {
      _channelSmazEnabled[i] = await _channelSettingsStore.loadSmazEnabled(i);
    }
  }

  void _sendMessageDirect(
    Contact contact,
    String text,
    int attempt,
    int timestampSeconds,
  ) async {
    if (!isConnected || text.isEmpty) return;
    final outboundText = prepareContactOutboundText(contact, text);
    await sendFrame(
      buildSendTextMsgFrame(
        contact.publicKey,
        outboundText,
        attempt: attempt,
        timestampSeconds: timestampSeconds,
      ),
    );
  }

  void _updateMessage(Message message) {
    final contactKey = pubKeyToHex(message.senderKey);
    final messages = _conversations[contactKey];
    if (messages != null) {
      final index = messages.indexWhere((m) => m.messageId == message.messageId);
      if (index != -1) {
        messages[index] = message;
        _messageStore.saveMessages(contactKey, messages);
        notifyListeners();
      }
    }
  }

  void _recordPathResult(
    String contactPubKeyHex,
    PathSelection selection,
    bool success,
    int? tripTimeMs,
  ) {
    if (_pathHistoryService == null) return;
    _pathHistoryService!.recordPathResult(
      contactPubKeyHex,
      selection,
      success: success,
      tripTimeMs: tripTimeMs,
    );
  }

  Contact _applyAutoSelection(Contact contact, PathSelection? selection) {
    if (selection == null || selection.useFlood || selection.pathBytes.isEmpty) {
      return contact;
    }

    return Contact(
      publicKey: contact.publicKey,
      name: contact.name,
      type: contact.type,
      pathLength: selection.hopCount >= 0 ? selection.hopCount : contact.pathLength,
      path: Uint8List.fromList(selection.pathBytes),
      latitude: contact.latitude,
      longitude: contact.longitude,
      lastSeen: contact.lastSeen,
      lastMessageAt: contact.lastMessageAt,
    );
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_state == MeshCoreConnectionState.scanning) return;

    _scanResults.clear();
    _setState(MeshCoreConnectionState.scanning);

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults.clear();
      for (var result in results) {
        if (result.device.platformName.startsWith("MeshCore-") ||
            result.advertisementData.advName.startsWith("MeshCore-")) {
          _scanResults.add(result);
        }
      }
      notifyListeners();
    });

    await FlutterBluePlus.startScan(
      timeout: timeout,
      androidScanMode: AndroidScanMode.lowLatency,
    );

    await Future.delayed(timeout);
    await stopScan();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (_state == MeshCoreConnectionState.scanning) {
      _setState(MeshCoreConnectionState.disconnected);
    }
  }

  Future<void> connect(BluetoothDevice device, {String? displayName}) async {
    if (_state == MeshCoreConnectionState.connecting ||
        _state == MeshCoreConnectionState.connected) {
      return;
    }

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
    unawaited(_backgroundService?.start());
    notifyListeners();

    try {
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      await device.connect(
        timeout: const Duration(seconds: 15),
        mtu: null,
        license: License.free,
      );

      // Request larger MTU for sending larger frames
      try {
        final mtu = await device.requestMtu(185);
        debugPrint('MTU set to: $mtu');
      } catch (e) {
        debugPrint('MTU request failed: $e, using default');
      }

      List<BluetoothService> services = await device.discoverServices();

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

      // Retry setNotifyValue with increasing delays
      bool notifySet = false;
      for (int attempt = 0; attempt < 3 && !notifySet; attempt++) {
        try {
          if (attempt > 0) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
          await _txCharacteristic!.setNotifyValue(true);
          notifySet = true;
        } catch (e) {
          debugPrint('setNotifyValue attempt ${attempt + 1}/3 failed: $e');
          if (attempt == 2) rethrow;
        }
      }
      _notifySubscription = _txCharacteristic!.onValueReceived.listen(_handleFrame);

      _setState(MeshCoreConnectionState.connected);

      // Enable wake lock to prevent BLE disconnection when screen turns off
      await WakelockPlus.enable();

      await _requestDeviceInfo();
      final gotSelfInfo = await _waitForSelfInfo(
        timeout: const Duration(seconds: 3),
      );
      if (!gotSelfInfo) {
        await refreshDeviceInfo();
        await _waitForSelfInfo(timeout: const Duration(seconds: 3));
      }

      // Keep device clock aligned on every connection.
      await syncTime();
    } catch (e) {
      debugPrint("Connection error: $e");
      await disconnect(manual: false);
      rethrow;
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

  bool get _shouldAutoReconnect =>
      !_manualDisconnect && _lastDeviceId != null;

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

      final device = _lastDevice ??
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

  Future<void> disconnect({bool manual = true}) async {
    if (_state == MeshCoreConnectionState.disconnecting) return;

    if (manual) {
      _manualDisconnect = true;
      _cancelReconnectTimer();
      unawaited(_backgroundService?.stop());
    } else {
      _manualDisconnect = false;
    }
    _setState(MeshCoreConnectionState.disconnecting);

    // Disable wake lock when disconnecting
    await WakelockPlus.disable();

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

    try {
      // Skip queued BLE operations so disconnect doesn't get stuck behind them.
      await _device?.disconnect(queue: false);
    } catch (e) {
      debugPrint("Disconnect error: $e");
    }

    _device = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _deviceDisplayName = null;
    _deviceId = null;
    _contacts.clear();
    _conversations.clear();
    _loadedConversationKeys.clear();
    _selfPublicKey = null;
    _selfName = null;
    _selfLatitude = null;
    _selfLongitude = null;
    _batteryMillivolts = null;
    _batteryRequested = false;
    _awaitingSelfInfo = false;
    _maxContacts = _defaultMaxContacts;
    _maxChannels = _defaultMaxChannels;
    _isSyncingQueuedMessages = false;
    _queuedMessageSyncInFlight = false;
    _didInitialQueueSync = false;
    _pendingQueueSync = false;
    _isSyncingChannels = false;
    _channelSyncInFlight = false;

    _setState(MeshCoreConnectionState.disconnected);
    if (!manual) {
      _scheduleReconnect();
    }
  }

  Future<void> sendFrame(Uint8List data) async {
    if (!isConnected || _rxCharacteristic == null) {
      throw Exception("Not connected to a MeshCore device");
    }

    _bleDebugLogService?.logFrame(data, outgoing: true);

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

  Future<void> requestBatteryStatus({bool force = false}) async {
    if (!isConnected) return;
    if (_batteryRequested && !force) return;
    _batteryRequested = true;
    await sendFrame(buildGetBattAndStorageFrame());
  }

  Future<void> refreshDeviceInfo() async {
    if (!isConnected) return;
    _awaitingSelfInfo = true;
    await sendFrame(buildDeviceQueryFrame());
    await sendFrame(buildAppStartFrame());
    await requestBatteryStatus(force: true);
    await sendFrame(buildGetRadioSettingsFrame());
    _scheduleSelfInfoRetry();
  }

  Future<void> _requestDeviceInfo() async {
    _awaitingSelfInfo = true;
    await sendFrame(buildDeviceQueryFrame());
    await sendFrame(buildAppStartFrame());
    await requestBatteryStatus();

    _scheduleSelfInfoRetry();
  }

  void _scheduleSelfInfoRetry() {
    _selfInfoRetryTimer?.cancel();
    _selfInfoRetryTimer = Timer.periodic(
      const Duration(milliseconds: 3500),
      (timer) {
        if (!isConnected) {
          timer.cancel();
          return;
        }
        if (!_awaitingSelfInfo) {
          timer.cancel();
          return;
        }
        unawaited(sendFrame(buildAppStartFrame()));
      },
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
    await getContacts(
      since: _latestContactLastmod(),
      preserveExisting: true,
    );
  }

  Future<void> getContactByKey(Uint8List pubKey) async {
    if (!isConnected) return;
    await sendFrame(buildGetContactByKeyFrame(pubKey));
  }

  Future<void> sendMessage(
    Contact contact,
    String text,
  ) async {
    if (!isConnected || text.isEmpty) return;

    // Handle auto-rotation if enabled
    PathSelection? autoSelection;
    if (_appSettingsService?.settings.autoRouteRotationEnabled == true) {
      autoSelection = _pathHistoryService?.getNextAutoPathSelection(contact.publicKeyHex);
      if (autoSelection != null) {
        _pathHistoryService?.recordPathAttempt(contact.publicKeyHex, autoSelection);
        if (!autoSelection.useFlood && autoSelection.pathBytes.isNotEmpty) {
          await setContactPath(
            contact,
            Uint8List.fromList(autoSelection.pathBytes),
            autoSelection.pathBytes.length,
          );
        }
      }
    }

    if (_retryService != null) {
      final pathBytes = _resolveOutgoingPathBytes(contact, autoSelection);
      final pathLength = _resolveOutgoingPathLength(contact, autoSelection);
      final selectedContact = _applyAutoSelection(contact, autoSelection);
      await _retryService!.sendMessageWithRetry(
        contact: selectedContact,
        text: text,
        pathSelection: autoSelection,
        pathBytes: pathBytes,
        pathLength: pathLength,
      );
    } else {
      // Fallback to old behavior if retry service not initialized
      final pathBytes = _resolveOutgoingPathBytes(contact, autoSelection);
      final pathLength = _resolveOutgoingPathLength(contact, autoSelection);
      final message = Message.outgoing(
        contact.publicKey,
        text,
        pathLength: pathLength,
        pathBytes: pathBytes,
      );
      _addMessage(contact.publicKeyHex, message);
      notifyListeners();
      final outboundText = prepareContactOutboundText(contact, text);
      await sendFrame(
        buildSendTextMsgFrame(
          contact.publicKey,
          outboundText,
        ),
      );
    }
  }

  Future<void> setContactPath(
    Contact contact,
    Uint8List customPath,
    int pathLen,
  ) async {
    if (!isConnected) return;

    await sendFrame(buildUpdateContactPathFrame(
      contact.publicKey,
      customPath,
      pathLen,
      type: contact.type,
      name: contact.name,
    ));
  }

  /// Set path override for a contact (persists across contact refreshes)
  /// pathLen: -1 = force flood, null = auto (use device path), >= 0 = specific path
  Future<void> setPathOverride(
    Contact contact, {
    int? pathLen,
    Uint8List? pathBytes,
  }) async {
    appLogger.info('setPathOverride called for ${contact.name}: pathLen=$pathLen, bytesLen=${pathBytes?.length ?? 0}', tag: 'Connector');

    // Find contact in list
    final index = _contacts.indexWhere((c) => c.publicKeyHex == contact.publicKeyHex);
    if (index == -1) {
      appLogger.warn('setPathOverride: Contact not found in list: ${contact.name}', tag: 'Connector');
      return;
    }

    appLogger.info('Found contact at index $index. Current override: ${_contacts[index].pathOverride}', tag: 'Connector');

    // Update contact with new path override
    _contacts[index] = _contacts[index].copyWith(
      pathOverride: pathLen,
      pathOverrideBytes: pathBytes,
      clearPathOverride: pathLen == null, // Clear if pathLen is null
    );

    appLogger.info('Updated contact. New override: ${_contacts[index].pathOverride}, bytesLen: ${_contacts[index].pathOverrideBytes?.length}', tag: 'Connector');

    // Save to storage
    await _contactStore.saveContacts(_contacts);
    appLogger.info('Saved contacts to storage', tag: 'Connector');

    // If setting a specific path (not flood, not auto), also sync with device
    if (pathLen != null && pathLen >= 0 && pathBytes != null) {
      appLogger.info('Sending path to device...', tag: 'Connector');
      await setContactPath(contact, pathBytes, pathLen);
      appLogger.info('Path sent to device', tag: 'Connector');
    }

    debugPrint('Set path override for ${contact.name}: pathLen=$pathLen, bytes=${pathBytes?.length ?? 0}');
    notifyListeners();
  }

  Future<PathSelection> preparePathForContactSend(Contact contact) async {
    PathSelection? autoSelection;
    final autoRotationEnabled =
        _appSettingsService?.settings.autoRouteRotationEnabled == true;
    if (autoRotationEnabled && contact.pathOverride == null) {
      autoSelection = _pathHistoryService?.getNextAutoPathSelection(
        contact.publicKeyHex,
      );
      if (autoSelection != null) {
        _pathHistoryService?.recordPathAttempt(
          contact.publicKeyHex,
          autoSelection,
        );
      }
    }

    final pathBytes = _resolveOutgoingPathBytes(contact, autoSelection);
    final pathLength = _resolveOutgoingPathLength(contact, autoSelection) ?? -1;

    if (pathLength < 0) {
      await clearContactPath(contact);
    } else {
      await setContactPath(contact, pathBytes, pathLength);
    }

    return _selectionFromPath(pathLength, pathBytes);
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
    final ackHashHex = ackHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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

  Future<void> sendChannelMessage(Channel channel, String text) async{
    if (!isConnected || text.isEmpty) return;

    // Check if this is a reaction - if so, process it immediately instead of adding as a message
    final reactionInfo = ReactionHelper.parseReaction(text);
    if (reactionInfo != null) {
      // Check if we've already processed this reaction
      _processedChannelReactions.putIfAbsent(channel.index, () => {});
      final reactionKey = reactionInfo.reactionKey;
      final reactionIdentifier = reactionKey != null ? '${reactionKey}_${reactionInfo.emoji}' : null;

      if (reactionIdentifier != null && _processedChannelReactions[channel.index]!.contains(reactionIdentifier)) {
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
      if (reactionIdentifier != null) {
        _processedChannelReactions[channel.index]!.add(reactionIdentifier);
      }

      notifyListeners();

      // Send the reaction to the device (don't add as a visible message)
      await sendFrame(buildSendChannelTextMsgFrame(channel.index, text));
      return;
    }

    final message = ChannelMessage.outgoing(text, _selfName ?? 'Me', channel.index);
    _addChannelMessage(channel.index, message);
    notifyListeners();

    final trimmed = text.trim();
    final isStructuredPayload = trimmed.startsWith('g:') || trimmed.startsWith('m:');
    final outboundText = (isChannelSmazEnabled(channel.index) && !isStructuredPayload)
        ? Smaz.encodeIfSmaller(text)
        : text;
    await sendFrame(buildSendChannelTextMsgFrame(channel.index, outboundText));
  }

  Future<void> removeContact(Contact contact) async {
    if (!isConnected) return;

    await sendFrame(buildRemoveContactFrame(contact.publicKey));
    _contacts.removeWhere((c) => c.publicKeyHex == contact.publicKeyHex);
    _knownContactKeys.remove(contact.publicKeyHex);
    unawaited(_persistContacts());
    _conversations.remove(contact.publicKeyHex);
    _loadedConversationKeys.remove(contact.publicKeyHex);
    _contactLastReadMs.remove(contact.publicKeyHex);
    _unreadStore.saveContactLastRead(
      Map<String, int>.from(_contactLastReadMs),
    );
    _messageStore.clearMessages(contact.publicKeyHex);
    notifyListeners();
  }

  Future<void> clearContactPath(Contact contact) async {
    if (!isConnected) return;

    await sendFrame(buildResetPathFrame(contact.publicKey));
    final existingIndex =
        _contacts.indexWhere((c) => c.publicKeyHex == contact.publicKeyHex);
    if (existingIndex >= 0) {
      final existing = _contacts[existingIndex];
      // Use copyWith to preserve pathOverride and pathOverrideBytes
      _contacts[existingIndex] = existing.copyWith(
        pathLength: -1,
        path: Uint8List(0),
      );
      notifyListeners();
      unawaited(_persistContacts());
    }
    // The device will send updated contact info with path_len = -1
  }

  void updateContactInMemory(
    String publicKeyHex, {
    Uint8List? pathBytes,
    int? pathLength,
  }) {
    final existingIndex =
        _contacts.indexWhere((c) => c.publicKeyHex == publicKeyHex);
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

    debugPrint('[QueueSync] Requesting next message (retry: $_queueSyncRetries/$_maxQueueSyncRetries)');

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
    debugPrint('[QueueSync] Timeout waiting for message (retry: $_queueSyncRetries/$_maxQueueSyncRetries)');

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

  Future<void> setNodeLocation({required double lat, required double lon}) async {
    if (!isConnected) return;
    await sendFrame(buildSetAdvertLatLonFrame(lat, lon));
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

  Future<void> getChannels({int? maxChannels}) async {
    if (!isConnected) return;
    if (_isSyncingChannels) {
      debugPrint('[ChannelSync] Already syncing channels, ignoring request');
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

    debugPrint('[ChannelSync] Starting sync for $_totalChannelsToRequest channels');

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

    debugPrint('[ChannelSync] Requesting channel $channelIndex/$_totalChannelsToRequest (retry: $_channelSyncRetries/$_maxChannelSyncRetries)');

    try {
      await sendFrame(buildGetChannelFrame(channelIndex));
    } catch (e) {
      debugPrint('[ChannelSync] Error sending channel request: $e');
      _channelSyncInFlight = false;
      _cleanupChannelSync(completed: false);
    }
  }

  void _handleChannelSyncTimeout(int channelIndex) {
    debugPrint('[ChannelSync] Timeout waiting for channel $channelIndex (retry: $_channelSyncRetries/$_maxChannelSyncRetries)');

    if (_channelSyncRetries < _maxChannelSyncRetries) {
      // Retry the same channel
      _channelSyncRetries++;
      _channelSyncInFlight = false;
      unawaited(_requestNextChannel());
    } else {
      // Max retries reached for this channel, restore from cache and move to next
      debugPrint('[ChannelSync] Max retries reached for channel $channelIndex, attempting cache restore');

      // Try to restore this channel from cache
      try {
        final cachedChannel = _previousChannelsCache.firstWhere(
          (c) => c.index == channelIndex
        );
        if (!cachedChannel.isEmpty) {
          _channels.add(cachedChannel);
          debugPrint('[ChannelSync] Restored channel $channelIndex (${cachedChannel.name}) from cache');
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

    debugPrint('[ChannelSync] Sync complete: received ${_channels.length}/$_totalChannelsToRequest channels');

    _cleanupChannelSync(completed: true);

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
      _previousChannelsCache.clear();
    }
    // Keep cache on failure/disconnection for future attempts
  }

  Future<void> setChannel(int index, String name, Uint8List psk) async {
    if (!isConnected) return;

    await sendFrame(buildSetChannelFrame(index, name, psk));
    // Refresh channels after setting
    await getChannels();
  }

  Future<void> deleteChannel(int index) async {
    if (!isConnected) return;

    // Delete by setting empty name and zero PSK
    await sendFrame(buildSetChannelFrame(index, '', Uint8List(16)));
    _channelLastReadMs.remove(index);
    _unreadStore.saveChannelLastRead(
      Map<int, int>.from(_channelLastReadMs),
    );
    // Refresh channels after deleting
    await getChannels();
  }

  void _handleFrame(List<int> data) {
    if (data.isEmpty) return;

    final frame = Uint8List.fromList(data);
    _receivedFramesController.add(frame);
    _bleDebugLogService?.logFrame(frame, outgoing: false);

    final code = frame[0];
    debugPrint('RX frame: code=$code len=${frame.length}');

    switch (code) {
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
      case respCodeContact:
        debugPrint('Got CONTACT');
        _handleContact(frame);
        break;
      case respCodeEndOfContacts:
        debugPrint('Got END_OF_CONTACTS');
        _isLoadingContacts = false;
        _preserveContactsOnRefresh = false;
        notifyListeners();
        unawaited(_persistContacts());
        if (!_didInitialQueueSync || _pendingQueueSync) {
          _didInitialQueueSync = true;
          _pendingQueueSync = false;
          unawaited(syncQueuedMessages(force: true));
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
        _handleLogRxData(frame);
        break;
      case respCodeChannelInfo:
        _handleChannelInfo(frame);
        break;
      case respCodeRadioSettings:
        _handleRadioSettings(frame);
        break;
      case respCodeBattAndStorage:
        _handleBatteryAndStorage(frame);
        break;
      default:
        debugPrint('Unknown frame code: $code');
    }
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
    if (frame.length < 4 + pubKeySize) return;

    _currentTxPower = frame[2];
    _maxTxPower = frame[3];
    _selfPublicKey = Uint8List.fromList(frame.sublist(4, 4 + pubKeySize));
    _selfLatitude = readInt32LE(frame, 36) / 1000000.0;
    _selfLongitude = readInt32LE(frame, 40) / 1000000.0;

    // Radio settings (if frame is long enough)
    if (frame.length >= 58) {
      _currentFreqHz = readUint32LE(frame, 48);
      _currentBwHz = readUint32LE(frame, 52);
      _currentSf = frame[56];
      _currentCr = frame[57];
    }

    // Node name starts at offset 58 if frame is long enough
    if (frame.length > 58) {
      _selfName = readCString(frame, 58, frame.length - 58);
    }
    _awaitingSelfInfo = false;
    _selfInfoRetryTimer?.cancel();
    _selfInfoRetryTimer = null;
    notifyListeners();

    // Auto-fetch contacts after getting self info
    getContacts();
  }

  void _handleDeviceInfo(Uint8List frame) {
    if (frame.length < 4) return;
    // Firmware reports MAX_CONTACTS / 2 for v3+ device info.
    final reportedContacts = frame[2];
    final reportedChannels = frame[3];
    final nextMaxContacts = reportedContacts > 0 ? reportedContacts * 2 : _maxContacts;
    final nextMaxChannels = reportedChannels > 0 ? reportedChannels : _maxChannels;
    final previousMaxChannels = _maxChannels;
    if (nextMaxContacts != _maxContacts || nextMaxChannels != _maxChannels) {
      _maxContacts = nextMaxContacts;
      _maxChannels = nextMaxChannels;
      if (nextMaxChannels > previousMaxChannels) {
        unawaited(loadChannelSettings(maxChannels: nextMaxChannels));
        unawaited(loadAllChannelMessages(maxChannels: nextMaxChannels));
        if (isConnected) {
          unawaited(getChannels(maxChannels: nextMaxChannels));
        }
      }
      notifyListeners();
    }
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

  void _handleRadioSettings(Uint8List frame) {
    // Frame format from C++:
    // [0] = RESP_CODE_RADIO_SETTINGS
    // [1-4] = freq (uint32 LE, in Hz)
    // [5-8] = bw (uint32 LE, in Hz)
    // [9] = sf
    // [10] = cr
    if (frame.length >= 11) {
      _currentFreqHz = readUint32LE(frame, 1);
      _currentBwHz = readUint32LE(frame, 5);
      _currentSf = frame[9];
      _currentCr = frame[10];
      debugPrint('Radio settings: freq=$_currentFreqHz bw=$_currentBwHz sf=$_currentSf cr=$_currentCr');
      notifyListeners();
    }
  }

  void _handleBatteryAndStorage(Uint8List frame) {
    // Frame format from C++:
    // [0] = RESP_CODE_BATT_AND_STORAGE
    // [1-2] = battery_mv (uint16 LE)
    // [3-6] = storage_used_kb (uint32 LE)
    // [7-10] = storage_total_kb (uint32 LE)
    if (frame.length >= 3) {
      _batteryMillivolts = readUint16LE(frame, 1);
      notifyListeners();
    }
  }

  /// Calculate timeout for a message based on radio settings and path length
  /// Returns timeout in milliseconds, considering number of hops
  int calculateTimeout({required int pathLength, int messageBytes = 100}) {
    // If we have radio settings, use them for accurate calculation
    if (_currentFreqHz != null &&
        _currentBwHz != null &&
        _currentSf != null &&
        _currentCr != null) {
      final cr = _currentCr! <= 4 ? _currentCr! : _currentCr! - 4;
      return calculateMessageTimeout(
        freqHz: _currentFreqHz!,
        bwHz: _currentBwHz!,
        sf: _currentSf!,
        cr: cr,
        pathLength: pathLength,
        messageBytes: messageBytes,
      );
    }

    // Fallback: Conservative estimates based on typical settings
    // Assume SF7, BW125, which gives ~50ms airtime for 100 bytes
    const estimatedAirtime = 50;

    if (pathLength < 0) {
      // Flood mode: Base delay + 16× airtime
      return 500 + (16 * estimatedAirtime);
    } else {
      // Direct path: Base delay + ((airtime×6 + 250ms)×(hops+1))
      return 500 + ((estimatedAirtime * 6 + 250) * (pathLength + 1));
    }
  }

  void _handleContact(Uint8List frame) {
    final contact = Contact.fromFrame(frame);
    if (contact != null) {
      if (contact.type == advTypeRepeater) {
        _contactLastReadMs.remove(contact.publicKeyHex);
        _unreadStore.saveContactLastRead(
          Map<String, int>.from(_contactLastReadMs),
        );
      }
      // Check if this is a new contact
      final isNewContact = !_knownContactKeys.contains(contact.publicKeyHex);
      final existingIndex = _contacts.indexWhere(
        (c) => c.publicKeyHex == contact.publicKeyHex,
      );

      if (existingIndex >= 0) {
        final existing = _contacts[existingIndex];
        final mergedLastMessageAt = existing.lastMessageAt.isAfter(contact.lastMessageAt)
            ? existing.lastMessageAt
            : contact.lastMessageAt;

        appLogger.info('Refreshing contact ${contact.name}: devicePath=${contact.pathLength}, existingOverride=${existing.pathOverride}', tag: 'Connector');

        // CRITICAL: Preserve user's path override when contact is refreshed from device
        _contacts[existingIndex] = contact.copyWith(
          lastMessageAt: mergedLastMessageAt,
          pathOverride: existing.pathOverride, // Preserve user's path choice
          pathOverrideBytes: existing.pathOverrideBytes,
        );

        appLogger.info('After merge: pathOverride=${_contacts[existingIndex].pathOverride}, devicePath=${_contacts[existingIndex].pathLength}', tag: 'Connector');
      } else {
        _contacts.add(contact);
        appLogger.info('Added new contact ${contact.name}: pathLen=${contact.pathLength}', tag: 'Connector');
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

  Future<void> _persistContacts() async {
    await _contactStore.saveContacts(_contacts);
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
    if (pathBytes.isEmpty || publicKey.length < pathHashSize) return false;
    for (int i = 0; i + pathHashSize <= pathBytes.length; i += pathHashSize) {
      final prefix = pathBytes.sublist(i, i + pathHashSize);
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
        final hasContact = _contacts.any((c) => _matchesPrefix(c.publicKey, senderPrefix));
        if (!hasContact) {
          debugPrint('Received message from unknown contact, refreshing contacts...');
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
      _maybeMarkActiveContactRead(message);
      notifyListeners();

      // Show notification for new incoming message
      if (!message.isOutgoing && !message.isCli && _appSettingsService != null) {
        final settings = _appSettingsService!.settings;
        if (settings.notificationsEnabled && settings.notifyOnNewMessage) {
          // Find the contact name
          if(contact?.type == advTypeChat) { 
            _notificationService.showMessageNotification(
              contactName: contact?.name ?? 'Unknown',
              message: message.text,
              contactId: message.senderKeyHex,
              badgeCount: getTotalUnreadCount(),
            );
          }else if(contact?.type == advTypeRoom) {
            _notificationService.showMessageNotification(
              contactName: contact?.name ?? 'Unknown Room',
              message: message.text.substring(4),
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
    if (frame.isEmpty) return null;
    final code = frame[0];
    if (code != respCodeContactMsgRecv && code != respCodeContactMsgRecvV3) {
      return null;
    }

    // Companion radio layout:
    // [code][snr?][res?][res?][prefix x6][path_len][txt_type][timestamp x4][extra?][text...]
    final prefixOffset = code == respCodeContactMsgRecvV3 ? 4 : 1;
    const prefixLen = 6;
    final pathLenOffset = prefixOffset + prefixLen;
    final txtTypeOffset = pathLenOffset + 1;
    final timestampOffset = txtTypeOffset + 1;
    final baseTextOffset = timestampOffset + 4;

    if (frame.length <= baseTextOffset) return null;
    final fourBytePubMSG = frame.sublist(baseTextOffset, baseTextOffset + 4);
    final senderPrefix = frame.sublist(prefixOffset, prefixOffset + prefixLen);
    final flags = frame[txtTypeOffset];
    final shiftedType = flags >> 2;
    final rawType = flags;
    final isPlain = shiftedType == txtTypePlain || rawType == txtTypePlain;
    final isCli = shiftedType == txtTypeCliData || rawType == txtTypeCliData;
    if (!isPlain && !isCli) {
      return null;
    }

    // Try base text offset; if empty and there is room for the optional 4-byte extra
    // (used by signed/plain variants), try again skipping those bytes.
    var text = readCString(frame, baseTextOffset, frame.length - baseTextOffset);
    if (text.isEmpty && frame.length > baseTextOffset + 4) {
      text = readCString(frame, baseTextOffset + 4, frame.length - (baseTextOffset + 4));
    }
    if (text.isEmpty) return null;
    final decodedText = isCli ? text : (Smaz.tryDecodePrefixed(text) ?? text);

    final timestampRaw = readUint32LE(frame, timestampOffset);
    final pathLenByte = frame[pathLenOffset];

    final contact = _contacts.cast<Contact?>().firstWhere(
      (c) => c != null && _matchesPrefix(c.publicKey, senderPrefix),
      orElse: () => null,
    );
    if (contact == null) return null;

    return Message(
      senderKey: contact.publicKey,
      text: decodedText,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampRaw * 1000),
      isOutgoing: false,
      isCli: isCli,
      status: MessageStatus.delivered,
      pathLength: pathLenByte == 0xFF ? 0 : pathLenByte,
      pathBytes: Uint8List(0),
      fourByteRoomContactKey: fourBytePubMSG
    );
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
        trimmed.startsWith('g:') || trimmed.startsWith('m:') || trimmed.startsWith('V1|');
    if (!isStructuredPayload && isContactSmazEnabled(contact.publicKeyHex)) {
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
    _notificationService.showChannelMessageNotification(
      channelName: label,
      message: message.text,
      channelIndex: channelIndex,
      badgeCount: getTotalUnreadCount(),
    );
  }

  void _handleIncomingChannelMessage(Uint8List frame) {
    final message = ChannelMessage.fromFrame(frame);
    if (message != null && message.channelIndex != null) {
      if (_shouldDropSelfChannelMessage(message.senderName, message.pathBytes)) {
        return;
      }
      _updateContactLastMessageAtByName(
        message.senderName,
        message.timestamp,
        pathBytes: message.pathBytes,
      );
      final isNew = _addChannelMessage(message.channelIndex!, message);
      _maybeMarkActiveChannelRead(message);
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
    final raw = Uint8List.fromList(frame.sublist(3));
    final packet = _parseRawPacket(raw);
    if (packet == null || packet.payloadType != _payloadTypeGroupText) return;

    final payload = packet.payload;
    if (payload.length <= _cipherMacSize) return;
    final channelHash = payload[0];
    final encrypted = Uint8List.fromList(payload.sublist(1));

    for (final channel in _channels) {
      if (channel.isEmpty) continue;
      final hash = _computeChannelHash(channel.psk);
      if (hash != channelHash) continue;

      final decrypted = _decryptPayload(channel.psk, encrypted);
      if (decrypted == null || decrypted.length < 6) return;

      final txtType = decrypted[4];
      if ((txtType >> 2) != 0) {
        return;
      }

      final timestampRaw = readUint32LE(decrypted, 0);
      final text = readCString(decrypted, 5, decrypted.length - 5);
      final parsed = _splitSenderText(text);
      final decodedText = Smaz.tryDecodePrefixed(parsed.text) ?? parsed.text;
      if (_shouldDropSelfChannelMessage(parsed.senderName, packet.pathBytes)) {
        return;
      }

      final message = ChannelMessage(
        senderKey: null,
        senderName: parsed.senderName,
        text: decodedText,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampRaw * 1000),
        isOutgoing: false,
        status: ChannelMessageStatus.sent,
        pathLength: packet.isFlood ? packet.pathBytes.length : 0,
        pathBytes: packet.pathBytes,
        channelIndex: channel.index,
      );

      _updateContactLastMessageAtByName(
        parsed.senderName,
        message.timestamp,
        pathBytes: message.pathBytes,
      );
      final isNew = _addChannelMessage(channel.index, message);
      _maybeMarkActiveChannelRead(message);
      notifyListeners();
      if (isNew) {
        final label = channel.name.isEmpty ? 'Channel ${channel.index}' : channel.name;
        _maybeNotifyChannelMessage(message, channelName: label);
      }
      return;
    }
  }

  void _handleMessageSent(Uint8List frame) {
    // Frame format from C++:
    // [0] = RESP_CODE_SENT
    // [1] = is_flood (1 or 0)
    // [2-5] = expected_ack_hash (uint32)
    // [6-9] = estimated_timeout_ms (uint32)

    if (frame.length >= 10) {
      final isFlood = frame[1] != 0;
      final ackHash = Uint8List.fromList(frame.sublist(2, 6));
      final timeoutMs = readUint32LE(frame, 6);

      // Check if this is a CLI command ACK - if so, ignore it
      if (_lastSentWasCliCommand) {
        final ackHashHex = ackHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        debugPrint('Ignoring CLI command ACK (sent): $ackHashHex');
        _lastSentWasCliCommand = false;
        return;
      }

      if (_handleRepeaterCommandSent(ackHash, timeoutMs)) {
        return;
      }

      if (_retryService != null) {
        _retryService!.updateMessageFromSent(ackHash, timeoutMs);
      }
    } else {
      // Fallback to old behavior
      for (var messages in _conversations.values) {
        for (int i = messages.length - 1; i >= 0; i--) {
          if (messages[i].isOutgoing && messages[i].status == MessageStatus.pending) {
            messages[i] = messages[i].copyWith(status: MessageStatus.sent);
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  void _handleSendConfirmed(Uint8List frame) {
    // Frame format from C++:
    // [0] = PUSH_CODE_SEND_CONFIRMED
    // [1-4] = ack_hash (uint32)
    // [5-8] = trip_time_ms (uint32)

    if (frame.length >= 9) {
      final ackHash = Uint8List.fromList(frame.sublist(1, 5));
      final tripTimeMs = readUint32LE(frame, 5);

      // CLI command ACKs are already filtered in _handleMessageSent, so this should only see real messages

      if (_handleRepeaterCommandAck(ackHash, tripTimeMs)) {
        return;
      }

      // Handle ACK in retry service
      if (_retryService != null) {
        _retryService!.handleAckReceived(ackHash, tripTimeMs);
      }
    } else {
      // Fallback to old behavior
      for (var messages in _conversations.values) {
        for (int i = messages.length - 1; i >= 0; i--) {
          if (messages[i].isOutgoing && messages[i].status == MessageStatus.sent) {
            messages[i] = messages[i].copyWith(status: MessageStatus.delivered);
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  bool _handleRepeaterCommandSent(Uint8List ackHash, int timeoutMs) {
    final ackHashHex = ackHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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

  bool _handleRepeaterCommandAck(Uint8List ackHash, int tripTimeMs) {
    final ackHashHex = ackHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final entry = _pendingRepeaterAcks.remove(ackHashHex);
    if (entry == null) return false;
    entry.timeout?.cancel();
    _recordPathResult(entry.contactKeyHex, entry.selection, true, tripTimeMs);
    return true;
  }

  void _handleChannelInfo(Uint8List frame) {
    final channel = Channel.fromFrame(frame);
    if (channel == null) return;

    debugPrint('[ChannelSync] Received channel ${channel.index}: ${channel.isEmpty ? "empty" : channel.name}');

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
        unawaited(_requestNextChannel());
        return;
      } else {
        // Received a channel but not the one we're waiting for
        // This can happen if device sends unsolicited updates
        debugPrint('[ChannelSync] Received unexpected channel ${channel.index}, expected $_nextChannelIndexToRequest');
        // Add it anyway but don't advance sync
        if (!channel.isEmpty && !_channels.any((c) => c.index == channel.index)) {
          _channels.add(channel);
        }
        return;
      }
    }

    // Not syncing, or received unsolicited update - handle normally
    if (!channel.isEmpty) {
      // Update or add channel
      final existingIndex = _channels.indexWhere((c) => c.index == channel.index);
      if (existingIndex >= 0) {
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

  int _calculateReadTimestampMs(Iterable<DateTime>? timestamps) {
    var latestMs = 0;
    if (timestamps != null) {
      for (final timestamp in timestamps) {
        final ms = timestamp.millisecondsSinceEpoch;
        if (ms > latestMs) {
          latestMs = ms;
        }
      }
    }
    return latestMs;
  }

  void _setContactLastReadMs(String contactKeyHex, int timestampMs, {bool notify = true}) {
    if (!_shouldTrackUnreadForContactKey(contactKeyHex)) return;
    final existing = _contactLastReadMs[contactKeyHex] ?? 0;
    if (timestampMs <= existing) return;
    _contactLastReadMs[contactKeyHex] = timestampMs;
    _unreadStore.saveContactLastRead(
      Map<String, int>.from(_contactLastReadMs),
    );
    if (notify) {
      notifyListeners();
    }
  }

  void _setChannelLastReadMs(int channelIndex, int timestampMs, {bool notify = true}) {
    final existing = _channelLastReadMs[channelIndex] ?? 0;
    if (timestampMs <= existing) return;
    _channelLastReadMs[channelIndex] = timestampMs;
    _unreadStore.saveChannelLastRead(
      Map<int, int>.from(_channelLastReadMs),
    );
    if (notify) {
      notifyListeners();
    }
  }

  void _maybeMarkActiveContactRead(Message message) {
    if (message.isOutgoing || message.isCli) return;
    if (_activeContactKey != message.senderKeyHex) return;
    if (!_shouldTrackUnreadForContactKey(message.senderKeyHex)) return;
    _setContactLastReadMs(
      message.senderKeyHex,
      message.timestamp.millisecondsSinceEpoch,
      notify: false,
    );
  }

  void _maybeMarkActiveChannelRead(ChannelMessage message) {
    if (message.isOutgoing) return;
    final channelIndex = message.channelIndex;
    if (channelIndex == null || _activeChannelIndex != channelIndex) return;
    _setChannelLastReadMs(
      channelIndex,
      message.timestamp.millisecondsSinceEpoch,
      notify: false,
    );
  }

  void _addMessage(String pubKeyHex, Message message) {
    _conversations.putIfAbsent(pubKeyHex, () => []);
    final messages = _conversations[pubKeyHex]!;

    // Parse reaction info
    final reactionInfo = Message.parseReaction(message.text);
    if (reactionInfo != null) {
      // Check if we've already processed this exact reaction using lightweight key
      _processedContactReactions.putIfAbsent(pubKeyHex, () => {});
      final reactionKey = reactionInfo.reactionKey;
      final reactionIdentifier = reactionKey != null ? '${reactionKey}_${reactionInfo.emoji}' : null;

      final isDuplicate = reactionIdentifier != null &&
          _processedContactReactions[pubKeyHex]!.contains(reactionIdentifier);

      if (!isDuplicate) {
        // New reaction - process it
        _processContactReaction(messages, reactionInfo);
        _messageStore.saveMessages(pubKeyHex, messages);

        // Mark as processed
        if (reactionIdentifier != null) {
          _processedContactReactions[pubKeyHex]!.add(reactionIdentifier);
        }

        notifyListeners();
      }
      return; // Don't add reaction as a visible message
    }

    messages.add(message);
    _messageStore.saveMessages(pubKeyHex, messages);
    notifyListeners();
  }

  void _processContactReaction(List<Message> messages, ReactionInfo reactionInfo) {
    // Find target message by messageId
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].messageId == reactionInfo.targetMessageId) {
        final currentReactions = Map<String, int>.from(messages[i].reactions);
        currentReactions[reactionInfo.emoji] =
            (currentReactions[reactionInfo.emoji] ?? 0) + 1;

        messages[i] = messages[i].copyWith(reactions: currentReactions);
        break;
      }
    }
  }

  _RawPacket? _parseRawPacket(Uint8List raw) {
    if (raw.length < 3) return null;
    var index = 0;
    final header = raw[index++];
    final routeType = header & _phRouteMask;
    final hasTransport = routeType == _routeTransportFlood || routeType == _routeTransportDirect;
    if (hasTransport) {
      if (raw.length < index + 4) return null;
      index += 4;
    }
    if (raw.length <= index) return null;
    final pathLen = raw[index++];
    if (raw.length < index + pathLen) return null;
    final pathBytes = Uint8List.fromList(raw.sublist(index, index + pathLen));
    index += pathLen;
    if (raw.length <= index) return null;
    final payload = Uint8List.fromList(raw.sublist(index));

    return _RawPacket(
      header: header,
      routeType: routeType,
      payloadType: (header >> _phTypeShift) & _phTypeMask,
      payloadVer: (header >> _phVerShift) & _phVerMask,
      pathBytes: pathBytes,
      payload: payload,
    );
  }

  int _computeChannelHash(Uint8List psk) {
    final digest = crypto.sha256.convert(psk).bytes;
    return digest[0];
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

    final cipher = ECBBlockCipher(AESFastEngine());
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
      final offset = (colonIndex + 1 < text.length && text[colonIndex + 1] == ' ')
          ? colonIndex + 2
          : colonIndex + 1;
      return _ParsedText(
        senderName: potentialSender,
        text: text.substring(offset),
      );
    }
    return _ParsedText(senderName: 'Unknown', text: text);
  }

  Uint8List _resolveOutgoingPathBytes(
    Contact contact,
    PathSelection? selection,
  ) {
    // Priority 1: Check user's path override
    if (contact.pathOverride != null) {
      if (contact.pathOverride! < 0) {
        return Uint8List(0); // Force flood
      }
      return contact.pathOverrideBytes ?? Uint8List(0);
    }

    // Priority 2: Check device flood mode or PathSelection flood
    if (contact.pathLength < 0 || selection?.useFlood == true) {
      return Uint8List(0);
    }

    // Priority 3: Check PathSelection (auto-rotation)
    if (selection != null && selection.pathBytes.isNotEmpty) {
      return Uint8List.fromList(selection.pathBytes);
    }

    // Priority 4: Use device's discovered path
    return contact.path;
  }

  int? _resolveOutgoingPathLength(
    Contact contact,
    PathSelection? selection,
  ) {
    // Priority 1: Check user's path override
    if (contact.pathOverride != null) {
      return contact.pathOverride;
    }

    // Priority 2: Check device flood mode or PathSelection flood
    if (contact.pathLength < 0 || selection?.useFlood == true) {
      return -1;
    }

    // Priority 3: Check PathSelection (auto-rotation)
    if (selection != null && selection.pathBytes.isNotEmpty) {
      return selection.hopCount;
    }

    // Priority 4: Use device's discovered path
    return contact.pathLength;
  }

  PathSelection _selectionFromPath(int pathLength, Uint8List pathBytes) {
    if (pathLength < 0) {
      return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
    }
    return PathSelection(
      pathBytes: pathBytes,
      hopCount: pathLength,
      useFlood: false,
    );
  }

  bool _addChannelMessage(int channelIndex, ChannelMessage message) {
    _channelMessages.putIfAbsent(channelIndex, () => []);
    final messages = _channelMessages[channelIndex]!;

    // Parse reaction info
    final reactionInfo = ChannelMessage.parseReaction(message.text);
    if (reactionInfo != null) {
      // Check if we've already processed this exact reaction using lightweight key
      _processedChannelReactions.putIfAbsent(channelIndex, () => {});
      final reactionKey = reactionInfo.reactionKey;
      final reactionIdentifier = reactionKey != null ? '${reactionKey}_${reactionInfo.emoji}' : null;

      final isDuplicate = reactionIdentifier != null &&
          _processedChannelReactions[channelIndex]!.contains(reactionIdentifier);

      if (!isDuplicate) {
        // New reaction - process it
        _processReaction(messages, reactionInfo);
        // Save updated messages
        _channelMessageStore.saveChannelMessages(channelIndex, messages);

        // Mark as processed
        if (reactionIdentifier != null) {
          _processedChannelReactions[channelIndex]!.add(reactionIdentifier);
        }
      }
      return false; // Don't add reaction as a visible message
    }

    // Parse reply info from message text
    final replyInfo = ChannelMessage.parseReplyMention(message.text);
    ChannelMessage processedMessage = message;

    if (replyInfo != null) {
      // Find original message by sender name (most recent match)
      final originalMessage = _findMessageBySender(messages, replyInfo.mentionedNode);

      if (originalMessage != null) {
        // Create new message with reply metadata
        processedMessage = ChannelMessage(
          senderKey: message.senderKey,
          senderName: message.senderName,
          text: replyInfo.actualMessage,
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
      final mergedPathBytes = _selectPreferredPathBytes(existing.pathBytes, processedMessage.pathBytes);
      final mergedPathVariants = _mergePathVariants(existing.pathVariants, processedMessage.pathVariants);
      final mergedPathLength = _mergePathLength(
        existing.pathLength,
        processedMessage.pathLength,
        mergedPathBytes.length,
      );
      final newRepeatCount = existing.repeatCount + 1;
      messages[existingIndex] = existing.copyWith(
        repeatCount: newRepeatCount,
        pathLength: mergedPathLength,
        pathBytes: mergedPathBytes,
        pathVariants: mergedPathVariants,
        // Mark as sent when first repeat is heard
        status: newRepeatCount == 1 && existing.status == ChannelMessageStatus.pending
            ? ChannelMessageStatus.sent
            : existing.status,
      );
    } else {
      messages.add(processedMessage);
    }

    // Save to persistent storage
    _channelMessageStore.saveChannelMessages(
      channelIndex,
      messages,
    );
    return isNew;
  }

  ChannelMessage? _findMessageBySender(List<ChannelMessage> messages, String mentionedNode) {
    // Search backwards for most recent message from this sender
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].senderName == mentionedNode && !messages[i].isOutgoing) {
        return messages[i];
      }
    }
    return null;
  }

  void _processReaction(List<ChannelMessage> messages, ReactionInfo reactionInfo) {
    // Find target message by messageId
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].messageId == reactionInfo.targetMessageId) {
        final currentReactions = Map<String, int>.from(messages[i].reactions);
        currentReactions[reactionInfo.emoji] =
            (currentReactions[reactionInfo.emoji] ?? 0) + 1;

        messages[i] = messages[i].copyWith(reactions: currentReactions);
        notifyListeners();
        break;
      }
    }
  }

  int _findChannelRepeatIndex(List<ChannelMessage> messages, ChannelMessage incoming) {
    for (int i = messages.length - 1; i >= 0; i--) {
      final existing = messages[i];
      if (_isChannelRepeat(existing, incoming)) {
        return i;
      }
    }
    return -1;
  }

  bool _isChannelRepeat(ChannelMessage existing, ChannelMessage incoming) {
    if (existing.text != incoming.text) return false;

    final diffMs = (existing.timestamp.millisecondsSinceEpoch -
            incoming.timestamp.millisecondsSinceEpoch)
        .abs();
    if (diffMs > 5000) return false;

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
    final selfKey = _selfPublicKey;
    if (selfKey == null) return false;
    if (pathBytes.length < pathHashSize) return false;
    final trimmed = senderName.trim();
    if (trimmed.isEmpty) return false;
    final selfName = _selfName?.trim();
    if (selfName == null || selfName.isEmpty) return false;
    if (trimmed != selfName) return false;
    final prefix = selfKey.sublist(0, pathHashSize);
    for (int i = 0; i + pathHashSize <= pathBytes.length; i += pathHashSize) {
      var match = true;
      for (int j = 0; j < pathHashSize; j++) {
        if (pathBytes[i + j] != prefix[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        return true;
      }
    }
    return false;
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
    // Disable wake lock when connection is lost
    WakelockPlus.disable();

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
    _maxContacts = _defaultMaxContacts;
    _maxChannels = _defaultMaxChannels;
    _isSyncingQueuedMessages = false;
    _queuedMessageSyncInFlight = false;
    _isSyncingChannels = false;
    _channelSyncInFlight = false;

    _setState(MeshCoreConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _setState(MeshCoreConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _reconnectTimer?.cancel();
    _receivedFramesController.close();

    // Flush pending unread writes before disposal
    _unreadStore.flush();

    super.dispose();
  }
}

const int _phRouteMask = 0x03;
const int _phTypeShift = 2;
const int _phTypeMask = 0x0F;
const int _phVerShift = 6;
const int _phVerMask = 0x03;

const int _routeTransportFlood = 0x00;
const int _routeFlood = 0x01;
const int _routeDirect = 0x02;
const int _routeTransportDirect = 0x03;

const int _payloadTypeGroupText = 0x05;
const int _cipherMacSize = 2;

class _RawPacket {
  final int header;
  final int routeType;
  final int payloadType;
  final int payloadVer;
  final Uint8List pathBytes;
  final Uint8List payload;

  _RawPacket({
    required this.header,
    required this.routeType,
    required this.payloadType,
    required this.payloadVer,
    required this.pathBytes,
    required this.payload,
  });

  bool get isFlood => routeType == _routeFlood || routeType == _routeTransportFlood;
}

class _ParsedText {
  final String senderName;
  final String text;

  _ParsedText({
    required this.senderName,
    required this.text,
  });
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
