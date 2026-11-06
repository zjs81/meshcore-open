import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../theme/mesh_theme.dart';

/// Size in degrees of a square grid cell that covers roughly [cellPx]
/// screen pixels at [zoom] (Web Mercator, 256 px tiles).
double mapGridCellDegrees(double zoom, {double cellPx = 64}) =>
    360.0 / (256.0 * pow(2.0, zoom)) * cellPx;

/// Key of the grid cell that [point] falls into for a cell size of [cellDeg].
String mapGridCellKey(LatLng point, double cellDeg) =>
    '${(point.latitude / cellDeg).floor()}:${(point.longitude / cellDeg).floor()}';

/// Buckets [items] into grid cells of [cellDeg] degrees, keeping insertion
/// order inside each cell.
Map<String, List<T>> mapGridCluster<T>(
  Iterable<T> items,
  LatLng Function(T item) positionOf,
  double cellDeg,
) {
  final cells = <String, List<T>>{};
  for (final item in items) {
    (cells[mapGridCellKey(positionOf(item), cellDeg)] ??= <T>[]).add(item);
  }
  return cells;
}

/// Round marker that stands for several shared points of interest. When
/// [includesSelf] is set, it is drawn with the "You" ring and person icon so
/// the user's own position stays visible under the POIs placed there.
class PoiClusterMarker extends StatelessWidget {
  final int count;
  final bool includesSelf;
  final String semanticLabel;

  const PoiClusterMarker({
    super.key,
    required this.count,
    required this.semanticLabel,
    this.includesSelf = false,
  });

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: includesSelf ? MapPalette.panelDark : MapPalette.router,
        border: Border.all(
          color: includesSelf ? MapPalette.selected : MapPalette.markerOutline,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: MapPalette.markerShadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: includesSelf
          ? const Icon(
              Icons.person_pin_circle,
              color: MapPalette.selected,
              size: 24,
            )
          : Text(
              '$count',
              style: MeshTheme.mono(
                fontSize: count >= 100 ? 13 : 15,
                fontWeight: FontWeight.w800,
                color: MapPalette.markerOutline,
              ),
            ),
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          circle,
          if (includesSelf)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: MapPalette.router,
                  borderRadius: BorderRadius.circular(MeshRadii.pill),
                  border: Border.all(
                    color: MapPalette.markerOutline,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: MeshTheme.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: MapPalette.markerOutline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
