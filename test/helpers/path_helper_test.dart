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
  test('splitPathBytes groups bytes by hash width', () {
    final hops = PathHelper.splitPathBytes([0xA1, 0xA2, 0xC1, 0xC2], 2);

    expect(hops, hasLength(2));
    expect(hops.first, equals(Uint8List.fromList([0xA1, 0xA2])));
    expect(hops.last, equals(Uint8List.fromList([0xC1, 0xC2])));
    expect(PathHelper.formatHopHex(hops.first), equals('A1A2'));
  });

  test(
    'resolvePathNames ignores chat nodes and keeps repeater/room nodes with 1-byte paths',
    () {
      final contacts = [
        _contact(firstByte: 0xF2, name: 'MunTui', type: advTypeChat),
        _contact(firstByte: 0x7E, name: 'zrepeater', type: advTypeRepeater),
        _contact(firstByte: 0xBA, name: 'USS Ronald Reagan', type: advTypeRoom),
      ];

      final resolved = PathHelper.resolvePathNames(
        [0xF2, 0x7E, 0xBA],
        contacts,
        1, // 1-byte hash width
      );

      expect(resolved, equals('F2 → zrepeater → USS Ronald Reagan'));
    },
  );

  test('resolvePathNames supports multi-byte paths', () {
    final contacts = [
      _contact(firstByte: 0xA1, name: 'Repeater1', type: advTypeRepeater),
      _contact(firstByte: 0xC1, name: 'Room42', type: advTypeRoom),
    ];

    // Contacts with 2-byte public keys
    contacts[0] = Contact(
      publicKey: Uint8List.fromList([0xA1, 0xA2, ...List.filled(30, 0)]),
      name: 'Repeater1',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.now(),
    );
    contacts[1] = Contact(
      publicKey: Uint8List.fromList([0xC1, 0xC2, ...List.filled(30, 0)]),
      name: 'Room42',
      type: advTypeRoom,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.now(),
    );

    final resolved = PathHelper.resolvePathNames(
      [0xA1, 0xA2, 0xC1, 0xC2],
      contacts,
      2, // 2-byte hash width
    );

    expect(resolved, equals('Repeater1 → Room42'));
  });
}
