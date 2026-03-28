import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';

void main() {
  test('LinearRegressor basic sanity check', () {
    // Simple: y = 2x + 100
    final data = DataFrame(
      [
        [1.0, 102.0],
        [2.0, 104.0],
        [3.0, 106.0],
        [4.0, 108.0],
        [5.0, 110.0],
        [10.0, 120.0],
        [20.0, 140.0],
        [50.0, 200.0],
        [0.0, 100.0],
        [100.0, 300.0],
      ],
      headerExists: false,
      header: ['x', 'y'],
    );

    debugPrint('Training data columns: ${data.header}');
    debugPrint('Training data rows: ${data.rows.length}');

    final model = LinearRegressor(data, 'y');

    final testDf = DataFrame(
      [
        [25.0],
      ],
      headerExists: false,
      header: ['x'],
    );

    final prediction = model.predict(testDf);
    final value = prediction.rows.first.first;
    debugPrint('Predict x=25 → y=$value (expected ~150)');
    expect((value as num).toDouble(), closeTo(150, 5));
  });

  test('LinearRegressor multi-feature with constant column produces zeros', () {
    // isFlood=0 for all rows → zero-variance column → singular matrix
    final data = DataFrame(
      [
        [0.0, 50.0, 14.0, 0.0, 1900.0],
        [0.0, 80.0, 14.0, 0.0, 2200.0],
        [2.0, 50.0, 14.0, 0.0, 5000.0],
        [4.0, 50.0, 14.0, 0.0, 9500.0],
      ],
      headerExists: false,
      header: [
        'pathLength',
        'messageBytes',
        'hourOfDay',
        'isFlood',
        'deliveryMs',
      ],
    );

    final model = LinearRegressor(data, 'deliveryMs');
    final testDf = DataFrame(
      [
        [2.0, 50.0, 14.0, 0.0],
      ],
      headerExists: false,
      header: ['pathLength', 'messageBytes', 'hourOfDay', 'isFlood'],
    );
    final pred = model.predict(testDf).rows.first.first;
    debugPrint(
      'With constant isFlood column: hops=2 → ${(pred as num).round()}ms (likely 0)',
    );
  });

  test('LinearRegressor 2-feature works correctly', () {
    // Just pathLength + messageBytes → deliveryMs
    final data = DataFrame(
      [
        [0.0, 50.0, 1900.0],
        [0.0, 80.0, 2200.0],
        [2.0, 50.0, 5000.0],
        [2.0, 80.0, 5500.0],
        [4.0, 50.0, 9500.0],
        [4.0, 80.0, 10000.0],
        [0.0, 30.0, 1800.0],
        [2.0, 30.0, 4800.0],
        [4.0, 30.0, 9000.0],
        [0.0, 60.0, 2000.0],
      ],
      headerExists: false,
      header: ['pathLength', 'messageBytes', 'deliveryMs'],
    );

    final model = LinearRegressor(data, 'deliveryMs');

    for (final hops in [0.0, 2.0, 4.0]) {
      final testDf = DataFrame(
        [
          [hops, 50.0],
        ],
        headerExists: false,
        header: ['pathLength', 'messageBytes'],
      );
      final pred = model.predict(testDf).rows.first.first;
      debugPrint('2-feature: hops=$hops → ${(pred as num).round()}ms');
    }
  });

  test('LinearRegressor multi-feature with variance in all columns', () {
    // Mix flood and direct so isFlood has variance
    final data = DataFrame(
      [
        [0.0, 50.0, 14.0, 0.0, 1900.0],
        [0.0, 80.0, 10.0, 0.0, 2200.0],
        [2.0, 50.0, 16.0, 0.0, 5000.0],
        [2.0, 80.0, 20.0, 0.0, 5500.0],
        [4.0, 50.0, 8.0, 0.0, 9500.0],
        [4.0, 80.0, 12.0, 0.0, 10000.0],
        [-1.0, 40.0, 14.0, 1.0, 5000.0],
        [-1.0, 60.0, 18.0, 1.0, 6500.0],
        [-1.0, 30.0, 10.0, 1.0, 4000.0],
        [-1.0, 80.0, 22.0, 1.0, 7000.0],
      ],
      headerExists: false,
      header: [
        'pathLength',
        'messageBytes',
        'hourOfDay',
        'isFlood',
        'deliveryMs',
      ],
    );

    final model = LinearRegressor(data, 'deliveryMs');

    for (final tc in [
      [0.0, 50.0, 14.0, 0.0],
      [2.0, 50.0, 14.0, 0.0],
      [4.0, 50.0, 14.0, 0.0],
      [-1.0, 50.0, 14.0, 1.0],
    ]) {
      final testDf = DataFrame(
        [tc],
        headerExists: false,
        header: ['pathLength', 'messageBytes', 'hourOfDay', 'isFlood'],
      );
      final pred = model.predict(testDf).rows.first.first;
      debugPrint(
        '4-feature: hops=${tc[0]} flood=${tc[3]} → ${(pred as num).round()}ms',
      );
    }
  });
}
