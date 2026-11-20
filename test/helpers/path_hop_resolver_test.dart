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
  final publicKey = Uint8List(32)..first = prefix;
  // Keep every contact's full key distinct so prefix collisions stay
  // distinguishable, like real repeater keys.
  for (var i = 1; i < 5; i++) {
    publicKey[i] = (name.hashCode >> (i * 3)) & 0xFF;
  }
  return Contact(
    publicKey: publicKey,
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

  test('resolves an ambiguous path around an impossible hop', () {
    // The nearer candidate for hop 1 would force a >250 km second hop; the
    // resolution must pick the relay that keeps every segment plausible.
    final deadEnd = _contact(
      prefix: 0xAA,
      name: 'Dead end',
      latitude: 0,
      longitude: 0.5,
    );
    final relay = _contact(
      prefix: 0xAA,
      name: 'Relay',
      latitude: 0,
      longitude: 1.7,
    );
    final destination = _contact(
      prefix: 0xBB,
      name: 'Destination',
      latitude: 0,
      longitude: 2.8,
    );

    final resolved = PathHopResolver.resolve(
      pathBytes: const [0xAA, 0xBB],
      contacts: [deadEnd, relay, destination],
      endpoint: const LatLng(0, 0),
    );

    expect(resolved.map((contact) => contact?.name), ['Relay', 'Destination']);
  });

  test('avoids impossible hops over 250 km when an alternative exists', () {
    final tooFar = _contact(
      prefix: 0xAA,
      name: 'Too far',
      latitude: 0,
      longitude: 2.5,
    );
    final reachable = _contact(
      prefix: 0xAA,
      name: 'Reachable',
      latitude: 0,
      longitude: 1.5,
    );

    final resolved = PathHopResolver.resolve(
      pathBytes: const [0xAA],
      contacts: [tooFar, reachable],
      endpoint: const LatLng(0, 0),
    );

    expect(resolved.single?.name, 'Reachable');
  });

  test('never assigns a >250 km hop even when it is the only option', () {
    final tooFar = _contact(
      prefix: 0xAA,
      name: 'Too far',
      latitude: 0,
      longitude: 2.5,
    );

    final resolved = PathHopResolver.resolve(
      pathBytes: const [0xAA],
      contacts: [tooFar],
      endpoint: const LatLng(0, 0),
    );

    expect(resolved.single, isNull);
  });

  test('flagged duplicates are ambiguous and honour explicit selections', () {
    final firstKey = Uint8List(32)..first = 0xAA;
    final secondKey = Uint8List(32)..first = 0xAA;
    secondKey[1] = 0x02;
    final first = Contact(
      publicKey: firstKey,
      name: 'First',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.utc(2026),
    );
    final second = Contact(
      publicKey: secondKey,
      name: 'Second',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.utc(2025),
    );

    final automatic = PathHopResolver.resolveDetailed(
      pathBytes: const [0xAA],
      contacts: [first, second],
    );
    expect(automatic.single.ambiguous, isTrue);
    expect(automatic.single.candidates.length, 2);

    final picked = PathHopResolver.resolveDetailed(
      pathBytes: const [0xAA],
      contacts: [first, second],
      forcedSelection: {'AA': pubKeyToHex(secondKey)},
    );
    expect(picked.single.selected?.name, 'Second');
    expect(picked.single.ambiguous, isFalse);
  });

  test('prioritises active repeaters over recently seen inactive ones', () {
    final activeKey = Uint8List(32)..first = 0xAA;
    final inactiveKey = Uint8List(32)..first = 0xAA;
    inactiveKey[1] = 0x02;
    final staleActive = Contact(
      publicKey: activeKey,
      name: 'Active',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.utc(2024),
    );
    final recentInactive = Contact(
      publicKey: inactiveKey,
      name: 'Inactive',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.utc(2026),
      isActive: false,
    );

    final resolved = PathHopResolver.resolveDetailed(
      pathBytes: const [0xAA],
      contacts: [recentInactive, staleActive],
    );

    expect(resolved.single.candidates.first.name, 'Active');
    expect(resolved.single.selected?.name, 'Active');
  });
}
