import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../connector/meshcore_connector.dart';
import '../../connector/meshcore_protocol.dart';
import '../../storage/prefs_manager.dart';
import '../../utils/app_logger.dart';
import '../app_settings_service.dart';
import 'network_map_api_client.dart';
import 'network_map_gzip.dart';
import 'network_map_records.dart';

/// Random per-install identifier, regenerated every 24 h and never derived
/// from the radio key.
class NetworkMapInstallId {
  static const _keyId = 'network_map_install_id';
  static const _keyCreatedAt = 'network_map_install_id_created_at';
  static const Duration lifetime = Duration(hours: 24);

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final Random _random;

  NetworkMapInstallId(this._prefs, {DateTime Function()? now, Random? random})
    : _now = now ?? DateTime.now,
      _random = random ?? Random.secure();

  String current() {
    final now = _now();
    final id = _prefs.getString(_keyId);
    final createdMs = _prefs.getInt(_keyCreatedAt);
    if (id != null && createdMs != null) {
      final age = now.difference(
        DateTime.fromMillisecondsSinceEpoch(createdMs),
      );
      if (!age.isNegative && age < lifetime) return id;
    }
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    final fresh = base64Url.encode(bytes).replaceAll('=', '');
    unawaited(_prefs.setString(_keyId, fresh));
    unawaited(_prefs.setInt(_keyCreatedAt, now.millisecondsSinceEpoch));
    return fresh;
  }
}

class _Queued<T> {
  final DateTime queuedAt;
  final T record;

  _Queued(this.queuedAt, this.record);
}

/// Records waiting for upload, with the contract's batch caps and age limit.
class NetworkMapUploadQueue {
  static const int maxPacketsPerBatch = 2000;
  static const int maxAdvertsPerBatch = 200;
  static const Duration maxQueueAge = Duration(hours: 1);

  /// The server drops records more than 65 min old, so anything past an hour
  /// is not worth sending.
  static const Duration maxRecordAge = Duration(minutes: 60);

  // Bounds memory if uploads keep failing for the full hour.
  static const int _maxQueuedPackets = maxPacketsPerBatch * 5;

  final List<_Queued<NetworkMapPacketRecord>> _packets = [];
  final List<_Queued<NetworkMapAdvertRecord>> _adverts = [];

  bool get isEmpty => _packets.isEmpty && _adverts.isEmpty;
  int get packetCount => _packets.length;
  int get advertCount => _adverts.length;

  void addPacket(NetworkMapPacketRecord record, DateTime now) {
    _packets.add(_Queued(now, record));
    if (_packets.length > _maxQueuedPackets) _packets.removeAt(0);
  }

  void addAdvert(NetworkMapAdvertRecord record, DateTime now) {
    // Only the latest advert per key is useful within one batch window.
    _adverts.removeWhere((q) => q.record.key == record.key);
    _adverts.add(_Queued(now, record));
  }

  void dropExpired(DateTime now) {
    final cutoffSeconds = networkMapMinute(now.subtract(maxRecordAge));
    bool expired(DateTime queuedAt, int t) =>
        now.difference(queuedAt) > maxQueueAge || t < cutoffSeconds;
    _packets.removeWhere((q) => expired(q.queuedAt, q.record.t));
    _adverts.removeWhere((q) => expired(q.queuedAt, q.record.t));
  }

  void clear() {
    _packets.clear();
    _adverts.clear();
  }

  /// The oldest records up to the per-batch caps. They stay queued until
  /// [remove] confirms the upload.
  ({List<NetworkMapPacketRecord> packets, List<NetworkMapAdvertRecord> adverts})
  peekBatch() => (
    packets: [for (final q in _packets.take(maxPacketsPerBatch)) q.record],
    adverts: [for (final q in _adverts.take(maxAdvertsPerBatch)) q.record],
  );

  void remove(int packets, int adverts) {
    _packets.removeRange(0, min(packets, _packets.length));
    _adverts.removeRange(0, min(adverts, _adverts.length));
  }
}

/// Opt-in uploader for the network map.
///
/// Listens to raw RX log frames only while the user has opted in and a radio
/// is connected, and uploads header-only records in batches.
class NetworkMapUploadService extends ChangeNotifier {
  static const Duration uploadInterval = Duration(seconds: 60);
  static const Duration heartbeatInterval = Duration(minutes: 5);
  static const Duration maxBackoff = Duration(minutes: 15);
  static const int _maxJitterMs = 10000;

  static const _keySentDay = 'network_map_sent_day';
  static const _keySentCount = 'network_map_sent_count';
  static const _keyLastUpload = 'network_map_last_upload';

  final MeshCoreConnector _connector;
  final AppSettingsService _settings;
  final http.Client _client;
  final String baseUrl;
  final Random _random = Random();
  final NetworkMapUploadQueue _queue = NetworkMapUploadQueue();

  StreamSubscription<Uint8List>? _frameSub;
  Timer? _timer;
  bool _uploading = false;

  /// Bumped whenever sharing is turned off. An upload started under an older
  /// generation is never sent and its result is ignored, so nothing leaves the
  /// phone after consent is withdrawn and a late response can't touch a queue
  /// that was cleared and refilled in the meantime.
  int _consentGeneration = 0;
  int _failures = 0;
  Duration _retryAfter = Duration.zero;
  Duration _nextInterval = uploadInterval;
  DateTime? _listenMark;
  int _listenSeconds = 0;
  DateTime? _lastUploadAt;
  DateTime? _lastAttemptAt;
  int _packetsSentToday = 0;
  String? _appId;

  NetworkMapUploadService({
    required MeshCoreConnector connector,
    required AppSettingsService settings,
    http.Client? client,
    this.baseUrl = networkMapBaseUrl,
  }) : _connector = connector,
       _settings = settings,
       _client = client ?? http.Client() {
    _loadStatus();
    _connector.addListener(_sync);
    _settings.addListener(_sync);
    _sync();
  }

  bool get enabled => _settings.settings.networkMapUploadEnabled;

  /// True while frames are being collected.
  bool get isActive => _frameSub != null;
  DateTime? get lastUploadAt => _lastUploadAt;
  int get packetsSentToday {
    final prefs = PrefsManager.instance;
    return prefs.getString(_keySentDay) == _dayKey(DateTime.now())
        ? _packetsSentToday
        : 0;
  }

  Future<void> setEnabled(bool value) =>
      _settings.setNetworkMapUploadEnabled(value);

  void _loadStatus() {
    final prefs = PrefsManager.instance;
    final lastMs = prefs.getInt(_keyLastUpload);
    if (lastMs != null) {
      _lastUploadAt = DateTime.fromMillisecondsSinceEpoch(lastMs);
    }
    _packetsSentToday = prefs.getInt(_keySentCount) ?? 0;
  }

  void _sync() {
    if (!enabled && (isActive || !_queue.isEmpty || _uploading)) {
      _queue.clear();
      _consentGeneration++;
    }
    // The store-review demo radio is simulated; its traffic must not reach
    // the real map.
    final shouldListen =
        enabled && _connector.isConnected && !_connector.isReviewMode;
    if (shouldListen == isActive) return;
    if (shouldListen) {
      _frameSub = _connector.receivedFrames.listen(_onFrame);
      _listenMark = DateTime.now();
      _lastAttemptAt ??= DateTime.now();
      _schedule(uploadInterval);
    } else {
      _accrueListenTime();
      _listenMark = null;
      unawaited(_frameSub?.cancel());
      _frameSub = null;
      _timer?.cancel();
      _timer = null;
    }
    notifyListeners();
  }

  void _onFrame(Uint8List frame) {
    if (frame.isEmpty || frame[0] != pushCodeLogRxData) return;
    final now = DateTime.now();
    final packet = buildPacketRecord(frame, now);
    if (packet == null) return;
    _queue.addPacket(packet, now);
    if (packet.pt == payloadTypeADVERT) {
      unawaited(
        buildAdvertRecord(frame, now).then((advert) {
          if (advert != null && isActive) _queue.addAdvert(advert, now);
        }),
      );
    }
  }

  void _accrueListenTime() {
    final mark = _listenMark;
    if (mark == null) return;
    final now = DateTime.now();
    _listenSeconds += now.difference(mark).inSeconds;
    _listenMark = now;
  }

  void _schedule(Duration base) {
    _timer?.cancel();
    final jitter = Duration(milliseconds: _random.nextInt(_maxJitterMs + 1));
    _timer = Timer(base + jitter, _tick);
  }

  Future<void> _tick() async {
    if (!isActive || _uploading) return;
    final now = DateTime.now();
    _queue.dropExpired(now);
    final sinceLast = now.difference(_lastAttemptAt ?? now);
    if (_queue.isEmpty && sinceLast < heartbeatInterval) {
      _schedule(_nextInterval);
      return;
    }
    await _upload();
    if (isActive) {
      _schedule(_failures == 0 ? _nextInterval : _backoffDelay);
    }
  }

  Duration get _backoffDelay {
    final exp = uploadInterval * pow(2, _failures - 1).toInt();
    final delay = exp > maxBackoff ? maxBackoff : exp;
    return _retryAfter > delay ? _retryAfter : delay;
  }

  Future<void> _upload() async {
    _uploading = true;
    final generation = _consentGeneration;
    bool stale() => generation != _consentGeneration || !enabled;
    _lastAttemptAt = DateTime.now();
    try {
      _accrueListenTime();
      final batch = _queue.peekBatch();
      final lat = _connector.selfLatitude;
      final lon = _connector.selfLongitude;
      final hasPosition =
          lat != null &&
          lon != null &&
          (lat.abs() > 1e-6 || lon.abs() > 1e-6) &&
          lat.abs() <= 90 &&
          lon.abs() <= 180;
      final body = buildUploadBody(
        installId: NetworkMapInstallId(PrefsManager.instance).current(),
        app: await _appString(),
        loc: hasPosition ? NetworkMapLoc.snapped(lat, lon) : null,
        preset: NetworkMapPreset.fromRadio(
          freqKhz: _connector.currentFreqHz,
          bwHz: _connector.currentBwHz,
          sf: _connector.currentSf,
          cr: _connector.currentCr,
        ),
        listenSeconds: min(_listenSeconds, 600),
        packets: batch.packets,
        adverts: batch.adverts,
      );
      if (stale()) return;
      final jsonBytes = utf8.encode(jsonEncode(body));
      final gzipped = gzipEncode(jsonBytes);
      final response = await _client
          .post(
            Uri.parse('$baseUrl/v1/upload'),
            headers: {
              'Content-Type': 'application/json',
              if (gzipped != null) 'Content-Encoding': 'gzip',
            },
            body: gzipped ?? jsonBytes,
          )
          .timeout(const Duration(seconds: 30));
      if (stale()) return;
      final status = response.statusCode;
      if (status == 202 || status == 200) {
        _queue.remove(batch.packets.length, batch.adverts.length);
        _onUploaded(batch.packets.length, response.body);
      } else if (status == 429 || status >= 500) {
        _onFailed(response.headers['retry-after'], response.body);
      } else {
        // 400/413/415: resending the same batch can never succeed.
        appLogger.warn(
          'Network map upload rejected ($status): ${response.body}',
          tag: 'NetworkMap',
        );
        _queue.remove(batch.packets.length, batch.adverts.length);
        _listenSeconds = 0;
        _failures = 0;
      }
    } catch (e) {
      if (stale()) return;
      appLogger.warn('Network map upload failed: $e', tag: 'NetworkMap');
      _onFailed(null, null);
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  void _onUploaded(int packetCount, String body) {
    final now = DateTime.now();
    _failures = 0;
    _retryAfter = Duration.zero;
    _listenSeconds = 0;
    _lastUploadAt = now;
    _nextInterval = uploadInterval;
    try {
      final next = (jsonDecode(body) as Map)['nextUploadSeconds'];
      if (next is num && next >= 30 && next <= 900) {
        _nextInterval = Duration(seconds: next.toInt());
      }
    } catch (_) {}

    final prefs = PrefsManager.instance;
    final today = _dayKey(now);
    if (prefs.getString(_keySentDay) != today) _packetsSentToday = 0;
    _packetsSentToday += packetCount;
    unawaited(prefs.setString(_keySentDay, today));
    unawaited(prefs.setInt(_keySentCount, _packetsSentToday));
    unawaited(prefs.setInt(_keyLastUpload, now.millisecondsSinceEpoch));
  }

  void _onFailed(String? retryAfterHeader, String? body) {
    _failures++;
    var retryAfter = int.tryParse(retryAfterHeader?.trim() ?? '');
    if (retryAfter == null && body != null) {
      try {
        final value = (jsonDecode(body) as Map)['retryAfterSeconds'];
        if (value is num) retryAfter = value.toInt();
      } catch (_) {}
    }
    _retryAfter = retryAfter == null
        ? Duration.zero
        : Duration(seconds: min(retryAfter, maxBackoff.inSeconds));
  }

  @visibleForTesting
  int get queuedPacketCount => _queue.packetCount;

  @visibleForTesting
  void queuePacketForTest(NetworkMapPacketRecord record) =>
      _queue.addPacket(record, DateTime.now());

  @visibleForTesting
  Future<void> uploadNowForTest() => _upload();

  Future<String> _appString() async {
    if (_appId != null) return _appId!;
    var version = '';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    final cleaned = version.replaceAll(RegExp(r'[^\x21-\x7E]'), '');
    final id = cleaned.isEmpty ? 'meshcore-open' : 'meshcore-open/$cleaned';
    return _appId = id.length > 64 ? id.substring(0, 64) : id;
  }

  static String _dayKey(DateTime time) =>
      '${time.year}-${time.month}-${time.day}';

  @override
  void dispose() {
    _connector.removeListener(_sync);
    _settings.removeListener(_sync);
    _timer?.cancel();
    unawaited(_frameSub?.cancel());
    _client.close();
    super.dispose();
  }
}
