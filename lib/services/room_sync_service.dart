import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import '../storage/room_sync_store.dart';
import 'app_settings_service.dart';
import 'app_debug_log_service.dart';
import 'storage_service.dart';

enum RoomSyncStatusKind {
  syncOff,
  syncDisabled,
  syncing,
  connectedWaitingSync,
  connectedStale,
  connectedSynced,
  notLoggedIn,
}

class _PendingRoomLogin {
  final String roomPubKeyHex;
  final Completer<bool?> completer;

  const _PendingRoomLogin({
    required this.roomPubKeyHex,
    required this.completer,
  });
}

class RoomSyncService extends ChangeNotifier {
  static const Duration _loginTimeoutFallback = Duration(seconds: 12);
  static const int _maxAutoLoginAttempts = 3;
  static const int _autoLoginBurstSize = 2;
  static const Duration _autoLoginBurstPause = Duration(seconds: 4);
  static const int _autoLoginJitterMinMs = 350;
  static const int _autoLoginJitterMaxMs = 1250;
  static const Duration _pushSyncThrottle = Duration(seconds: 20);

  final RoomSyncStore _roomSyncStore;
  final StorageService _storageService;

  MeshCoreConnector? _connector;
  AppDebugLogService? _debugLogService;
  AppSettingsService? _appSettingsService;
  StreamSubscription<Uint8List>? _frameSubscription;
  Timer? _nextSyncTimer;
  Timer? _syncTimeoutTimer;

  final Map<String, _PendingRoomLogin> _pendingLoginByPrefix = {};
  final Set<String> _activeRoomSessions = {};
  final Map<String, RoomSyncStateRecord> _states = {};
  final Random _random = Random();

  MeshCoreConnectionState? _lastConnectionState;
  Duration _currentInterval = Duration.zero;
  bool _started = false;
  bool _lastRoomSyncEnabled = false;
  bool _syncInFlight = false;
  bool _autoLoginInProgress = false;
  DateTime? _lastPushTriggeredSyncAt;

  RoomSyncService({
    required RoomSyncStore roomSyncStore,
    required StorageService storageService,
  }) : _roomSyncStore = roomSyncStore,
       _storageService = storageService;

  Map<String, RoomSyncStateRecord> get states => Map.unmodifiable(_states);

  bool isRoomAutoSyncEnabled(String roomPubKeyHex) {
    return _states[roomPubKeyHex]?.autoSyncEnabled ?? false;
  }

  /// Whether the room has an active login session for the current connection.
  /// Returns true even when global room sync is disabled, so callers can use
  /// this to skip the login dialog when the user is already authenticated.
  bool isRoomSessionActive(String roomPubKeyHex) {
    return _activeRoomSessions.contains(roomPubKeyHex);
  }

  int? roomAclPermissions(String roomPubKeyHex) {
    return _states[roomPubKeyHex]?.lastAclPermissions;
  }

  int? roomFirmwareLevel(String roomPubKeyHex) {
    return _states[roomPubKeyHex]?.lastLoginFirmwareLevel;
  }

  Future<void> setRoomAutoSyncEnabled(
    String roomPubKeyHex,
    bool enabled,
  ) async {
    final existing =
        _states[roomPubKeyHex] ??
        RoomSyncStateRecord(roomPubKeyHex: roomPubKeyHex);
    _states[roomPubKeyHex] = existing.copyWith(autoSyncEnabled: enabled);

    if (!enabled) {
      _activeRoomSessions.remove(roomPubKeyHex);
    } else {
      final connector = _connector;
      if (connector != null && connector.isConnected && _roomSyncEnabled) {
        unawaited(_tryLoginRoomByPubKey(roomPubKeyHex));
      }
    }

    await _persistStates();
    notifyListeners();
  }

  bool isRoomStale(String roomPubKeyHex) {
    final state = _states[roomPubKeyHex];
    if (state == null || state.lastSuccessfulSyncAtMs == null) return true;
    final ageMs =
        DateTime.now().millisecondsSinceEpoch - state.lastSuccessfulSyncAtMs!;
    return ageMs > _staleAfter.inMilliseconds;
  }

  Future<void> initialize({
    required MeshCoreConnector connector,
    required AppSettingsService appSettingsService,
    AppDebugLogService? appDebugLogService,
  }) async {
    if (_started) return;
    _connector = connector;
    _appSettingsService = appSettingsService;
    _debugLogService = appDebugLogService;
    _states
      ..clear()
      ..addAll(await _roomSyncStore.load());
    _lastConnectionState = connector.state;
    _frameSubscription = connector.receivedFrames.listen(_handleFrame);
    connector.addListener(_handleConnectorChange);
    appSettingsService.addListener(_handleSettingsChange);
    _started = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _appSettingsService?.removeListener(_handleSettingsChange);
    _frameSubscription?.cancel();
    _nextSyncTimer?.cancel();
    _syncTimeoutTimer?.cancel();
    _pendingLoginByPrefix.clear();
    _activeRoomSessions.clear();
    super.dispose();
  }

  void _handleConnectorChange() {
    final connector = _connector;
    if (connector == null) return;
    final state = connector.state;
    if (state == _lastConnectionState) return;
    _lastConnectionState = state;
    if (state == MeshCoreConnectionState.connected) {
      _onConnected();
    } else {
      _onDisconnected();
    }
  }

  void _onConnected() {
    if (!_roomSyncEnabled) return;
    _lastRoomSyncEnabled = true;
    _currentInterval = _defaultSyncInterval;
    _scheduleNextSync(_defaultSyncInterval);
    unawaited(_autoLoginSavedRooms());
  }

  void _onDisconnected() {
    _lastRoomSyncEnabled = false;
    _syncInFlight = false;
    _nextSyncTimer?.cancel();
    _syncTimeoutTimer?.cancel();
    _pendingLoginByPrefix.clear();
    _activeRoomSessions.clear();
    notifyListeners();
  }

  void _handleSettingsChange() {
    final nowEnabled = _roomSyncEnabled;
    final connector = _connector;
    final isConnected = connector != null && connector.isConnected;

    if (nowEnabled && !_lastRoomSyncEnabled && isConnected) {
      _lastRoomSyncEnabled = true;
      _currentInterval = _defaultSyncInterval;
      _scheduleNextSync(_defaultSyncInterval);
      unawaited(_autoLoginSavedRooms());
    } else if (!nowEnabled && _lastRoomSyncEnabled) {
      _lastRoomSyncEnabled = false;
      _nextSyncTimer?.cancel();
      _syncTimeoutTimer?.cancel();
    }
    notifyListeners();
  }

  Future<void> _autoLoginSavedRooms() async {
    if (_autoLoginInProgress) return;
    final connector = _connector;
    if (connector == null || !connector.isConnected) return;
    if (!_roomSyncEnabled || !_roomSyncAutoLoginEnabled) return;
    _autoLoginInProgress = true;
    try {
      final savedPasswords = await _storageService.loadRepeaterPasswords();
      if (savedPasswords.isEmpty) return;

      for (int i = 0; i < 20 && connector.isLoadingContacts; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final roomContacts = connector.contacts
          .where(
            (c) =>
                c.type == advTypeRoom &&
                savedPasswords.containsKey(c.publicKeyHex) &&
                isRoomAutoSyncEnabled(c.publicKeyHex),
          )
          .toList();
      if (roomContacts.isEmpty) return;

      roomContacts.sort((a, b) {
        final aState = _states[a.publicKeyHex];
        final bState = _states[b.publicKeyHex];
        final aScore =
            aState?.lastSuccessfulSyncAtMs ?? aState?.lastLoginSuccessAtMs ?? 0;
        final bScore =
            bState?.lastSuccessfulSyncAtMs ?? bState?.lastLoginSuccessAtMs ?? 0;
        return bScore.compareTo(aScore);
      });

      int processed = 0;
      for (final room in roomContacts) {
        final delay = _nextAutoLoginDelay(processed);
        if (delay > Duration.zero) {
          await Future.delayed(delay);
        }
        if (!connector.isConnected ||
            !_roomSyncEnabled ||
            !_roomSyncAutoLoginEnabled) {
          break;
        }
        final password = savedPasswords[room.publicKeyHex];
        if (password == null || password.isEmpty) continue;
        final success = await _loginRoomWithRetries(room, password);
        if (success) {
          _activeRoomSessions.add(room.publicKeyHex);
          _recordLoginSuccess(room.publicKeyHex);
        } else {
          _recordFailure(room.publicKeyHex);
        }
        processed++;
      }
    } finally {
      _autoLoginInProgress = false;
      await _persistStates();
      notifyListeners();
    }
  }

  Future<bool> _loginRoomWithRetries(Contact room, String password) async {
    if (!isRoomAutoSyncEnabled(room.publicKeyHex)) return false;
    for (int attempt = 0; attempt < _maxAutoLoginAttempts; attempt++) {
      final result = await _loginRoom(room, password);
      if (result == true) return true;
      if (result == false) return false;
      // null indicates timeout/transport failure, so retry.
      continue;
    }
    return false;
  }

  Future<bool?> _loginRoom(Contact room, String password) async {
    final connector = _connector;
    if (connector == null || !connector.isConnected) return null;
    if (!isRoomAutoSyncEnabled(room.publicKeyHex)) return false;
    _recordLoginAttempt(room.publicKeyHex);

    final selection = await connector.preparePathForContactSend(room);
    final frame = buildSendLoginFrame(room.publicKey, password);
    final timeoutMs = connector.calculateTimeout(
      pathLength: selection.useFlood ? -1 : selection.hopCount,
      messageBytes: frame.length > maxFrameSize ? frame.length : maxFrameSize,
    );
    final timeout =
        Duration(milliseconds: timeoutMs).compareTo(Duration.zero) > 0
        ? Duration(milliseconds: timeoutMs)
        : _loginTimeoutFallback;

    final prefix = _prefixHex(room.publicKey.sublist(0, 6));
    final completer = Completer<bool?>();
    _pendingLoginByPrefix[prefix] = _PendingRoomLogin(
      roomPubKeyHex: room.publicKeyHex,
      completer: completer,
    );

    try {
      await connector.sendFrame(frame);
      final result = await completer.future.timeout(
        timeout,
        onTimeout: () => null,
      );
      return result;
    } catch (_) {
      return null;
    } finally {
      final currentPending = _pendingLoginByPrefix[prefix];
      if (currentPending != null &&
          identical(currentPending.completer, completer)) {
        _pendingLoginByPrefix.remove(prefix);
      }
    }
  }

  void _handleFrame(Uint8List frame) {
    if (frame.isEmpty) return;
    final code = frame[0];

    if (code == pushCodeMsgWaiting) {
      _handleQueuedMessagesHint();
    }

    if (code == pushCodeLoginSuccess || code == pushCodeLoginFail) {
      _handleLoginResponseFrame(frame, code == pushCodeLoginSuccess);
      return;
    }

    if (!_syncInFlight) return;
    if (code == respCodeNoMoreMessages) {
      _markSyncSuccess();
      return;
    }
    if (code == respCodeContactMsgRecv ||
        code == respCodeContactMsgRecvV3 ||
        code == respCodeChannelMsgRecv ||
        code == respCodeChannelMsgRecvV3) {
      // Messages are still flowing — extend the timeout to avoid a false failure
      // while a large queue is being drained.
      _syncTimeoutTimer?.cancel();
      _syncTimeoutTimer = Timer(_syncTimeout, _markSyncFailure);
    }
  }

  void _handleQueuedMessagesHint() {
    final connector = _connector;
    if (connector == null || !connector.isConnected) return;
    if (!_roomSyncEnabled) return;
    if (_syncInFlight) return;

    final hasEnabledActiveRooms = _activeRoomSessions.any(
      isRoomAutoSyncEnabled,
    );
    if (!hasEnabledActiveRooms) return;

    final lastTrigger = _lastPushTriggeredSyncAt;
    final now = DateTime.now();
    if (lastTrigger != null &&
        now.difference(lastTrigger) < _pushSyncThrottle) {
      return;
    }

    _lastPushTriggeredSyncAt = now;
    _scheduleNextSync(Duration.zero);
  }

  void _handleLoginResponseFrame(Uint8List frame, bool success) {
    if (frame.length < 8) return;
    final prefix = _prefixHex(frame.sublist(2, 8));
    final pending = _pendingLoginByPrefix[prefix];
    if (pending != null && !pending.completer.isCompleted) {
      if (success) {
        _recordLoginMetadataFromFrame(pending.roomPubKeyHex, frame);
      }
      pending.completer.complete(success);
      return;
    }
    if (!success) return;

    // Manual room logins are handled outside RoomSyncService; in that path we can
    // still capture metadata if the prefix resolves uniquely to a room contact.
    final roomPubKeyHex = _resolveRoomPubKeyHexByPrefix(prefix);
    if (roomPubKeyHex != null) {
      _recordLoginMetadataFromFrame(roomPubKeyHex, frame);
      unawaited(_persistStates());
      notifyListeners();
    }
  }

  void _scheduleNextSync(Duration delay) {
    _nextSyncTimer?.cancel();
    _nextSyncTimer = Timer(delay, () {
      unawaited(_runSyncCycle());
    });
  }

  Future<void> _runSyncCycle() async {
    final connector = _connector;
    if (connector == null || !connector.isConnected) return;
    if (!_roomSyncEnabled) return;
    if (_activeRoomSessions.isEmpty) {
      _scheduleNextSync(_defaultSyncInterval);
      return;
    }
    final enabledSessionCount = _activeRoomSessions
        .where((roomPubKeyHex) => isRoomAutoSyncEnabled(roomPubKeyHex))
        .length;
    if (enabledSessionCount == 0) {
      _scheduleNextSync(_defaultSyncInterval);
      return;
    }
    if (_syncInFlight) return;

    _syncInFlight = true;
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(_syncTimeout, _markSyncFailure);

    try {
      await connector.syncQueuedMessages(force: true);
    } catch (_) {
      _markSyncFailure();
    }
  }

  void _markSyncSuccess() {
    _syncTimeoutTimer?.cancel();
    _syncInFlight = false;
    _currentInterval = _defaultSyncInterval;

    for (final roomPubKeyHex in _activeRoomSessions) {
      if (!isRoomAutoSyncEnabled(roomPubKeyHex)) continue;
      final existing =
          _states[roomPubKeyHex] ??
          RoomSyncStateRecord(roomPubKeyHex: roomPubKeyHex);
      _states[roomPubKeyHex] = existing.copyWith(
        lastSuccessfulSyncAtMs: DateTime.now().millisecondsSinceEpoch,
        consecutiveFailures: 0,
      );
    }
    _persistStates();
    notifyListeners();
    _scheduleNextSync(_currentInterval);
  }

  void _markSyncFailure() {
    _syncTimeoutTimer?.cancel();
    _syncInFlight = false;
    for (final roomPubKeyHex in _activeRoomSessions) {
      if (!isRoomAutoSyncEnabled(roomPubKeyHex)) continue;
      _recordFailure(roomPubKeyHex);
    }
    _currentInterval = _nextBackoffInterval(_currentInterval);
    _persistStates();
    notifyListeners();
    _scheduleNextSync(_currentInterval);
  }

  Duration _nextBackoffInterval(Duration current) {
    final doubledMs = current.inMilliseconds * 2;
    if (doubledMs >= _maxSyncInterval.inMilliseconds) {
      return _maxSyncInterval;
    }
    return Duration(milliseconds: doubledMs);
  }

  RoomSyncStatusKind roomStatusKind(String roomPubKeyHex) {
    if (!_roomSyncEnabled) return RoomSyncStatusKind.syncOff;
    if (!isRoomAutoSyncEnabled(roomPubKeyHex)) {
      return RoomSyncStatusKind.syncDisabled;
    }
    if (_syncInFlight) return RoomSyncStatusKind.syncing;
    final connector = _connector;
    final isActivelyConnected = connector != null && connector.isConnected;
    final state = _states[roomPubKeyHex];
    if (isActivelyConnected && _activeRoomSessions.contains(roomPubKeyHex)) {
      if (state?.lastSuccessfulSyncAtMs == null) {
        return RoomSyncStatusKind.connectedWaitingSync;
      }
      return isRoomStale(roomPubKeyHex)
          ? RoomSyncStatusKind.connectedStale
          : RoomSyncStatusKind.connectedSynced;
    }
    return RoomSyncStatusKind.notLoggedIn;
  }

  Future<void> registerManualRoomLogin(String roomPubKeyHex) async {
    final existing = _states[roomPubKeyHex];
    if (existing == null) {
      _states[roomPubKeyHex] = RoomSyncStateRecord(
        roomPubKeyHex: roomPubKeyHex,
        autoSyncEnabled: true,
      );
    } else if (!existing.autoSyncEnabled) {
      return;
    }
    _activeRoomSessions.add(roomPubKeyHex);
    _recordLoginSuccess(roomPubKeyHex);
    await _persistStates();
    notifyListeners();
    if (_roomSyncEnabled) {
      _scheduleNextSync(Duration.zero);
    }
  }

  String? roomStatusLabel(String roomPubKeyHex) {
    switch (roomStatusKind(roomPubKeyHex)) {
      case RoomSyncStatusKind.syncOff:
        return 'Room sync off';
      case RoomSyncStatusKind.syncDisabled:
        return 'Sync disabled';
      case RoomSyncStatusKind.syncing:
        return 'Syncing...';
      case RoomSyncStatusKind.connectedWaitingSync:
        return 'Connected, waiting sync';
      case RoomSyncStatusKind.connectedStale:
        return 'Connected, stale';
      case RoomSyncStatusKind.connectedSynced:
        return 'Connected, synced';
      case RoomSyncStatusKind.notLoggedIn:
        return 'Not logged in';
    }
  }

  void _recordLoginAttempt(String roomPubKeyHex) {
    final existing =
        _states[roomPubKeyHex] ??
        RoomSyncStateRecord(roomPubKeyHex: roomPubKeyHex);
    _states[roomPubKeyHex] = existing.copyWith(
      lastLoginAttemptAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _recordLoginSuccess(String roomPubKeyHex) {
    final existing =
        _states[roomPubKeyHex] ??
        RoomSyncStateRecord(roomPubKeyHex: roomPubKeyHex);
    _states[roomPubKeyHex] = existing.copyWith(
      lastLoginSuccessAtMs: DateTime.now().millisecondsSinceEpoch,
      consecutiveFailures: 0,
    );
  }

  void _recordLoginMetadataFromFrame(String roomPubKeyHex, Uint8List frame) {
    final existing =
        _states[roomPubKeyHex] ??
        RoomSyncStateRecord(roomPubKeyHex: roomPubKeyHex);
    final serverTimestamp = frame.length >= 12 ? readUint32LE(frame, 8) : null;
    final aclPermissions = frame.length >= 13 ? frame[12] : null;
    final firmwareLevel = frame.length >= 14 ? frame[13] : null;
    _states[roomPubKeyHex] = existing.copyWith(
      lastLoginServerTimestamp: serverTimestamp,
      lastAclPermissions: aclPermissions,
      lastLoginFirmwareLevel: firmwareLevel,
    );
  }

  void _recordFailure(String roomPubKeyHex) {
    final existing =
        _states[roomPubKeyHex] ??
        RoomSyncStateRecord(roomPubKeyHex: roomPubKeyHex);
    final nextFailures = existing.consecutiveFailures + 1;
    _states[roomPubKeyHex] = existing.copyWith(
      lastFailureAtMs: DateTime.now().millisecondsSinceEpoch,
      consecutiveFailures: nextFailures,
    );
    _debugLogService?.warn(
      'Room sync/login failure for $roomPubKeyHex (consecutive: $nextFailures)',
      tag: 'RoomSync',
    );
  }

  Duration _nextAutoLoginDelay(int processedCount) {
    if (processedCount <= 0) return Duration.zero;
    if (processedCount % _autoLoginBurstSize == 0) {
      return _autoLoginBurstPause;
    }
    final range = _autoLoginJitterMaxMs - _autoLoginJitterMinMs;
    final jitterMs = range <= 0
        ? _autoLoginJitterMinMs
        : _autoLoginJitterMinMs + _random.nextInt(range + 1);
    return Duration(milliseconds: jitterMs);
  }

  Future<void> _persistStates() async {
    await _roomSyncStore.save(_states);
  }

  String _prefixHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String? _resolveRoomPubKeyHexByPrefix(String prefixHex) {
    final connector = _connector;
    if (connector == null) return null;
    final matches = connector.contacts
        .where((contact) {
          if (contact.type != advTypeRoom) return false;
          if (contact.publicKey.length < 6) return false;
          return _prefixHex(contact.publicKey.sublist(0, 6)) == prefixHex;
        })
        .map((contact) => contact.publicKeyHex)
        .toSet()
        .toList();
    if (matches.length != 1) return null;
    return matches.first;
  }

  Future<void> _tryLoginRoomByPubKey(String roomPubKeyHex) async {
    final connector = _connector;
    if (connector == null || !connector.isConnected) return;
    final savedPasswords = await _storageService.loadRepeaterPasswords();
    final password = savedPasswords[roomPubKeyHex];
    if (password == null || password.isEmpty) return;
    final roomContact = connector.contacts.cast<Contact?>().firstWhere(
      (c) =>
          c != null && c.publicKeyHex == roomPubKeyHex && c.type == advTypeRoom,
      orElse: () => null,
    );
    if (roomContact == null) return;
    final success = await _loginRoomWithRetries(roomContact, password);
    if (success) {
      _activeRoomSessions.add(roomPubKeyHex);
      _recordLoginSuccess(roomPubKeyHex);
    } else {
      _recordFailure(roomPubKeyHex);
    }
    await _persistStates();
    notifyListeners();
  }

  bool get _roomSyncEnabled =>
      _appSettingsService?.settings.roomSyncEnabled ?? true;
  bool get _roomSyncAutoLoginEnabled =>
      _appSettingsService?.settings.roomSyncAutoLoginEnabled ?? true;
  Duration get _defaultSyncInterval => Duration(
    seconds: _appSettingsService?.settings.roomSyncIntervalSeconds ?? 90,
  );
  Duration get _maxSyncInterval => Duration(
    seconds: _appSettingsService?.settings.roomSyncMaxIntervalSeconds ?? 600,
  );
  Duration get _syncTimeout => Duration(
    seconds: _appSettingsService?.settings.roomSyncTimeoutSeconds ?? 15,
  );
  Duration get _staleAfter => Duration(
    minutes: _appSettingsService?.settings.roomSyncStaleMinutes ?? 15,
  );
}
