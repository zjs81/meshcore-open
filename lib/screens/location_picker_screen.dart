import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/map_tile_cache_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/adaptive_app_bar_title.dart';
import 'coordinate_map_screen.dart';
import 'map_screen.dart';

/// Map with a fixed centre pin. Pops the chosen [LatLng], or null on back.
class LocationPickerScreen extends StatefulWidget {
  /// Start position; defaults to the Map tab's last camera.
  final LatLng? initial;

  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const double _minZoom = 2.0;
  static const double _maxZoom = 18.0;
  static const double _pinnedZoom = 15.0;
  static const double _pinSize = 48.0;

  final MapController _mapController = MapController();
  late final ({LatLng center, double zoom}) _initialCamera;
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _initialCamera = initial != null
        ? (center: initial, zoom: _pinnedZoom)
        : savedMapCamera() ?? (center: const LatLng(20, 0), zoom: _minZoom);
    _center = _initialCamera.center;
  }

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

  /// Wraps longitude to ±180 (the camera can go past it) and clamps latitude.
  LatLng get _normalizedCenter {
    final lon = ((_center.longitude + 180) % 360 + 360) % 360 - 180;
    return LatLng(_center.latitude.clamp(-90.0, 90.0), lon);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mapTheme = MeshMapTheme.of(context);
    final tileCache = context.read<MapTileCacheService>();
    final center = _normalizedCenter;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AdaptiveAppBarTitle(l10n.location_pickOnMap),
      ),
      // Scrolls at large text sizes instead of covering the map.
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCamera.center,
                      initialZoom: _initialCamera.zoom,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      interactionOptions: const InteractionOptions(
                        flags: ~InteractiveFlag.rotate,
                      ),
                      onPositionChanged: (camera, _) =>
                          setState(() => _center = camera.center),
                      onTap: (_, point) => _mapController.move(
                        point,
                        _mapController.camera.zoom,
                      ),
                    ),
                    children: [tileCache.buildTileLayer(context)],
                  ),
                  // Pin tip at the map centre.
                  Center(
                    child: IgnorePointer(
                      child: Transform.translate(
                        offset: const Offset(0, -_pinSize / 2),
                        child: Icon(
                          Icons.location_on,
                          size: _pinSize,
                          color: mapTheme.followsTheme
                              ? mapTheme.accent
                              : MapPalette.batteryLow,
                          shadows: const [
                            Shadow(
                              color: MapPalette.markerShadow,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        CoordinateMapControlButton(
                          icon: Icons.add,
                          tooltip: l10n.map_zoomIn,
                          onPressed: () => _zoomBy(1),
                        ),
                        const SizedBox(height: 8),
                        CoordinateMapControlButton(
                          icon: Icons.remove,
                          tooltip: l10n.map_zoomOut,
                          onPressed: () => _zoomBy(-1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.6,
              ),
              child: Material(
                color: scheme.surfaceContainerLow,
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.locationPicker_hint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${center.latitude.toStringAsFixed(6)}, '
                          '${center.longitude.toStringAsFixed(6)}',
                          style: MeshTheme.mono(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(context, center),
                          icon: const Icon(Icons.check),
                          label: Text(l10n.locationPicker_useLocation),
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
    );
  }
}
