import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/path_hop_resolver.dart';
import 'package:meshcore_open/models/contact.dart';

Contact _contact({
  required int prefix,
  int? secondByte,
  required String name,
  required double latitude,
  required double longitude,
  DateTime? lastSeen,
}) {
  final key = Uint8List(32)..first = prefix;
  if (secondByte != null) key[1] = secondByte;
  return Contact(
    publicKey: key,
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

  test(
    'rejects single candidate impossibly far and preserves previousPosition',
    () {
      // Arizona self/local repeaters vs East Coast collision (~3700 km away).
      const selfArizona = LatLng(33.4484, -112.0740);
      final azHop1 = _contact(
        prefix: 0x48,
        name: 'AZ Repeater 1',
        latitude: 33.60097,
        longitude: -112.02457,
      );
      final eastCoastBogus = _contact(
        prefix: 0x9C,
        name: 'East Coast 9C',
        latitude: 42.3601,
        longitude: -71.0589,
      );
      final azHop3 = _contact(
        prefix: 0x53,
        name: 'AZ Repeater 2',
        latitude: 33.46300,
        longitude: -111.65000,
      );

      final resolved = PathHopResolver.resolve(
        pathBytes: const [0x53, 0x9C, 0x48],
        contacts: [azHop1, eastCoastBogus, azHop3],
        endpoint: selfArizona,
        resolveFromEnd: true,
      );

      expect(resolved.map((c) => c?.name), [
        'AZ Repeater 2',
        null,
        'AZ Repeater 1',
      ]);
    },
  );

  test('rejects multiple candidates when all are impossibly far', () {
    const selfArizona = LatLng(33.4484, -112.0740);
    final eastCoast = _contact(
      prefix: 0x9C,
      name: 'East Coast 9C',
      latitude: 42.3601,
      longitude: -71.0589,
      lastSeen: DateTime.utc(2026, 2),
    );
    final europe = _contact(
      prefix: 0x9C,
      name: 'Europe 9C',
      latitude: 48.8566,
      longitude: 2.3522,
      lastSeen: DateTime.utc(2026, 1),
    );

    final resolved = PathHopResolver.resolve(
      pathBytes: const [0x9C],
      contacts: [eastCoast, europe],
      endpoint: selfArizona,
    );

    expect(resolved, [null]);
  });

  test(
    'picks plausible candidate when another candidate is impossibly far',
    () {
      const selfArizona = LatLng(33.4484, -112.0740);
      final eastCoastNewer = _contact(
        prefix: 0x9C,
        name: 'East Coast 9C',
        latitude: 42.3601,
        longitude: -71.0589,
        lastSeen: DateTime.utc(2026, 5),
      );
      final localOlder = _contact(
        prefix: 0x9C,
        name: 'Local AZ 9C',
        latitude: 33.50,
        longitude: -111.90,
        lastSeen: DateTime.utc(2026, 1),
      );

      final resolved = PathHopResolver.resolve(
        pathBytes: const [0x9C],
        contacts: [eastCoastNewer, localOlder],
        endpoint: selfArizona,
      );

      expect(resolved.single?.name, 'Local AZ 9C');
    },
  );

  test('consecutive unresolved hops widen distance budget proportionally', () {
    // At equator, 1 degree longitude is ~111.32 km.
    // With 2 unresolved intermediate hops (hopGap = 3), budget is 3 * 250 km = 750 km.
    // 6.0 degrees (~667.9 km) is beyond 1-hop (250 km) and 2-hop (500 km),
    // but within 3-hop (750 km).
    const endpoint = LatLng(0, 0);
    final distantValid = _contact(
      prefix: 0xCC,
      name: 'Valid 3-hop target',
      latitude: 0,
      longitude: 6.0,
    );

    final resolvedWithTwoUnknowns = PathHopResolver.resolve(
      pathBytes: const [0xAA, 0xBB, 0xCC],
      contacts: [distantValid],
      endpoint: endpoint,
    );
    expect(resolvedWithTwoUnknowns, [null, null, distantValid]);

    // With only 1 hop (hopGap = 1, budget = 250 km), 6.0 degrees is rejected.
    final resolvedDirect = PathHopResolver.resolve(
      pathBytes: const [0xCC],
      contacts: [distantValid],
      endpoint: endpoint,
    );
    expect(resolvedDirect, [null]);
  });

  test(
    'endpoint == null rejects a leading distant outlier and keeps local cluster',
    () {
      final bogusFirst = _contact(
        prefix: 0x9C,
        name: 'East Coast Outlier',
        latitude: 42.3601,
        longitude: -71.0589,
        lastSeen: DateTime.utc(2026, 6),
      );
      final local1 = _contact(
        prefix: 0x48,
        name: 'Local 1',
        latitude: 33.60097,
        longitude: -112.02457,
      );
      final local2 = _contact(
        prefix: 0x53,
        name: 'Local 2',
        latitude: 33.46300,
        longitude: -111.65000,
      );
      final local3 = _contact(
        prefix: 0x6C,
        name: 'Local 3',
        latitude: 33.42,
        longitude: -111.80,
      );

      final resolved = PathHopResolver.resolve(
        pathBytes: const [0x9C, 0x48, 0x53, 0x6C],
        contacts: [bogusFirst, local1, local2, local3],
        endpoint: null,
      );

      expect(resolved.map((c) => c?.name), [
        null,
        'Local 1',
        'Local 2',
        'Local 3',
      ]);
    },
  );

  test(
    'endpoint != null rejects first-hop outlier and resolves subsequent local hops',
    () {
      const selfArizona = LatLng(33.4484, -112.0740);
      final bogusFirst = _contact(
        prefix: 0xEA,
        name: 'East Coast First Hop',
        latitude: 42.3601,
        longitude: -71.0589,
      );
      final local2 = _contact(
        prefix: 0x48,
        name: 'Local 2',
        latitude: 33.60097,
        longitude: -112.02457,
      );
      final local3 = _contact(
        prefix: 0x53,
        name: 'Local 3',
        latitude: 33.46300,
        longitude: -111.65000,
      );

      final resolved = PathHopResolver.resolve(
        pathBytes: const [0xEA, 0x48, 0x53],
        contacts: [bogusFirst, local2, local3],
        endpoint: selfArizona,
      );

      expect(resolved.map((c) => c?.name), [null, 'Local 2', 'Local 3']);
    },
  );

  test('legitimate long-range line-of-sight LoRa hops still resolve', () {
    // ~200 km mountain-to-mountain hop (within 250 km single-hop budget).
    const self = LatLng(33.4484, -112.0740);
    final mountainPeak = _contact(
      prefix: 0xAA,
      name: 'Mountain Peak',
      latitude: 35.1983,
      longitude: -111.6513, // Flagstaff (~198 km from Phoenix)
    );
    final secondPeak = _contact(
      prefix: 0xBB,
      name: 'North Rim',
      latitude: 36.2100,
      longitude: -112.0600, // ~118 km from Flagstaff
    );

    final resolved = PathHopResolver.resolve(
      pathBytes: const [0xAA, 0xBB],
      contacts: [mountainPeak, secondPeak],
      endpoint: self,
    );

    expect(resolved.map((c) => c?.name), ['Mountain Peak', 'North Rim']);
  });

  test('multi-byte path hash width rejects impossible hop', () {
    const self = LatLng(33.4484, -112.0740);
    final local = _contact(
      prefix: 0x48,
      secondByte: 0x01,
      name: 'Local 2-byte',
      latitude: 33.60,
      longitude: -112.02,
    );
    final bogus = _contact(
      prefix: 0x9C,
      secondByte: 0x02,
      name: 'Bogus 2-byte',
      latitude: 40.7128,
      longitude: -74.0060,
    );

    final resolved = PathHopResolver.resolve(
      pathBytes: const [0x48, 0x01, 0x9C, 0x02],
      contacts: [local, bogus],
      endpoint: self,
      pathHashByteWidth: 2,
    );

    expect(resolved.map((c) => c?.name), ['Local 2-byte', null]);
  });

  test(
    'preferredContacts overrides nearer general contact with same prefix when plausible',
    () {
      const self = LatLng(33.4484, -112.0740);
      final nearerGeneral = _contact(
        prefix: 0x48,
        secondByte: 0x01,
        name: 'Nearer General 48',
        latitude: 33.4600,
        longitude: -112.0700,
        lastSeen: DateTime.utc(2026, 6),
      );
      final selectedPreferred = _contact(
        prefix: 0x48,
        secondByte: 0x02,
        name: 'Selected Preferred 48',
        latitude: 33.9000,
        longitude: -111.7000,
        lastSeen: DateTime.utc(2026, 1),
      );
      final secondHopGeneral = _contact(
        prefix: 0x53,
        name: 'Second Hop 53',
        latitude: 33.9500,
        longitude: -111.6500,
      );

      final resolvedWithEndpoint = PathHopResolver.resolve(
        pathBytes: const [0x48, 0x53],
        contacts: [nearerGeneral, selectedPreferred, secondHopGeneral],
        preferredContacts: [selectedPreferred],
        endpoint: self,
      );
      expect(resolvedWithEndpoint.map((c) => c?.name), [
        'Selected Preferred 48',
        'Second Hop 53',
      ]);

      final resolvedWithoutEndpoint = PathHopResolver.resolve(
        pathBytes: const [0x48, 0x53],
        contacts: [nearerGeneral, selectedPreferred, secondHopGeneral],
        preferredContacts: [selectedPreferred],
        endpoint: null,
      );
      expect(resolvedWithoutEndpoint.map((c) => c?.name), [
        'Selected Preferred 48',
        'Second Hop 53',
      ]);
    },
  );

  test(
    'impossibly far preferredContact is rejected and falls back to plausible general contact',
    () {
      const self = LatLng(33.4484, -112.0740);
      final bogusPreferred = _contact(
        prefix: 0x9C,
        secondByte: 0x01,
        name: 'East Coast Preferred 9C',
        latitude: 42.3601,
        longitude: -71.0589,
      );
      final localGeneral = _contact(
        prefix: 0x9C,
        secondByte: 0x02,
        name: 'Local General 9C',
        latitude: 33.60097,
        longitude: -112.02457,
      );

      final resolved = PathHopResolver.resolve(
        pathBytes: const [0x9C],
        contacts: [bogusPreferred, localGeneral],
        preferredContacts: [bogusPreferred],
        endpoint: self,
      );
      expect(resolved.map((c) => c?.name), ['Local General 9C']);
    },
  );
}
