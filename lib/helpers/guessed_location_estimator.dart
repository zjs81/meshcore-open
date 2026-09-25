import 'dart:math';
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import 'path_helper.dart';

typedef GuessCandidate = ({Uint8List publicKey, List<(List<int>, int)> paths});

typedef GuessInput = ({
  List<GuessCandidate> candidates,
  List<(Uint8List, double, double)> anchors,
  (double, double)? selfPosition,
  double? maxRangeKm,
});

/// Longest single radio link we trust when matching hops to repeaters. The
/// free-space estimate from the radio settings runs to hundreds of km, far
/// beyond real terrestrial links, so it is capped here.
const double maxPlausibleLinkKm = 150;

/// Runs in a background isolate: estimates positions for nodes without a
/// location from the repeaters their paths end on. Returns
/// (candidate index, lat, lon, high confidence) for each placed node.
///
/// Paths run from our radio outward, so the last hop is the repeater that
/// heard the node directly. Short hop hashes collide, so each path is walked
/// from our own position and every hop is matched to the nearest repeater with
/// that prefix that is within radio range of the previous hop.
List<(int, double, double, bool)> estimateGuessedLocations(GuessInput input) {
  const distance = Distance();
  final maxLinkKm = min(
    input.maxRangeKm ?? maxPlausibleLinkKm,
    maxPlausibleLinkKm,
  );
  final maxLinkM = maxLinkKm * 1000;

  final anchorsByPrefix = <String, List<LatLng>>{};
  for (final (key, lat, lon) in input.anchors) {
    for (var width = 1; width <= 3 && width <= key.length; width++) {
      anchorsByPrefix
          .putIfAbsent(PathHelper.formatHopHex(key.sublist(0, width)), () => [])
          .add(LatLng(lat, lon));
    }
  }
  final self = input.selfPosition;
  final selfPosition = self == null ? null : LatLng(self.$1, self.$2);

  LatLng? lastHopAnchor(List<int> pathBytes, int hopWidth) {
    final hops = PathHelper.splitPathBytes(pathBytes, hopWidth);
    var previous = selfPosition;
    LatLng? resolved;
    for (final hop in hops) {
      resolved = null;
      final candidates = anchorsByPrefix[PathHelper.formatHopHex(hop)];
      if (candidates == null) continue;
      if (previous == null) {
        // Without a reference point only an unambiguous prefix is trusted.
        if (candidates.length == 1) resolved = candidates.first;
      } else {
        double? best;
        for (final candidate in candidates) {
          final d = distance(previous, candidate);
          if (d <= maxLinkM && (best == null || d < best)) {
            best = d;
            resolved = candidate;
          }
        }
      }
      if (resolved != null) previous = resolved;
    }
    return resolved;
  }

  final result = <(int, double, double, bool)>[];
  for (var i = 0; i < input.candidates.length; i++) {
    final candidate = input.candidates[i];

    // One vote per observed path for the repeater it ended on.
    final votes = <LatLng, int>{};
    for (final (pathBytes, hopWidth) in candidate.paths) {
      if (pathBytes.isEmpty || hopWidth < 1) continue;
      final anchor = lastHopAnchor(pathBytes, hopWidth);
      if (anchor != null) votes[anchor] = (votes[anchor] ?? 0) + 1;
    }
    if (votes.isEmpty) continue;

    // A node cannot hear two repeaters more than two links apart; drop
    // outliers, falling back to the most-voted anchor if none agree.
    var anchors = votes.keys.toList();
    if (anchors.length > 1) {
      final consistent = anchors
          .where(
            (a) => anchors.any((b) => b != a && distance(a, b) <= 2 * maxLinkM),
          )
          .toList();
      anchors = consistent.isNotEmpty
          ? consistent
          : [votes.entries.reduce((a, b) => b.value > a.value ? b : a).key];
    }

    final LatLng position;
    if (anchors.length == 1) {
      // Spread single-anchor guesses around the anchor so they stay visible.
      position = _offsetGuessedPosition(
        anchors[0],
        candidate.publicKey,
        radiusMeters: 330,
      );
    } else {
      var lat = 0.0, lon = 0.0, total = 0;
      for (final a in anchors) {
        final weight = votes[a]!;
        lat += a.latitude * weight;
        lon += a.longitude * weight;
        total += weight;
      }
      position = _offsetGuessedPosition(
        LatLng(lat / total, lon / total),
        candidate.publicKey,
        radiusMeters: anchors.length >= 3 ? 80 : 120,
      );
    }
    if (!isPlausibleLocation(position.latitude, position.longitude)) {
      continue;
    }
    result.add((i, position.latitude, position.longitude, anchors.length >= 2));
  }
  return result;
}

bool isPlausibleLocation(double lat, double lon) {
  const double epsilon = 1e-6;
  return (lat.abs() > epsilon || lon.abs() > epsilon) &&
      lat >= -90.0 &&
      lat <= 90.0 &&
      lon >= -180.0 &&
      lon <= 180.0;
}

LatLng _offsetGuessedPosition(
  LatLng anchor,
  Uint8List publicKey, {
  required double radiusMeters,
}) {
  final seed = _guessSeed(publicKey);
  final angle = ((seed & 0xFFFF) / 0x10000) * 2 * pi;
  final latOffsetDeg = (radiusMeters / 111320.0) * cos(angle);
  final lonScale = max(cos(anchor.latitude * pi / 180.0).abs(), 0.2);
  final lonOffsetDeg = (radiusMeters / (111320.0 * lonScale)) * sin(angle);
  return LatLng(
    anchor.latitude + latOffsetDeg,
    anchor.longitude + lonOffsetDeg,
  );
}

int _guessSeed(Uint8List publicKey) {
  var seed = 0x811C9DC5;
  for (final byte in publicKey) {
    seed ^= byte;
    seed = (seed * 0x01000193) & 0x7FFFFFFF;
  }
  return seed;
}
