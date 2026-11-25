import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/services/coverage_service.dart';

void main() {
  const center = LatLng(45.5, -122.6);
  const distance = Distance();

  CoverageService flatService() => CoverageService(
    elevationDataSource: (points) async =>
        List<double?>.filled(points.length, 100),
  );

  test(
    'flat terrain coverage reaches the radio horizon on every bearing',
    () async {
      final result = await flatService().computeCoverage(
        center,
        antennaHeightMeters: 10,
        frequencyMHz: 915,
      );

      expect(result.hasData, isTrue);
      expect(result.horizonMeters, greaterThan(20000));
      expect(result.rings.map((ring) => ring.level).toList(), const [
        CoverageLevel.marginal,
        CoverageLevel.good,
        CoverageLevel.excellent,
      ]);

      final marginal = result.rings.first.points;
      expect(marginal.length, CoverageService.rayCount);
      for (final point in marginal) {
        expect(
          distance.as(LengthUnit.Meter, center, point),
          closeTo(result.horizonMeters, result.horizonMeters * 0.02),
        );
      }

      final excellent = result.rings.last.points;
      for (final point in excellent) {
        expect(
          distance.as(LengthUnit.Meter, center, point),
          closeTo(result.horizonMeters / 3, result.horizonMeters * 0.02),
        );
      }
    },
  );

  test('a ridge blocks coverage on bearings behind it only', () async {
    final service = CoverageService(
      elevationDataSource: (points) async => [
        for (final point in points)
          if (distance.as(LengthUnit.Meter, center, point) > 6000 &&
              point.latitude > center.latitude)
            2000.0
          else
            100.0,
      ],
    );

    final result = await service.computeCoverage(
      center,
      antennaHeightMeters: 10,
      frequencyMHz: 915,
    );

    expect(result.hasData, isTrue);
    final marginal = result.rings.first.points;
    // Bearing index 0 points due north into the ridge; the edge itself is
    // reachable, everything behind it is not.
    expect(
      distance.as(LengthUnit.Meter, center, marginal.first),
      lessThan(7000),
    );
    // Index 48 points due south, clear to the horizon.
    expect(
      distance.as(
        LengthUnit.Meter,
        center,
        marginal[CoverageService.rayCount ~/ 2],
      ),
      closeTo(result.horizonMeters, result.horizonMeters * 0.02),
    );
  });

  test('missing elevation data yields no coverage', () async {
    final service = CoverageService(
      elevationDataSource: (points) async =>
          List<double?>.filled(points.length, null),
    );

    final result = await service.computeCoverage(
      center,
      antennaHeightMeters: 10,
    );

    expect(result.hasData, isFalse);
    expect(result.rings, isEmpty);
  });

  test('horizon scales with antenna height and clamps at the cap', () async {
    final service = flatService();
    final low = await service.computeCoverage(center, antennaHeightMeters: 2);
    final high = await service.computeCoverage(
      center,
      antennaHeightMeters: 100,
    );
    final tallest = await service.computeCoverage(
      center,
      antennaHeightMeters: 122,
    );

    expect(low.horizonMeters, CoverageService.minHorizonMeters);
    expect(high.horizonMeters, greaterThan(low.horizonMeters));
    expect(
      high.horizonMeters,
      lessThanOrEqualTo(CoverageService.maxHorizonMeters),
    );
    expect(tallest.horizonMeters, CoverageService.maxHorizonMeters);
  });
}
