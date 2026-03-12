import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/utils/login_response_parser.dart';

void main() {
  group('parseTerminalLoginResponse', () {
    test('ignores generic error frames', () {
      final frame = Uint8List.fromList(<int>[respCodeErr, 136]);
      final prefix = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]);

      expect(
        parseTerminalLoginResponse(frame, targetPrefix: prefix),
        isNull,
      );
    });

    test('accepts one-byte success frames', () {
      final frame = Uint8List.fromList(<int>[pushCodeLoginSuccess]);
      final prefix = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]);

      expect(
        parseTerminalLoginResponse(frame, targetPrefix: prefix),
        isTrue,
      );
    });

    test('accepts one-byte fail frames', () {
      final frame = Uint8List.fromList(<int>[pushCodeLoginFail]);
      final prefix = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]);

      expect(
        parseTerminalLoginResponse(frame, targetPrefix: prefix),
        isFalse,
      );
    });
  });
}
