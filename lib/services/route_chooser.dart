import 'dart:math' as math;

import '../models/path_history.dart';
import '../models/path_selection.dart';

/// Results lose half their weight every [routeStatsHalfLife], so a route's
/// recent behaviour outweighs what it did weeks ago.
const Duration routeStatsHalfLife = Duration(hours: 24);

/// Most results a route's faded stats hold. Fading is by time, so a route
/// used constantly would otherwise pile up so many successes that it takes
/// dozens of failures to lose its rank after its repeater dies; the cap
/// keeps it to a handful.
const double routeEvidenceCap = 16;

/// Multiplier for a route that fits what the radio hears right now (its
/// first hop, or the contact itself for the direct route, was heard).
const double routeContextFitBonus = 1.15;

/// Multiplier for a route that doesn't fit what the radio hears right now.
/// Soft on purpose: not hearing a repeater is weak evidence it's gone.
const double routeContextMissPenalty = 0.6;

/// Small bonus for the path the radio itself currently holds.
const double routeRadioPathBonus = 1.05;

/// Score multiplier for a route already tried for the same message: retries
/// lean toward something different without wasting the attempt on a route
/// much weaker than the one that just missed.
const double routeRetryRepeatPenalty = 0.5;

/// Share of the score that comes from speed; the rest is delivery odds.
const double _speedShare = 0.15;

/// Fraction of a result's weight left after the time from [since] to [now].
double routeDecayFactor(DateTime? since, DateTime now) {
  if (since == null) return 1.0;
  final seconds = now.difference(since).inSeconds;
  if (seconds <= 0) return 1.0;
  return math.pow(0.5, seconds / routeStatsHalfLife.inSeconds).toDouble();
}

/// [record]'s faded delivery and failure counts as of [now].
({double success, double failure}) fadedRouteStats(
  PathRecord record,
  DateTime now,
) {
  final f = routeDecayFactor(record.statsAt, now);
  return (success: record.recentSuccess * f, failure: record.recentFailure * f);
}

/// Faded counts after adding one result to [record] (or to a new route when
/// it is null) at [now].
({double success, double failure}) addRouteResult(
  PathRecord? record, {
  required bool success,
  required DateTime now,
}) {
  final faded = record == null
      ? (success: 0.0, failure: 0.0)
      : fadedRouteStats(record, now);
  var s = faded.success + (success ? 1 : 0);
  var f = faded.failure + (success ? 0 : 1);
  final total = s + f;
  if (total > routeEvidenceCap) {
    final scale = routeEvidenceCap / total;
    s *= scale;
    f *= scale;
  }
  return (success: s, failure: f);
}

/// How well [record] fits what the radio hears right now.
double routeContextFactor(PathRecord record, RouteContext context) {
  var factor = 1.0;
  final radioPath = context.radioPath;
  if (radioPath != null &&
      radioPath.length == record.pathBytes.length &&
      _sameBytes(radioPath, record.pathBytes)) {
    factor *= routeRadioPathBonus;
  }
  if (!context.hasNeighbourInfo) return factor;
  final fits = record.hopCount == 0
      ? context.contactHeardDirectly
      : context.firstHopHeard(record.pathBytes, record.hashWidth);
  return factor * (fits ? routeContextFitBonus : routeContextMissPenalty);
}

double _speedFactor(PathRecord record, int? fastestTripMs) {
  final speed = fastestTripMs == null || record.tripTimeMs <= 0
      ? 0.6
      : (fastestTripMs / record.tripTimeMs).clamp(0.0, 1.0);
  return (1 - _speedShare) + _speedShare * speed;
}

/// Fastest known trip time among [records], or null when none is known.
int? fastestTripMs(Iterable<PathRecord> records) {
  int? best;
  for (final r in records) {
    if (r.tripTimeMs > 0 && (best == null || r.tripTimeMs < best)) {
      best = r.tripTimeMs;
    }
  }
  return best;
}

/// Deterministic rank: expected delivery odds (faded), adjusted for speed
/// and context. Used for ordering lists and choosing what to evict.
double routeExpectedScore(
  PathRecord record, {
  required DateTime now,
  required int? fastestTripMs,
  RouteContext context = RouteContext.unknown,
}) {
  final stats = fadedRouteStats(record, now);
  final mean = (stats.success + 1) / (stats.success + stats.failure + 2);
  return mean *
      _speedFactor(record, fastestTripMs) *
      routeContextFactor(record, context);
}

/// Thompson sampling: draws plausible delivery odds for each route from what
/// is known about it and returns the route with the best draw. Proven routes
/// win most of the time; uncertain ones are still tried now and then, so a
/// route that starts working again gets noticed.
PathRecord pickRoute(
  List<PathRecord> candidates, {
  required math.Random random,
  required DateTime now,
  RouteContext context = RouteContext.unknown,
  bool Function(PathRecord record)? triedThisMessage,
}) {
  assert(candidates.isNotEmpty);
  final fastest = fastestTripMs(candidates);
  PathRecord? best;
  var bestScore = -1.0;
  for (final record in candidates) {
    final stats = fadedRouteStats(record, now);
    final draw = sampleBeta(random, stats.success + 1, stats.failure + 1);
    final score =
        draw *
        _speedFactor(record, fastest) *
        routeContextFactor(record, context) *
        (triedThisMessage?.call(record) == true
            ? routeRetryRepeatPenalty
            : 1.0);
    if (score > bestScore) {
      bestScore = score;
      best = record;
    }
  }
  return best!;
}

/// A sample from Beta([a], [b]), both > 0.
double sampleBeta(math.Random random, double a, double b) {
  final x = _sampleGamma(random, a);
  final y = _sampleGamma(random, b);
  final sum = x + y;
  return sum <= 0 ? 0.5 : x / sum;
}

/// Gamma(shape, 1) by Marsaglia–Tsang; shapes below 1 use the boost
/// Gamma(a) = Gamma(a + 1) * U^(1/a).
double _sampleGamma(math.Random random, double shape) {
  if (shape < 1) {
    final u = random.nextDouble();
    return _sampleGamma(random, shape + 1) * math.pow(u, 1 / shape);
  }
  final d = shape - 1 / 3;
  final c = 1 / math.sqrt(9 * d);
  while (true) {
    double x;
    double v;
    do {
      x = _sampleNormal(random);
      v = 1 + c * x;
    } while (v <= 0);
    v = v * v * v;
    final u = random.nextDouble();
    if (u < 1 - 0.0331 * x * x * x * x) return d * v;
    if (math.log(u) < 0.5 * x * x + d * (1 - v + math.log(v))) return d * v;
  }
}

double _sampleNormal(math.Random random) {
  // Box–Muller; 1 - nextDouble() avoids log(0).
  final u1 = 1 - random.nextDouble();
  final u2 = random.nextDouble();
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

bool _sameBytes(List<int> a, List<int> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
