import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

typedef ElevationDataSource =
    Future<List<double?>> Function(List<LatLng> points);

class LineOfSightSample {
  final double distanceMeters;
  final double terrainMeters;
  final double lineHeightMeters;
  final double refractedHeightMeters;
  final double clearanceMeters;

  const LineOfSightSample({
    required this.distanceMeters,
    required this.terrainMeters,
    required this.lineHeightMeters,
    required this.refractedHeightMeters,
    required this.clearanceMeters,
  });
}

class LineOfSightObstruction {
  final int sampleIndex;
  final LatLng point;
  final double distanceMeters;
  final double clearanceMeters;
  final double obstructionMeters;
  final double terrainMeters;
  final double lineHeightMeters;

  const LineOfSightObstruction({
    required this.sampleIndex,
    required this.point,
    required this.distanceMeters,
    required this.clearanceMeters,
    required this.obstructionMeters,
    required this.terrainMeters,
    required this.lineHeightMeters,
  });
}

class LineOfSightResult {
  final bool hasData;
  final bool isClear;
  final double totalDistanceMeters;
  final double maxObstructionMeters;
  final double? firstObstructionDistanceMeters;
  final List<LineOfSightSample> samples;
  final List<LineOfSightObstruction> obstructions;
  final String? errorMessage;
  final double usedKFactor;
  final double? frequencyMHz;

  const LineOfSightResult({
    required this.hasData,
    required this.isClear,
    required this.totalDistanceMeters,
    required this.maxObstructionMeters,
    required this.firstObstructionDistanceMeters,
    required this.samples,
    required this.obstructions,
    required this.usedKFactor,
    this.frequencyMHz,
    this.errorMessage,
  });

  const LineOfSightResult.error({
    required this.totalDistanceMeters,
    required this.errorMessage,
    this.usedKFactor = 4.0 / 3.0,
    this.frequencyMHz,
  }) : hasData = false,
       isClear = false,
       maxObstructionMeters = 0,
       firstObstructionDistanceMeters = null,
       samples = const [],
       obstructions = const [];
}

class LineOfSightPathSegment {
  final int index;
  final LatLng start;
  final LatLng end;
  final LineOfSightResult result;

  const LineOfSightPathSegment({
    required this.index,
    required this.start,
    required this.end,
    required this.result,
  });
}

class LineOfSightPathResult {
  final List<LineOfSightPathSegment> segments;
  final int clearSegments;
  final int blockedSegments;
  final int unknownSegments;

  const LineOfSightPathResult({
    required this.segments,
    required this.clearSegments,
    required this.blockedSegments,
    required this.unknownSegments,
  });
}

class LineOfSightService {
  static const String errorElevationUnavailable =
      'los_error_elevation_unavailable';
  static const String errorInvalidInput = 'los_error_invalid_input';

  static const double _earthRadiusMeters = 6371000.0;
  static const Distance _distance = Distance();
  static const Duration _cacheTtl = Duration(hours: 24);
  static const int _maxFetchAttempts = 4; // initial try + 3 retries
  static const int _maxPointsPerElevationRequest = 100;
  static const int _maxConcurrentElevationRequests = 8;
  static const Duration _initialBackoff = Duration(milliseconds: 300);
  static const double _baselineFrequencyMHz = 915.0;
  static const double _baselineKFactor = 4.0 / 3.0;

  static double get baselineFrequencyMHz => _baselineFrequencyMHz;
  static double get baselineKFactor => _baselineKFactor;

  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final ElevationDataSource? _elevationDataSource;
  final Map<String, _CachedElevation> _elevationCache = {};

  LineOfSightService({
    http.Client? httpClient,
    ElevationDataSource? elevationDataSource,
  }) : _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null,
       _elevationDataSource = elevationDataSource;

  Future<LineOfSightPathResult> analyzePath(
    List<LatLng> points, {
    double startAntennaHeightMeters = 1.5,
    double endAntennaHeightMeters = 1.5,
    double? frequencyMHz,
    double obstructionToleranceMeters = 0.0,
  }) async {
    if (points.length < 2) {
      return const LineOfSightPathResult(
        segments: [],
        clearSegments: 0,
        blockedSegments: 0,
        unknownSegments: 0,
      );
    }

    final segments = <LineOfSightPathSegment>[];
    var clearSegments = 0;
    var blockedSegments = 0;
    var unknownSegments = 0;

    final kFactor = kFactorForFrequency(frequencyMHz);
    for (int i = 0; i < points.length - 1; i++) {
      final result = await analyzeLink(
        points[i],
        points[i + 1],
        startAntennaHeightMeters: startAntennaHeightMeters,
        endAntennaHeightMeters: endAntennaHeightMeters,
        kFactor: kFactor,
        frequencyMHz: frequencyMHz,
        obstructionToleranceMeters: obstructionToleranceMeters,
      );
      segments.add(
        LineOfSightPathSegment(
          index: i,
          start: points[i],
          end: points[i + 1],
          result: result,
        ),
      );

      if (!result.hasData) {
        unknownSegments++;
      } else if (result.isClear) {
        clearSegments++;
      } else {
        blockedSegments++;
      }
    }

    return LineOfSightPathResult(
      segments: segments,
      clearSegments: clearSegments,
      blockedSegments: blockedSegments,
      unknownSegments: unknownSegments,
    );
  }

  Future<LineOfSightResult> analyzeLink(
    LatLng start,
    LatLng end, {
    double startAntennaHeightMeters = 1.5,
    double endAntennaHeightMeters = 1.5,
    required double kFactor,
    double? frequencyMHz,
    double obstructionToleranceMeters = 0.0,
  }) async {
    final totalDistanceMeters = _distance.as(LengthUnit.Meter, start, end);
    if (totalDistanceMeters <= 1) {
      return LineOfSightResult(
        hasData: true,
        isClear: true,
        totalDistanceMeters: totalDistanceMeters,
        maxObstructionMeters: 0,
        firstObstructionDistanceMeters: null,
        samples: const [],
        obstructions: const [],
        usedKFactor: kFactor,
        frequencyMHz: frequencyMHz,
      );
    }

    final samplePoints = _buildSamplePoints(start, end, totalDistanceMeters);
    final elevations = await fetchElevations(samplePoints);

    if (elevations.any((e) => e == null)) {
      return LineOfSightResult.error(
        totalDistanceMeters: totalDistanceMeters,
        errorMessage: errorElevationUnavailable,
        usedKFactor: kFactor,
        frequencyMHz: frequencyMHz,
      );
    }

    return computeFromElevations(
      points: samplePoints,
      elevations: elevations.cast<double>(),
      startAntennaHeightMeters: startAntennaHeightMeters,
      endAntennaHeightMeters: endAntennaHeightMeters,
      kFactor: kFactor,
      frequencyMHz: frequencyMHz,
      obstructionToleranceMeters: obstructionToleranceMeters,
    );
  }

  static LineOfSightResult computeFromElevations({
    required List<LatLng> points,
    required List<double> elevations,
    double startAntennaHeightMeters = 1.5,
    double endAntennaHeightMeters = 1.5,
    required double kFactor,
    double? frequencyMHz,
    double obstructionToleranceMeters = 0.0,
  }) {
    if (points.length < 2 || elevations.length != points.length) {
      return LineOfSightResult.error(
        totalDistanceMeters: 0,
        errorMessage: errorInvalidInput,
        usedKFactor: kFactor,
        frequencyMHz: frequencyMHz,
      );
    }

    final totalDistanceMeters = _distance.as(
      LengthUnit.Meter,
      points.first,
      points.last,
    );
    final effectiveEarthRadius = _earthRadiusMeters * kFactor;
    final startLineHeight = elevations.first + startAntennaHeightMeters;
    final endLineHeight = elevations.last + endAntennaHeightMeters;

    var maxObstructionMeters = 0.0;
    double? firstObstructionDistanceMeters;
    final samples = <LineOfSightSample>[];
    final obstructions = <LineOfSightObstruction>[];
    var isClear = true;
    LineOfSightObstruction? clusterWorstObstruction;

    for (int i = 0; i < points.length; i++) {
      final fraction = points.length == 1 ? 0.0 : i / (points.length - 1);
      final distanceFromStart = totalDistanceMeters * fraction;
      final lineHeight =
          startLineHeight + (endLineHeight - startLineHeight) * fraction;

      final earthBulge =
          (distanceFromStart * (totalDistanceMeters - distanceFromStart)) /
          (2 * effectiveEarthRadius);
      final terrainHeight = elevations[i] + earthBulge;
      final clearance = lineHeight - terrainHeight;
      final unrefBulge =
          (distanceFromStart * (totalDistanceMeters - distanceFromStart)) /
          (2 * _earthRadiusMeters);
      final refractedHeight = lineHeight + (unrefBulge - earthBulge);

      if (clearance < -obstructionToleranceMeters) {
        isClear = false;
        final obstruction = -clearance;
        if (obstruction > maxObstructionMeters) {
          maxObstructionMeters = obstruction;
        }
        firstObstructionDistanceMeters ??= distanceFromStart;
        final candidate = LineOfSightObstruction(
          sampleIndex: i,
          point: points[i],
          distanceMeters: distanceFromStart,
          clearanceMeters: clearance,
          obstructionMeters: obstruction,
          terrainMeters: terrainHeight,
          lineHeightMeters: lineHeight,
        );
        if (clusterWorstObstruction == null ||
            candidate.obstructionMeters >
                clusterWorstObstruction.obstructionMeters) {
          clusterWorstObstruction = candidate;
        }
      } else if (clusterWorstObstruction != null) {
        obstructions.add(clusterWorstObstruction);
        clusterWorstObstruction = null;
      }

      samples.add(
        LineOfSightSample(
          distanceMeters: distanceFromStart,
          terrainMeters: terrainHeight,
          lineHeightMeters: lineHeight,
          refractedHeightMeters: refractedHeight,
          clearanceMeters: clearance,
        ),
      );
    }
    if (clusterWorstObstruction != null) {
      obstructions.add(clusterWorstObstruction);
    }

    return LineOfSightResult(
      hasData: true,
      isClear: isClear,
      totalDistanceMeters: totalDistanceMeters,
      maxObstructionMeters: maxObstructionMeters,
      firstObstructionDistanceMeters: firstObstructionDistanceMeters,
      samples: samples,
      obstructions: obstructions,
      usedKFactor: kFactor,
      frequencyMHz: frequencyMHz,
    );
  }

  static double kFactorForFrequency(double? frequencyMHz) {
    if (frequencyMHz == null) return _baselineKFactor;
    final delta =
        (frequencyMHz - _baselineFrequencyMHz) / _baselineFrequencyMHz;
    final adjustment = delta * 0.15;
    final scaled = _baselineKFactor * (1 + adjustment);
    return scaled.clamp(1.1, 1.6).toDouble();
  }

  List<LatLng> _buildSamplePoints(
    LatLng start,
    LatLng end,
    double distanceMeters,
  ) {
    final sampleCount = distanceMeters < 2000
        ? 21
        : distanceMeters < 10000
        ? 41
        : 81;

    final points = <LatLng>[];
    for (int i = 0; i < sampleCount; i++) {
      final t = i / (sampleCount - 1);
      points.add(
        LatLng(
          start.latitude + (end.latitude - start.latitude) * t,
          start.longitude + (end.longitude - start.longitude) * t,
        ),
      );
    }
    return points;
  }

  /// Fetches elevations for [points], serving cache hits (24 h TTL) and
  /// requesting the rest in chunks of at most [_maxPointsPerElevationRequest]
  /// because the upstream API rejects larger batches.
  Future<List<double?>> fetchElevations(List<LatLng> points) async {
    final dataSource = _elevationDataSource;
    if (dataSource != null) {
      return dataSource(points);
    }

    final uncached = <int, LatLng>{};
    final values = List<double?>.filled(points.length, null);
    for (int i = 0; i < points.length; i++) {
      final key = _cacheKey(points[i]);
      final cached = _readCachedValue(key);
      if (cached != null) {
        values[i] = cached;
      } else {
        uncached[i] = points[i];
      }
    }

    if (uncached.isEmpty) return values;

    final indices = uncached.keys.toList();
    final chunks = <Map<int, LatLng>>[];
    for (
      int start = 0;
      start < indices.length;
      start += _maxPointsPerElevationRequest
    ) {
      final end = min(start + _maxPointsPerElevationRequest, indices.length);
      chunks.add({
        for (final i in indices.sublist(start, end)) i: uncached[i]!,
      });
    }
    // Run chunks in parallel batches; sequential requests make a coverage
    // run take tens of seconds on a phone.
    for (
      int start = 0;
      start < chunks.length;
      start += _maxConcurrentElevationRequests
    ) {
      final end = min(start + _maxConcurrentElevationRequests, chunks.length);
      await Future.wait([
        for (final chunk in chunks.sublist(start, end))
          _fetchElevationChunk(chunk, points, values),
      ]);
    }
    return values;
  }

  Future<void> _fetchElevationChunk(
    Map<int, LatLng> uncached,
    List<LatLng> points,
    List<double?> values,
  ) async {
    final latCsv = uncached.values
        .map((p) => p.latitude.toStringAsFixed(6))
        .join(',');
    final lonCsv = uncached.values
        .map((p) => p.longitude.toStringAsFixed(6))
        .join(',');

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/elevation?latitude=$latCsv&longitude=$lonCsv',
    );

    final response = await _getWithBackoff(uri);
    if (response.statusCode != 200) {
      return;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final elevations = decoded['elevation'];
    if (elevations is! List) {
      return;
    }

    final indices = uncached.keys.toList();
    for (int i = 0; i < min(indices.length, elevations.length); i++) {
      final value = elevations[i];
      if (value is! num) continue;
      final index = indices[i];
      final elevation = value.toDouble();
      values[index] = elevation;
      _elevationCache[_cacheKey(points[index])] = _CachedElevation(
        value: elevation,
        expiresAt: DateTime.now().add(_cacheTtl),
      );
    }
  }

  Future<http.Response> _getWithBackoff(Uri uri) async {
    var attempt = 0;
    Duration backoff = _initialBackoff;

    while (true) {
      attempt++;
      try {
        final response = await _httpClient.get(uri);
        if (!_shouldRetryStatus(response.statusCode) ||
            attempt >= _maxFetchAttempts) {
          return response;
        }
      } catch (_) {
        if (attempt >= _maxFetchAttempts) rethrow;
      }

      await Future.delayed(backoff);
      backoff *= 2;
    }
  }

  bool _shouldRetryStatus(int statusCode) {
    return statusCode == 429 || statusCode >= 500;
  }

  double? _readCachedValue(String key) {
    final cached = _elevationCache[key];
    if (cached == null) return null;
    if (DateTime.now().isAfter(cached.expiresAt)) {
      _elevationCache.remove(key);
      return null;
    }
    return cached.value;
  }

  String _cacheKey(LatLng point) {
    return '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}

class _CachedElevation {
  final double value;
  final DateTime expiresAt;

  const _CachedElevation({required this.value, required this.expiresAt});
}
