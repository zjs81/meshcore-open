import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('calculateLoRaAirtime', () {
    test('rejects negative payload sizes', () {
      expect(
        () => calculateLoRaAirtime(
          payloadBytes: -1,
          spreadingFactor: 7,
          bandwidthHz: 125000,
          codingRate: 5,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects invalid spreading factors', () {
      expect(
        () => calculateLoRaAirtime(
          payloadBytes: 10,
          spreadingFactor: 4,
          bandwidthHz: 125000,
          codingRate: 5,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects invalid bandwidths', () {
      expect(
        () => calculateLoRaAirtime(
          payloadBytes: 10,
          spreadingFactor: 7,
          bandwidthHz: 0,
          codingRate: 5,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects invalid coding rates', () {
      expect(
        () => calculateLoRaAirtime(
          payloadBytes: 10,
          spreadingFactor: 7,
          bandwidthHz: 125000,
          codingRate: 9,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects negative preamble symbol counts', () {
      expect(
        () => calculateLoRaAirtime(
          payloadBytes: 10,
          spreadingFactor: 7,
          bandwidthHz: 125000,
          codingRate: 5,
          preambleSymbols: -1,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('returns a positive airtime for valid params', () {
      final airtime = calculateLoRaAirtime(
        payloadBytes: 10,
        spreadingFactor: 7,
        bandwidthHz: 125000,
        codingRate: 5,
      );

      expect(airtime, greaterThan(0));
    });
  });

  group('calculateMessageTimeout', () {
    test('rejects invalid radio frequency', () {
      expect(
        () => calculateMessageTimeout(
          freqHz: 1,
          bwHz: 125000,
          sf: 7,
          cr: 5,
          pathLength: 0,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects negative message sizes', () {
      expect(
        () => calculateMessageTimeout(
          freqHz: 915000,
          bwHz: 125000,
          sf: 7,
          cr: 5,
          pathLength: 0,
          messageBytes: -1,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('rejects path lengths below the flood sentinel', () {
      expect(
        () => calculateMessageTimeout(
          freqHz: 915000,
          bwHz: 125000,
          sf: 7,
          cr: 5,
          pathLength: -2,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('uses longer timeout for flood mode than direct mode', () {
      final direct = calculateMessageTimeout(
        freqHz: 915000,
        bwHz: 125000,
        sf: 7,
        cr: 5,
        pathLength: 0,
      );
      final flood = calculateMessageTimeout(
        freqHz: 915000,
        bwHz: 125000,
        sf: 7,
        cr: 5,
        pathLength: -1,
      );

      expect(flood, greaterThan(direct));
    });

    test('increases routed timeout as path length grows', () {
      final oneHop = calculateMessageTimeout(
        freqHz: 915000,
        bwHz: 125000,
        sf: 7,
        cr: 5,
        pathLength: 0,
      );
      final threeHop = calculateMessageTimeout(
        freqHz: 915000,
        bwHz: 125000,
        sf: 7,
        cr: 5,
        pathLength: 2,
      );

      expect(threeHop, greaterThan(oneHop));
    });
  });
}
