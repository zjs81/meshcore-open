import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import '../services/network_map/network_map_api_client.dart';

final Map<
  String,
  ({DateTime cachedAt, Future<Map<String, List<NetworkMapRepeater>>> future})
>
_networkMapHopFetchCache = {};
const _networkMapHopFetchCacheTtl = Duration(minutes: 5);

/// Looks up unresolved path-hop prefixes with one bounded network-map request.
Future<Map<String, List<NetworkMapRepeater>>> fetchNetworkMapForHops({
  required Iterable<String> hopHexes,
  required List<LatLng> anchors,
  NetworkMapApiClient? client,
}) async {
  final wanted = {
    for (final hex in hopHexes)
      if (hex.isNotEmpty) hex.toLowerCase(),
  };
  if (wanted.isEmpty || anchors.isEmpty) return const {};

  var minLat = anchors.first.latitude;
  var maxLat = minLat;
  var minLon = anchors.first.longitude;
  var maxLon = minLon;
  for (final point in anchors.skip(1)) {
    minLat = point.latitude < minLat ? point.latitude : minLat;
    maxLat = point.latitude > maxLat ? point.latitude : maxLat;
    minLon = point.longitude < minLon ? point.longitude : minLon;
    maxLon = point.longitude > maxLon ? point.longitude : maxLon;
  }

  final boxes = NetworkMapBbox.forVisibleArea(
    west: minLon - 1,
    south: minLat - 1,
    east: maxLon + 1,
    north: maxLat + 1,
  );
  if (boxes == null) return const {};

  final now = DateTime.now();
  _networkMapHopFetchCache.removeWhere(
    (_, entry) => now.difference(entry.cachedAt) >= _networkMapHopFetchCacheTtl,
  );
  final prefixes = wanted.toList()..sort();
  final cacheKey =
      '${client?.baseUrl ?? networkMapBaseUrl}|'
      '${boxes.map((box) => box.query).join(';')}|${prefixes.join(',')}';
  final cached = _networkMapHopFetchCache[cacheKey];
  if (cached != null &&
      DateTime.now().difference(cached.cachedAt) <
          _networkMapHopFetchCacheTtl) {
    return cached.future;
  }

  final future = _fetchNetworkMapForHops(boxes, wanted, client);
  _networkMapHopFetchCache[cacheKey] = (cachedAt: now, future: future);
  return future;
}

Future<Map<String, List<NetworkMapRepeater>>> _fetchNetworkMapForHops(
  List<NetworkMapBbox> boxes,
  Set<String> wanted,
  NetworkMapApiClient? client,
) async {
  final ownClient = client ?? NetworkMapApiClient();
  try {
    final results = await Future.wait(boxes.map(ownClient.fetchRepeaters));
    final matches = <String, List<NetworkMapRepeater>>{};
    for (final repeater in results.expand((items) => items)) {
      for (final prefix in wanted) {
        if (repeater.key.startsWith(prefix)) {
          matches.putIfAbsent(prefix.toUpperCase(), () => []).add(repeater);
        }
      }
    }
    return matches;
  } catch (_) {
    return const {};
  } finally {
    if (client == null) ownClient.close();
  }
}

List<Contact> networkMapFillContacts(
  Map<String, List<NetworkMapRepeater>> matches, {
  required String fallbackName,
}) {
  final seen = <String>{};
  return [
    for (final repeater in matches.values.expand((items) => items))
      if ((repeater.type == advTypeRepeater || repeater.type == advTypeRoom) &&
          seen.add(repeater.key))
        Contact(
          publicKey: hexToPubKey(repeater.key),
          name: repeater.name ?? fallbackName,
          type: repeater.type,
          pathLength: 0,
          path: Uint8List(0),
          latitude: repeater.cell.center.latitude,
          longitude: repeater.cell.center.longitude,
          lastSeen: repeater.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0),
          isActive: false,
        ),
  ];
}

List<Contact> mergeNetworkMapContacts(
  List<Contact> localContacts,
  List<Contact> onlineContacts,
) {
  final merged = [...localContacts];
  final indexes = {
    for (var i = 0; i < merged.length; i++) merged[i].publicKeyHex: i,
  };
  for (final online in onlineContacts) {
    final index = indexes[online.publicKeyHex];
    if (index == null) {
      indexes[online.publicKeyHex] = merged.length;
      merged.add(online);
    } else if (!merged[index].hasLocation && online.hasLocation) {
      merged[index] = online;
    }
  }
  return merged;
}
