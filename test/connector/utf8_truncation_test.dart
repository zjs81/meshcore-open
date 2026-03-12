import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('UTF-8 truncation', () {
    test('buildSetAdvertNameFrame does not split a multibyte character', () {
      final frame = buildSetAdvertNameFrame('${'a' * 30}😀');
      final nameBytes = frame.sublist(1);

      expect(() => utf8.decode(nameBytes, allowMalformed: false), returnsNormally);
      expect(utf8.decode(nameBytes, allowMalformed: false), 'a' * 30);
    });

    test('buildSetChannelFrame does not split a multibyte channel name', () {
      final frame = buildSetChannelFrame(1, '${'a' * 30}😀', Uint8List(16));
      final rawNameBytes = frame.sublist(2, 34);
      final zeroIndex = rawNameBytes.indexOf(0);
      final nameBytes = zeroIndex >= 0
          ? rawNameBytes.sublist(0, zeroIndex)
          : rawNameBytes;

      expect(() => utf8.decode(nameBytes, allowMalformed: false), returnsNormally);
      expect(utf8.decode(nameBytes, allowMalformed: false), 'a' * 30);
    });

    test('buildAppStartFrame preserves whole multibyte characters when truncated', () {
      final frame = buildAppStartFrame(appName: 'aaaaaaa😀😀');
      final rawNameBytes = frame.sublist(2);
      final zeroIndex = rawNameBytes.indexOf(0);
      final nameBytes = zeroIndex >= 0
          ? rawNameBytes.sublist(0, zeroIndex)
          : rawNameBytes;

      expect(() => utf8.decode(nameBytes, allowMalformed: false), returnsNormally);
    });
  });
}
