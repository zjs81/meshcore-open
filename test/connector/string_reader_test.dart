import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('readCString', () {
    test('returns empty string when offset is past the end of the buffer', () {
      final text = readCString(Uint8List.fromList(<int>[0x41, 0x42]), 5, 10);

      expect(text, isEmpty);
    });

    test('stops at the first null terminator within maxLen', () {
      final text = readCString(
        Uint8List.fromList(<int>[0x41, 0x42, 0x00, 0x43]),
        0,
        4,
      );

      expect(text, 'AB');
    });
  });
}
