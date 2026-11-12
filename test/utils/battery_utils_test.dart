import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/utils/battery_utils.dart';

void main() {
  group('battery utils', () {
    test('nmc range maps 3.0V to 0% and 4.2V to 100%', () {
      expect(estimateBatteryPercentFromVolts(3.0, 'nmc'), 0);
      expect(estimateBatteryPercentFromVolts(4.2, 'nmc'), 100);
    });

    test('lifepo4 range maps 2.6V to 0% and 3.65V to 100%', () {
      expect(estimateBatteryPercentFromVolts(2.6, 'lifepo4'), 0);
      expect(estimateBatteryPercentFromVolts(3.65, 'lifepo4'), 100);
    });

    test('unknown chemistry falls back to nmc mapping', () {
      expect(
        estimateBatteryPercentFromMillivolts(3600, 'unknown'),
        estimateBatteryPercentFromMillivolts(3600, 'nmc'),
      );
    });

    test('voltage at or below nominal cell voltage is one cell', () {
      expect(batteryCellCount(3600, 'nmc'), 1);
      expect(batteryCellCount(3800, 'nmc'), 1);
      expect(batteryCellCount(4200, 'nmc'), 1);
    });

    test('multi-cell packs resolve to the nearest plausible cell count', () {
      expect(batteryCellCount(7400, 'lipo'), 2);
      expect(batteryCellCount(8400, 'lipo'), 2);
      expect(batteryCellCount(6000, 'lipo'), 2);
      expect(batteryCellCount(12600, 'lipo'), 3);
      expect(batteryCellCount(16800, 'lipo'), 4);
      expect(batteryCellCount(14600, 'lifepo4'), 4);
    });

    test('percent is computed from the average cell voltage', () {
      final reading = batteryReadingFromMillivolts(8400, 'lipo');
      expect(reading.cellCount, 2);
      expect(reading.averageCellMillivolts, 4200);
      expect(reading.percent, 100);
    });

    test('mid-range 2S lipo maps to per-cell percent', () {
      final reading = batteryReadingFromMillivolts(8000, 'lipo');
      expect(reading.cellCount, 2);
      expect(reading.averageCellMillivolts, 4000);
      expect(reading.percent, 83);
    });

    test('single-cell readings match the single-cell estimate', () {
      expect(
        batteryReadingFromMillivolts(3600, 'nmc').percent,
        estimateBatteryPercentFromMillivolts(3600, 'nmc'),
      );
    });
  });
}
