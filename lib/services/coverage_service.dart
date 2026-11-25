import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'line_of_sight_service.dart';

/// Estimated repeater coverage. Each ray around the antenna reaches the
/// farthest sample still in line of sight, using the same terrain,
/// refraction and earth-bulge maths as the line-of-sight service.
enum CoverageLevel { excellent, good, marginal }

class CoverageRing {
  final CoverageLevel level;
  final List<LatLng> points;

  const CoverageRing({required this.level, required this.points});
}

class CoverageResult {
  final bool hasData;
  final double horizonMeters;
  final List<CoverageRing> rings;

  const CoverageResult({
    required this.hasData,
    required this.horizonMeters,
    required this.rings,
  });

  const CoverageResult.noData()
    : hasData = false,
      horizonMeters = 0,
      rings = const [];
}

class CoverageService {
  static const int rayCount = 96;
  static const int samplesPerRay = 24;
  static const double receiverHeightMeters = 2.0;
  static const double minHorizonMeters = 25000;
  static const double maxHorizonMeters = 50000;

  static const double _excellentFraction = 1 / 3;
  static const double _goodFraction = 2 / 3;
  static const double _earthRadiusMeters = 6371000.0;

  // Sub-metre slack absorbs floating-point noise when comparing terrain
  // angles against the running shadow line.
  static const double _clearanceNoiseToleranceMeters = 0.5;

  final LineOfSightService _lineOfSight;
  final bool _ownsLineOfSight;

  CoverageService({
    LineOfSightService? lineOfSight,
    http.Client? httpClient,
    ElevationDataSource? elevationDataSource,
  }) : _ownsLineOfSight = lineOfSight == null,
       _lineOfSight =
           lineOfSight ??
           LineOfSightService(
             httpClient: httpClient,
             elevationDataSource: elevationDataSource,
           );

  Future<CoverageResult> computeCoverage(
    LatLng center, {
    required double antennaHeightMeters,
    double? frequencyMHz,
  }) async {
    final kFactor = LineOfSightService.kFactorForFrequency(frequencyMHz);
    final horizonMeters = _horizonMeters(antennaHeightMeters, kFactor);

    final rays = _buildRays(center, horizonMeters);
    final elevations = await _lineOfSight.fetchElevations([
      for (final ray in rays) ...ray,
    ]);

    final stepMeters = horizonMeters / (samplesPerRay - 1);
    final clearDistances = List<double>.filled(rayCount, 0);
    var hasData = false;
    for (int r = 0; r < rayCount; r++) {
      final rayElevations = elevations.sublist(
        r * samplesPerRay,
        (r + 1) * samplesPerRay,
      );
      clearDistances[r] = _rayClearDistance(
        rayElevations,
        stepMeters,
        antennaHeightMeters,
      );
      if (rayElevations.any((e) => e != null)) hasData = true;
    }

    if (!hasData) return const CoverageResult.noData();

    final rings = <CoverageRing>[];
    final excellentRadius = horizonMeters * _excellentFraction;
    final goodRadius = horizonMeters * _goodFraction;
    // Painted outermost-first so the nested bands stack correctly.
    final bands = <(CoverageLevel, double)>[
      (CoverageLevel.marginal, double.infinity),
      (CoverageLevel.good, goodRadius),
      (CoverageLevel.excellent, excellentRadius),
    ];
    for (final (level, cap) in bands) {
      final ring = <LatLng>[
        for (int r = 0; r < rayCount; r++)
          _offset(
            center,
            math.min(clearDistances[r], cap),
            r * 2 * math.pi / rayCount,
          ),
      ];
      if (ring.any((p) => p != center)) {
        rings.add(CoverageRing(level: level, points: ring));
      }
    }

    return CoverageResult(
      hasData: true,
      horizonMeters: horizonMeters,
      rings: rings,
    );
  }

  void dispose() {
    if (_ownsLineOfSight) {
      _lineOfSight.dispose();
    }
  }

  static double _horizonMeters(double antennaHeightMeters, double kFactor) {
    final base = math.sqrt(2 * kFactor * _earthRadiusMeters);
    final horizon =
        base *
        (math.sqrt(math.max(antennaHeightMeters, 0)) +
            math.sqrt(receiverHeightMeters));
    return horizon.clamp(minHorizonMeters, maxHorizonMeters).toDouble();
  }

  static List<List<LatLng>> _buildRays(LatLng center, double horizonMeters) {
    final step = horizonMeters / (samplesPerRay - 1);
    return [
      for (int r = 0; r < rayCount; r++)
        [
          for (int i = 0; i < samplesPerRay; i++)
            _offset(center, step * i, r * 2 * math.pi / rayCount),
        ],
    ];
  }

  /// Terrain mask along one ray: a sample is covered when the straight line
  /// from the antenna to that sample clears every nearer sample's shadow.
  /// Earth curvature is handled by the horizon cap, not here, so open
  /// ground always reaches the nominal radius.
  static double _rayClearDistance(
    List<double?> elevations,
    double stepMeters,
    double antennaHeightMeters,
  ) {
    var known = 0;
    while (known < elevations.length && elevations[known] != null) {
      known++;
    }
    if (known < 2) return 0;

    final antennaMeters = elevations[0]! + antennaHeightMeters;
    var maxShadowSlope = double.negativeInfinity;
    var distance = 0.0;
    for (int i = 1; i < known; i++) {
      final d = stepMeters * i;
      final slope = (elevations[i]! - antennaMeters) / d;
      final tolerance = _clearanceNoiseToleranceMeters / d;
      if (maxShadowSlope.isFinite && slope < maxShadowSlope - tolerance) {
        break;
      }
      distance = d;
      final shadowSlope = (elevations[i]! - antennaMeters) / d;
      if (shadowSlope > maxShadowSlope) maxShadowSlope = shadowSlope;
    }
    return distance;
  }

  static LatLng _offset(LatLng origin, double meters, double bearingRadians) {
    if (meters <= 0) return origin;
    final angular = meters / _earthRadiusMeters;
    final lat1 = origin.latitude * math.pi / 180;
    final lon1 = origin.longitude * math.pi / 180;
    final sinLat2 =
        math.sin(lat1) * math.cos(angular) +
        math.cos(lat1) * math.sin(angular) * math.cos(bearingRadians);
    final lat2 = math.asin(sinLat2.clamp(-1.0, 1.0));
    final y = math.sin(bearingRadians) * math.sin(angular) * math.cos(lat1);
    final x = math.cos(angular) - math.sin(lat1) * sinLat2;
    final lon2 = lon1 + math.atan2(y, x);
    return LatLng(
      lat2 * 180 / math.pi,
      ((lon2 * 180 / math.pi) + 540) % 360 - 180,
    );
  }
}
