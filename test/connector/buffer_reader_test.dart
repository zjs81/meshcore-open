import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('BufferReader.readCString', () {
    test('returns available text when maxLength exceeds remaining bytes', () {
      final reader = BufferReader(
        Uint8List.fromList(<int>[0x41, 0x42]),
      );

      final text = reader.readCString(10);

      expect(text, 'AB');
    });

    test('returns empty string for zero maxLength without advancing', () {
      final reader = BufferReader(
        Uint8List.fromList(<int>[0x41, 0x42, 0x43]),
      );

      final text = reader.readCString(0);

      expect(text, isEmpty);
      expect(reader.remaining, 3);
    });
  });

  group('BufferReader.readCStringGreedy', () {
    test('returns available text when maxLength exceeds remaining bytes', () {
      final reader = BufferReader(
        Uint8List.fromList(<int>[0x41, 0x42]),
      );

      final text = reader.readCStringGreedy(10);

      expect(text, 'AB');
    });
  });
}
