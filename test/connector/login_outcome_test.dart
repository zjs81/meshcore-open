import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('parseLoginOutcome', () {
    test('accepts one-byte login success frame', () {
      final frame = Uint8List.fromList(<int>[pushCodeLoginSuccess]);

      expect(parseLoginOutcome(frame), isTrue);
    });

    test('accepts one-byte login fail frame', () {
      final frame = Uint8List.fromList(<int>[pushCodeLoginFail]);

      expect(parseLoginOutcome(frame), isFalse);
    });

    test('matches prefixed login frame for target', () {
      final prefix = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]);
      final frame = Uint8List.fromList(<int>[
        pushCodeLoginSuccess,
        0,
        ...prefix,
      ]);

      expect(parseLoginOutcome(frame, targetPrefix: prefix), isTrue);
    });

    test('ignores prefixed login frame for different target', () {
      final prefix = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]);
      final frame = Uint8List.fromList(<int>[
        pushCodeLoginSuccess,
        0,
        9,
        9,
        9,
        9,
        9,
        9,
      ]);

      expect(parseLoginOutcome(frame, targetPrefix: prefix), isNull);
    });
  });
}
