import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/path_helper.dart';
import 'package:meshcore_open/models/contact.dart';

Contact _contact({
  required int firstByte,
  required String name,
  required int type,
}) {
  final key = Uint8List(32)..[0] = firstByte;
  return Contact(
    publicKey: key,
    name: name,
    type: type,
    pathLength: 0,
    path: Uint8List(0),
    lastSeen: DateTime.now(),
  );
}

void main() {
  test('resolvePathNames ignores chat nodes and keeps repeater/room nodes', () {
    final contacts = [
      _contact(firstByte: 0xF2, name: 'MunTui', type: advTypeChat),
      _contact(firstByte: 0x7E, name: 'zrepeater', type: advTypeRepeater),
      _contact(firstByte: 0xBA, name: 'USS Ronald Reagan', type: advTypeRoom),
    ];

    final resolved = PathHelper.resolvePathNames([0xF2, 0x7E, 0xBA], contacts);

    expect(resolved, equals('F2 → zrepeater → USS Ronald Reagan'));
  });
}
