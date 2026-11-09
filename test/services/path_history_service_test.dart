import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/path_history.dart';
import 'package:meshcore_open/models/path_selection.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';

// ---------------------------------------------------------------------------
// Fake storage — no SharedPreferences dependency, all in-memory.
// ---------------------------------------------------------------------------
class FakeStorageService extends StorageService {
  final Map<String, ContactPathHistory> _store = {};

  @override
  Future<void> savePathHistory(
    String contactPubKeyHex,
    ContactPathHistory history,
  ) async {
    _store[contactPubKeyHex] = history;
  }

  @override
  Future<ContactPathHistory?> loadPathHistory(String contactPubKeyHex) async {
    return _store[contactPubKeyHex];
  }

  @override
  Future<void> clearPathHistory(String contactPubKeyHex) async {
    _store.remove(contactPubKeyHex);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Build a minimal Contact with the given pubKeyHex, pathLength, and path.
///
/// [publicKeyHex] must be exactly 64 hex characters (32 bytes).
Contact _makeContact({
  required String publicKeyHex,
  int pathLength = -1,
  List<int> path = const [],
}) {
  assert(publicKeyHex.length == 64, 'publicKeyHex must be 64 chars');
  final bytes = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    bytes[i] = int.parse(publicKeyHex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return Contact(
    publicKey: bytes,
    name: 'Test',
    type: 1,
    pathLength: pathLength,
    path: Uint8List.fromList(path),
    lastSeen: DateTime.now(),
  );
}

/// A 64-char hex string derived from a short tag (padded with zeros).
String _hex(String tag) {
  // Convert tag to hex-safe characters, then pad
  final hexTag = tag.codeUnits
      .map((c) => c.toRadixString(16).padLeft(2, '0'))
      .join();
  return hexTag.padLeft(64, '0');
}

/// Flush the microtask / async queue so that deferred storage loads complete.
Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
}

/// Seed the service's cache for [pubKeyHex] by adding one path record and
/// waiting for the async storage-load path to complete.
///
/// Call this before making synchronous assertions on a contact that has never
/// been seen by the service.
Future<void> _seed(
  PathHistoryService svc,
  String pubKeyHex, {
  List<int> pathBytes = const [1],
  int hopCount = 1,
  double weight = 1.0,
}) async {
  final contact = _makeContact(
    publicKeyHex: pubKeyHex,
    pathLength: hopCount,
    path: pathBytes,
  );
  svc.handlePathUpdated(contact, initialWeight: weight);
  await _flush();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeStorageService storage;
  late PathHistoryService svc;

  setUp(() {
    storage = FakeStorageService();
    // Picks are random by design (Thompson sampling); seed for repeatability.
    svc = PathHistoryService(storage, random: math.Random(1));
  });

  /// How often each route is picked over [n] selections, keyed by hex bytes.
  Map<String, int> tally(
    String pubKey, {
    int n = 400,
    int attemptIndex = 0,
    List<PathSelection> recent = const [],
  }) {
    final counts = <String, int>{};
    for (var i = 0; i < n; i++) {
      final pick = svc.selectPathForAttempt(
        pubKey,
        attemptIndex: attemptIndex,
        maxRetries: 5,
        recentSelections: recent,
      );
      final key = pick.useFlood
          ? 'flood'
          : pick.pathBytes.map((b) => b.toRadixString(16)).join(',');
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  group('path selection', () {
    test('empty path history returns flood', () {
      const pubKey =
          '0000000000000000000000000000000000000000000000000000000000000001';
      final selection = svc.selectPathForAttempt(
        pubKey,
        attemptIndex: 0,
        maxRetries: 5,
      );
      expect(selection.useFlood, isTrue);
    });

    test('returns flood when maxRetries == 0', () {
      const pubKey =
          '0000000000000000000000000000000000000000000000000000000000000001';
      final selection = svc.selectPathForAttempt(
        pubKey,
        attemptIndex: 0,
        maxRetries: 0,
      );
      expect(selection.useFlood, isTrue);
    });

    test('single known path is used for non-final attempts', () async {
      final pubKey = _hex('aabb');
      await _seed(svc, pubKey, pathBytes: [0x01, 0x02], hopCount: 2);

      for (int i = 0; i < 4; i++) {
        final selection = svc.selectPathForAttempt(
          pubKey,
          attemptIndex: i,
          maxRetries: 5,
        );
        expect(
          selection.useFlood,
          isFalse,
          reason: 'attempt $i should be path',
        );
        expect(selection.pathBytes, equals([0x01, 0x02]));
      }
    });

    test('retries usually move to a different path', () async {
      final pubKey = _hex('rot1');
      await _seed(svc, pubKey, pathBytes: [0xAA], hopCount: 1, weight: 1.0);
      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0xBB], hopCount: 1, useFlood: false),
        success: true,
        successIncrement: 0.0,
      );
      await _flush();

      // After [0xBB] missed, the retry should mostly try [0xAA].
      final counts = tally(
        pubKey,
        attemptIndex: 1,
        recent: const [
          PathSelection(pathBytes: [0xBB], hopCount: 1, useFlood: false),
        ],
      );
      expect(counts['flood'], isNull);
      expect(counts['aa']!, greaterThan(counts['bb'] ?? 0));
    });

    test('a third retry favours the path not yet tried', () async {
      final pubKey = _hex('rot2');
      await _seed(svc, pubKey, pathBytes: [0xA1], hopCount: 1, weight: 3.0);
      for (final bytes in const [
        [0xB2],
        [0xC3],
      ]) {
        svc.recordPathResult(
          pubKey,
          PathSelection(pathBytes: bytes, hopCount: 1, useFlood: false),
          success: true,
        );
      }
      await _flush();

      final counts = tally(
        pubKey,
        attemptIndex: 2,
        recent: const [
          PathSelection(pathBytes: [0xB2], hopCount: 1, useFlood: false),
          PathSelection(pathBytes: [0xC3], hopCount: 1, useFlood: false),
        ],
      );
      // [0xA1] is untested (no results) yet still the most likely pick,
      // because both others just missed for this message.
      expect(counts['a1']!, greaterThan(counts['b2'] ?? 0));
      expect(counts['a1']!, greaterThan(counts['c3'] ?? 0));
    });

    test('first attempts favour the best path but still try others', () async {
      final pubKey = _hex('rot3');
      await _seed(svc, pubKey, pathBytes: [0xA1], hopCount: 1, weight: 4.0);
      for (var i = 0; i < 6; i++) {
        svc.recordPathResult(
          pubKey,
          const PathSelection(pathBytes: [0xB2], hopCount: 1, useFlood: false),
          success: true,
        );
      }
      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0xC3], hopCount: 1, useFlood: false),
        success: false,
      );
      await _flush();

      final counts = tally(pubKey);
      expect(counts['b2']!, greaterThan(counts['a1'] ?? 0));
      expect(counts['b2']!, greaterThan(counts['c3'] ?? 0));
      // Exploration: the untested path is still tried now and then.
      expect(counts['a1'] ?? 0, greaterThan(0));
    });

    // Issue #643: the direct path (zero hops, no bytes) must be a rotation
    // candidate alongside saved multi-hop routes.
    test('direct path is a candidate alongside other routes', () async {
      final pubKey = _hex('dir1');
      await _seed(svc, pubKey, pathBytes: const [], hopCount: 0, weight: 2.0);
      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0xA1], hopCount: 1, useFlood: false),
        success: true,
      );
      await _flush();

      final counts = tally(pubKey);
      expect(counts['flood'], isNull);
      expect(counts[''] ?? 0, greaterThan(0), reason: 'direct must be tried');
      expect(counts['a1'] ?? 0, greaterThan(0));
    });

    test('a lone direct path is used instead of flooding', () async {
      final pubKey = _hex('dir2');
      await _seed(svc, pubKey, pathBytes: const [], hopCount: 0);
      final pick = svc.selectPathForAttempt(
        pubKey,
        attemptIndex: 0,
        maxRetries: 5,
      );
      expect(pick.useFlood, isFalse);
      expect(pick.hopCount, 0);
    });

    test('resolvePathSelection keeps a direct auto selection', () {
      final contact = _makeContact(
        publicKeyHex: _hex('dir3'),
        pathLength: 2,
        path: const [0x01, 0x02],
      );
      final resolved = resolvePathSelection(
        contact,
        selection: const PathSelection(
          pathBytes: [],
          hopCount: 0,
          useFlood: false,
        ),
      );
      expect(resolved.useFlood, isFalse);
      expect(resolved.hopCount, 0);
      expect(resolved.pathBytes, isEmpty);
    });

    test('final attempt is always flood regardless of known paths', () async {
      final pubKey = _hex('ef01');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1);

      for (final retries in [1, 2, 5, 10]) {
        final lastAttempt = svc.selectPathForAttempt(
          pubKey,
          attemptIndex: retries - 1,
          maxRetries: retries,
        );
        expect(
          lastAttempt.useFlood,
          isTrue,
          reason: 'maxRetries=$retries: last attempt must be flood',
        );
      }
    });
  });

  group('path scoring', () {
    test('higher reliability beats higher route weight', () async {
      final pubKey = _hex('rank1');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 4.5);

      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x01], hopCount: 1, useFlood: false),
        success: false,
        failureDecrement: 0.1,
      );
      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x01], hopCount: 1, useFlood: false),
        success: false,
        failureDecrement: 0.1,
      );
      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x02], hopCount: 1, useFlood: false),
        success: true,
        successIncrement: 0.0,
      );
      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x02], hopCount: 1, useFlood: false),
        success: true,
        successIncrement: 0.0,
      );
      await _flush();

      final counts = tally(pubKey);
      expect(counts['2']!, greaterThan(counts['1'] ?? 0));
    });

    test('lower latency wins when reliability is tied', () async {
      final pubKey = _hex('rank2');
      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x10], hopCount: 1, useFlood: false),
        success: true,
        tripTimeMs: 1200,
        successIncrement: 0.0,
      );
      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x20], hopCount: 1, useFlood: false),
        success: true,
        tripTimeMs: 400,
        successIncrement: 0.0,
      );
      await _flush();

      final counts = tally(pubKey, n: 1000);
      expect(counts['20']!, greaterThan(counts['10'] ?? 0));
    });

    test('fresher path wins when reliability and latency are tied', () async {
      final pubKey = _hex('rank3');
      final oldTimestamp = DateTime.now().subtract(const Duration(days: 10));
      final newTimestamp = DateTime.now().subtract(const Duration(hours: 1));
      storage._store[pubKey] = ContactPathHistory(
        contactPubKeyHex: pubKey,
        recentPaths: [
          PathRecord(
            hopCount: 1,
            tripTimeMs: 900,
            timestamp: oldTimestamp,
            wasFloodDiscovery: false,
            pathBytes: const [0x01],
            successCount: 1,
            failureCount: 0,
            routeWeight: 1.0,
          ),
          PathRecord(
            hopCount: 1,
            tripTimeMs: 900,
            timestamp: newTimestamp,
            wasFloodDiscovery: false,
            pathBytes: const [0x02],
            successCount: 1,
            failureCount: 0,
            routeWeight: 1.0,
          ),
        ],
      );
      svc.getRecentPaths(pubKey);
      await _flush();

      final counts = tally(pubKey, n: 1000);
      expect(counts['2']!, greaterThan(counts['1'] ?? 0));
    });

    test('route weight alone does not decide between equal routes', () async {
      final pubKey = _hex('rank4');
      final sharedTimestamp = DateTime.now().subtract(
        const Duration(minutes: 30),
      );
      storage._store[pubKey] = ContactPathHistory(
        contactPubKeyHex: pubKey,
        recentPaths: [
          PathRecord(
            hopCount: 1,
            tripTimeMs: 750,
            timestamp: sharedTimestamp,
            wasFloodDiscovery: false,
            pathBytes: const [0x01],
            successCount: 1,
            failureCount: 0,
            routeWeight: 4.0,
          ),
          PathRecord(
            hopCount: 1,
            tripTimeMs: 750,
            timestamp: sharedTimestamp,
            wasFloodDiscovery: false,
            pathBytes: const [0x02],
            successCount: 1,
            failureCount: 0,
            routeWeight: 1.0,
          ),
        ],
      );
      svc.getRecentPaths(pubKey);
      await _flush();

      // Choice follows delivery results; weight only guards deletion.
      final counts = tally(pubKey, n: 1000);
      expect(counts['1']!, inInclusiveRange(350, 650));
    });
  });

  // -------------------------------------------------------------------------
  // Group 3: recordPathResult — weight adjustment
  // -------------------------------------------------------------------------
  group('recordPathResult weight adjustment', () {
    test('success increments weight by successIncrement', () async {
      final pubKey = _hex('w001');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 1.0);

      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x01], hopCount: 1, useFlood: false),
        success: true,
        successIncrement: 0.5,
      );
      await _flush();

      final paths = svc.getRecentPaths(pubKey);
      expect(paths, isNotEmpty);
      expect(paths.first.routeWeight, closeTo(1.5, 0.001));
      expect(paths.first.timestamp, isNotNull);
    });

    test('attempts do not set timestamp before first success', () async {
      final pubKey = _hex('w000');

      svc.recordPathAttempt(
        pubKey,
        const PathSelection(pathBytes: [0x01], hopCount: 1, useFlood: false),
      );
      await _flush();

      final paths = svc.getRecentPaths(pubKey);
      expect(paths, isNotEmpty);
      expect(paths.first.successCount, equals(0));
      expect(paths.first.timestamp, isNull);
    });

    test('failure preserves the last success timestamp', () async {
      final pubKey = _hex('w006');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 1.0);

      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x01], hopCount: 1, useFlood: false),
        success: true,
        successIncrement: 0.0,
      );
      await _flush();
      final successTimestamp = svc.getRecentPaths(pubKey).first.timestamp;

      await Future<void>.delayed(const Duration(milliseconds: 5));
      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x01], hopCount: 1, useFlood: false),
        success: false,
        failureDecrement: 0.1,
      );
      await _flush();

      final paths = svc.getRecentPaths(pubKey);
      expect(paths.first.timestamp, equals(successTimestamp));
    });

    test('success clamps at maxWeight', () async {
      final pubKey = _hex('w002');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 4.8);

      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x01], hopCount: 1, useFlood: false),
        success: true,
        successIncrement: 0.5,
        maxWeight: 5.0,
      );
      await _flush();

      final paths = svc.getRecentPaths(pubKey);
      expect(paths.first.routeWeight, closeTo(5.0, 0.001));
    });

    test('failure decrements weight', () async {
      final pubKey = _hex('w003');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 2.0);

      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [0x01], hopCount: 1, useFlood: false),
        success: false,
        failureDecrement: 0.5,
      );
      await _flush();

      final paths = svc.getRecentPaths(pubKey);
      expect(paths.first.routeWeight, closeTo(1.5, 0.001));
    });

    test('a route that delivered this week survives a run of failures', () {
      // e.g. a repeater down for a day: the route must still be there when
      // it comes back. Faded stats keep it out of use meanwhile.
      var clock = DateTime(2026, 11, 1);
      final timed = PathHistoryService(
        FakeStorageService(),
        random: math.Random(1),
        clock: () => clock,
      );
      final pubKey = _hex('w0a1');
      const route = PathSelection(
        pathBytes: [0x01],
        hopCount: 1,
        useFlood: false,
      );
      return () async {
        timed.getRecentPaths(pubKey);
        await _flush();
        timed.recordPathResult(pubKey, route, success: true);
        clock = clock.add(const Duration(days: 1));
        for (var i = 0; i < 6; i++) {
          timed.recordPathResult(
            pubKey,
            route,
            success: false,
            failureDecrement: 0.5,
          );
        }
        expect(timed.getRecentPaths(pubKey), hasLength(1));

        // A week without a delivery: the next failure removes it.
        clock = clock.add(const Duration(days: 8));
        timed.recordPathResult(
          pubKey,
          route,
          success: false,
          failureDecrement: 0.5,
        );
        expect(timed.getRecentPaths(pubKey), isEmpty);
      }();
    });

    test('failure to 0 removes the path', () async {
      final pubKey = _hex('w004');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 0.3);

      // The service requires failureCount >= 3 to remove a path
      for (int i = 0; i < 3; i++) {
        svc.recordPathResult(
          pubKey,
          const PathSelection(pathBytes: [0x01], hopCount: 1, useFlood: false),
          success: false,
          failureDecrement: 0.5, // 0.3 - 0.5 = -0.2 → remove
        );
      }
      await _flush();

      final paths = svc.getRecentPaths(pubKey);
      expect(
        paths.any((p) => p.pathBytes.length == 1 && p.pathBytes[0] == 0x01),
        isFalse,
        reason: 'path with weight <= 0 should have been removed',
      );
    });

    test(
      'flood result does not affect path records, updates floodStats',
      () async {
        final pubKey = _hex('w005');
        await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 1.0);

        final pathsBefore = svc.getRecentPaths(pubKey);
        final weightBefore = pathsBefore.first.routeWeight;

        svc.recordPathResult(
          pubKey,
          const PathSelection(pathBytes: [], hopCount: -1, useFlood: true),
          success: true,
          tripTimeMs: 1234,
        );
        await _flush();

        // Path records should be unchanged.
        final pathsAfter = svc.getRecentPaths(pubKey);
        expect(pathsAfter.first.routeWeight, equals(weightBefore));

        // Flood stats should be updated.
        final stats = svc.getFloodStats(pubKey);
        expect(stats, isNotNull);
        expect(stats!.successCount, equals(1));
        expect(stats.lastTripTimeMs, equals(1234));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Group 4: handlePathUpdated
  // -------------------------------------------------------------------------
  group('handlePathUpdated', () {
    test('full history evicts the weakest path for a new one', () async {
      final pubKey = _hex('full');
      for (int i = 0; i < 100; i++) {
        svc.handlePathUpdated(
          _makeContact(publicKeyHex: pubKey, pathLength: 2, path: [i, 0xEE]),
        );
        await _flush();
      }
      const weak = PathSelection(
        pathBytes: [7, 0xEE],
        hopCount: 2,
        useFlood: false,
      );
      svc.recordPathResult(pubKey, weak, success: false);
      svc.recordPathResult(pubKey, weak, success: false);

      svc.handlePathUpdated(
        _makeContact(publicKeyHex: pubKey, pathLength: 2, path: [0xFF, 0xEE]),
      );
      await _flush();

      final paths = svc.getRecentPaths(pubKey).map((p) => p.pathBytes);
      expect(paths, hasLength(100));
      expect(paths, contains(equals([0xFF, 0xEE])));
      expect(paths, isNot(contains(equals([7, 0xEE]))));
    });

    test(
      'pathLength >= 0 with path bytes → records path using pathLength',
      () async {
        final pubKey = _hex('h001');
        final contact = _makeContact(
          publicKeyHex: pubKey,
          pathLength: 3,
          path: [0x01, 0x02, 0x03],
        );

        svc.handlePathUpdated(contact);
        await _flush();

        final paths = svc.getRecentPaths(pubKey);
        expect(paths, isNotEmpty);
        expect(paths.first.hopCount, equals(3));
        expect(paths.first.pathBytes, equals([0x01, 0x02, 0x03]));
      },
    );

    test(
      'pathLength < 0 with path bytes → records path using path.length as hopCount',
      () async {
        final pubKey = _hex('h002');
        final contact = _makeContact(
          publicKeyHex: pubKey,
          pathLength: -1, // flood indicator from firmware
          path: [0xAA, 0xBB],
        );

        svc.handlePathUpdated(contact);
        await _flush();

        final paths = svc.getRecentPaths(pubKey);
        expect(paths, isNotEmpty);
        // hopCount should equal path.length (2), not pathLength (-1).
        expect(paths.first.hopCount, equals(2));
        expect(paths.first.pathBytes, equals([0xAA, 0xBB]));
      },
    );

    test('pathLength < 0 with empty path → skipped (returns early)', () async {
      final pubKey = _hex('h003');
      final contact = _makeContact(
        publicKeyHex: pubKey,
        pathLength: -1,
        path: [],
      );

      svc.handlePathUpdated(contact);
      await _flush();

      // Nothing should have been recorded.
      final paths = svc.getRecentPaths(pubKey);
      expect(paths, isEmpty);
    });

    test('initialWeight is applied to the new record', () async {
      final pubKey = _hex('h004');
      final contact = _makeContact(
        publicKeyHex: pubKey,
        pathLength: 1,
        path: [0x55],
      );

      svc.handlePathUpdated(contact, initialWeight: 2.5);
      await _flush();

      final paths = svc.getRecentPaths(pubKey);
      expect(paths.first.routeWeight, closeTo(2.5, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // Group 5: recordFloodPathAttribution
  // -------------------------------------------------------------------------
  group('recordFloodPathAttribution', () {
    test('credits existing path with success increment', () async {
      final pubKey = _hex('fa01');
      await _seed(
        svc,
        pubKey,
        pathBytes: [0x01, 0x02],
        hopCount: 2,
        weight: 1.0,
      );

      svc.recordFloodPathAttribution(
        contactPubKeyHex: pubKey,
        pathBytes: [0x01, 0x02],
        hopCount: 2,
        tripTimeMs: 3000,
        successIncrement: 0.5,
        maxWeight: 5.0,
      );
      await _flush();

      final paths = svc.getRecentPaths(pubKey);
      final credited = paths.firstWhere(
        (p) => p.pathBytes.length == 2 && p.pathBytes[0] == 0x01,
      );
      expect(credited.routeWeight, closeTo(1.5, 0.001));
      expect(credited.successCount, equals(1));
      expect(credited.tripTimeMs, equals(3000));
    });

    test('a flood answered directly credits the direct path', () async {
      final pubKey = _hex('fa0d');
      await _seed(svc, pubKey, pathBytes: [0xAA], hopCount: 1, weight: 1.0);

      svc.recordFloodPathAttribution(
        contactPubKeyHex: pubKey,
        pathBytes: const [],
        hopCount: 0,
        tripTimeMs: 800,
        successIncrement: 0.5,
        maxWeight: 5.0,
      );
      await _flush();

      final direct = svc
          .getRecentPaths(pubKey)
          .firstWhere((p) => p.pathBytes.isEmpty && p.hopCount == 0);
      expect(direct.successCount, 1);
      expect(direct.routeWeight, closeTo(1.5, 0.001));
    });

    test('creates new path record when path is unknown', () async {
      final pubKey = _hex('fa02');
      // Seed with a different path so the cache is warm.
      await _seed(svc, pubKey, pathBytes: [0xAA], hopCount: 1, weight: 1.0);

      svc.recordFloodPathAttribution(
        contactPubKeyHex: pubKey,
        pathBytes: [0xBB, 0xCC],
        hopCount: 2,
        tripTimeMs: 2000,
        successIncrement: 0.5,
        maxWeight: 5.0,
      );
      await _flush();

      final paths = svc.getRecentPaths(pubKey);
      final newPath = paths.firstWhere(
        (p) => p.pathBytes.length == 2 && p.pathBytes[0] == 0xBB,
      );
      // New path: weight = 1.0 (default) + 0.5 = 1.5
      expect(newPath.routeWeight, closeTo(1.5, 0.001));
      expect(newPath.successCount, equals(1));
      expect(newPath.wasFloodDiscovery, isTrue);
    });

    test('clamps weight at maxWeight', () async {
      final pubKey = _hex('fa03');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 4.8);

      svc.recordFloodPathAttribution(
        contactPubKeyHex: pubKey,
        pathBytes: [0x01],
        hopCount: 1,
        successIncrement: 0.5,
        maxWeight: 5.0,
      );
      await _flush();

      final paths = svc.getRecentPaths(pubKey);
      expect(paths.first.routeWeight, closeTo(5.0, 0.001));
    });

    test('ignores empty pathBytes for a multi-hop path', () async {
      final pubKey = _hex('fa04');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 1.0);

      final pathsBefore = svc.getRecentPaths(pubKey);
      final weightBefore = pathsBefore.first.routeWeight;

      // Hops without their bytes can't be replayed; only zero hops (the
      // direct path) may be recorded without bytes.
      svc.recordFloodPathAttribution(
        contactPubKeyHex: pubKey,
        pathBytes: [],
        hopCount: 2,
        successIncrement: 0.5,
        maxWeight: 5.0,
      );
      await _flush();

      // Existing path should be untouched and nothing new recorded.
      final pathsAfter = svc.getRecentPaths(pubKey);
      expect(pathsAfter, hasLength(1));
      expect(pathsAfter.first.routeWeight, equals(weightBefore));
    });

    test('ignores negative hopCount (flood indicator)', () async {
      final pubKey = _hex('fa05');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 1.0);

      final pathsBefore = svc.getRecentPaths(pubKey);
      final weightBefore = pathsBefore.first.routeWeight;

      svc.recordFloodPathAttribution(
        contactPubKeyHex: pubKey,
        pathBytes: [0x01],
        hopCount: -1,
        successIncrement: 0.5,
        maxWeight: 5.0,
      );
      await _flush();

      final pathsAfter = svc.getRecentPaths(pubKey);
      expect(pathsAfter.first.routeWeight, equals(weightBefore));
    });

    test('flood stats still recorded independently', () async {
      final pubKey = _hex('fa06');
      await _seed(svc, pubKey, pathBytes: [0x01], hopCount: 1, weight: 1.0);

      // Record a flood success (this updates flood stats).
      svc.recordPathResult(
        pubKey,
        const PathSelection(pathBytes: [], hopCount: -1, useFlood: true),
        success: true,
        tripTimeMs: 5000,
      );

      // Then attribute the flood success to a path.
      svc.recordFloodPathAttribution(
        contactPubKeyHex: pubKey,
        pathBytes: [0x01],
        hopCount: 1,
        tripTimeMs: 5000,
        successIncrement: 0.5,
        maxWeight: 5.0,
      );
      await _flush();

      // Both flood stats and path attribution should exist.
      final stats = svc.getFloodStats(pubKey);
      expect(stats, isNotNull);
      expect(stats!.successCount, equals(1));

      final paths = svc.getRecentPaths(pubKey);
      expect(paths.first.routeWeight, closeTo(1.5, 0.001));
    });
  });

  group('learned state is preserved', () {
    const sel = PathSelection(pathBytes: [0x01], hopCount: 1, useFlood: false);

    test('recordPathAttempt keeps the learned route weight', () async {
      final pubKey = _hex('k001');
      await _seed(svc, pubKey, pathBytes: [0x01], weight: 1.0);
      svc.recordPathResult(pubKey, sel, success: true, successIncrement: 1.0);
      await _flush();

      svc.recordPathAttempt(pubKey, sel);
      await _flush();

      expect(svc.getRecentPaths(pubKey).first.routeWeight, closeTo(2.0, 1e-9));
    });

    test('handlePathUpdated keeps the learned route weight', () async {
      final pubKey = _hex('k002');
      await _seed(svc, pubKey, pathBytes: [0x01], weight: 3.0);

      svc.handlePathUpdated(
        _makeContact(publicKeyHex: pubKey, pathLength: 1, path: [0x01]),
      );
      await _flush();

      expect(svc.getRecentPaths(pubKey).first.routeWeight, closeTo(3.0, 1e-9));
    });

    test('recordPathResult after eviction merges with stored counts', () async {
      final pubKey = _hex('k003');
      await _seed(svc, pubKey, pathBytes: [0x01], weight: 1.0);
      for (var i = 0; i < 3; i++) {
        svc.recordPathResult(pubKey, sel, success: true, successIncrement: 0.5);
      }
      await _flush();
      // Saves are batched; a restart only follows a flush (app backgrounded).
      await svc.flushPendingWrites();

      final fresh = PathHistoryService(storage);
      fresh.recordPathResult(pubKey, sel, success: true, successIncrement: 0.5);
      await _flush();

      final record = fresh.getRecentPaths(pubKey).first;
      expect(record.successCount, equals(4));
      expect(record.routeWeight, closeTo(3.0, 1e-9));
    });

    test('getRecentPaths load does not drop a concurrent add', () async {
      final pubKey = _hex('k004');
      await _seed(svc, pubKey, pathBytes: [0x01], weight: 1.0);
      await svc.flushPendingWrites();

      final fresh = PathHistoryService(storage);
      fresh.getRecentPaths(pubKey);
      fresh.handlePathUpdated(
        _makeContact(publicKeyHex: pubKey, pathLength: 1, path: [0x02]),
      );
      await _flush();

      final paths = fresh.getRecentPaths(pubKey).map((p) => p.pathBytes);
      expect(
        paths,
        containsAll([
          [0x01],
          [0x02],
        ]),
      );
    });
  });
}
