import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/path_history.dart';
import 'package:meshcore_open/models/path_selection.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/route_chooser.dart';

import 'path_history_service_test.dart' show FakeStorageService;

final _now = DateTime(2026, 11, 8, 12);

PathRecord _route(
  List<int> bytes, {
  double success = 0,
  double failure = 0,
  DateTime? statsAt,
  int tripTimeMs = 0,
}) => PathRecord(
  hopCount: bytes.length,
  tripTimeMs: tripTimeMs,
  timestamp: null,
  wasFloodDiscovery: false,
  pathBytes: bytes,
  successCount: success.round(),
  failureCount: failure.round(),
  recentSuccess: success,
  recentFailure: failure,
  statsAt: statsAt ?? _now,
);

Map<List<int>, int> _tally(
  List<PathRecord> routes, {
  int draws = 2000,
  RouteContext context = RouteContext.unknown,
}) {
  final random = math.Random(42);
  final counts = {for (final r in routes) r.pathBytes: 0};
  for (var i = 0; i < draws; i++) {
    final pick = pickRoute(routes, random: random, now: _now, context: context);
    counts[pick.pathBytes] = counts[pick.pathBytes]! + 1;
  }
  return counts;
}

RouteContext _hearing(Set<int> firstHops, {bool contactDirect = false}) =>
    RouteContext(
      hasNeighbourInfo: true,
      contactHeardDirectly: contactDirect,
      firstHopHeard: (bytes, width) =>
          bytes.isNotEmpty && firstHops.contains(bytes.first),
    );

void main() {
  group('fading', () {
    test('results lose half their weight per half-life', () {
      expect(routeDecayFactor(_now, _now), 1.0);
      expect(
        routeDecayFactor(_now.subtract(routeStatsHalfLife), _now),
        closeTo(0.5, 1e-9),
      );
      expect(
        routeDecayFactor(_now.subtract(routeStatsHalfLife * 3), _now),
        closeTo(0.125, 1e-9),
      );
      expect(routeDecayFactor(null, _now), 1.0);
    });

    test('a new result is added on top of the faded old ones', () {
      final old = _route(
        [1],
        success: 4,
        failure: 2,
        statsAt: _now.subtract(routeStatsHalfLife),
      );
      final next = addRouteResult(old, success: false, now: _now);
      expect(next.success, closeTo(2, 1e-9));
      expect(next.failure, closeTo(2, 1e-9));
    });

    test('a route proven long ago ranks below one working today', () {
      final stale = _route(
        [1],
        success: 20,
        statsAt: _now.subtract(const Duration(days: 10)),
      );
      final fresh = _route([2], success: 3);
      double score(PathRecord r) =>
          routeExpectedScore(r, now: _now, fastestTripMs: null);
      expect(score(fresh), greaterThan(score(stale)));
    });

    test('history saved before fading existed seeds from capped counts', () {
      final legacy = PathRecord.fromJson({
        'hop_count': 1,
        'trip_time_ms': 0,
        'timestamp': _now.toIso8601String(),
        'was_flood': false,
        'path_bytes': [1],
        'success_count': 40,
        'failure_count': 1,
      });
      expect(legacy.recentSuccess, 5);
      expect(legacy.recentFailure, 1);
      expect(legacy.statsAt, _now);
    });
  });

  group('sampling', () {
    test('Beta samples average a / (a + b)', () {
      final random = math.Random(7);
      for (final (a, b) in [(1.0, 1.0), (8.0, 2.0), (0.6, 3.5)]) {
        var sum = 0.0;
        const n = 6000;
        for (var i = 0; i < n; i++) {
          final x = sampleBeta(random, a, b);
          expect(x, inInclusiveRange(0, 1));
          sum += x;
        }
        expect(sum / n, closeTo(a / (a + b), 0.02), reason: 'Beta($a, $b)');
      }
    });

    test('a proven route wins most picks but others still get tried', () {
      final strong = _route([1], success: 20, failure: 1);
      final weak = _route([2], success: 1, failure: 10);
      final unknown = _route([3]);
      final counts = _tally([strong, weak, unknown]);
      expect(counts[strong.pathBytes]!, greaterThan(1700));
      // Exploration: an untested route is still tried now and then.
      expect(counts[unknown.pathBytes]!, greaterThan(20));
      expect(counts[weak.pathBytes]!, lessThan(counts[unknown.pathBytes]!));
    });
  });

  group('context', () {
    test('a route whose first hop is heard beats an equal one that is not', () {
      final viaA = _route([0xA0, 0x10], success: 3, failure: 1);
      final viaB = _route([0xB0, 0x10], success: 3, failure: 1);
      final counts = _tally([viaA, viaB], context: _hearing({0xA0}));
      expect(counts[viaA.pathBytes]!, greaterThan(1300));
    });

    test('direct is preferred when the contact was heard directly', () {
      final direct = _route([], success: 3, failure: 1);
      final relayed = _route([0xA0], success: 3, failure: 1);
      final heard = _tally([
        direct,
        relayed,
      ], context: _hearing({0xA0}, contactDirect: true));
      final notHeard = _tally([direct, relayed], context: _hearing({0xA0}));
      expect(
        heard[direct.pathBytes]!,
        greaterThan(notHeard[direct.pathBytes]!),
      );
      expect(notHeard[relayed.pathBytes]!, greaterThan(1000));
    });

    test('with nothing heard, context changes nothing', () {
      final route = _route([0xA0], success: 1);
      expect(routeContextFactor(route, RouteContext.unknown), 1.0);
    });
  });

  // A tiny simulated mesh: each route delivers with a fixed probability.
  // Each message gets up to [maxRetries] attempts, the last one a flood.
  group('simulation', () {
    late PathHistoryService svc;
    late DateTime clock;
    const contact =
        '00000000000000000000000000000000000000000000000000000000000000aa';
    const maxRetries = 4;

    setUp(() async {
      clock = _now;
      svc = PathHistoryService(
        FakeStorageService(),
        random: math.Random(1),
        clock: () => clock,
      );
      svc.getRecentPaths(contact);
      await Future<void>.delayed(Duration.zero);
    });

    void seed(List<int> bytes) => svc.recordPathAttempt(
      contact,
      PathSelection(pathBytes: bytes, hopCount: bytes.length, useFlood: false),
    );

    /// Sends [messages] messages; returns the average number of route
    /// attempts before delivery (flood counts as one more).
    double run(
      int messages,
      double Function(List<int> bytes) deliveryRate, {
      RouteContext context = RouteContext.unknown,
      math.Random? rng,
    }) {
      final random = rng ?? math.Random(99);
      var attempts = 0;
      for (var m = 0; m < messages; m++) {
        clock = clock.add(const Duration(minutes: 10));
        final used = <PathSelection>[];
        for (var attempt = 0; attempt < maxRetries; attempt++) {
          attempts++;
          final pick = svc.selectPathForAttempt(
            contact,
            attemptIndex: attempt,
            maxRetries: maxRetries,
            recentSelections: used,
            context: context,
          );
          if (pick.useFlood) break; // flood always gets through here
          final ok = random.nextDouble() < deliveryRate(pick.pathBytes);
          svc.recordPathResult(contact, pick, success: ok);
          if (ok) break;
          used.add(pick);
        }
      }
      return attempts / messages;
    }

    test('settles on the reliable route', () {
      seed([0x01]);
      seed([0x02]);
      seed([0x03]);
      final rates = {0x01: 0.95, 0x02: 0.5, 0x03: 0.1};
      run(100, (b) => rates[b.first]!); // learn
      final avg = run(200, (b) => rates[b.first]!);
      expect(avg, lessThan(1.25));
    });

    test('moves off a route that stops working', () {
      seed([0x01]);
      seed([0x02]);
      var rates = {0x01: 0.95, 0x02: 0.8};
      run(100, (b) => rates[b.first]!);
      // The best repeater goes offline.
      rates = {0x01: 0.0, 0x02: 0.8};
      run(10, (b) => rates[b.first]!); // a few messages to notice
      final avg = run(100, (b) => rates[b.first]!);
      expect(avg, lessThan(1.5));
    });

    test('home and work routes follow what the radio hears', () {
      seed([0xA0, 0x10]); // via the home repeater
      seed([0xB0, 0x10]); // via the work repeater
      double homeRates(List<int> b) => b.first == 0xA0 ? 0.9 : 0.05;
      double workRates(List<int> b) => b.first == 0xB0 ? 0.9 : 0.05;

      run(60, homeRates, context: _hearing({0xA0}));
      final atWork = run(60, workRates, context: _hearing({0xB0}));
      final backHome = run(60, homeRates, context: _hearing({0xA0}));
      expect(atWork, lessThan(1.6));
      expect(backHome, lessThan(1.6));
    });
  });
}
