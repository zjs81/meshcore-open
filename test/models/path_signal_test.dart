import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/channel_message.dart';

void main() {
  group('PathSignal.strongest', () {
    test('prefers higher SNR regardless of arrival order', () {
      final weak = PathSignal(snrDb: -5, rssiDbm: -120);
      final strong = PathSignal(snrDb: 12, rssiDbm: -90);
      expect(PathSignal.strongest([weak, strong]), same(strong));
      expect(PathSignal.strongest([strong, weak]), same(strong));
    });

    test('breaks SNR ties with RSSI', () {
      final quieter = PathSignal(snrDb: 8, rssiDbm: -110);
      final louder = PathSignal(snrDb: 8, rssiDbm: -70);
      expect(PathSignal.strongest([quieter, louder]), same(louder));
    });

    test('ranks a present measurement above a missing one', () {
      final rssiOnly = PathSignal(rssiDbm: -80);
      final none = PathSignal();
      expect(PathSignal.strongest([none, rssiOnly]), same(rssiOnly));
      expect(PathSignal.strongest([none]), same(none));
    });

    test('a measured SNR outranks an RSSI-only copy', () {
      final rssiOnly = PathSignal(rssiDbm: -80);
      final snrOnly = PathSignal(snrDb: -30);
      expect(PathSignal.strongest([rssiOnly, snrOnly]), same(snrOnly));
    });

    test('returns null for an empty iterable', () {
      expect(PathSignal.strongest([]), isNull);
    });
  });
}
