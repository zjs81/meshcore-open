import 'dart:typed_data';
import 'dart:ui';

import 'package:latlong2/latlong.dart';

import 'path_history.dart';

/// One observed route rendered on the path map — the live traced path
/// (primary) or an alternate from the contact's path history — resolved to
/// map coordinates with per-hop confidence flags.
class DisplayPath {
  final String id;
  final String label;
  final Color color;
  final bool isPrimary;

  /// Outbound hop prefixes, including hops that could not be placed on the map.
  final List<Uint8List> hopBytes;

  /// Resolved map points: self, each locatable hop, then the target when its
  /// position is known. Hops with no position are skipped here but still
  /// counted in [unresolvedHops].
  final List<LatLng> points;

  /// Display name for each entry of [points].
  final List<String> pointLabels;

  /// Whether each entry of [points] is a GPS-grade position (vs inferred).
  final List<bool> pointConfirmed;

  /// Per segment (length points-1): true when either endpoint is inferred or
  /// unlocatable hops were skipped in between — rendered dashed.
  final List<bool> segmentEstimated;

  /// Per segment: the transmission ordinal of the segment's destination,
  /// used to highlight the matching hop-list row during animation.
  final List<int> rowForSegment;

  /// Total transmissions on the full route (including unlocatable hops).
  final int totalTransmissions;

  /// True when the route ends with a chat-target endpoint row.
  final bool hasTargetEndpoint;

  final int gpsConfirmedHops;
  final int unresolvedHops;
  final double distanceMeters;

  /// History metadata; null for the live traced (primary) path.
  final PathRecord? record;

  const DisplayPath({
    required this.id,
    required this.label,
    required this.color,
    required this.isPrimary,
    required this.hopBytes,
    required this.points,
    required this.pointLabels,
    required this.pointConfirmed,
    required this.segmentEstimated,
    required this.rowForSegment,
    required this.totalTransmissions,
    required this.hasTargetEndpoint,
    required this.gpsConfirmedHops,
    required this.unresolvedHops,
    required this.distanceMeters,
    this.record,
  });
}
