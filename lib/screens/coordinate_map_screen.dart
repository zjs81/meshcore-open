import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../helpers/link_handler.dart';
import '../l10n/l10n.dart';
import '../services/map_tile_cache_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/mesh_ui.dart';

/// Dedicated full-screen map centered on a tapped GPS coordinate.
class CoordinateMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? label;

  const CoordinateMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.label,
  });

  @override
  State<CoordinateMapScreen> createState() => _CoordinateMapScreenState();
}

class _CoordinateMapScreenState extends State<CoordinateMapScreen> {
  static const double _initialZoom = 15.0;
  static const double _minZoom = 2.0;
  static const double _maxZoom = 18.0;

  final MapController _mapController = MapController();

  LatLng get _position => LatLng(widget.latitude, widget.longitude);

  String get _coordinateText => widget.label?.trim().isNotEmpty == true
      ? widget.label!.trim()
      : '${widget.latitude}, ${widget.longitude}';

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(camera.center, nextZoom);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final mapTheme = MeshMapTheme.of(context);
    final tileCache = context.read<MapTileCacheService>();
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final labelSurface = scheme.surfaceContainerLow;
    final iconAccent = readableAccent(
      scheme.primary,
      labelSurface,
      minContrast: 3,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AdaptiveAppBarTitle(l10n.coordinateMap_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: l10n.coordinate_copyLocation,
            onPressed: () =>
                LinkHandler.copyCoordinateLocation(context, _coordinateText),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: l10n.coordinate_openInMaps,
            onPressed: () => LinkHandler.openCoordinateInExternalMaps(
              context,
              widget.latitude,
              widget.longitude,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _position,
              initialZoom: _initialZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              interactionOptions: InteractionOptions(
                flags: ~InteractiveFlag.rotate,
                scrollWheelVelocity: isDesktop ? 0.012 : 0.005,
                cursorKeyboardRotationOptions:
                    CursorKeyboardRotationOptions.disabled(),
                keyboardOptions: isDesktop
                    ? const KeyboardOptions(
                        enableArrowKeysPanning: true,
                        enableWASDPanning: true,
                        enableRFZooming: true,
                      )
                    : const KeyboardOptions.disabled(),
              ),
            ),
            children: [
              tileCache.buildTileLayer(context),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _position,
                    width: 48,
                    height: 48,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mapTheme.followsTheme
                              ? mapTheme.accent
                              : MapPalette.batteryLow,
                          border: Border.all(
                            color: MapPalette.markerOutline,
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
                        child: const Icon(
                          Icons.location_on,
                          color: MapPalette.markerOutline,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _CoordinateMapControlButton(
                  icon: Icons.add,
                  tooltip: l10n.map_zoomIn,
                  onPressed: () => _zoomBy(1),
                ),
                const SizedBox(height: 8),
                _CoordinateMapControlButton(
                  icon: Icons.remove,
                  tooltip: l10n.map_zoomOut,
                  onPressed: () => _zoomBy(-1),
                ),
                const SizedBox(height: 8),
                _CoordinateMapControlButton(
                  icon: Icons.my_location,
                  tooltip: l10n.map_centerMap,
                  onPressed: () => _mapController.move(_position, _initialZoom),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Material(
                color: labelSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MeshRadii.md),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: iconAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _coordinateText,
                          style: MeshTheme.mono(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
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
    );
  }
}

class _CoordinateMapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CoordinateMapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeshRadii.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 22,
      ),
    );
  }
}
