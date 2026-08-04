import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../services/map_tile_cache_service.dart';

class TelemetryLocationMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String label;
  final int contactType;
  final String contactPublicKeyHex;

  const TelemetryLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.contactType,
    required this.contactPublicKeyHex,
  });

  @override
  State<TelemetryLocationMap> createState() => _TelemetryLocationMapState();
}

class _TelemetryLocationMapState extends State<TelemetryLocationMap> {
  static const double _initialZoom = 14.0;
  static const double _minZoom = 2.0;
  static const double _maxZoom = 18.0;

  final MapController _mapController = MapController();

  LatLng get _position => LatLng(widget.latitude, widget.longitude);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TelemetryLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude == widget.latitude &&
        oldWidget.longitude == widget.longitude) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(_position, _initialZoom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connector = context.watch<MeshCoreConnector>();
    final settingsService = context.watch<AppSettingsService>();
    final settings = settingsService.settings;
    final tileCache = context.read<MapTileCacheService>();
    final contacts = _filteredContacts(connector, settings);
    final isDesktop = _isDesktopPlatform(defaultTargetPlatform);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
            final squareHeight = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : maxHeight;
            // Prefer square sizing by width, but cap only the height so the map
            // remains usable on wide screens without growing past the viewport.
            final mapHeight = squareHeight > maxHeight
                ? maxHeight
                : squareHeight;

            return SizedBox(
              width: double.infinity,
              height: mapHeight,
              child: Stack(
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
                          ...contacts.map(_buildContactMarker),
                          _buildTelemetryMarker(),
                          _buildLabelMarker(_position, widget.label),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _MapButton(
                      icon: Icons.filter_list,
                      tooltip: context.l10n.map_filterNodes,
                      onPressed: () =>
                          _showFilterDialog(context, settingsService),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Column(
                      children: [
                        _MapButton(
                          icon: Icons.add,
                          tooltip: context.l10n.map_zoomIn,
                          onPressed: () => _zoomBy(1),
                        ),
                        const SizedBox(height: 6),
                        _MapButton(
                          icon: Icons.remove,
                          tooltip: context.l10n.map_zoomOut,
                          onPressed: () => _zoomBy(-1),
                        ),
                        const SizedBox(height: 6),
                        _MapButton(
                          icon: Icons.my_location,
                          tooltip: context.l10n.map_centerMap,
                          onPressed: () =>
                              _mapController.move(_position, _initialZoom),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Contact> _filteredContacts(
    MeshCoreConnector connector,
    AppSettings settings,
  ) {
    final contacts = settings.mapShowDiscoveryContacts
        ? connector.allContacts
        : connector.allContacts.where((contact) => contact.isActive).toList();

    return contacts.where((contact) {
      if (!contact.hasLocation) return false;
      if (contact.publicKeyHex == widget.contactPublicKeyHex) return false;
      if (contact.type == advTypeChat) return settings.mapShowChatNodes;
      if (contact.type == advTypeRepeater) return settings.mapShowRepeaters;
      return settings.mapShowOtherNodes;
    }).toList();
  }

  Marker _buildTelemetryMarker() {
    return Marker(
      point: _position,
      width: 44,
      height: 44,
      child: IgnorePointer(
        child: _MarkerBubble(
          color: Colors.red,
          icon: _getNodeIcon(widget.contactType),
          size: 24,
        ),
      ),
    );
  }

  Marker _buildContactMarker(Contact contact) {
    return Marker(
      point: LatLng(contact.latitude!, contact.longitude!),
      width: 34,
      height: 34,
      child: IgnorePointer(
        child: _MarkerBubble(
          color: _getNodeColor(contact.type),
          icon: _getNodeIcon(contact.type),
          size: 18,
        ),
      ),
    );
  }

  Marker _buildLabelMarker(LatLng point, String label) {
    return Marker(
      point: point,
      width: 140,
      height: 24,
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        child: Transform.translate(
          offset: const Offset(0, -24),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(camera.center, nextZoom);
  }

  bool _isDesktopPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.linux ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS;
  }

  Color _getNodeColor(int type) {
    switch (type) {
      case advTypeChat:
        return Colors.blue;
      case advTypeRepeater:
        return Colors.green;
      case advTypeRoom:
        return Colors.purple;
      case advTypeSensor:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNodeIcon(int type) {
    switch (type) {
      case advTypeChat:
        return Icons.person;
      case advTypeRepeater:
        return Icons.router;
      case advTypeRoom:
        return Icons.meeting_room;
      case advTypeSensor:
        return Icons.sensors;
      default:
        return Icons.device_unknown;
    }
  }

  void _showFilterDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.map_filterNodes),
        content: SingleChildScrollView(
          child: Consumer<AppSettingsService>(
            builder: (consumerContext, service, child) {
              final settings = service.settings;
              // Reuse the global map filters so the telemetry preview and the
              // main map stay consistent without another settings model.
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: Text(context.l10n.map_chatNodes),
                    value: settings.mapShowChatNodes,
                    onChanged: (value) {
                      service.setMapShowChatNodes(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(context.l10n.map_repeaters),
                    value: settings.mapShowRepeaters,
                    onChanged: (value) {
                      service.setMapShowRepeaters(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(context.l10n.map_otherNodes),
                    value: settings.mapShowOtherNodes,
                    onChanged: (value) {
                      service.setMapShowOtherNodes(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(context.l10n.map_showDiscoveryContacts),
                    value: settings.mapShowDiscoveryContacts,
                    onChanged: (value) {
                      service.setMapShowDiscoveryContacts(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }
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

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MapButton({
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
