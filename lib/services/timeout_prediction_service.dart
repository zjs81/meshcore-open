import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import '../models/delivery_observation.dart';
import 'storage_service.dart';

class _ContactStats {
  int count = 0;
  double _sum = 0;

  void add(double ms) {
    count++;
    _sum += ms;
  }

  double get mean => _sum / count;
}

class TimeoutPredictionService extends ChangeNotifier {
  final StorageService? _storage;

  static const int minObservations = 10;
  static const int maxObservations = 100;
  static const int _retrainInterval = 5;
  // 1.5x multiplier on raw prediction to account for variance in delivery
  // times — tight enough to improve on worst-case physics, loose enough
  // to avoid premature timeouts from model noise.
  static const double _safetyMargin = 1.5;
  static const int _minContactObservations = 10;

  List<DeliveryObservation> _observations = [];
  LinearRegressor? _model;
  List<String> _activeFeatures = [];
  int _observationsSinceLastTrain = 0;
  final Map<String, _ContactStats> _contactStats = {};
  Timer? _persistTimer;

  /// When true, [recordObservation] ignores new deliveries. Review mode sets
  /// this so the simulated radio's fixed ACK delay never trains the real model.
  static bool recordingSuspended = false;

  TimeoutPredictionService(StorageService storage) : _storage = storage;
  TimeoutPredictionService.noStorage() : _storage = null;

  int get observationCount => _observations.length;
  bool get hasModel => _model != null;

  Future<void> initialize() async {
    _observations = await _storage?.loadDeliveryObservations() ?? [];
    _rebuildContactStats();

    if (_observations.length >= minObservations) {
      _trainModel();
    }

    debugPrint(
      'TimeoutPrediction: initialized with ${_observations.length} observations, '
      'model=${_model != null ? "ready" : "waiting for data"}',
    );
  }

  void recordObservation({
    required String contactKey,
    required int pathLength,
    required int messageBytes,
    required int tripTimeMs,
  }) {
    if (recordingSuspended) return;
    final isFlood = pathLength < 0;
    final observation = DeliveryObservation(
      contactKey: contactKey,
      // Clamp to 0 for flood so the hop-count slope is learned from direct paths
      // only; isFlood carries the flood signal as a separate feature.
      pathLength: isFlood ? 0 : pathLength,
      messageBytes: messageBytes,
      isFlood: isFlood,
      deliveryMs: tripTimeMs,
      timestamp: DateTime.now(),
    );

    _observations.add(observation);
    if (_observations.length > maxObservations) {
      _observations.removeAt(0);
      _rebuildContactStats();
    } else {
      _contactStats.putIfAbsent(contactKey, () => _ContactStats());
      _contactStats[contactKey]!.add(tripTimeMs.toDouble());
    }

    _observationsSinceLastTrain++;
    if (_observationsSinceLastTrain >= _retrainInterval &&
        _observations.length >= minObservations) {
      _trainModel();
    }

    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 2), () {
      _storage?.saveDeliveryObservations(_observations);
    });
    debugPrint(
      'TimeoutPrediction: recorded ${tripTimeMs}ms for $pathLength hops '
      '(${_observations.length} total)',
    );
  }

  int? predictTimeout({
    String? contactKey,
    required int pathLength,
    required int messageBytes,
  }) {
    if (_model == null) return null;

    try {
      if (_activeFeatures.isEmpty) return null;

      final flood = pathLength < 0;
      final allFeatures = {
        // Clamp to 0 for flood — mirrors recordObservation so training and
        // prediction see the same pathLength values; isFlood carries the signal.
        'pathLength': flood ? 0.0 : pathLength.toDouble(),
        'messageBytes': messageBytes.toDouble(),
        'isFlood': flood ? 1.0 : 0.0,
      };
      final row = _activeFeatures.map((f) => allFeatures[f]!).toList();

      final features = DataFrame(
        [row],
        headerExists: false,
        header: _activeFeatures,
      );

      final prediction = _model!.predict(features);
      final rawValue = prediction.rows.first.first;
      var predictedMs = (rawValue is double)
          ? rawValue
          : (rawValue as num).toDouble();

      debugPrint(
        'TimeoutPrediction: raw prediction=$predictedMs for '
        'pathLength=$pathLength, messageBytes=$messageBytes, '
        'features=$_activeFeatures',
      );

      // Sanity check: if prediction is negative or zero, fall back
      if (predictedMs <= 0) return null;

      // Blend with per-contact mean if enough data
      if (contactKey != null) {
        final stats = _contactStats[contactKey];
        if (stats != null && stats.count >= _minContactObservations) {
          predictedMs = 0.5 * predictedMs + 0.5 * stats.mean;
        }
      }

      // Connector clamps this between physics min/max bounds
      final timeout = (predictedMs * _safetyMargin).ceil();
      debugPrint(
        'TimeoutPrediction: ML timeout ${timeout}ms '
        '(raw: ${predictedMs.round()}ms, contact: $contactKey)',
      );
      return timeout;
    } catch (e) {
      debugPrint('TimeoutPrediction: prediction failed: $e');
      return null;
    }
  }

  void _trainModel() {
    try {
      // Build feature columns, then exclude any with zero variance
      // (ml_algo's OLS produces all-zero coefficients for singular matrices)
      final allNames = ['pathLength', 'messageBytes', 'isFlood'];
      final allExtractors = <double Function(DeliveryObservation)>[
        // pathLength is already clamped to >=0 in recordObservation, but guard
        // here as well for any observations loaded from older persisted data.
        (o) => o.pathLength < 0 ? 0.0 : o.pathLength.toDouble(),
        (o) => o.messageBytes.toDouble(),
        (o) => o.isFlood ? 1.0 : 0.0,
      ];

      _activeFeatures = [];
      for (var i = 0; i < allNames.length; i++) {
        final values = _observations.map(allExtractors[i]).toSet();
        if (values.length > 1) _activeFeatures.add(allNames[i]);
      }

      if (_activeFeatures.isEmpty) {
        debugPrint(
          'TimeoutPrediction: no features with variance, skipping training',
        );
        return;
      }

      final header = [..._activeFeatures, 'deliveryMs'];
      final rows = _observations.map((o) {
        final row = <double>[];
        for (var i = 0; i < allNames.length; i++) {
          if (_activeFeatures.contains(allNames[i])) {
            row.add(allExtractors[i](o));
          }
        }
        row.add(o.deliveryMs.toDouble());
        return row;
      });

      final data = DataFrame([header, ...rows], headerExists: true);

      _model = LinearRegressor(data, 'deliveryMs');
      _observationsSinceLastTrain = 0;

      // Log training summary with sample predictions
      final avgMs =
          _observations.map((o) => o.deliveryMs).reduce((a, b) => a + b) /
          _observations.length;
      debugPrint(
        'TimeoutPrediction: trained on ${_observations.length} observations '
        '(avg: ${avgMs.round()}ms, features: $_activeFeatures)',
      );
    } catch (e) {
      debugPrint('TimeoutPrediction: training failed: $e');
    }
  }

  @override
  void dispose() {
    if (_persistTimer?.isActive == true) {
      _storage?.saveDeliveryObservations(_observations);
    }
    _persistTimer?.cancel();
    super.dispose();
  }

  void _rebuildContactStats() {
    _contactStats.clear();
    for (final obs in _observations) {
      _contactStats.putIfAbsent(obs.contactKey, () => _ContactStats());
      _contactStats[obs.contactKey]!.add(obs.deliveryMs.toDouble());
    }
  }
}
