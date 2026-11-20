import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/packet_path.dart';
import '../utils/coalesced_writes.dart';
import 'storage_service.dart';

/// Rolling record of the routing paths the radio has seen packets travel.
/// Backs the map's packet-path lines and live packet animations.
class PacketPathService extends ChangeNotifier {
  /// Records older than this are dropped from storage.
  static const Duration retention = Duration(days: 30);

  @visibleForTesting
  static const int maxRecords = 4000;

  final StorageService _storage;
  final Map<String, ObservedPath> _paths = {};
  final List<ObservedPath> _pendingBeforeLoad = [];
  final CoalescedWrites _writes = CoalescedWrites(
    delay: const Duration(seconds: 5),
  );

  bool _loaded = false;
  bool _notifyPending = false;
  int _version = 0;
  int get version => _version;

  PacketPathService(this._storage);

  Future<void> initialize() async {
    await _load();
  }

  void setDevicePublicKey(String publicKeyHex) {
    unawaited(_writes.flush());
    _storage.setPublicKeyHex = publicKeyHex;
    _paths.clear();
    _pendingBeforeLoad.clear();
    _loaded = false;
    _version++;
    notifyListeners();
    unawaited(_load());
  }

  Future<void> _load() async {
    final stored = await _storage.loadObservedPaths();
    final cutoff = DateTime.now().subtract(retention).millisecondsSinceEpoch;
    for (final path in stored) {
      if (path.lastSeenMs < cutoff) continue;
      _paths[path.key] = path;
    }
    for (final path in _pendingBeforeLoad) {
      _merge(path);
    }
    _pendingBeforeLoad.clear();
    _loaded = true;
    if (_paths.isNotEmpty) _scheduleSave();
    _version++;
    notifyListeners();
  }

  /// Records one observed packet path. Cheap to call from the frame pump.
  void record(List<int> pathBytes, int hashWidth, {DateTime? seenAt}) {
    if (pathBytes.isEmpty) return;
    final seen = seenAt ?? DateTime.now();
    final width = hashWidth.clamp(1, 3);
    if (!_loaded) {
      if (_pendingBeforeLoad.length < 200) {
        _pendingBeforeLoad.add(
          ObservedPath(
            pathBytes: Uint8List.fromList(pathBytes),
            hashWidth: width,
            firstSeenMs: seen.millisecondsSinceEpoch,
            lastSeenMs: seen.millisecondsSinceEpoch,
            count: 1,
          ),
        );
      }
      return;
    }
    final key = base64Encode(pathBytes);
    final existing = _paths[key];
    if (existing == null) {
      _paths[key] = ObservedPath(
        pathBytes: Uint8List.fromList(pathBytes),
        hashWidth: width,
        firstSeenMs: seen.millisecondsSinceEpoch,
        lastSeenMs: seen.millisecondsSinceEpoch,
        count: 1,
      );
    } else {
      _paths[key] = existing.merge(seen);
    }
    _scheduleSave();
    _scheduleNotify();
  }

  void _merge(ObservedPath path) {
    final existing = _paths[path.key];
    if (existing == null) {
      _paths[path.key] = path;
    } else {
      _paths[path.key] = ObservedPath(
        pathBytes: existing.pathBytes,
        hashWidth: existing.hashWidth,
        firstSeenMs: path.firstSeenMs < existing.firstSeenMs
            ? path.firstSeenMs
            : existing.firstSeenMs,
        lastSeenMs: path.lastSeenMs > existing.lastSeenMs
            ? path.lastSeenMs
            : existing.lastSeenMs,
        count: existing.count + path.count,
      );
    }
  }

  /// Paths seen within [window], most recently seen first.
  List<ObservedPath> pathsWithin(Duration window) {
    final cutoff = DateTime.now().subtract(window).millisecondsSinceEpoch;
    final visible = _paths.values.where((p) => p.lastSeenMs >= cutoff).toList();
    visible.sort((a, b) => b.lastSeenMs.compareTo(a.lastSeenMs));
    return visible;
  }

  void _scheduleSave() {
    if (_paths.length > maxRecords) {
      final sorted = _paths.values.toList()
        ..sort((a, b) => b.lastSeenMs.compareTo(a.lastSeenMs));
      for (final stale in sorted.skip(maxRecords)) {
        _paths.remove(stale.key);
      }
    }
    final snapshot = List<ObservedPath>.from(_paths.values);
    _writes.schedule('packet_paths', () async {
      await _storage.saveObservedPaths(snapshot);
    });
  }

  void _scheduleNotify() {
    if (_notifyPending) return;
    _notifyPending = true;
    Timer(const Duration(seconds: 1), () {
      _notifyPending = false;
      if (_disposed) return;
      _version++;
      notifyListeners();
    });
  }

  bool _disposed = false;

  /// Runs queued saves now, e.g. before the app is backgrounded.
  Future<void> flushPendingWrites() => _writes.flush();

  @override
  void dispose() {
    _disposed = true;
    unawaited(_writes.flush());
    super.dispose();
  }
}
