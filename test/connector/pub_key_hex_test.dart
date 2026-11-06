import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/contact.dart';

String _reference(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('pubKeyToHex is lowercase, zero-padded hex for every byte value', () {
    final all = Uint8List.fromList(List<int>.generate(256, (i) => i));
    expect(pubKeyToHex(all), _reference(all));
    expect(pubKeyToHex(Uint8List(0)), '');
    expect(pubKeyToHex(Uint8List.fromList([0x00, 0x0a, 0xff])), '000aff');
  });

  test('pubKeyToHex round-trips random keys through hexToPubKey', () {
    final random = Random(7);
    for (var i = 0; i < 200; i++) {
      final key = Uint8List.fromList(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
      final hex = pubKeyToHex(key);
      expect(hex, _reference(key));
      expect(hexToPubKey(hex), key);
    }
  });

  test('Contact.publicKeyHex is stable and drives equality', () {
    final key = Uint8List.fromList(List<int>.generate(32, (i) => i * 7));
    Contact make(String name) => Contact(
      publicKey: key,
      name: name,
      type: 1,
      pathLength: -1,
      path: Uint8List(0),
      lastSeen: DateTime(2026),
    );
    final a = make('a');
    expect(a.publicKeyHex, _reference(key));
    expect(identical(a.publicKeyHex, a.publicKeyHex), isTrue);
    expect(a, make('renamed'));
    expect(a.hashCode, make('renamed').hashCode);
    expect(a.copyWith(name: 'b').publicKeyHex, a.publicKeyHex);
  });
}
