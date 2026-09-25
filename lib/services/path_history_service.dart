import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/path_history.dart';
import '../models/path_selection.dart';
import 'storage_service.dart';

class PathHistoryService extends ChangeNotifier {
  final StorageService _storage;
  final Map<String, ContactPathHistory> _cache = {};
  final Map<String, int> _autoRotationIndex = {};
  final Map<String, _FloodStats> _floodStats = {};
  final Map<String, Future<void>> _pendingLoads = {};

  // LRU cache eviction tracking
  static const int _maxCachedContacts = 50;
  final List<String> _cacheAccessOrder = [];

  static const int _maxHistoryEntries = 100;

  int _version = 0;
  int get version => _version;

  PathHistoryService(this._storage);

  void setDevicePublicKey(String publicKeyHex) {
    _storage.setPublicKeyHex = publicKeyHex;
    _cache.clear();
    _cacheAccessOrder.clear();
    _autoRotationIndex.clear();
    _floodStats.clear();
    _version++;
    notifyListeners();
  }

  Future<void> initialize() async {
    // Load cached path histories on startup if needed
  }

  void handlePathUpdated(Contact contact, {double initialWeight = 1.0}) {
    if (contact.pathLength < 0 && contact.path.isEmpty) return;
    final hopCount = contact.pathLength < 0
        ? contact.path.length
        : contact.pathLength;
    _addPathRecord(
      contactPubKeyHex: contact.publicKeyHex,
      hopCount: hopCount,
      tripTimeMs: 0,
      wasFloodDiscovery: true,
      pathBytes: contact.path,
      successCount: 0,
      failureCount: 0,
      initialWeight: initialWeight,
      timestamp: null,
    );
  }

  void recordPathAttempt(String contactPubKeyHex, PathSelection selection) {
    if (selection.useFlood) {
      _updateFloodStats(contactPubKeyHex);
      return;
    }

    _addPathRecord(
      contactPubKeyHex: contactPubKeyHex,
      hopCount: selection.hopCount,
      tripTimeMs: 0,
      wasFloodDiscovery: false,
      pathBytes: selection.pathBytes,
      successCount: 0,
      failureCount: 0,
      timestamp: null,
    );
  }

  /// When a flood message is delivered, credit the contact's current device
  /// path so that the route the ACK traveled back through gets a weight boost.
  void recordFloodPathAttribution({
    required String contactPubKeyHex,
    required List<int> pathBytes,
    required int hopCount,
    int? tripTimeMs,
    double successIncrement = 0.5,
    double maxWeight = 5.0,
  }) {
    if (pathBytes.isEmpty || hopCount < 0) return;
    if (!_cache.containsKey(contactPubKeyHex)) {
      _ensureLoaded(contactPubKeyHex).then((_) {
        if (!_cache.containsKey(contactPubKeyHex)) return;
        recordFloodPathAttribution(
          contactPubKeyHex: contactPubKeyHex,
          pathBytes: pathBytes,
          hopCount: hopCount,
          tripTimeMs: tripTimeMs,
          successIncrement: successIncrement,
          maxWeight: maxWeight,
        );
      });
      return;
    }

    final existing = _findPathRecord(contactPubKeyHex, pathBytes);
    final successCount = (existing?.successCount ?? 0) + 1;
    final failureCount = existing?.failureCount ?? 0;

    final currentWeight = existing?.routeWeight ?? 1.0;
    final newWeight = (currentWeight + successIncrement).clamp(0.0, maxWeight);

    debugPrint(
      'Flood path attribution: crediting path [${pathBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(',')}] '
      'for $contactPubKeyHex (weight $currentWeight → $newWeight)',
    );

    _addPathRecord(
      contactPubKeyHex: contactPubKeyHex,
      hopCount: hopCount,
      tripTimeMs: tripTimeMs ?? existing?.tripTimeMs ?? 0,
      wasFloodDiscovery: true,
      pathBytes: pathBytes,
      successCount: successCount,
      failureCount: failureCount,
      routeWeight: newWeight,
      timestamp: DateTime.now(),
    );
  }

  void recordPathResult(
    String contactPubKeyHex,
    PathSelection selection, {
    required bool success,
    int? tripTimeMs,
    double successIncrement = 0.5,
    double failureDecrement = 0.5,
    double maxWeight = 5.0,
  }) {
    if (selection.useFlood) {
      final stats = _floodStats.putIfAbsent(
        contactPubKeyHex,
        () => _FloodStats(),
      );
      if (success) {
        stats.successCount += 1;
        if (tripTimeMs != null) stats.lastTripTimeMs = tripTimeMs;
      } else {
        stats.failureCount += 1;
      }
      stats.lastUsed = DateTime.now();
      return;
    }

    if (!_cache.containsKey(contactPubKeyHex)) {
      _ensureLoaded(contactPubKeyHex).then((_) {
        if (!_cache.containsKey(contactPubKeyHex)) return;
        recordPathResult(
          contactPubKeyHex,
          selection,
          success: success,
          tripTimeMs: tripTimeMs,
          successIncrement: successIncrement,
          failureDecrement: failureDecrement,
          maxWeight: maxWeight,
        );
      });
      return;
    }

    final existing = _findPathRecord(contactPubKeyHex, selection.pathBytes);
    final successCount = (existing?.successCount ?? 0) + (success ? 1 : 0);
    final failureCount = (existing?.failureCount ?? 0) + (success ? 0 : 1);

    final currentWeight = existing?.routeWeight ?? 1.0;
    double newWeight;
    if (success) {
      newWeight = (currentWeight + successIncrement).clamp(0.0, maxWeight);
    } else {
      newWeight = currentWeight - failureDecrement;
      if (newWeight <= 0 && failureCount >= 3) {
        removePathRecord(contactPubKeyHex, selection.pathBytes);
        return;
      }
      // Keep the record with a small floor weight until we have enough evidence
      newWeight = newWeight.clamp(0.1, maxWeight);
    }

    _addPathRecord(
      contactPubKeyHex: contactPubKeyHex,
      hopCount: selection.hopCount,
      tripTimeMs: success ? (tripTimeMs ?? 0) : (existing?.tripTimeMs ?? 0),
      wasFloodDiscovery: existing?.wasFloodDiscovery ?? false,
      pathBytes: selection.pathBytes,
      successCount: successCount,
      failureCount: failureCount,
      routeWeight: newWeight,
      timestamp: success ? DateTime.now() : existing?.timestamp,
    );
  }

  PathSelection selectPathForAttempt(
    String contactPubKeyHex, {
    required int attemptIndex,
    required int maxRetries,
    List<PathSelection> recentSelections = const [],
  }) {
    if (maxRetries <= 0 || attemptIndex >= maxRetries - 1) {
      return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
    }

    final ranked = _getRankedPaths(contactPubKeyHex);
    if (ranked.isEmpty) {
      return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
    }

    _trackAccess(contactPubKeyHex);

    final recentPaths = recentSelections
        .where((selection) => !selection.useFlood)
        .map((selection) => selection.pathBytes)
        .toList();
    final candidates = recentPaths.isEmpty
        ? ranked
        : ranked
              .where(
                (path) => !recentPaths.any(
                  (recentPath) => _pathsEqual(path.pathBytes, recentPath),
                ),
              )
              .toList();
    final selected = candidates.isNotEmpty
        ? (recentPaths.isEmpty
              ? _selectRotatedCandidate(contactPubKeyHex, candidates)
              : candidates.first)
        : ranked.first;

    return PathSelection(
      pathBytes: selected.pathBytes,
      hopCount: selected.hopCount,
      useFlood: false,
    );
  }

  PathRecord _selectRotatedCandidate(
    String contactPubKeyHex,
    List<PathRecord> candidates,
  ) {
    if (candidates.length <= 1) {
      _autoRotationIndex[contactPubKeyHex] = 0;
      return candidates.first;
    }

    final currentIndex = _autoRotationIndex[contactPubKeyHex] ?? 0;
    final selectedIndex = currentIndex % candidates.length;
    _autoRotationIndex[contactPubKeyHex] =
        (selectedIndex + 1) % candidates.length;
    return candidates[selectedIndex];
  }

  void _addPathRecord({
    required String contactPubKeyHex,
    required int hopCount,
    required int tripTimeMs,
    required bool wasFloodDiscovery,
    required List<int> pathBytes,
    required int successCount,
    required int failureCount,
    double? routeWeight,
    double initialWeight = 1.0,
    DateTime? timestamp,
  }) {
    void add() => _addPathRecordInternal(
      contactPubKeyHex,
      hopCount,
      tripTimeMs,
      wasFloodDiscovery,
      pathBytes,
      successCount,
      failureCount,
      routeWeight,
      initialWeight,
      timestamp,
    );

    if (_cache.containsKey(contactPubKeyHex)) {
      add();
    } else {
      _ensureLoaded(contactPubKeyHex).then((_) => add());
    }
  }

  Future<void> _ensureLoaded(String contactPubKeyHex) {
    if (_cache.containsKey(contactPubKeyHex)) return Future.value();
    return _pendingLoads[contactPubKeyHex] ??=
        _loadHistoryFromStorage(contactPubKeyHex)
            .then((loaded) {
              _cache[contactPubKeyHex] ??=
                  loaded ??
                  ContactPathHistory(
                    contactPubKeyHex: contactPubKeyHex,
                    recentPaths: [],
                  );
              _trackAccess(contactPubKeyHex);
              _evictIfNeeded();
            })
            .whenComplete(() {
              _pendingLoads.remove(contactPubKeyHex);
            });
  }

  void _addPathRecordInternal(
    String contactPubKeyHex,
    int hopCount,
    int tripTimeMs,
    bool wasFloodDiscovery,
    List<int> pathBytes,
    int successCount,
    int failureCount,
    double? routeWeight,
    double initialWeight,
    DateTime? timestamp,
  ) {
    var history = _cache[contactPubKeyHex];
    if (history == null) return;
    _version++;

    final existing = _findPathRecord(contactPubKeyHex, pathBytes);
    if (existing != null) {
      successCount = successCount == 0 ? existing.successCount : successCount;
      failureCount = failureCount == 0 ? existing.failureCount : failureCount;
      if (tripTimeMs == 0) {
        tripTimeMs = existing.tripTimeMs;
      }
      wasFloodDiscovery = existing.wasFloodDiscovery || wasFloodDiscovery;
      timestamp ??= existing.timestamp;
    }
    routeWeight ??= existing?.routeWeight ?? initialWeight;

    final newRecord = PathRecord(
      hopCount: hopCount,
      tripTimeMs: tripTimeMs,
      timestamp: timestamp,
      wasFloodDiscovery: wasFloodDiscovery,
      pathBytes: pathBytes,
      successCount: successCount,
      failureCount: failureCount,
      routeWeight: routeWeight,
    );

    final updatedPaths = List<PathRecord>.from(history.recentPaths);

    updatedPaths.removeWhere((p) => _pathsEqual(p.pathBytes, pathBytes));

    if (existing == null && updatedPaths.length >= _maxHistoryEntries) {
      return;
    }

    updatedPaths.insert(0, newRecord);

    final updatedHistory = ContactPathHistory(
      contactPubKeyHex: contactPubKeyHex,
      recentPaths: updatedPaths,
    );

    _cache[contactPubKeyHex] = updatedHistory;
    _trackAccess(contactPubKeyHex);
    _evictIfNeeded();
    _storage.savePathHistory(contactPubKeyHex, updatedHistory);

    notifyListeners();
  }

  /// Whether this contact's history is in the in-memory cache.
  bool isCached(String contactPubKeyHex) =>
      _cache.containsKey(contactPubKeyHex);

  /// Paths already in memory, without loading from storage or changing the
  /// cache order. For bulk readers that must not churn the 50-contact cache.
  List<PathRecord> peekRecentPaths(String contactPubKeyHex) =>
      _cache[contactPubKeyHex]?.recentPaths ?? const [];

  /// Reads saved paths straight from storage without adding them to the
  /// cache, evicting anything, or notifying listeners.
  Future<List<PathRecord>> readStoredPaths(String contactPubKeyHex) async {
    final cached = _cache[contactPubKeyHex];
    if (cached != null) return cached.recentPaths;
    final stored = await _loadHistoryFromStorage(contactPubKeyHex);
    return stored?.recentPaths ?? const [];
  }

  List<PathRecord> getRecentPaths(String contactPubKeyHex) {
    final history = _cache[contactPubKeyHex];
    if (history != null) {
      _trackAccess(contactPubKeyHex);
      return history.recentPaths;
    }

    _ensureLoaded(contactPubKeyHex).then((_) {
      if (_cache[contactPubKeyHex]?.recentPaths.isNotEmpty ?? false) {
        _version++;
        notifyListeners();
      }
    });

    return [];
  }

  Future<ContactPathHistory?> _loadHistoryFromStorage(
    String contactPubKeyHex,
  ) async {
    return await _storage.loadPathHistory(contactPubKeyHex);
  }

  PathRecord? getFastestPath(String contactPubKeyHex) {
    final history = _cache[contactPubKeyHex];
    if (history != null) {
      _trackAccess(contactPubKeyHex);
    }
    return history?.fastest;
  }

  PathRecord? getMostRecentPath(String contactPubKeyHex) {
    final history = _cache[contactPubKeyHex];
    if (history != null) {
      _trackAccess(contactPubKeyHex);
    }
    return history?.mostRecent;
  }

  ({
    int successCount,
    int failureCount,
    int lastTripTimeMs,
    DateTime? lastUsed,
  })?
  getFloodStats(String contactPubKeyHex) {
    final stats = _floodStats[contactPubKeyHex];
    if (stats == null) return null;
    return (
      successCount: stats.successCount,
      failureCount: stats.failureCount,
      lastTripTimeMs: stats.lastTripTimeMs,
      lastUsed: stats.lastUsed,
    );
  }

  Future<void> clearPathHistory(String contactPubKeyHex) async {
    _cache.remove(contactPubKeyHex);
    _cacheAccessOrder.remove(contactPubKeyHex);
    _autoRotationIndex.remove(contactPubKeyHex);
    _floodStats.remove(contactPubKeyHex);
    await _storage.clearPathHistory(contactPubKeyHex);
    _version++;
    notifyListeners();
  }

  Future<void> removePathRecord(
    String contactPubKeyHex,
    List<int> pathBytes,
  ) async {
    final history = _cache[contactPubKeyHex];
    if (history == null) return;

    final updatedPaths = List<PathRecord>.from(history.recentPaths)
      ..removeWhere((p) => _pathsEqual(p.pathBytes, pathBytes));

    _cache[contactPubKeyHex] = ContactPathHistory(
      contactPubKeyHex: contactPubKeyHex,
      recentPaths: updatedPaths,
    );

    await _storage.savePathHistory(contactPubKeyHex, _cache[contactPubKeyHex]!);
    _version++;
    notifyListeners();
  }

  PathRecord? _findPathRecord(String contactPubKeyHex, List<int> pathBytes) {
    final history = _cache[contactPubKeyHex];
    if (history == null) return null;
    for (final record in history.recentPaths) {
      if (_pathsEqual(record.pathBytes, pathBytes)) {
        return record;
      }
    }
    return null;
  }

  List<PathRecord> _getRankedPaths(String contactPubKeyHex) {
    final history = _cache[contactPubKeyHex];
    if (history == null) return [];

    final ranked = List<PathRecord>.from(history.recentPaths)
      ..removeWhere((p) => p.pathBytes.isEmpty);
    final fastestTripMs = _getFastestKnownTripMs(ranked);
    final highestRouteWeight = _getHighestKnownRouteWeight(ranked);

    ranked.sort((a, b) {
      final scoreCompare =
          _scorePathRecord(
            b,
            fastestTripMs: fastestTripMs,
            highestRouteWeight: highestRouteWeight,
          ).compareTo(
            _scorePathRecord(
              a,
              fastestTripMs: fastestTripMs,
              highestRouteWeight: highestRouteWeight,
            ),
          );
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      if (a.routeWeight != b.routeWeight) {
        return b.routeWeight.compareTo(a.routeWeight);
      }
      final aTrip = a.tripTimeMs == 0 ? 999999 : a.tripTimeMs;
      final bTrip = b.tripTimeMs == 0 ? 999999 : b.tripTimeMs;
      if (aTrip != bTrip) return aTrip.compareTo(bTrip);
      final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return ranked;
  }

  int? _getFastestKnownTripMs(List<PathRecord> paths) {
    final knownTrips = paths
        .where((path) => path.tripTimeMs > 0)
        .map((path) => path.tripTimeMs)
        .toList();
    if (knownTrips.isEmpty) return null;
    return knownTrips.reduce((a, b) => a < b ? a : b);
  }

  double _getHighestKnownRouteWeight(List<PathRecord> paths) {
    if (paths.isEmpty) return 1.0;
    final highestWeight = paths
        .map((path) => path.routeWeight)
        .reduce((a, b) => a > b ? a : b);
    return highestWeight <= 0 ? 1.0 : highestWeight;
  }

  double _scorePathRecord(
    PathRecord path, {
    required int? fastestTripMs,
    required double highestRouteWeight,
  }) {
    final totalAttempts = path.successCount + path.failureCount;
    final reliability = (path.successCount + 1) / (totalAttempts + 2);
    final latency = fastestTripMs == null || path.tripTimeMs <= 0
        ? 0.6
        : (fastestTripMs / path.tripTimeMs).clamp(0.0, 1.0);
    final freshness = path.timestamp == null
        ? 0.0
        : 1.0 /
              (1.0 +
                  (DateTime.now().difference(path.timestamp!).inMinutes /
                      60.0 /
                      24.0));
    final routeWeight = (path.routeWeight / highestRouteWeight).clamp(0.0, 1.0);

    return (reliability * 0.45) +
        (latency * 0.25) +
        (freshness * 0.1) +
        (routeWeight * 0.2);
  }

  bool _pathsEqual(List<int> a, List<int> b) {
    return listEquals(a, b);
  }

  void _updateFloodStats(String contactPubKeyHex) {
    final stats = _floodStats.putIfAbsent(
      contactPubKeyHex,
      () => _FloodStats(),
    );
    stats.lastUsed = DateTime.now();
  }

  void _trackAccess(String contactPubKeyHex) {
    _cacheAccessOrder.remove(contactPubKeyHex);
    _cacheAccessOrder.add(contactPubKeyHex);
  }

  void _evictIfNeeded() {
    while (_cache.length > _maxCachedContacts && _cacheAccessOrder.isNotEmpty) {
      final oldest = _cacheAccessOrder.removeAt(0);
      _cache.remove(oldest);
      _autoRotationIndex.remove(oldest);
      _floodStats.remove(oldest);
    }
  }

  void clearAllHistories() {
    _cache.clear();
    _cacheAccessOrder.clear();
    _autoRotationIndex.clear();
    _floodStats.clear();
    _storage.clearAllPathHistories();
    _version = 0;
    notifyListeners();
  }
}

class _FloodStats {
  int successCount = 0;
  int failureCount = 0;
  int lastTripTimeMs = 0;
  DateTime? lastUsed;
}
