import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/delivery_observation.dart';
import 'package:meshcore_open/services/timeout_prediction_service.dart';

void main() {
  late TimeoutPredictionService service;

  setUp(() {
    service = TimeoutPredictionService.noStorage();
  });

  test('trains on sample data and predicts sensible timeouts', () {
    // Simulate realistic delivery data:
    // Direct 0-hop messages: ~1500-2500ms
    // 2-hop messages: ~4000-6000ms
    // 4-hop messages: ~8000-12000ms
    // Flood messages: ~3000-8000ms
    final sampleData = [
      // 0-hop direct
      _obs(pathLength: 0, messageBytes: 20, deliveryMs: 1800),
      _obs(pathLength: 0, messageBytes: 50, deliveryMs: 2100),
      _obs(pathLength: 0, messageBytes: 80, deliveryMs: 2400),
      _obs(pathLength: 0, messageBytes: 30, deliveryMs: 1925),
      // 2-hop direct
      _obs(pathLength: 2, messageBytes: 40, deliveryMs: 4500),
      _obs(pathLength: 2, messageBytes: 60, deliveryMs: 5200),
      _obs(pathLength: 2, messageBytes: 25, deliveryMs: 4100),
      // 4-hop direct
      _obs(pathLength: 4, messageBytes: 50, deliveryMs: 9800),
      _obs(pathLength: 4, messageBytes: 30, deliveryMs: 8500),
      _obs(pathLength: 4, messageBytes: 70, deliveryMs: 10570),
      // Flood
      _obs(pathLength: -1, messageBytes: 40, deliveryMs: 5000),
      _obs(pathLength: -1, messageBytes: 60, deliveryMs: 6500),
    ];

    // Feed all observations
    for (final obs in sampleData) {
      service.recordObservation(
        contactKey: obs.contactKey,
        pathLength: obs.pathLength,
        messageBytes: obs.messageBytes,
        tripTimeMs: obs.deliveryMs,
      );
    }

    expect(service.hasModel, isTrue);
    expect(service.observationCount, equals(12));

    // Predict for different scenarios
    final direct0 = service.predictTimeout(pathLength: 0, messageBytes: 50);
    final direct2 = service.predictTimeout(pathLength: 2, messageBytes: 50);
    final direct4 = service.predictTimeout(pathLength: 4, messageBytes: 50);
    final flood = service.predictTimeout(pathLength: -1, messageBytes: 50);

    // All should return non-null (model is trained)
    expect(direct0, isNotNull);
    expect(direct2, isNotNull);
    expect(direct4, isNotNull);
    expect(flood, isNotNull);

    // More hops should predict longer timeouts
    expect(direct4!, greaterThan(direct2!));
    expect(direct2, greaterThan(direct0!));

    // All should be positive
    expect(direct0, greaterThan(0));
    expect(direct4, greaterThan(0));

    // Print predictions for visibility
    debugPrint('Predictions (with 1.5x safety margin):');
    debugPrint('  0-hop direct: ${direct0}ms');
    debugPrint('  2-hop direct: ${direct2}ms');
    debugPrint('  4-hop direct: ${direct4}ms');
    debugPrint('  flood:        ${flood}ms');
  });

  test('returns null before minimum observations', () {
    for (var i = 0; i < TimeoutPredictionService.minObservations - 1; i++) {
      service.recordObservation(
        contactKey: 'abc',
        pathLength: 0,
        messageBytes: 50,
        tripTimeMs: 2000,
      );
    }

    expect(service.hasModel, isFalse);
    expect(service.predictTimeout(pathLength: 0, messageBytes: 50), isNull);
  });

  test('caps observations at maxObservations', () {
    for (var i = 0; i < TimeoutPredictionService.maxObservations + 20; i++) {
      service.recordObservation(
        contactKey: 'abc',
        pathLength: 0,
        messageBytes: 50,
        tripTimeMs: 2000 + i,
      );
    }

    expect(
      service.observationCount,
      equals(TimeoutPredictionService.maxObservations),
    );
  });

  test('blends per-contact stats after enough observations', () {
    // Train with mixed contacts and varied features:
    // contactA is fast (0-hop), contactB is slow (2-hop)
    for (var i = 0; i < 12; i++) {
      service.recordObservation(
        contactKey: 'contactA',
        pathLength: 0,
        messageBytes: 30 + i,
        tripTimeMs: 1500,
      );
      service.recordObservation(
        contactKey: 'contactB',
        pathLength: 2,
        messageBytes: 30 + i,
        tripTimeMs: 8000,
      );
    }

    final predA = service.predictTimeout(
      contactKey: 'contactA',
      pathLength: 0,
      messageBytes: 50,
    );
    final predB = service.predictTimeout(
      contactKey: 'contactB',
      pathLength: 0,
      messageBytes: 50,
    );

    expect(predA, isNotNull);
    expect(predB, isNotNull);
    // Contact B (slow) should have a higher predicted timeout than A (fast)
    expect(predB!, greaterThan(predA!));

    debugPrint('Per-contact blending:');
    debugPrint('  contactA (fast): ${predA}ms');
    debugPrint('  contactB (slow): ${predB}ms');
  });
}

DeliveryObservation _obs({
  required int pathLength,
  required int messageBytes,
  required int deliveryMs,
  String contactKey = 'test_contact',
}) {
  return DeliveryObservation(
    contactKey: contactKey,
    pathLength: pathLength,
    messageBytes: messageBytes,
    secondsSinceLastRx: 5,
    isFlood: pathLength < 0,
    deliveryMs: deliveryMs,
    timestamp: DateTime.now(),
  );
}
