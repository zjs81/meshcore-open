import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/contact.dart';

Contact _contact(List<int> key) => Contact(
  publicKey: Uint8List.fromList(key),
  name: 'Node',
  type: advTypeChat,
  pathLength: -1,
  path: Uint8List(0),
  lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
);

void main() {
  final contact = _contact([0xA3, 0x0F, 0xB2, 0x44]);

  test('formats the first pathHashByteWidth bytes as uppercase hex', () {
    expect(contact.publicKeyPrefixHex(1), 'A3');
    expect(contact.publicKeyPrefixHex(2), 'A30F');
    expect(contact.publicKeyPrefixHex(3), 'A30FB2');
  });

  test('clamps width to the supported 1-3 range', () {
    expect(contact.publicKeyPrefixHex(0), 'A3');
    expect(contact.publicKeyPrefixHex(4), 'A30FB2');
  });

  test('handles keys shorter than the width', () {
    expect(_contact([0x01]).publicKeyPrefixHex(3), '01');
  });
}
