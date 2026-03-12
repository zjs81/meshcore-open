import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('hex2Uint8List', () {
    test('decodes uppercase hex', () {
      expect(hex2Uint8List('A0FF'), orderedEquals(<int>[0xA0, 0xFF]));
    });

    test('decodes lowercase hex', () {
      expect(hex2Uint8List('a0ff'), orderedEquals(<int>[0xA0, 0xFF]));
    });

    test('rejects empty hex strings', () {
      expect(
        () => hex2Uint8List(''),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects odd-length hex strings', () {
      expect(
        () => hex2Uint8List('ABC'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('integer readers', () {
    test('readUint16LE parses little-endian values', () {
      final data = Uint8List.fromList(<int>[0x34, 0x12]);

      expect(readUint16LE(data, 0), 0x1234);
    });

    test('readUint32LE parses little-endian values', () {
      final data = Uint8List.fromList(<int>[0x78, 0x56, 0x34, 0x12]);

      expect(readUint32LE(data, 0), 0x12345678);
    });

    test('readInt32LE parses negative values', () {
      final data = Uint8List.fromList(<int>[0xFF, 0xFF, 0xFF, 0xFF]);

      expect(readInt32LE(data, 0), -1);
    });
  });

  group('message size helpers', () {
    test('maxContactMessageBytes stays within protocol limits', () {
      expect(maxContactMessageBytes(), inInclusiveRange(0, maxTextPayloadBytes));
      expect(maxContactMessageBytes(), lessThan(maxFrameSize));
    });

    test('maxChannelMessageBytes shrinks for longer sender names', () {
      final shortName = maxChannelMessageBytes('ab');
      final longName = maxChannelMessageBytes('a' * 200);

      expect(longName, lessThanOrEqualTo(shortName));
      expect(longName, inInclusiveRange(0, maxTextPayloadBytes));
    });

    test('maxChannelMessageBytes treats null sender names conservatively', () {
      final withNull = maxChannelMessageBytes(null);
      final withShortName = maxChannelMessageBytes('ab');

      expect(withNull, lessThanOrEqualTo(withShortName));
    });

    test('maxChannelMessageBytes handles long multibyte names conservatively', () {
      final withAscii = maxChannelMessageBytes('abcdef');
      final withEmoji = maxChannelMessageBytes('😀' * 40);

      expect(withEmoji, lessThanOrEqualTo(withAscii));
      expect(withEmoji, inInclusiveRange(0, maxTextPayloadBytes));
    });
  });
}
