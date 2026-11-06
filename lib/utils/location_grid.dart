import 'dart:math' as math;

/// Grid spacing in degrees (~2.2 km north–south). Shared with the network map
/// server, which rejects any uploaded coordinate that is not a grid center.
const double locationGridSize = 0.02;

/// Snaps a coordinate to the center of its network-map grid cell.
///
/// Every coordinate that leaves the phone goes through this. The algorithm is
/// fixed by the network map API contract; snapping a center returns the same
/// center.
({double lat, double lon}) snapToLocationGrid(double lat, double lon) {
  const g = locationGridSize;
  final latIdx = (lat / g).floor();
  final latC = ((latIdx + 0.5) * g).clamp(-89.99, 89.99).toDouble();
  final step = g / math.max(math.cos(latC * math.pi / 180), 0.1);
  final lonIdx = ((lon + 180) / step).floor();
  final lonC = -180 + (lonIdx + 0.5) * step;
  return (lat: _round6(latC), lon: _round6(lonC));
}

double _round6(double value) => (value * 1e6).round() / 1e6;
