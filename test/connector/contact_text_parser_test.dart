import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('parseContactMessageText', () {
    test('parses a plain v3 contact message', () {
      final frame = Uint8List.fromList(<int>[
        respCodeContactMsgRecvV3,
        0,
        0,
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        0,
        txtTypePlain,
        0,
        0,
        0,
        0,
        ...'hello'.codeUnits,
        0,
      ]);

      final parsed = parseContactMessageText(frame);

      expect(parsed, isNotNull);
      expect(parsed!.senderPrefix, orderedEquals(<int>[1, 2, 3, 4, 5, 6]));
      expect(parsed.text, 'hello');
    });

    test('parses a cli contact message when type is stored in shifted bits', () {
      final frame = Uint8List.fromList(<int>[
        respCodeContactMsgRecv,
        1,
        2,
        3,
        4,
        5,
        6,
        0,
        txtTypeCliData << 2,
        0,
        0,
        0,
        0,
        ...'status'.codeUnits,
        0,
      ]);

      final parsed = parseContactMessageText(frame);

      expect(parsed, isNotNull);
      expect(parsed!.text, 'status');
    });

    test('falls back to the offset+4 text position for legacy frames', () {
      final frame = Uint8List.fromList(<int>[
        respCodeContactMsgRecv,
        1,
        2,
        3,
        4,
        5,
        6,
        0,
        txtTypePlain,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        ...'hello'.codeUnits,
        0,
      ]);

      final parsed = parseContactMessageText(frame);

      expect(parsed, isNotNull);
      expect(parsed!.text, 'hello');
    });

    test('rejects unknown text types', () {
      final frame = Uint8List.fromList(<int>[
        respCodeContactMsgRecv,
        1,
        2,
        3,
        4,
        5,
        6,
        0,
        0x7F,
        0,
        0,
        0,
        0,
        ...'hello'.codeUnits,
        0,
      ]);

      expect(parseContactMessageText(frame), isNull);
    });

    test('preserves leading and trailing spaces in the message text', () {
      final frame = Uint8List.fromList(<int>[
        respCodeContactMsgRecv,
        1,
        2,
        3,
        4,
        5,
        6,
        0,
        txtTypePlain,
        0,
        0,
        0,
        0,
        ...'  hello  '.codeUnits,
        0,
      ]);

      final parsed = parseContactMessageText(frame);

      expect(parsed, isNotNull);
      expect(parsed!.text, '  hello  ');
    });
  });
}
