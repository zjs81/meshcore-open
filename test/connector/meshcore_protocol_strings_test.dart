import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('utf8BoundaryLength', () {
    test('returns full length when it fits', () {
      expect(utf8BoundaryLength(utf8.encode('abc'), 31), 3);
    });

    test('never splits a multi-byte character', () {
      // 'é' is 2 bytes; 'a' + 15 × 'é' = 31 bytes, so 30 bytes cuts one.
      final bytes = utf8.encode('a${'é' * 15}');
      expect(utf8BoundaryLength(bytes, 30), 29);
      expect(utf8BoundaryLength(bytes, 31), 31);
    });

    test('backs up over a 4-byte emoji', () {
      final bytes = utf8.encode('ab😀');
      expect(utf8BoundaryLength(bytes, 5), 2);
    });
  });

  group('buildSetAdvertNameFrame', () {
    test('truncates long names on a character boundary', () {
      final name = 'Ж' * 20; // 40 bytes
      final frame = buildSetAdvertNameFrame(name);
      final nameBytes = frame.sublist(1);
      expect(nameBytes.length, 30);
      expect(utf8.decode(nameBytes), 'Ж' * 15);
    });

    test('keeps names shorter than the limit intact', () {
      final frame = buildSetAdvertNameFrame('Node');
      expect(utf8.decode(frame.sublist(1)), 'Node');
    });
  });

  group('BufferWriter.writeCString', () {
    test('NUL-terminates and truncates on a character boundary', () {
      final writer = BufferWriter()..writeCString('#${'ё' * 20}', 32);
      final bytes = writer.toBytes();
      expect(bytes.length, 32);
      final end = bytes.indexOf(0);
      expect(utf8.decode(bytes.sublist(0, end)), '#${'ё' * 15}');
    });
  });

  group('path hash width', () {
    test('buildSendAnonReqFrame clamps width to 3', () {
      final frame = buildSendAnonReqFrame(
        Uint8List(32),
        requestType: 1,
        replyPath: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        replyHopCount: 2,
        pathHashWidth: 4,
      );
      final encodedPathLen = frame[1 + 32 + 1];
      expect(encodedPathLen >> 6, 2); // width 3
      expect(frame.sublist(1 + 32 + 2), [4, 5, 6, 1, 2, 3]);
    });

    test('buildSetPathHashModeFrame clamps mode to 2', () {
      expect(buildSetPathHashModeFrame(3), [cmdSetPathHashMode, 0, 2]);
    });
  });
}
