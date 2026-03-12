import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';

void main() {
  group('normalizeTimeoutCodingRate', () {
    test('keeps valid LoRa coding rates as-is', () {
      expect(normalizeTimeoutCodingRate(5), 5);
      expect(normalizeTimeoutCodingRate(8), 8);
    });

    test('converts firmware compact coding rates into LoRa values', () {
      expect(normalizeTimeoutCodingRate(1), 5);
      expect(normalizeTimeoutCodingRate(4), 8);
    });

    test('rejects invalid coding rates', () {
      expect(normalizeTimeoutCodingRate(0), isNull);
      expect(normalizeTimeoutCodingRate(9), isNull);
      expect(normalizeTimeoutCodingRate(null), isNull);
    });
  });
}
