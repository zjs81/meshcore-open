import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/services/line_of_sight_service.dart';

void main() {
  List<LatLng> makePoints(int count) {
    return List<LatLng>.generate(count, (i) => LatLng(0, i * 0.00001));
  }

  test('computeFromElevations reports clear LOS on flat terrain', () {
    final points = makePoints(21);
    final elevations = List<double>.filled(points.length, 100);

    final result = LineOfSightService.computeFromElevations(
      points: points,
      elevations: elevations,
      startAntennaHeightMeters: 2,
      endAntennaHeightMeters: 2,
      kFactor: 4.0 / 3.0,
    );

    expect(result.hasData, isTrue);
    expect(result.isClear, isTrue);
    expect(result.maxObstructionMeters, equals(0));
    expect(result.firstObstructionDistanceMeters, isNull);
    expect(result.obstructions, isEmpty);
  });

  test(
    'computeFromElevations reports blocked LOS with central obstruction',
    () {
      final points = makePoints(21);
      final elevations = List<double>.filled(points.length, 100);
      elevations[10] = 300;

      final result = LineOfSightService.computeFromElevations(
        points: points,
        elevations: elevations,
        startAntennaHeightMeters: 1.5,
        endAntennaHeightMeters: 1.5,
        kFactor: 4.0 / 3.0,
      );

      expect(result.hasData, isTrue);
      expect(result.isClear, isFalse);
      expect(result.maxObstructionMeters, greaterThan(0));
      expect(result.firstObstructionDistanceMeters, isNotNull);
      expect(result.obstructions, hasLength(1));
      expect(result.obstructions.single.sampleIndex, equals(10));
      expect(result.obstructions.single.point, equals(points[10]));
    },
  );

  test('computeFromElevations groups contiguous blocked samples', () {
    final points = makePoints(21);
    final elevations = List<double>.filled(points.length, 100);
    elevations[9] = 220;
    elevations[10] = 320;
    elevations[11] = 240;

    final result = LineOfSightService.computeFromElevations(
      points: points,
      elevations: elevations,
      startAntennaHeightMeters: 1.5,
      endAntennaHeightMeters: 1.5,
      kFactor: 4.0 / 3.0,
    );

    expect(result.obstructions, hasLength(1));
    expect(result.obstructions.single.sampleIndex, equals(10));
    expect(result.obstructions.single.obstructionMeters, greaterThan(0));
  });

  test('analyzePath summarizes clear and blocked segments', () async {
    final service = LineOfSightService(
      elevationDataSource: (points) async {
        final elevations = List<double?>.filled(points.length, 100);
        if (points.first.longitude > 0.00005) {
          elevations[elevations.length ~/ 2] = 300;
        }
        return elevations;
      },
    );

    final path = [
      const LatLng(0, 0),
      const LatLng(0, 0.0001),
      const LatLng(0, 0.0002),
    ];

    final result = await service.analyzePath(path);

    expect(result.segments.length, 2);
    expect(result.clearSegments, 1);
    expect(result.blockedSegments, 1);
    expect(result.unknownSegments, 0);
  });

  test('fetchElevations batches requests into chunks of 100 points', () async {
    final requestCounts = <int>[];
    final client = MockClient((request) async {
      final latCsv = request.url.queryParameters['latitude']!;
      final count = latCsv.split(',').length;
      requestCounts.add(count);
      return http.Response(
        jsonEncode({'elevation': List.filled(count, 100)}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = LineOfSightService(httpClient: client);

    final elevations = await service.fetchElevations(makePoints(250));

    expect(requestCounts, [100, 100, 50]);
    expect(elevations, everyElement(100.0));
    client.close();
  });
}
