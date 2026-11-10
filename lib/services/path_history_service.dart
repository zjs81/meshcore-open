import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/path_history.dart';
import '../models/path_selection.dart';
import '../utils/app_logger.dart';
import '../utils/coalesced_writes.dart';
import 'route_chooser.dart';
import 'storage_service.dart';

class PathHistoryService extends ChangeNotifier {
  final StorageService _storage;
  final Map<String, ContactPathHistory> _cache = {};
  final Map<String, _FloodStats> _floodStats = {};
  final Map<String, Future<bool>> _pendingLoads = {};
  int _generation = 0;
  bool _disposed = false;
  Future<void> _clearing = Future<void>.value();
  // A path record lands for most received messages, so saves are batched.
  final CoalescedWrites _writes = CoalescedWrites(
    delay: const Duration(seconds: 5),
  );

  // LRU cache eviction tracking
  static const int _maxCachedContacts = 50;
  final List<String> _cacheAccessOrder = [];

  static const int _maxHistoryEntries = 100;

  /// A failing route is only deleted once it hasn't delivered for this long.
  static const Duration _forgetRouteAfter = Duration(days: 7);

  int _version = 0;
  int get version => _version;

  final math.Random _random;
  final DateTime Function() _now;

  /// [random] and [clock] are for tests: route picks are random by design.
  PathHistoryService(
    this._storage, {
    math.Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? math.Random(),
       _now = clock ?? DateTime.now;

  void setDevicePublicKey(String publicKeyHex) {
    if (_disposed) return;
    // Queued saves use the storage key on entry, so they still land under
    // the previous radio's key.
    unawaited(_writes.flush());
    _generation++;
    _pendingLoads.clear();
    _storage.setPublicKeyHex = publicKeyHex;
    _cache.clear();
    _cacheAccessOrder.clear();
    _floodStats.clear();
    _version++;
    notifyListeners();
  }

  Future<void> initialize() async {
    // Load cached path histories on startup if needed
  }

  void handlePathUpdated(Contact contact, {double initialWeight = 1.0}) {
    if (_disposed) return;
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
    if (_disposed) return;
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
    if (_disposed) return;
    // A flood answered directly credits the direct (zero-hop) path.
    if (hopCount < 0 || (pathBytes.isEmpty && hopCount != 0)) return;
    if (!_cache.containsKey(contactPubKeyHex)) {
      final generation = _generation;
      _ensureLoaded(contactPubKeyHex).then((loaded) {
        if (!loaded ||
            _disposed ||
            generation != _generation ||
            !_cache.containsKey(contactPubKeyHex)) {
          return;
        }
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
    final now = _now();
    final faded = addRouteResult(existing, success: true, now: now);

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
      timestamp: now,
      recentSuccess: faded.success,
      recentFailure: faded.failure,
      statsAt: now,
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
    if (_disposed) return;
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
      final generation = _generation;
      _ensureLoaded(contactPubKeyHex).then((loaded) {
        if (!loaded ||
            _disposed ||
            generation != _generation ||
            !_cache.containsKey(contactPubKeyHex)) {
          return;
        }
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
    final now = _now();
    final faded = addRouteResult(existing, success: success, now: now);

    final currentWeight = existing?.routeWeight ?? 1.0;
    double newWeight;
    if (success) {
      newWeight = (currentWeight + successIncrement).clamp(0.0, maxWeight);
    } else {
      newWeight = currentWeight - failureDecrement;
      // Faded stats already push a failing route out of use, and a repeater
      // that is down for a day comes back; only forget a route that keeps
      // failing and hasn't delivered in a week. Route weight is bookkeeping
      // only now and plays no part in this.
      final lastWorked = existing?.timestamp;
      final longDead =
          lastWorked == null || now.difference(lastWorked) > _forgetRouteAfter;
      if (failureCount >= 3 && longDead) {
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
      timestamp: success ? now : existing?.timestamp,
      recentSuccess: faded.success,
      recentFailure: faded.failure,
      statsAt: now,
    );
  }

  /// Route for one send attempt of a message to [contactPubKeyHex].
  ///
  /// The last attempt always floods. Otherwise a known route is drawn by
  /// Thompson sampling over faded delivery stats, weighted by how well it
  /// fits [context]; routes used for this message's recent attempts score
  /// lower so retries usually try something different.
  PathSelection selectPathForAttempt(
    String contactPubKeyHex, {
    required int attemptIndex,
    required int maxRetries,
    List<PathSelection> recentSelections = const [],
    RouteContext context = RouteContext.unknown,
  }) {
    if (maxRetries <= 0 || attemptIndex >= maxRetries - 1) {
      return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
    }

    final ranked = _getRankedPaths(contactPubKeyHex, context: context);
    if (ranked.isEmpty) {
      return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
    }

    _trackAccess(contactPubKeyHex);

    final recentPaths = recentSelections
        .where((selection) => !selection.useFlood)
        .map((selection) => selection.pathBytes)
        .toList();
    final selected = pickRoute(
      ranked,
      random: _random,
      now: _now(),
      context: context,
      triedThisMessage: (path) => recentPaths.any(
        (recentPath) => _pathsEqual(path.pathBytes, recentPath),
      ),
    );

    return PathSelection(
      pathBytes: selected.pathBytes,
      hopCount: selected.hopCount,
      useFlood: false,
    );
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
    double? recentSuccess,
    double? recentFailure,
    DateTime? statsAt,
  }) {
    if (_disposed) return;
    final generation = _generation;
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
      recentSuccess: recentSuccess,
      recentFailure: recentFailure,
      statsAt: statsAt,
    );

    if (_cache.containsKey(contactPubKeyHex)) {
      add();
    } else {
      _ensureLoaded(contactPubKeyHex).then((loaded) {
        if (loaded && !_disposed && generation == _generation) add();
      });
    }
  }

  Future<bool> _ensureLoaded(String contactPubKeyHex) {
    if (_disposed) return Future.value(false);
    if (_cache.containsKey(contactPubKeyHex)) return Future.value(true);
    final existing = _pendingLoads[contactPubKeyHex];
    if (existing != null) return existing;
    final generation = _generation;
    late final Future<bool> pending;
    pending = _loadHistoryFromStorage(contactPubKeyHex)
        .then((loaded) {
          if (_disposed ||
              generation != _generation ||
              !identical(_pendingLoads[contactPubKeyHex], pending)) {
            return false;
          }
          _cache[contactPubKeyHex] ??=
              loaded ??
              ContactPathHistory(
                contactPubKeyHex: contactPubKeyHex,
                recentPaths: [],
              );
          _trackAccess(contactPubKeyHex);
          _evictIfNeeded();
          return true;
        })
        .whenComplete(() {
          if (identical(_pendingLoads[contactPubKeyHex], pending)) {
            _pendingLoads.remove(contactPubKeyHex);
          }
        });
    _pendingLoads[contactPubKeyHex] = pending;
    return pending;
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
    DateTime? timestamp, {
    double? recentSuccess,
    double? recentFailure,
    DateTime? statsAt,
  }) {
    if (_disposed) return;
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
      if (recentSuccess == null) {
        // Not a result: keep the faded stats as they were.
        recentSuccess = existing.recentSuccess;
        recentFailure = existing.recentFailure;
        statsAt = existing.statsAt;
      }
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
      // A brand-new record starts with no faded results.
      recentSuccess: recentSuccess ?? 0,
      recentFailure: recentFailure ?? 0,
      statsAt: statsAt,
    );

    final updatedPaths = List<PathRecord>.from(history.recentPaths);

    updatedPaths.removeWhere((p) => _pathsEqual(p.pathBytes, pathBytes));

    // Make room by dropping the weakest path so new discoveries still land.
    if (existing == null && updatedPaths.length >= _maxHistoryEntries) {
      updatedPaths.remove(_lowestScoredPath(updatedPaths));
    }

    updatedPaths.insert(0, newRecord);

    final updatedHistory = ContactPathHistory(
      contactPubKeyHex: contactPubKeyHex,
      recentPaths: updatedPaths,
    );

    _cache[contactPubKeyHex] = updatedHistory;
    _trackAccess(contactPubKeyHex);
    _evictIfNeeded();
    // The snapshot is written, not the cache entry: the LRU may evict it
    // before the batch runs.
    _writes.schedule(
      contactPubKeyHex,
      () => _storage.savePathHistory(contactPubKeyHex, updatedHistory),
    );

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
    if (_disposed) return [];
    final cached = _cache[contactPubKeyHex];
    if (cached != null) return cached.recentPaths;
    final stored = await _loadHistoryFromStorage(contactPubKeyHex);
    return stored?.recentPaths ?? const [];
  }

  List<PathRecord> getRecentPaths(String contactPubKeyHex) {
    if (_disposed) return [];
    final history = _cache[contactPubKeyHex];
    if (history != null) {
      _trackAccess(contactPubKeyHex);
      return history.recentPaths;
    }

    final generation = _generation;
    _ensureLoaded(contactPubKeyHex).then((loaded) {
      if (!loaded || _disposed || generation != _generation) return;
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
    final generation = _generation;
    await _clearing;
    await _writes.flush();
    if (_disposed || generation != _generation) return null;
    final history = await _storage.loadPathHistory(contactPubKeyHex);
    return _disposed || generation != _generation ? null : history;
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

  /// Runs [clear] after earlier clears and queued saves. [_clearing] itself
  /// never fails, so one failed clear cannot break later loads and flushes;
  /// the returned future still reports the failure to its caller.
  Future<void> _queueClear(int generation, Future<void> Function() clear) {
    final previous = _clearing;
    final run = () async {
      await previous;
      await _writes.flush();
      if (_disposed || generation != _generation) return;
      await clear();
    }();
    _clearing = run.then<void>(
      (_) {},
      onError: (Object error, StackTrace _) {
        appLogger.warn('Clearing path history failed: $error', tag: 'Storage');
      },
    );
    return run;
  }

  Future<void> clearPathHistory(String contactPubKeyHex) async {
    if (_disposed) return;
    final generation = _generation;
    _pendingLoads.remove(contactPubKeyHex);
    _cache.remove(contactPubKeyHex);
    _cacheAccessOrder.remove(contactPubKeyHex);
    _floodStats.remove(contactPubKeyHex);
    _writes.cancel(contactPubKeyHex);
    await _queueClear(generation, () {
      return _storage.clearPathHistory(contactPubKeyHex);
    });
    if (_disposed || generation != _generation) return;
    _version++;
    notifyListeners();
  }

  Future<void> removePathRecord(
    String contactPubKeyHex,
    List<int> pathBytes,
  ) async {
    if (_disposed) return;
    final generation = _generation;
    final history = _cache[contactPubKeyHex];
    if (history == null) return;

    final updatedPaths = List<PathRecord>.from(history.recentPaths)
      ..removeWhere((p) => _pathsEqual(p.pathBytes, pathBytes));

    _cache[contactPubKeyHex] = ContactPathHistory(
      contactPubKeyHex: contactPubKeyHex,
      recentPaths: updatedPaths,
    );

    final updated = _cache[contactPubKeyHex]!;
    _writes.cancel(contactPubKeyHex);
    await _writes.flush();
    if (_disposed || generation != _generation) return;
    await _storage.savePathHistory(contactPubKeyHex, updated);
    if (_disposed || generation != _generation) return;
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

  List<PathRecord> _getRankedPaths(
    String contactPubKeyHex, {
    RouteContext context = RouteContext.unknown,
  }) {
    final history = _cache[contactPubKeyHex];
    if (history == null) return [];

    // Records without hop bytes are unusable, except the direct path: zero
    // hops has no bytes by definition (issue #643: rotation never tried it).
    final ranked = List<PathRecord>.from(history.recentPaths)
      ..removeWhere((p) => p.pathBytes.isEmpty && p.hopCount != 0);
    final now = _now();
    final fastest = fastestTripMs(ranked);
    final scores = {
      for (final p in ranked)
        p: routeExpectedScore(
          p,
          now: now,
          fastestTripMs: fastest,
          context: context,
        ),
    };

    ranked.sort((a, b) {
      final scoreCompare = scores[b]!.compareTo(scores[a]!);
      if (scoreCompare != 0) return scoreCompare;
      final aTrip = a.tripTimeMs == 0 ? 999999 : a.tripTimeMs;
      final bTrip = b.tripTimeMs == 0 ? 999999 : b.tripTimeMs;
      if (aTrip != bTrip) return aTrip.compareTo(bTrip);
      final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return ranked;
  }

  PathRecord _lowestScoredPath(List<PathRecord> paths) {
    final now = _now();
    final fastest = fastestTripMs(paths);
    double score(PathRecord p) =>
        routeExpectedScore(p, now: now, fastestTripMs: fastest);
    return paths.reduce((a, b) => score(b) < score(a) ? b : a);
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
      _floodStats.remove(oldest);
    }
  }

  /// Runs queued saves now, e.g. before the app is backgrounded.
  Future<void> flushPendingWrites() async {
    await _clearing;
    await _writes.flush();
  }

  @override
  void dispose() {
    if (_disposed) return;
    unawaited(_writes.flush());
    _disposed = true;
    _generation++;
    _pendingLoads.clear();
    _cache.clear();
    _cacheAccessOrder.clear();
    _floodStats.clear();
    super.dispose();
  }

  void clearAllHistories() {
    if (_disposed) return;
    final generation = ++_generation;
    _pendingLoads.clear();
    _cache.clear();
    _cacheAccessOrder.clear();
    _floodStats.clear();
    _writes.dispose();
    // Nothing awaits this one; _queueClear logs a failure.
    unawaited(
      _queueClear(
        generation,
        _storage.clearAllPathHistories,
      ).catchError((Object _) {}),
    );
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
