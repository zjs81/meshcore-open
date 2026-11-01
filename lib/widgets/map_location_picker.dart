import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/map_tile_cache_service.dart';

/// Phone GPS fix for centering a map; null when location is unavailable,
/// denied, or the platform has no provider.
Future<LatLng?> fetchPhonePosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 5),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  } catch (_) {
    return null;
  }
}

/// Dialog that lets the user pick a position on the map with a pin.
/// [initial] is the existing point (shown as the pin); [startCenter] is where
/// the camera starts, typically the phone's location.
/// Returns the chosen point, or null when cancelled.
Future<LatLng?> showMapLocationPicker(
  BuildContext context, {
  LatLng? initial,
  LatLng? startCenter,
}) {
  return showDialog<LatLng>(
    context: context,
    builder: (dialogContext) =>
        _MapLocationPickerDialog(initial: initial, startCenter: startCenter),
  );
}

class _MapLocationPickerDialog extends StatefulWidget {
  final LatLng? initial;
  final LatLng? startCenter;

  const _MapLocationPickerDialog({this.initial, this.startCenter});

  @override
  State<_MapLocationPickerDialog> createState() =>
      _MapLocationPickerDialogState();
}

class _MapLocationPickerDialogState extends State<_MapLocationPickerDialog> {
  static const double _minZoom = 2.0;
  static const double _maxZoom = 18.0;

  final MapController _mapController = MapController();
  late LatLng? _pin = widget.initial;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tileCache = context.read<MapTileCacheService>();
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final center = widget.startCenter ?? _pin ?? const LatLng(20, 0);
    final mapHeight = MediaQuery.sizeOf(context).height * 0.55;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.repeater_locationPickerHint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: mapHeight,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: widget.startCenter != null
                            ? 14.0
                            : _pin == null
                            ? 3.0
                            : 12.0,
                        minZoom: _minZoom,
                        maxZoom: _maxZoom,
                        interactionOptions: InteractionOptions(
                          flags: ~InteractiveFlag.rotate,
                          scrollWheelVelocity: isDesktop ? 0.012 : 0.005,
                          cursorKeyboardRotationOptions:
                              CursorKeyboardRotationOptions.disabled(),
                          keyboardOptions: const KeyboardOptions.disabled(),
                        ),
                        onTap: (_, latLng) => setState(() => _pin = latLng),
                      ),
                      children: [
                        tileCache.buildTileLayer(context),
                        if (_pin != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _pin!,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.place,
                                  size: 40,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Column(
                        children: [
                          _ZoomButton(
                            icon: Icons.add,
                            tooltip: l10n.map_zoomIn,
                            onPressed: () => _zoomBy(1),
                          ),
                          const SizedBox(height: 6),
                          _ZoomButton(
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
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.common_cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _pin == null
                      ? null
                      : () => Navigator.pop(context, _pin),
                  child: Text(l10n.map_setLocationAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(camera.center, nextZoom);
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        padding: EdgeInsets.zero,
        iconSize: 20,
      ),
    );
  }
}
