import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_protocol.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../services/map_tile_cache_service.dart';
import '../theme/mesh_theme.dart';
import 'empty_state.dart';
import 'path_map_scaffold.dart';

/// A repeater-to-neighbor link with a resolved position, ready to draw.
/// [distanceMeters] is null when the repeater has no location, in which case
/// only the neighbor is shown: no link line and no link label.
class NeighborLink {
  final Contact neighbor;
  final LatLng point;
  final double snr;
  final int lastHeardSeconds;
  final double? distanceMeters;

  const NeighborLink({
    required this.neighbor,
    required this.point,
    required this.snr,
    required this.lastHeardSeconds,
    this.distanceMeters,
  });
}

/// Map of the logged-in repeater and its neighbors: a line per link labeled
/// with distance, SNR and time since the neighbor was last heard. Name and
/// link labels are pinned to their icon or line in screen space and fade out
/// when they would collide.
class NeighborsMapView extends StatefulWidget {
  final Contact repeater;
  final List<NeighborLink> links;
  final int hiddenCount;

  const NeighborsMapView({
    super.key,
    required this.repeater,
    required this.links,
    required this.hiddenCount,
  });

  @override
  State<NeighborsMapView> createState() => _NeighborsMapViewState();
}

class _NeighborsMapViewState extends State<NeighborsMapView> {
  static const double _minZoom = 2.0;
  static const double _maxZoom = 18.0;
  static const double _singlePointZoom = 13.0;
  static const double _labelGap = 4.0;
  static const double _labelMargin = 2.0;

  final MapController _mapController = MapController();
  MapCamera? _camera;
  String _fitSignature = '';

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NeighborsMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_fitSignature != _signature() && _allPoints.length > 1) {
      _fitSignature = _signature();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitCamera();
      });
    }
  }

  LatLng? get _repeaterPoint => widget.repeater.hasLocation
      ? LatLng(widget.repeater.latitude!, widget.repeater.longitude!)
      : null;

  List<LatLng> get _allPoints => [
    ?_repeaterPoint,
    ...widget.links.map((l) => l.point),
  ];

  String _signature() => Object.hashAll(
    _allPoints.map(
      (p) => Object.hash(
        p.latitude.toStringAsFixed(5),
        p.longitude.toStringAsFixed(5),
      ),
    ),
  ).toString();

  void _fitCamera() {
    final points = _allPoints;
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, _singlePointZoom);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(56),
        maxZoom: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tileCache = context.read<MapTileCacheService>();
    final settings = context.watch<AppSettingsService>().settings;
    final isImperial = settings.unitSystem == UnitSystem.imperial;
    final repeaterPoint = _repeaterPoint;

    if (widget.links.isEmpty) {
      return EmptyState(
        icon: Icons.map_outlined,
        title: l10n.neighbors_mapNoNeighborLocations,
      );
    }

    final points = _allPoints;
    if (_fitSignature.isEmpty && points.length > 1) {
      _fitSignature = _signature();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitCamera();
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
        final squareHeight = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : maxHeight;
        final mapHeight = squareHeight > maxHeight ? maxHeight : squareHeight;

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              height: mapHeight,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: buildPathMapOptions(
                      initialCenter: repeaterPoint ?? widget.links.first.point,
                      initialZoom: _singlePointZoom,
                      bounds: points.length > 1
                          ? LatLngBounds.fromPoints(points)
                          : null,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      onMapReady: () {
                        if (mounted) {
                          setState(() => _camera = _mapController.camera);
                        }
                      },
                      onPositionChanged: (camera, hasGesture) {
                        if (mounted) setState(() => _camera = camera);
                      },
                    ),
                    children: [
                      tileCache.buildTileLayer(context),
                      if (repeaterPoint != null)
                        PolylineLayer(
                          polylines: [
                            for (final link in widget.links)
                              Polyline(
                                points: [repeaterPoint, link.point],
                                strokeWidth: 3.5,
                                color: MeshTheme.snrColor(
                                  link.snr,
                                  blocked: false,
                                ),
                              ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          ...widget.links.map(_buildNeighborMarker),
                          if (repeaterPoint != null)
                            _buildRepeaterMarker(repeaterPoint),
                        ],
                      ),
                    ],
                  ),
                  if (_camera != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: LayoutBuilder(
                          builder: (context, inner) =>
                              _buildLabels(inner.biggest, isImperial, l10n),
                        ),
                      ),
                    ),
                  PathMapDesktopControls(
                    onZoomIn: () => zoomMapBy(
                      _mapController,
                      1,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                    ),
                    onZoomOut: () => zoomMapBy(
                      _mapController,
                      -1,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                    ),
                    onReset: _fitCamera,
                  ),
                  if (widget.hiddenCount > 0)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: MeshPalette.bg1.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(MeshRadii.md),
                            border: Border.all(color: MeshPalette.line2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.gps_off,
                                  size: 15,
                                  color: MeshPalette.warn,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l10n.neighbors_mapHiddenWithoutLocation(
                                      widget.hiddenCount,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: MeshPalette.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Projects labels to screen space. Neighbor name labels are pinned above
  /// their markers and link chips sit centered on their line; both fade out
  /// when they would collide with a marker or an earlier label.
  Widget _buildLabels(Size mapSize, bool isImperial, AppLocalizations l10n) {
    final camera = _camera!;
    final repeaterPoint = _repeaterPoint;
    final occupied = <Rect>[];
    final placed = <Widget>[];

    for (final link in widget.links) {
      occupied.add(
        Rect.fromCircle(
          center: camera.latLngToScreenOffset(link.point),
          radius: 17,
        ),
      );
    }
    if (repeaterPoint != null) {
      occupied.add(
        Rect.fromCircle(
          center: camera.latLngToScreenOffset(repeaterPoint),
          radius: 23,
        ),
      );
    }

    Widget chip(Size size, List<Widget> lines) => SizedBox(
      width: size.width,
      height: size.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MeshPalette.bg.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(MeshRadii.xs),
          border: Border.all(color: MeshPalette.line, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: lines,
          ),
        ),
      ),
    );

    // Neighbor name labels, pinned above their markers, faded out when they
    // would collide with anything else.
    for (final link in widget.links) {
      final center = camera.latLngToScreenOffset(link.point);
      final span = TextSpan(
        text: link.neighbor.name,
        style: MeshTheme.mono(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: MeshPalette.ink,
        ),
      );
      final size = _measureSpans([span], mapSize.width);
      final rect = _clampRect(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - 17 - size.height / 2 - 2),
          width: size.width,
          height: size.height,
        ),
        size,
        mapSize,
      );
      final hidden = _overlaps(rect, occupied);
      placed.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          child: Opacity(
            opacity: hidden ? 0 : 1,
            child: chip(size, [
              Text.rich(
                span,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ),
      );
      if (!hidden) occupied.add(rect);
    }

    // Link chips centered on their line: distance, SNR and heard-time on
    // separate lines; faded out instead of moved when something collides.
    if (repeaterPoint != null) {
      for (final link in widget.links) {
        final mid = LatLng(
          (repeaterPoint.latitude + link.point.latitude) / 2,
          (repeaterPoint.longitude + link.point.longitude) / 2,
        );
        final center = camera.latLngToScreenOffset(mid);
        final distance = isImperial
            ? '${(link.distanceMeters! / 1609.34).toStringAsFixed(2)} '
                  '${l10n.units_mi}'
            : '${(link.distanceMeters! / 1000).toStringAsFixed(2)} '
                  '${l10n.units_km}';
        final spans = [
          TextSpan(
            text: distance,
            style: MeshTheme.mono(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: MeshPalette.ink,
            ),
          ),
          TextSpan(
            text: '${link.snr.toStringAsFixed(1)} dB',
            style: MeshTheme.mono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: MeshTheme.snrColor(link.snr, blocked: false),
            ),
          ),
          TextSpan(
            text: _fmtDuration(l10n, link.lastHeardSeconds + 0.0),
            style: MeshTheme.mono(fontSize: 10, color: MeshPalette.ink2),
          ),
        ];
        final size = _measureSpans(spans, mapSize.width);
        final rect = _clampRect(
          Rect.fromCenter(
            center: center,
            width: size.width,
            height: size.height,
          ),
          size,
          mapSize,
        );
        final hidden = _overlaps(rect, occupied);
        placed.add(
          Positioned(
            left: rect.left,
            top: rect.top,
            child: Opacity(
              opacity: hidden ? 0 : 1,
              child: chip(size, [
                for (final span in spans)
                  Text.rich(
                    span,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
              ]),
            ),
          ),
        );
        if (!hidden) occupied.add(rect);
      }
    }

    return Stack(children: placed);
  }

  Rect _clampRect(Rect rect, Size size, Size mapSize) {
    final maxLeft = mapSize.width - size.width - _labelMargin;
    final maxTop = mapSize.height - size.height - _labelMargin;
    return Rect.fromLTWH(
      rect.left.clamp(_labelMargin, maxLeft),
      rect.top.clamp(_labelMargin, maxTop),
      size.width,
      size.height,
    );
  }

  bool _overlaps(Rect rect, List<Rect> occupied) {
    final inflated = rect.inflate(_labelGap / 2);
    return occupied.any((o) => o.overlaps(inflated));
  }

  Size _measureSpans(List<TextSpan> spans, double maxWidth) {
    var width = 0.0;
    var height = 0.0;
    for (final span in spans) {
      final painter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: maxWidth);
      width = painter.width > width ? painter.width : width;
      height += painter.height;
      painter.dispose();
    }
    return Size(width + 8, height + 4);
  }

  Marker _buildRepeaterMarker(LatLng point) {
    return Marker(
      point: point,
      width: 46,
      height: 46,
      child: IgnorePointer(
        child: _MarkerBubble(
          color: MeshPalette.signal,
          icon: Icons.cell_tower,
          size: 24,
        ),
      ),
    );
  }

  Marker _buildNeighborMarker(NeighborLink link) {
    final isRepeater = link.neighbor.type == advTypeRepeater;
    return Marker(
      point: link.point,
      width: 34,
      height: 34,
      child: IgnorePointer(
        child: _MarkerBubble(
          color: isRepeater ? MeshPalette.warn : MeshPalette.blue,
          icon: isRepeater ? Icons.router : Icons.person,
          size: 18,
        ),
      ),
    );
  }
}

String _fmtDuration(AppLocalizations l10n, double seconds) {
  if (seconds < 60) {
    return l10n.neighbors_durationSeconds(seconds.toStringAsFixed(1));
  }

  final int m = (seconds ~/ 60).toInt();
  final double s = seconds - (60 * m);

  if (m < 60) {
    return l10n.neighbors_durationMinutes(m, s.toStringAsFixed(0));
  }

  final int h = m ~/ 60;
  final int m2 = m % 60;

  return l10n.neighbors_durationHours(h, m2);
}

class _MarkerBubble extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;

  const _MarkerBubble({
    required this.color,
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
