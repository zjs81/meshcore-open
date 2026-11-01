import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/path_hop_resolver.dart';
import 'package:meshcore_open/models/contact.dart';

Contact _contact({
  required int prefix,
  required String name,
  required double latitude,
  required double longitude,
  DateTime? lastSeen,
}) {
  return Contact(
    publicKey: Uint8List(32)..first = prefix,
    name: name,
    type: advTypeRepeater,
    pathLength: 0,
    path: Uint8List(0),
    latitude: latitude,
    longitude: longitude,
    lastSeen: lastSeen ?? DateTime.utc(2026),
  );
}

void main() {
  test('received paths resolve hash conflicts from the receiver backward', () {
    final nearReceiver = _contact(
      prefix: 0xAA,
      name: 'Near receiver',
      latitude: 0,
      longitude: 0.1,
    );
    final nearPreviousHop = _contact(
      prefix: 0xBB,
      name: 'Near previous hop',
      latitude: 0,
      longitude: 1.1,
    );
    final wrongConflict = _contact(
      prefix: 0xBB,
      name: 'Near receiver but wrong',
      latitude: 0,
      longitude: 0.2,
    );
    final previousHop = _contact(
      prefix: 0xCC,
      name: 'Previous hop',
      latitude: 0,
      longitude: 1,
    );

    final resolved = PathHopResolver.resolve(
      pathBytes: const [0xBB, 0xCC, 0xAA],
      contacts: [nearReceiver, nearPreviousHop, wrongConflict, previousHop],
      endpoint: const LatLng(0, 0),
      resolveFromEnd: true,
    );

    expect(resolved.map((contact) => contact?.name), [
      'Near previous hop',
      'Previous hop',
      'Near receiver',
    ]);
  });

  test('falls back to the most recently seen conflict without locations', () {
    final older = Contact(
      publicKey: Uint8List(32)..first = 0xAA,
      name: 'Older',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.utc(2025),
    );
    final newer = Contact(
      publicKey: Uint8List(32)..first = 0xAA,
      name: 'Newer',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.utc(2026),
    );

    final resolved = PathHopResolver.resolve(
      pathBytes: const [0xAA],
      contacts: [older, newer],
    );

    expect(resolved.single?.name, 'Newer');
  });

  test('drops an isolated location that is too far from both neighbors', () {
    final previous = _contact(
      prefix: 0xAA,
      name: 'Previous',
      latitude: 1,
      longitude: 0,
    );
    final isolated = _contact(
      prefix: 0xBB,
      name: 'Isolated',
      latitude: 1,
      longitude: 1.7,
    );
    final next = _contact(
      prefix: 0xCC,
      name: 'Next',
      latitude: 1,
      longitude: 3.4,
    );

    final resolved = PathHopResolver.resolve(
      pathBytes: const [0xAA, 0xBB, 0xCC],
      contacts: [previous, isolated, next],
    );

    expect(resolved.map((contact) => contact?.name), [
      'Previous',
      null,
      'Next',
    ]);
  });
}
