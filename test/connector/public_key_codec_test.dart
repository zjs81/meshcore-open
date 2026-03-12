import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('public key codecs', () {
    test('round-trips a full 32-byte key through hex', () {
      final pubKey = Uint8List.fromList(List<int>.generate(32, (i) => i));

      expect(hexToPubKey(pubKeyToHex(pubKey)), orderedEquals(pubKey));
    });

    test('rejects odd-length public key hex', () {
      expect(
        () => hexToPubKey('abc'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid public key hex characters', () {
      expect(
        () => hexToPubKey('zz'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects public key hex longer than 32 bytes', () {
      expect(
        () => hexToPubKey('aa' * 33),
        throwsA(isA<FormatException>()),
      );
    });

    test('zero-pads shorter public key hex inputs', () {
      final pubKey = hexToPubKey('aabb');

      expect(pubKey.length, 32);
      expect(pubKey[0], 0xAA);
      expect(pubKey[1], 0xBB);
      expect(pubKey.skip(2), everyElement(0));
    });
  });
}
