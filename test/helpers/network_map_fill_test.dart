import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/network_map_fill.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/services/network_map/network_map_api_client.dart';

void main() {
  test('online fill adds coordinates to a same-key local contact', () {
    final publicKey = Uint8List(32)..first = 0xAA;
    final local = Contact(
      publicKey: publicKey,
      name: 'Local node',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.utc(2026),
    );
    final online = Contact(
      publicKey: Uint8List.fromList(publicKey),
      name: 'Online node',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      lastSeen: DateTime.utc(2026),
      latitude: 33.45,
      longitude: -112.08,
    );

    final merged = mergeNetworkMapContacts([local], [online]);

    expect(merged, hasLength(1));
    expect(merged.single.name, 'Online node');
    expect(merged.single.hasLocation, isTrue);
  });

  test(
    'fills multiple missing hop prefixes with one bounded request',
    () async {
      var requestCount = 0;
      final client = NetworkMapApiClient(
        client: MockClient((request) async {
          requestCount++;
          expect(request.url.path, '/v1/repeaters');
          expect(request.url.queryParameters['bbox'], isNotNull);
          return http.Response(
            jsonEncode({
              'repeaters': [
                {
                  'key': 'a1' * 32,
                  'name': 'Hop A',
                  'type': 2,
                  'cell': {
                    'cell': '872830828ffffff',
                    'lat': 33.45,
                    'lon': -112.08,
                  },
                },
                {
                  'key': 'b2' * 32,
                  'name': 'Hop B',
                  'type': 2,
                  'cell': {
                    'cell': '872830828ffffff',
                    'lat': 33.45,
                    'lon': -112.08,
                  },
                },
                {
                  'key': 'c3' * 32,
                  'name': 'Not requested',
                  'type': 2,
                  'cell': {
                    'cell': '872830828ffffff',
                    'lat': 33.45,
                    'lon': -112.08,
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final matches = await fetchNetworkMapForHops(
        hopHexes: ['A1', 'b2', 'A1'],
        anchors: const [LatLng(33.4, -112.1), LatLng(33.5, -112.0)],
        client: client,
      );
      final cachedMatches = await fetchNetworkMapForHops(
        hopHexes: ['b2', 'A1'],
        anchors: const [LatLng(33.4, -112.1), LatLng(33.5, -112.0)],
        client: client,
      );
      client.close();

      expect(requestCount, 1);
      expect(cachedMatches, matches);
      expect(matches.keys, containsAll(['A1', 'B2']));
      expect(matches.values.expand((items) => items).map((r) => r.name), [
        'Hop A',
        'Hop B',
      ]);
    },
  );

  test('does not query without unresolved prefixes or anchors', () async {
    var requestCount = 0;
    final client = NetworkMapApiClient(
      client: MockClient((_) async {
        requestCount++;
        return http.Response('{}', 200);
      }),
    );

    expect(
      await fetchNetworkMapForHops(
        hopHexes: const [],
        anchors: const [LatLng(0, 0)],
        client: client,
      ),
      isEmpty,
    );
    expect(
      await fetchNetworkMapForHops(
        hopHexes: ['aa'],
        anchors: const [],
        client: client,
      ),
      isEmpty,
    );
    expect(requestCount, 0);
    client.close();
  });
}
