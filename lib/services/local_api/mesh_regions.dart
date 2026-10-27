import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// Great-circle distance in kilometres.
double distanceKmBetween(double lat1, double lon1, double lat2, double lon2) {
  const earth = 6371.0;
  double rad(double degrees) => degrees * pi / 180.0;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return 2 * earth * asin(sqrt(a));
}

/// A flood-scope area: a MeshCore region name and the circle it covers.
class MeshRegion {
  final String name;
  final String label;
  final String kind; // "city" or "country"
  final double latitude;
  final double longitude;
  final double radiusKm;

  MeshRegion({
    required this.name,
    required this.label,
    required this.kind,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'label': label,
    'kind': kind,
    'lat': latitude,
    'lon': longitude,
    'radiusKm': radiusKm,
  };

  static MeshRegion? fromJson(Object? value) {
    if (value is! Map) return null;
    final name = value['name'];
    final label = value['label'];
    final lat = value['lat'];
    final lon = value['lon'];
    final radius = value['radiusKm'];
    if (name is! String || label is! String || lat is! num || lon is! num) {
      return null;
    }
    return MeshRegion(
      name: name,
      label: label,
      kind: value['kind'] as String? ?? 'city',
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      radiusKm: (radius as num?)?.toDouble() ?? 100,
    );
  }
}

/// A static, editable map of flood-scope areas.
///
/// This is deliberately data, not code: a community can list its repeater
/// regions with a centre and a radius. [resolve] picks the nearest centre
/// whose circle contains the point, so a city usually beats the country
/// fallback because it is nearer.
class MeshRegionCatalog {
  final List<MeshRegion> regions;

  MeshRegionCatalog(this.regions);

  static const String assetPath = 'assets/mesh_regions.json';

  static Future<MeshRegionCatalog> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return fromJsonString(raw);
  }

  static MeshRegionCatalog fromJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['regions'] is List) {
        return MeshRegionCatalog(
          (decoded['regions'] as List)
              .map(MeshRegion.fromJson)
              .whereType<MeshRegion>()
              .toList(),
        );
      }
    } catch (_) {
      // A broken asset means no suggestions, not a broken API.
    }
    return MeshRegionCatalog(const []);
  }

  List<Map<String, Object?>> toJson() =>
      regions.map((region) => region.toJson()).toList();

  bool contains(String name) => regions.any((region) => region.name == name);

  MeshRegion? resolve(double latitude, double longitude) {
    MeshRegion? best;
    var bestDistance = double.infinity;
    for (final region in regions) {
      final distance = distanceKmBetween(
        latitude,
        longitude,
        region.latitude,
        region.longitude,
      );
      if (distance > region.radiusKm) continue;
      if (distance < bestDistance) {
        best = region;
        bestDistance = distance;
      }
    }
    return best;
  }
}
