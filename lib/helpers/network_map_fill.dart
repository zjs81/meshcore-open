import 'package:latlong2/latlong.dart';

import '../services/network_map/network_map_api_client.dart';

/// Looks up unresolved routing-hop prefixes on the MeshCore Open network map.
///
/// [hopHexes] are hop prefix hex strings (as produced by
/// `PathHelper.formatHopHex`, any case). [anchors] are known positions along
/// the path (self and located repeaters); the query box is their bounding
/// area expanded by one degree, capped at the API's span limit. Returns a map
/// from hop hex to repeaters whose full public key starts with that prefix,
/// or an empty map when the lookup is impossible or fails (offline, too
/// large an area, no matches).
Future<Map<String, List<NetworkMapRepeater>>> fetchNetworkMapForHops({
  required Iterable<String> hopHexes,
  required List<LatLng> anchors,
  NetworkMapApiClient? client,
}) async {
  final wanted = <String>{
    for (final hex in hopHexes)
      if (hex.isNotEmpty) hex.toLowerCase(),
  };
  if (wanted.isEmpty || anchors.isEmpty) return const {};

  var minLat = anchors.first.latitude, maxLat = minLat;
  var minLon = anchors.first.longitude, maxLon = minLon;
  for (final point in anchors) {
    minLat = point.latitude < minLat ? point.latitude : minLat;
    maxLat = point.latitude > maxLat ? point.latitude : maxLat;
    minLon = point.longitude < minLon ? point.longitude : minLon;
    maxLon = point.longitude > maxLon ? point.longitude : maxLon;
  }
  if (maxLat - minLat > networkMapMaxBboxSpan ||
      maxLon - minLon > networkMapMaxBboxSpan) {
    return const {};
  }
  double span(double raw) => (raw + 2).clamp(0.0, networkMapMaxBboxSpan);
  final latSpan = span(maxLat - minLat);
  final lonSpan = span(maxLon - minLon);
  final latMid = (minLat + maxLat) / 2;
  final lonMid = (minLon + maxLon) / 2;
  final bbox = NetworkMapBbox(
    minLon: (lonMid - lonSpan / 2).clamp(-180.0, 180.0),
    minLat: (latMid - latSpan / 2).clamp(-90.0, 90.0),
    maxLon: (lonMid + lonSpan / 2).clamp(-180.0, 180.0),
    maxLat: (latMid + latSpan / 2).clamp(-90.0, 90.0),
  );
  if (!bbox.isWithinLimit) return const {};

  final ownClient = client ?? NetworkMapApiClient();
  try {
    final repeaters = await ownClient.fetchRepeaters(bbox);
    final matches = <String, List<NetworkMapRepeater>>{};
    for (final hex in wanted) {
      final found = repeaters
          .where((r) => r.key.startsWith(hex))
          .toList(growable: false);
      if (found.isNotEmpty) matches[hex.toUpperCase()] = found;
    }
    return matches;
  } catch (_) {
    return const {};
  } finally {
    if (client == null) ownClient.close();
  }
}
