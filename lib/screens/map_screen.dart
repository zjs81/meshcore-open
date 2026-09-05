import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/helpers/path_helper.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:meshcore_open/widgets/app_bar.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../l10n/contact_localization.dart';
import '../services/app_settings_service.dart';
import '../services/path_history_service.dart';
import '../services/map_marker_service.dart';
import '../services/map_tile_cache_service.dart';
import '../utils/contact_search.dart';
import '../utils/battery_utils.dart';
import '../utils/route_transitions.dart';
import '../widgets/quick_switch_bar.dart';
import '../widgets/sync_progress_overlay.dart';
import '../icons/los_icon.dart';
import 'channels_screen.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import '../theme/mesh_theme.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/repeater_login_dialog.dart';
import '../widgets/room_login_dialog.dart';
import '../helpers/snack_bar_builder.dart';
import 'repeater_hub_screen.dart';
import 'settings_screen.dart';
import 'line_of_sight_map_screen.dart';

class MapScreen extends StatefulWidget {
  final LatLng? highlightPosition;
  final String? highlightLabel;
  final String? highlightMarkerKey;
  final double highlightZoom;
  final bool hideBackButton;

  const MapScreen({
    super.key,
    this.highlightPosition,
    this.highlightLabel,
    this.highlightMarkerKey,
    this.highlightZoom = 15.0,
    this.hideBackButton = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Zoom level at which node labels start to appear
  static const double _labelZoomThreshold = 14.0;
  // Below this zoom, nearby nodes collapse into clusters.
  static const double _clusterOffZoom = 12.5;
  // Guessed (estimated) locations only render at closer zooms to avoid a
  // carpet of approximate markers at city-wide scale.
  static const double _guessedZoomThreshold = 12.0;
  static const double _mapMinZoom = 2.0;
  static const double _mapMaxZoom = 18.0;

  final MapController _mapController = MapController();
  final MapMarkerService _markerService = MapMarkerService();
  final Set<String> _hiddenMarkerIds = {};
  Set<String> _removedMarkerIds = {};
  bool _isBuildingPathTrace = false;
  bool _isSelectingPoi = false;
  bool _hasInitializedMap = false;
  bool _removedMarkersLoaded = false;
  final List<int> _pathTrace = [];
  final List<int> _pathTraceHopWidths = [];
  final List<Contact> _pathTraceContacts = [];
  final List<LatLng> _points = [];
  final List<Polyline> _polylines = [];
  bool _statsExpanded = false;
  bool _showNodeLabels = true;
  double _zoom = 10.0;
  String? _selectedKey;
  LatLng? _selectedGuessPos;
  _Freshness _freshness = _Freshness.all;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  List<_GuessedLocation> _cachedGuessedLocations = [];
  String _guessedLocationsCacheKey = '';
  int? _sharedMarkersCacheSignature;
  Locale? _sharedMarkersCacheLocale;
  List<_SharedMarker> _cachedSharedMarkers = const [];
  _NodeMarkersCacheKey? _nodeMarkersCacheKey;
  List<Marker> _cachedNodeMarkers = const [];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  ColorScheme get _overlayScheme => Theme.of(context).colorScheme;

  bool get _useDarkOverlay => Theme.of(context).brightness == Brightness.dark;

  Color get _overlayPanelColor => _useDarkOverlay
      ? MapPalette.panelDark
      : _overlayScheme.surfaceContainerLow.withValues(alpha: 0.96);

  Color get _overlayPrimaryTextColor =>
      _useDarkOverlay ? MapPalette.textPrimary : _overlayScheme.onSurface;

  Color get _overlaySecondaryTextColor => _useDarkOverlay
      ? MapPalette.textSecondary
      : _overlayScheme.onSurfaceVariant;

  Color get _overlayMutedTextColor =>
      _useDarkOverlay ? MapPalette.textMuted : _overlayScheme.onSurfaceVariant;

  Color get _overlayBorderColor =>
      _useDarkOverlay ? MapPalette.border : _overlayScheme.outlineVariant;

  Color get _overlayShadowColor => _useDarkOverlay
      ? MapPalette.markerShadow
      : Colors.black.withValues(alpha: 0.18);

  _NodeAge _ageOf(Contact contact) {
    final d = DateTime.now().difference(contact.lastSeen);
    if (d.inMinutes <= 60) return _NodeAge.online;
    if (d.inHours <= 24) return _NodeAge.recent;
    return _NodeAge.stale;
  }

  void _selectNode(Contact contact, {LatLng? guessedPosition}) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedKey = contact.publicKeyHex;
      _selectedGuessPos = guessedPosition;
      _searchQuery = '';
      _searchController.clear();
      _searchFocus.unfocus();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedKey = null;
      _selectedGuessPos = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRemovedMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MeshCoreConnector>().getChannels();
        if (widget.highlightPosition != null) {
          _mapController.move(widget.highlightPosition!, widget.highlightZoom);
        }
      }
    });
  }

  Future<void> _loadRemovedMarkers() async {
    final ids = await _markerService.loadRemovedIds();
    if (!mounted) return;
    setState(() {
      _removedMarkerIds = ids;
      _removedMarkersLoaded = true;
    });
    // If this screen was opened to highlight a marker, and that marker
    // was previously removed, re-enable it now that we've loaded the saved
    // removed IDs.
    if (widget.highlightMarkerKey != null &&
        _removedMarkerIds.contains(widget.highlightMarkerKey)) {
      final updated = Set<String>.from(_removedMarkerIds);
      updated.remove(widget.highlightMarkerKey);
      if (!mounted) return;
      setState(() {
        _removedMarkerIds = updated;
      });
      await _markerService.saveRemovedIds(updated);
    }
  }

  bool _checkLocationPlausibility(double lat, double lon) {
    const double epsilon = 1e-6;
    return (lat.abs() > epsilon || lon.abs() > epsilon) &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lon >= -180.0 &&
        lon <= 180.0;
  }

  double _standardDeviation(List<double> values) {
    if (values.length <= 1) {
      return 0.0;
    }

    final mean = values.reduce((a, b) => a + b) / values.length;

    double sumSquaredDiff = 0.0;
    for (final value in values) {
      final diff = value - mean;
      sumSquaredDiff += diff * diff;
    }

    // Sample standard deviation (n-1) — most appropriate here
    final variance = sumSquaredDiff / (values.length - 1);

    return sqrt(variance);
  }

  // Calculate zoom level based on the spread of points (std deviation in degrees)
  double _zoomFromStdDev(double latStdDev, double lonStdDev) {
    final maxSpread = max(latStdDev, lonStdDev);
    if (maxSpread <= 0) return 13.0;
    // Approximate: each zoom level halves the visible area
    // ~0.01 degrees spread -> zoom 13, ~0.1 -> zoom 10, ~1.0 -> zoom 7
    final zoom = 10.0 - log(maxSpread * 10 + 1) / ln10 * 3;
    return zoom.clamp(4.0, 15.0);
  }

  bool _isDesktopPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.linux ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS;
  }

  void _zoomMapBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta)
        .clamp(_mapMinZoom, _mapMaxZoom)
        .toDouble();
    _mapController.move(camera.center, nextZoom);
  }

  Widget _buildControlRail(
    BuildContext context, {
    required LatLng center,
    required double zoom,
    required MeshCoreConnector connector,
  }) {
    final hasSelf =
        connector.selfLatitude != null && connector.selfLongitude != null;
    return Positioned(
      left: 12,
      bottom: 96,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _overlayPanelColor,
          borderRadius: BorderRadius.circular(MeshRadii.md),
          border: Border.all(color: _overlayBorderColor),
          boxShadow: [
            BoxShadow(
              color: _overlayShadowColor,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MeshRadii.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                color: _overlayPrimaryTextColor,
                icon: const Icon(Icons.add),
                visualDensity: VisualDensity.standard,
                tooltip: context.l10n.map_zoomIn,
                onPressed: () => _zoomMapBy(1),
              ),
              IconButton(
                color: _overlayPrimaryTextColor,
                icon: const Icon(Icons.remove),
                tooltip: context.l10n.map_zoomOut,
                onPressed: () => _zoomMapBy(-1),
              ),
              IconButton(
                color: _overlayPrimaryTextColor,
                icon: const Icon(Icons.crop_free),
                tooltip: context.l10n.map_centerMap,
                onPressed: () => _mapController.move(center, zoom),
              ),
              if (hasSelf)
                IconButton(
                  color: MapPalette.selected,
                  icon: const Icon(Icons.my_location),
                  tooltip: context.l10n.map_setAsMyLocation,
                  onPressed: () => _mapController.move(
                    LatLng(connector.selfLatitude!, connector.selfLongitude!),
                    max(_zoom, 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMapContextPress(
    BuildContext context,
    MeshCoreConnector connector,
    LatLng latLng,
  ) {
    if (_isSelectingPoi) {
      setState(() {
        _isSelectingPoi = false;
      });
      _shareMarker(
        context: context,
        connector: connector,
        position: latLng,
        defaultLabel: context.l10n.map_pointOfInterest,
        flags: 'poi',
      );
      return;
    }
    _showShareMarkerAtPositionSheet(
      context: context,
      connector: connector,
      position: latLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final connectorSnapshot = context
            .select<MeshCoreConnector, _MapConnectorSnapshot>(
              _MapConnectorSnapshot.fromConnector,
            );
        final connector = connectorSnapshot.connector;
        final settings = context.select<AppSettingsService, AppSettings>(
          (service) => service.settings,
        );
        final pathHistoryVersion = context.select<PathHistoryService, int>(
          (service) => service.version,
        );
        final settingsService = context.read<AppSettingsService>();
        final pathHistory = context.read<PathHistoryService>();
        final tileCache = context.read<MapTileCacheService>();
        final scheme = Theme.of(context).colorScheme;
        final isDesktop = _isDesktopPlatform(defaultTargetPlatform);
        final allContacts = connector.allContacts;

        final contacts = settings.mapShowDiscoveryContacts
            ? allContacts
            : allContacts.where((c) => c.isActive).toList();

        final highlightPosition = widget.highlightPosition;
        final sharedMarkers = settings.mapShowMarkers
            ? _collectSharedMarkers(
                    connector,
                    connectorSnapshot.markerSignature,
                  )
                  .where(
                    (marker) =>
                        !_hiddenMarkerIds.contains(marker.id) &&
                        !_removedMarkerIds.contains(marker.id),
                  )
                  .toList()
            : <_SharedMarker>[];

        // Filter by time
        final now = DateTime.now();
        final filteredByTime = settings.mapTimeFilterHours == 0
            ? contacts
            : contacts.where((c) {
                final hoursSinceLastSeen = now.difference(c.lastSeen).inHours;
                return hoursSinceLastSeen <= settings.mapTimeFilterHours;
              }).toList();

        // Quick activity filter (search bar chips)
        final filteredByFreshness = switch (_freshness) {
          _Freshness.all => filteredByTime,
          _Freshness.online =>
            filteredByTime.where((c) => _ageOf(c) == _NodeAge.online).toList(),
          _Freshness.recent =>
            filteredByTime.where((c) => _ageOf(c) != _NodeAge.stale).toList(),
          _Freshness.stale =>
            filteredByTime.where((c) => _ageOf(c) == _NodeAge.stale).toList(),
        };

        // Filter by key prefix
        final keyPrefix = settings.mapKeyPrefix.trim();
        final filteredByKeyPrefix =
            (settings.mapKeyPrefixEnabled && keyPrefix.isNotEmpty)
            ? filteredByFreshness.where((c) {
                return c.publicKeyHex.toLowerCase().startsWith(
                  keyPrefix.toLowerCase(),
                );
              }).toList()
            : filteredByFreshness;

        // Filter by location
        final contactsWithLocation = filteredByKeyPrefix.where((c) {
          return c.hasLocation;
        }).toList();

        // All contacts with a known location — used as anchors regardless of
        // time/key-prefix filters so that repeaters are always available.
        final allContactsWithLocation = allContacts
            .where((c) => c.hasLocation)
            .toList();

        // Guessed markers represent the same node types as known-location
        // markers, so apply the node-type filters before estimating positions.
        final guessCandidates = _filterContactsBySettings(
          filteredByKeyPrefix,
          settings,
          noLocations: true,
        );

        // Compute guessed locations with caching
        final maxRangeKm = _estimateLoRaRangeKm(connector);
        final pathHashByteWidth = connector.pathHashByteWidth
            .clamp(1, 4)
            .toInt();
        final filteredKeys = guessCandidates
            .map((c) => '${c.publicKeyHex}:${c.path.join("-")}')
            .join(',');
        final anchorKeys = allContactsWithLocation
            .map(
              (c) =>
                  '${c.publicKeyHex}:${c.latitude}:${c.longitude}:${PathHelper.formatHopHex(c.path.isNotEmpty ? c.path.sublist(max(0, c.path.length - pathHashByteWidth)) : const [])}',
            )
            .join(',');
        final cacheKey =
            '$filteredKeys|$anchorKeys|$pathHistoryVersion:$pathHashByteWidth:${connector.currentFreqHz}:${connector.currentSf}:${connector.currentBwHz}:${connector.currentTxPower}:${settings.mapShowGuessedLocations}';
        if (cacheKey != _guessedLocationsCacheKey) {
          _guessedLocationsCacheKey = cacheKey;
          _cachedGuessedLocations = settings.mapShowGuessedLocations
              ? _computeGuessedLocations(
                  guessCandidates,
                  allContactsWithLocation,
                  pathHistory,
                  maxRangeKm,
                  pathHashByteWidth,
                )
              : [];
        }
        final guessedLocations = settings.mapShowGuessedLocations
            ? _cachedGuessedLocations
            : <_GuessedLocation>[];

        _polylines.clear();
        _polylines.addAll(
          _points.length > 1
              ? [
                  Polyline(
                    points: _points,
                    strokeWidth: 4,
                    color: MapPalette.selected,
                  ),
                ]
              : <Polyline>[],
        );

        // Collect polylines for shared markers' history with dashed lines
        final List<Polyline> sharedMarkerPolylines = [];
        for (final marker in sharedMarkers) {
          if (marker.history.isNotEmpty) {
            final points = List<LatLng>.from(marker.history);
            points.add(marker.position);
            sharedMarkerPolylines.add(
              Polyline(
                points: points,
                color: marker.isChannel
                    ? (marker.isPublicChannel
                          ? MapPalette.cluster
                          : MapPalette.router)
                    : MapPalette.shared,
                strokeWidth: 3,
              ),
            );
          }
        }

        // Calculate center and zoom of all nodes, or default to (0, 0)
        LatLng center = const LatLng(0, 0);
        double initialZoom = 10.0;
        final hasMapContent =
            contactsWithLocation.isNotEmpty ||
            sharedMarkers.isNotEmpty ||
            _isSelectingPoi ||
            highlightPosition != null;
        if (contactsWithLocation.isNotEmpty || sharedMarkers.isNotEmpty) {
          final allPoints = [
            ...contactsWithLocation.map(
              (c) => LatLng(c.latitude!, c.longitude!),
            ),
            ...sharedMarkers.map((m) => m.position),
          ];
          if (allPoints.length >= 3) {
            final latValues = allPoints.map((p) => p.latitude).toList();
            final lonValues = allPoints.map((p) => p.longitude).toList();

            final meanLat =
                latValues.reduce((a, b) => a + b) / latValues.length;
            final meanLon =
                lonValues.reduce((a, b) => a + b) / lonValues.length;
            final latStdDev = _standardDeviation(latValues);
            final lonStdDev = _standardDeviation(lonValues);

            final filteredPoints = allPoints
                .where(
                  (p) =>
                      (p.latitude - meanLat).abs() <= latStdDev * 2 &&
                      (p.longitude - meanLon).abs() <= lonStdDev * 2,
                )
                .toList();

            if (filteredPoints.isNotEmpty) {
              final filteredLatValues = filteredPoints
                  .map((p) => p.latitude)
                  .toList();
              final filteredLonValues = filteredPoints
                  .map((p) => p.longitude)
                  .toList();
              final avgLat = filteredLatValues.reduce((a, b) => a + b);
              final avgLon = filteredLonValues.reduce((a, b) => a + b);
              center = LatLng(
                avgLat / filteredPoints.length,
                avgLon / filteredPoints.length,
              );
              // Use std deviation of filtered points for zoom
              final filteredLatStdDev = _standardDeviation(filteredLatValues);
              final filteredLonStdDev = _standardDeviation(filteredLonValues);
              initialZoom = _zoomFromStdDev(
                filteredLatStdDev,
                filteredLonStdDev,
              );
            } else {
              center = LatLng(meanLat, meanLon);
              initialZoom = _zoomFromStdDev(latStdDev, lonStdDev);
            }
          } else {
            double avgLat = 0.0;
            double avgLon = 0.0;
            for (final point in allPoints) {
              avgLat += point.latitude;
              avgLon += point.longitude;
            }
            center = LatLng(
              avgLat / allPoints.length,
              avgLon / allPoints.length,
            );
            initialZoom = 12.0;
          }
        }
        if (highlightPosition != null) {
          center = highlightPosition;
          initialZoom = widget.highlightZoom;
        }

        // Re center map after removed markers have loaded
        if (!_hasInitializedMap && _removedMarkersLoaded) {
          _hasInitializedMap = true;
          _showNodeLabels = initialZoom >= _labelZoomThreshold;
          _zoom = initialZoom;
          if (hasMapContent) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _mapController.move(center, initialZoom);
              }
            });
          }
        }

        final allowBack = !connector.isConnected;

        final visibleContacts = _filterContactsBySettings(
          contactsWithLocation,
          settings,
        );
        Contact? selectedContact;
        if (_selectedKey != null) {
          for (final c in allContacts) {
            if (c.publicKeyHex == _selectedKey) {
              selectedContact = c;
              break;
            }
          }
        }
        final locatedTotal = allContacts.where((c) => c.hasLocation).length;
        final hiddenCount = max(0, locatedTotal - visibleContacts.length);
        final onlineCount = visibleContacts
            .where((c) => _ageOf(c) == _NodeAge.online)
            .length;
        final repeaterCount = visibleContacts
            .where((c) => c.type == advTypeRepeater)
            .length;

        return PopScope(
          canPop: allowBack,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: scheme.surface,
              foregroundColor: scheme.onSurface,
              title: AppBarTitle(context.l10n.map_title),
              centerTitle: true,
              automaticallyImplyLeading: false,
              bottom: const SyncProgressAppBarBottom(),
              actions: [
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (!_isBuildingPathTrace &&
                        connector.selfLatitude != null &&
                        connector.selfLongitude != null)
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.radar),
                            const SizedBox(width: 8),
                            Text(context.l10n.contacts_pathTrace),
                          ],
                        ),
                        onTap: () => _startPath(
                          LatLng(
                            connector.selfLatitude!,
                            connector.selfLongitude!,
                          ),
                        ),
                      ),
                    if (!_isBuildingPathTrace)
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const LosIcon(),
                            const SizedBox(width: 8),
                            Text(context.l10n.map_lineOfSight),
                          ],
                        ),
                        onTap: () {
                          final candidates = <LineOfSightEndpoint>[];
                          if (connector.selfLatitude != null &&
                              connector.selfLongitude != null) {
                            candidates.add(
                              LineOfSightEndpoint(
                                label: context.l10n.pathTrace_you,
                                point: LatLng(
                                  connector.selfLatitude!,
                                  connector.selfLongitude!,
                                ),
                                color: MapPalette.selected,
                                icon: Icons.person_pin_circle,
                              ),
                            );
                          }
                          for (final c in contactsWithLocation) {
                            candidates.add(
                              LineOfSightEndpoint(
                                label: c.name,
                                point: LatLng(c.latitude!, c.longitude!),
                                color: _getNodeColor(c.type),
                                icon: _getNodeIcon(c.type),
                              ),
                            );
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LineOfSightMapScreen(
                                title: context.l10n.map_losScreenTitle,
                                candidates: candidates,
                              ),
                            ),
                          );
                        },
                      ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(context.l10n.common_disconnect),
                        ],
                      ),
                      onTap: () => _disconnect(context, connector),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          const Icon(Icons.settings),
                          const SizedBox(width: 8),
                          Text(context.l10n.settings_title),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            body: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: initialZoom,
                    minZoom: _mapMinZoom,
                    maxZoom: _mapMaxZoom,
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
                    onTap: (_, latLng) {
                      if (_isSelectingPoi) {
                        setState(() {
                          _isSelectingPoi = false;
                        });
                        _shareMarker(
                          context: context,
                          connector: connector,
                          position: latLng,
                          defaultLabel: context.l10n.map_pointOfInterest,
                          flags: 'poi',
                        );
                        return;
                      }
                      // Tapping empty map dismisses selection + search.
                      if (_selectedKey != null || _searchQuery.isNotEmpty) {
                        setState(() {
                          _selectedKey = null;
                          _selectedGuessPos = null;
                          _searchQuery = '';
                          _searchController.clear();
                          _searchFocus.unfocus();
                        });
                      }
                    },
                    onLongPress: (_, latLng) {
                      _handleMapContextPress(context, connector, latLng);
                    },
                    onSecondaryTap: (_, latLng) {
                      _handleMapContextPress(context, connector, latLng);
                    },
                    onPositionChanged: (camera, hasGesture) {
                      // Track zoom in half-step buckets so cluster/marker
                      // detail levels update without rebuilding every frame.
                      final bucket = (camera.zoom * 2).roundToDouble() / 2;
                      final shouldShow = camera.zoom >= _labelZoomThreshold;
                      if ((bucket != _zoom || shouldShow != _showNodeLabels) &&
                          mounted) {
                        setState(() {
                          _zoom = bucket;
                          _showNodeLabels = shouldShow;
                        });
                      }
                    },
                  ),
                  children: [
                    tileCache.buildTileLayer(context),
                    if (_polylines.isNotEmpty && _isBuildingPathTrace)
                      PolylineLayer(polylines: _polylines),
                    if (sharedMarkerPolylines.isNotEmpty)
                      PolylineLayer(polylines: sharedMarkerPolylines),
                    MarkerLayer(
                      markers: [
                        if (highlightPosition != null)
                          Marker(
                            point: highlightPosition,
                            width: 44,
                            height: 44,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: MapPalette.batteryLow,
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
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        if (!settings.mapShowOverlaps &&
                            (_zoom >= _guessedZoomThreshold ||
                                _isBuildingPathTrace))
                          ..._buildGuessedMarker(
                            guessedLocations,
                            showLabels: _showNodeLabels,
                          ),
                        ..._buildNodeMarkersCached(
                          visibleContacts,
                          settings,
                          connectorSnapshot.contactsSignature,
                          connectorSnapshot.batterySignature,
                          _freshness,
                          settings.mapTimeFilterHours,
                          settings.mapKeyPrefixEnabled,
                          settings.mapKeyPrefix,
                          settings.mapShowDiscoveryContacts,
                          Object.hashAllUnordered(
                            settings.batteryChemistryByRepeaterId.entries.map(
                              (entry) => Object.hash(entry.key, entry.value),
                            ),
                          ),
                          showLabels: _showNodeLabels,
                          selectedContact: selectedContact,
                        ),
                        ...sharedMarkers.map(_buildSharedMarker),
                        if (connector.selfLatitude != null &&
                            connector.selfLongitude != null)
                          Marker(
                            point: LatLng(
                              connector.selfLatitude!,
                              connector.selfLongitude!,
                            ),
                            width: 40,
                            height: 40,
                            child: IgnorePointer(
                              ignoring: true,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: MapPalette.panelDark,
                                  border: Border.all(
                                    color: MapPalette.markerOutline,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    const BoxShadow(
                                      color: MapPalette.markerShadow,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: MapPalette.selected,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        if (_showNodeLabels &&
                            connector.selfLatitude != null &&
                            connector.selfLongitude != null)
                          _buildNodeLabelMarker(
                            point: LatLng(
                              connector.selfLatitude!,
                              connector.selfLongitude!,
                            ),
                            label: context.l10n.pathTrace_you,
                          ),
                      ],
                    ),
                  ],
                ),
                if (selectedContact == null)
                  _buildControlRail(
                    context,
                    center: center,
                    zoom: initialZoom,
                    connector: connector,
                  ),
                if (!_isBuildingPathTrace)
                  _buildTopOverlay(
                    context,
                    connector: connector,
                    settingsService: settingsService,
                    allContacts: allContacts,
                    guessedLocations: guessedLocations,
                    visibleCount:
                        visibleContacts.length +
                        ((settings.mapShowGuessedLocations &&
                                _zoom >= _guessedZoomThreshold)
                            ? guessedLocations.length
                            : 0),
                    onlineCount: onlineCount,
                    repeaterCount: repeaterCount,
                    hiddenCount: hiddenCount,
                    pinCount: sharedMarkers.length,
                  ),
                if (_isBuildingPathTrace) _buildPathTraceOverlay(),
                if (selectedContact != null && !_isBuildingPathTrace)
                  _buildSelectedNodeCard(context, selectedContact, connector),
              ],
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: QuickSwitchBar(
                selectedIndex: 2,
                onDestinationSelected: (index) =>
                    _handleQuickSwitch(index, context),
                contactsUnreadCount: connector.getTotalContactsUnreadCount(),
                channelsUnreadCount: connector.getTotalChannelsUnreadCount(),
                highContrast: _useDarkOverlay,
              ),
            ),
            floatingActionButton:
                (selectedContact == null && !_isBuildingPathTrace)
                ? FloatingActionButton(
                    onPressed: () => _showFilterSheet(context, settingsService),
                    tooltip: context.l10n.map_filterNodes,
                    child: const Icon(Icons.filter_list),
                  )
                : null,
          ),
        );
      },
    );
  }

  List<Marker> _buildNodeMarkersCached(
    List<Contact> contacts,
    AppSettings settings,
    int contactsSignature,
    int batterySignature,
    _Freshness freshness,
    double timeFilterHours,
    bool keyPrefixEnabled,
    String keyPrefix,
    bool showDiscoveryContacts,
    int batteryChemistrySignature, {
    required bool showLabels,
    Contact? selectedContact,
  }) {
    final visibleContactsSignature = Object.hashAll(
      contacts.map(
        (contact) =>
            Object.hash(_mapContactSignature(contact), _ageOf(contact)),
      ),
    );
    final key = _NodeMarkersCacheKey(
      contactsSignature: contactsSignature,
      visibleContactsSignature: visibleContactsSignature,
      batterySignature: batterySignature,
      freshness: freshness,
      timeFilterHours: timeFilterHours,
      keyPrefixEnabled: keyPrefixEnabled,
      keyPrefix: keyPrefix,
      showDiscoveryContacts: showDiscoveryContacts,
      batteryChemistrySignature: batteryChemistrySignature,
      showLabels: showLabels,
      selectedKey: selectedContact?.publicKeyHex,
      zoom: _zoom,
      overlapsMode: settings.mapShowOverlaps,
      showRepeaters: settings.mapShowRepeaters,
      showChatNodes: settings.mapShowChatNodes,
      showOtherNodes: settings.mapShowOtherNodes,
      isBuildingPathTrace: _isBuildingPathTrace,
    );
    if (key != _nodeMarkersCacheKey) {
      _nodeMarkersCacheKey = key;
      _cachedNodeMarkers = List.unmodifiable(
        _buildNodeMarkers(
          contacts,
          settings,
          showLabels: showLabels,
          selectedContact: selectedContact,
        ),
      );
    }
    return _cachedNodeMarkers;
  }

  List<_GuessedLocation> _computeGuessedLocations(
    List<Contact> allContacts,
    List<Contact> withLocation,
    PathHistoryService pathHistory,
    double? maxRangeKm,
    int pathHashByteWidth,
  ) {
    final result = <_GuessedLocation>[];
    final hopWidth = pathHashByteWidth.clamp(1, 4).toInt();
    final anchorsByPrefix = <String, List<Contact>>{};
    for (final repeater in withLocation) {
      if (repeater.type != advTypeRepeater) continue;
      if (repeater.publicKey.length < hopWidth) continue;
      final prefix = PathHelper.formatHopHex(
        repeater.publicKey.sublist(0, hopWidth),
      );
      anchorsByPrefix.putIfAbsent(prefix, () => []).add(repeater);
    }

    for (final contact in allContacts) {
      if (contact.hasLocation) continue;
      if (contact.lastSeen.isBefore(
        DateTime.now().subtract(const Duration(hours: 24)),
      )) {
        continue; // skip stale contacts
      }

      final anchorSet = <LatLng>{};

      // Collect the contact-side (last-hop) repeater from every known path.
      // path = [device-side hop, ..., contact-side hop]
      // Only the last hop chunk is actually within radio range of the contact.
      final pathSets = <List<int>>[
        contact.path.toList(),
        ...pathHistory
            .getRecentPaths(contact.publicKeyHex)
            .map((r) => r.pathBytes),
      ];
      for (final pathBytes in pathSets) {
        if (pathBytes.isEmpty) continue;
        final lastHop = pathBytes.sublist(max(0, pathBytes.length - hopWidth));
        if (lastHop.isEmpty) continue;

        final repeaters = anchorsByPrefix[PathHelper.formatHopHex(lastHop)];
        if (repeaters != null && repeaters.isNotEmpty) {
          final repeater = repeaters.first;
          anchorSet.add(LatLng(repeater.latitude!, repeater.longitude!));
        }
      }

      // Filter anchors that are geometrically inconsistent with radio range.
      // Two anchors more than 2 * maxRange apart cannot both be in direct radio
      // range of the same node, so isolated outliers are removed.
      final anchors = maxRangeKm != null && anchorSet.length > 1
          ? _filterConsistentAnchors(anchorSet.toList(), maxRangeKm)
          : anchorSet.toList();

      if (anchors.isEmpty) continue;

      final LatLng position;
      if (anchors.length == 1) {
        // Spread single-anchor guesses around the anchor so they remain visible.
        position = _offsetGuessedPosition(
          anchors[0],
          contact,
          radiusMeters: 330,
        );
        if (!_checkLocationPlausibility(
          position.latitude,
          position.longitude,
        )) {
          continue; // discard implausible guesses near (0, 0)
        }
      } else {
        double lat = 0, lon = 0, weight = 1.0;
        int counted = 0;
        for (final a in anchors) {
          if (counted == 0) {
            lat = a.latitude;
            lon = a.longitude;
          } else {
            lat += a.latitude * weight;
            lon += a.longitude * weight;
          }
          // weight subsequent anchors less to create a bias towards the first (if more than 2)
          weight = weight / 2;
          counted++;
        }
        position = _offsetGuessedPosition(
          LatLng(lat / anchors.length, lon / anchors.length),
          contact,
          radiusMeters: anchors.length >= 3 ? 80 : 120,
        );
        if (!_checkLocationPlausibility(
          position.latitude,
          position.longitude,
        )) {
          continue; // discard implausible guesses near (0, 0
        }
      }
      result.add(
        _GuessedLocation(
          contact: contact,
          position: position,
          highConfidence: anchors.length >= 2,
        ),
      );
    }

    return result;
  }

  LatLng _offsetGuessedPosition(
    LatLng anchor,
    Contact contact, {
    required double radiusMeters,
  }) {
    final seed = _guessSeed(contact.publicKey);
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

  /// Estimates the free-space maximum LoRa range in km from the connected
  /// device's current radio parameters.  Returns null if parameters are unknown.
  double? _estimateLoRaRangeKm(MeshCoreConnector connector) {
    final freqHz = connector.currentFreqHz;
    final bwHz = connector.currentBwHz;
    final sf = connector.currentSf;
    final txPower = connector.currentTxPower;
    if (freqHz == null || bwHz == null || sf == null || txPower == null) {
      return null;
    }
    // LoRa receiver sensitivity = thermal noise + NF + required demod SNR
    const noiseFigureDb = 6.0;
    final thermalNoiseDbm = -174.0 + 10 * log(bwHz.toDouble()) / ln10;
    final sensitivityDbm =
        thermalNoiseDbm + noiseFigureDb + _sfToRequiredSnrDb(sf);
    // FSPL at max range equals link budget:
    //   FSPL = 20*log10(d_m) + 20*log10(f_hz) - 147.55
    final linkBudgetDb = txPower.toDouble() - sensitivityDbm;
    final exponent =
        (linkBudgetDb + 147.55 - 20 * log(freqHz.toDouble()) / ln10) / 20;
    return pow(10, exponent) / 1000;
  }

  double _sfToRequiredSnrDb(int sf) {
    switch (sf) {
      case 5:
        return -2.5;
      case 6:
        return -5.0;
      case 7:
        return -7.5;
      case 8:
        return -10.0;
      case 9:
        return -12.5;
      case 10:
        return -15.0;
      case 11:
        return -17.5;
      case 12:
        return -20.0;
      default:
        return -10.0;
    }
  }

  /// Removes anchors that have no neighbour within 2 * maxRangeKm.
  /// A node cannot be simultaneously in radio range of two points farther apart
  /// than twice the expected maximum range.
  List<LatLng> _filterConsistentAnchors(
    List<LatLng> anchors,
    double maxRangeKm,
  ) {
    const distance = Distance();
    final maxDistM = maxRangeKm * 2000;
    return anchors
        .where((a) => anchors.any((b) => b != a && distance(a, b) <= maxDistM))
        .toList();
  }

  List<Marker> _buildGuessedMarker(
    List<_GuessedLocation> guessed, {
    required bool showLabels,
  }) {
    final markers = <Marker>[];

    for (final guess in guessed) {
      if (guess.contact.type == advTypeChat && _isBuildingPathTrace) {
        continue;
      }

      final color = _getNodeColor(guess.contact.type);
      final marker = Marker(
        point: guess.position,
        width: 48,
        height: 48,
        child: GestureDetector(
          onLongPress: () {
            if (_isBuildingPathTrace) _showNodeInfo(context, guess.contact);
          },
          onSecondaryTap: () {
            if (_isBuildingPathTrace) _showNodeInfo(context, guess.contact);
          },
          onTap: () => _isBuildingPathTrace
              ? _addToPath(context, guess.contact, position: guess.position)
              : _selectNode(guess.contact, guessedPosition: guess.position),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _overlayPanelColor,
                border: Border.all(
                  color: guess.highConfidence ? color : _overlayMutedTextColor,
                  width: guess.highConfidence ? 2.5 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _overlayShadowColor,
                    blurRadius: 7,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.not_listed_location,
                color: _overlayPrimaryTextColor,
                size: 19,
              ),
            ),
          ),
        ),
      );

      markers.add(marker);

      if (showLabels) {
        markers.add(
          _buildNodeLabelMarker(
            point: guess.position,
            label: guess.contact.name,
          ),
        );
      }
    }
    return markers;
  }

  List<Contact> _filterContactsBySettings(
    List<Contact> contacts,
    dynamic settings, {
    bool noLocations = false,
  }) {
    List<Contact> filtered = [];
    bool addContact = false;

    for (final contact in contacts) {
      addContact = false;
      if (!contact.hasLocation && !noLocations) {
        continue;
      }

      // Apply node type filters. The overlaps toggle is purely a visual
      // highlight (applied in _buildNodeMarkers) and no longer affects which
      // nodes are shown.
      if (contact.type == advTypeRepeater &&
          (settings.mapShowRepeaters || _isBuildingPathTrace)) {
        addContact = true;
      }
      if (contact.type == advTypeChat &&
          (settings.mapShowChatNodes || _isBuildingPathTrace)) {
        addContact = true;
      }
      if (contact.type != advTypeChat &&
          contact.type != advTypeRepeater &&
          (settings.mapShowOtherNodes || _isBuildingPathTrace)) {
        addContact = true;
      }

      if (contact.type == advTypeChat && _isBuildingPathTrace) {
        addContact = false;
      }

      if (addContact) {
        filtered.add(contact);
      }
    }
    return filtered;
  }

  List<Marker> _buildNodeMarkers(
    List<Contact> contacts,
    settings, {
    required bool showLabels,
    Contact? selectedContact,
  }) {
    final markers = <Marker>[];
    final overlapsMode = settings.mapShowOverlaps && !_isBuildingPathTrace;
    final selectedKey = selectedContact?.publicKeyHex;
    final items = contacts.where((c) => c.publicKeyHex != selectedKey).toList();

    // Key-prefix overlaps are a visual highlight only: flag the repeaters/rooms
    // whose first key byte collides with another repeater/room on the map.
    final overlapPrefixes = <String>{};
    if (overlapsMode) {
      final hopWidth = context
          .read<MeshCoreConnector>()
          .pathHashByteWidth
          .clamp(1, pubKeySize)
          .toInt();
      final counts = <String, int>{};
      for (final contact in contacts) {
        if ((contact.type == advTypeRepeater || contact.type == advTypeRoom) &&
            contact.publicKey.length >= hopWidth) {
          final prefix = PathHelper.formatHopHex(
            contact.publicKey.sublist(0, hopWidth),
          );
          counts[prefix] = (counts[prefix] ?? 0) + 1;
        }
      }
      counts.forEach((prefix, count) {
        if (count > 1) overlapPrefixes.add(prefix);
      });
    }
    final overlapHopWidth = context
        .read<MeshCoreConnector>()
        .pathHashByteWidth
        .clamp(1, pubKeySize)
        .toInt();
    bool isOverlap(Contact contact) =>
        overlapsMode &&
        (contact.type == advTypeRepeater || contact.type == advTypeRoom) &&
        contact.publicKey.length >= overlapHopWidth &&
        overlapPrefixes.contains(
          PathHelper.formatHopHex(
            contact.publicKey.sublist(0, overlapHopWidth),
          ),
        );

    void addNode(Contact contact, {bool dot = false}) {
      final overlap = isOverlap(contact);
      markers.add(_nodeMarker(contact, overlapsMode: overlap, dot: dot));
      if (showLabels) {
        markers.add(
          _buildNodeLabelMarker(
            point: LatLng(contact.latitude!, contact.longitude!),
            label: overlap
                ? "${contact.publicKeyHex.substring(0, 2)}:${contact.name}"
                : contact.name,
          ),
        );
      }
    }

    if (_zoom >= _clusterOffZoom || overlapsMode || _isBuildingPathTrace) {
      for (final contact in items) {
        addNode(contact);
      }
    } else {
      // Grid clustering: bucket markers into ~64px screen cells at the
      // current zoom; cells with 2+ nodes render as a numbered cluster.
      final cellDeg = 360.0 / (256.0 * pow(2.0, _zoom)) * 64.0;
      final cells = <String, List<Contact>>{};
      for (final contact in items) {
        final key =
            '${(contact.latitude! / cellDeg).floor()}:${(contact.longitude! / cellDeg).floor()}';
        (cells[key] ??= []).add(contact);
      }
      for (final cell in cells.values) {
        if (cell.length == 1) {
          addNode(cell.first, dot: true);
        } else {
          markers.add(_clusterMarker(cell));
        }
      }
    }

    // Selected node always renders individually on top, even when its
    // neighbors are clustered or it is filtered out.
    if (selectedContact != null && selectedContact.hasLocation) {
      markers.add(
        _nodeMarker(
          selectedContact,
          overlapsMode: isOverlap(selectedContact),
          selected: true,
        ),
      );
      markers.add(
        _buildNodeLabelMarker(
          point: LatLng(selectedContact.latitude!, selectedContact.longitude!),
          label: selectedContact.name,
        ),
      );
    }

    return markers;
  }

  Marker _nodeMarker(
    Contact contact, {
    bool overlapsMode = false,
    bool dot = false,
    bool selected = false,
  }) {
    final age = _ageOf(contact);
    final baseColor = overlapsMode
        ? MapPalette.batteryLow
        : _markerColor(contact);
    final stale = age == _NodeAge.stale;
    final online = age == _NodeAge.online;
    final batteryLow = _isBatteryLow(contact);
    final size = selected ? 46.0 : (dot ? 22.0 : 40.0);
    return Marker(
      point: LatLng(contact.latitude!, contact.longitude!),
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          if (_isBuildingPathTrace) _showNodeInfo(context, contact);
        },
        onSecondaryTap: () {
          if (_isBuildingPathTrace) _showNodeInfo(context, contact);
        },
        onTap: () => _isBuildingPathTrace
            ? _addToPath(context, contact)
            : _selectNode(contact),
        child: Center(
          child: dot && !selected
              ? Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor,
                    border: Border.all(
                      color: MapPalette.markerOutline,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: MapPalette.markerShadow,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                )
              : _buildNodeMarkerWidget(
                  color: baseColor,
                  icon: _getNodeIcon(contact.type),
                  selected: selected,
                  stale: stale,
                  online: online,
                  batteryLow: batteryLow,
                ),
        ),
      ),
    );
  }

  Marker _clusterMarker(List<Contact> members) {
    final count = members.length;
    double lat = 0, lon = 0;
    var online = 0;
    for (final m in members) {
      lat += m.latitude!;
      lon += m.longitude!;
      if (_ageOf(m) == _NodeAge.online) online++;
    }
    final center = LatLng(lat / count, lon / count);
    final size = count >= 50
        ? 54.0
        : count >= 16
        ? 50.0
        : count >= 6
        ? 46.0
        : 42.0;
    return Marker(
      point: center,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _zoomToCluster(members),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MapPalette.cluster,
            border: Border.all(color: MapPalette.markerOutline, width: 3),
            boxShadow: const [
              BoxShadow(
                color: MapPalette.markerShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: MeshTheme.mono(
                  fontSize: count >= 100 ? 11.5 : 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (online > 0)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MapPalette.online,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _zoomToCluster(List<Contact> members) {
    HapticFeedback.selectionClick();
    var minLat = double.infinity, maxLat = -double.infinity;
    var minLon = double.infinity, maxLon = -double.infinity;
    for (final m in members) {
      minLat = min(minLat, m.latitude!);
      maxLat = max(maxLat, m.latitude!);
      minLon = min(minLon, m.longitude!);
      maxLon = max(maxLon, m.longitude!);
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
        padding: const EdgeInsets.all(72),
        maxZoom: 16,
      ),
    );
  }

  Marker _buildNodeLabelMarker({required LatLng point, required String label}) {
    return Marker(
      point: point,
      width: 120,
      height: 24,
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        child: Transform.translate(
          offset: const Offset(0, -20),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _overlayPanelColor,
                borderRadius: BorderRadius.circular(MeshRadii.xs),
                border: Border.all(color: _overlayBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: _overlayShadowColor,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MeshTheme.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _overlayPrimaryTextColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getNodeColor(int type) {
    switch (type) {
      case advTypeChat:
        return MapPalette.selected;
      case advTypeRepeater:
        return MapPalette.repeater;
      case advTypeRoom:
        return MapPalette.router;
      case advTypeSensor:
        return MapPalette.sensor;
      default:
        return MapPalette.offline;
    }
  }

  Color _markerColor(Contact contact) {
    switch (contact.type) {
      case advTypeRepeater:
        return MapPalette.repeater;
      case advTypeRoom:
        return MapPalette.router;
      case advTypeSensor:
        return MapPalette.sensor;
      default:
        return _ageColor(_ageOf(contact));
    }
  }

  bool _isBatteryLow(Contact contact) {
    if (contact.type != advTypeRepeater) return false;
    final connector = context.read<MeshCoreConnector>();
    final millivolts = connector.getRepeaterBatteryMillivolts(
      contact.publicKeyHex,
    );
    if (millivolts == null) return false;
    final chemistry = context
        .read<AppSettingsService>()
        .batteryChemistryForRepeater(contact.publicKeyHex);
    return estimateBatteryPercentFromMillivolts(millivolts, chemistry) <= 20;
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

  Widget _buildNodeMarkerWidget({
    required Color color,
    required IconData icon,
    bool selected = false,
    bool stale = false,
    bool online = false,
    bool batteryLow = false,
  }) {
    final statusColor = batteryLow
        ? MapPalette.batteryLow
        : online
        ? MapPalette.online
        : stale
        ? MapPalette.offline
        : MapPalette.stale;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: selected ? 44 : 36,
          height: selected ? 44 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? MapPalette.selected : color,
            border: Border.all(
              color: MapPalette.markerOutline,
              width: selected ? 3 : 2.5,
            ),
            boxShadow: [
              const BoxShadow(
                color: MapPalette.markerShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
              if (selected)
                BoxShadow(
                  color: MapPalette.selected.withValues(alpha: 0.75),
                  blurRadius: 14,
                  spreadRadius: 3,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: selected ? 22 : 19),
        ),
        Positioned(
          right: selected ? -1 : -2,
          bottom: selected ? 0 : -2,
          child: Container(
            width: batteryLow ? 16 : (selected ? 13 : 12),
            height: batteryLow ? 16 : (selected ? 13 : 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              border: Border.all(color: _overlayPanelColor, width: 2),
            ),
            alignment: Alignment.center,
            child: batteryLow
                ? const Icon(Icons.battery_alert, size: 10, color: Colors.white)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _overlaySecondaryTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _ageColor(_NodeAge age) {
    switch (age) {
      case _NodeAge.online:
        return MapPalette.online;
      case _NodeAge.recent:
        return MapPalette.stale;
      case _NodeAge.stale:
        return MapPalette.textMuted;
    }
  }

  String _ageLabel(_NodeAge age) {
    switch (age) {
      case _NodeAge.online:
        return context.l10n.map_online;
      case _NodeAge.recent:
        return context.l10n.map_recent;
      case _NodeAge.stale:
        return context.l10n.map_stale;
    }
  }

  Widget _buildTopOverlay(
    BuildContext context, {
    required MeshCoreConnector connector,
    required AppSettingsService settingsService,
    required List<Contact> allContacts,
    required List<_GuessedLocation> guessedLocations,
    required int visibleCount,
    required int onlineCount,
    required int repeaterCount,
    required int hiddenCount,
    required int pinCount,
  }) {
    final settings = settingsService.settings;
    final hasQuery = _searchQuery.trim().isNotEmpty;
    return Positioned(
      top: 8,
      left: 12,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Material(
                  color: _overlayPanelColor,
                  shape: StadiumBorder(
                    side: BorderSide(color: _overlayBorderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: context.l10n.map_searchHint,
                      hintStyle: TextStyle(color: _overlaySecondaryTextColor),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: _overlayPrimaryTextColor,
                      ),
                      suffixIcon: hasQuery
                          ? IconButton(
                              color: _overlayPrimaryTextColor,
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: _overlayPrimaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: MapPalette.selected,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _overlayPanelColor,
                shape: StadiumBorder(
                  side: BorderSide(color: _overlayBorderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _statsExpanded = !_statsExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.hub,
                          size: 15,
                          color: MapPalette.selected,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$visibleCount',
                          style: MeshTheme.mono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _overlayPrimaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        AnimatedRotation(
                          turns: _statsExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more,
                            size: 16,
                            color: _overlayPrimaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final chips = <Widget>[
                _mapChip(
                  label: context.l10n.time_allTime,
                  selected: _freshness == _Freshness.all,
                  onTap: () => setState(() => _freshness = _Freshness.all),
                ),
                _mapChip(
                  label: context.l10n.map_online,
                  selected: _freshness == _Freshness.online,
                  color: MapPalette.online,
                  onTap: () => setState(() => _freshness = _Freshness.online),
                ),
                _mapChip(
                  label: context.l10n.map_recent,
                  selected: _freshness == _Freshness.recent,
                  color: MapPalette.stale,
                  onTap: () => setState(() => _freshness = _Freshness.recent),
                ),
                _mapChip(
                  label: context.l10n.map_stale,
                  selected: _freshness == _Freshness.stale,
                  color: MapPalette.offline,
                  onTap: () => setState(() => _freshness = _Freshness.stale),
                ),
                _mapChip(
                  label: context.l10n.map_repeaters,
                  selected: settings.mapShowRepeaters,
                  color: MapPalette.repeater,
                  onTap: () => settingsService.setMapShowRepeaters(
                    !settings.mapShowRepeaters,
                  ),
                ),
                _mapChip(
                  label: context.l10n.map_chatNodes,
                  selected: settings.mapShowChatNodes,
                  color: MapPalette.selected,
                  onTap: () => settingsService.setMapShowChatNodes(
                    !settings.mapShowChatNodes,
                  ),
                ),
              ];

              if (constraints.maxWidth < 600) {
                return Wrap(runSpacing: 6, children: chips);
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: chips),
              );
            },
          ),
          if (hasQuery)
            _buildSearchResults(context, allContacts, guessedLocations)
          else if (_statsExpanded)
            Align(
              alignment: Alignment.centerRight,
              child: _buildStatsCard(
                context,
                settings: settings,
                visibleCount: visibleCount,
                onlineCount: onlineCount,
                repeaterCount: repeaterCount,
                hiddenCount: hiddenCount,
                pinCount: pinCount,
                guessedCount: guessedLocations.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _mapChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final accent = color ?? MapPalette.selected;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.34),
                _overlayPanelColor,
              )
            : _overlayPanelColor,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? accent : _overlayBorderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check, size: 13, color: _overlayPrimaryTextColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? _overlayPrimaryTextColor
                        : _overlaySecondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    List<Contact> allContacts,
    List<_GuessedLocation> guessedLocations,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final matches =
        allContacts.where((c) => matchesContactQuery(c, query)).toList()
          ..sort((a, b) {
            if (a.hasLocation != b.hasLocation) {
              return a.hasLocation ? -1 : 1;
            }
            return b.lastSeen.compareTo(a.lastSeen);
          });
    final results = matches.take(8).toList();
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: _overlayPanelColor,
        borderRadius: BorderRadius.circular(MeshRadii.md),
        border: Border.all(color: _overlayBorderColor),
        boxShadow: [
          BoxShadow(
            color: _overlayShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.map_noResults,
                style: TextStyle(
                  color: _overlaySecondaryTextColor,
                  fontSize: 13,
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: results.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: _overlayBorderColor),
              itemBuilder: (context, index) {
                final c = results[index];
                final color = _getNodeColor(c.type);
                return InkWell(
                  onTap: () => _onSearchResultTap(c, guessedLocations),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(_getNodeIcon(c.type), size: 18, color: color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _overlayPrimaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                c.publicKeyHex.substring(0, 12),
                                style: MeshTheme.mono(
                                  fontSize: 10.5,
                                  color: _overlaySecondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (c.hasLocation)
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: _overlaySecondaryTextColor,
                          )
                        else
                          Text(
                            context.l10n.map_noGps.toUpperCase(),
                            style: MeshTheme.accentLabel(
                              color: _overlayMutedTextColor,
                              fontSize: 8.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _onSearchResultTap(
    Contact contact,
    List<_GuessedLocation> guessedLocations,
  ) {
    if (contact.hasLocation) {
      _selectNode(contact);
      _mapController.move(
        LatLng(contact.latitude!, contact.longitude!),
        max(_zoom, 14),
      );
      return;
    }
    _GuessedLocation? guess;
    for (final g in guessedLocations) {
      if (g.contact.publicKeyHex == contact.publicKeyHex) {
        guess = g;
        break;
      }
    }
    if (guess != null) {
      _selectNode(contact, guessedPosition: guess.position);
      _mapController.move(guess.position, max(_zoom, 13));
    } else {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
        _searchFocus.unfocus();
      });
      _showNodeInfo(context, contact);
    }
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required dynamic settings,
    required int visibleCount,
    required int onlineCount,
    required int repeaterCount,
    required int hiddenCount,
    required int pinCount,
    required int guessedCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: 230,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _overlayPanelColor,
        borderRadius: BorderRadius.circular(MeshRadii.md),
        border: Border.all(color: _overlayBorderColor),
        boxShadow: [
          BoxShadow(
            color: _overlayShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _statRow(context.l10n.map_visible, visibleCount, MapPalette.selected),
          _statRow(context.l10n.map_online, onlineCount, MapPalette.online),
          _statRow(
            context.l10n.map_repeaters,
            repeaterCount,
            MapPalette.repeater,
          ),
          _statRow(context.l10n.map_hidden, hiddenCount, MapPalette.offline),
          _statRow(context.l10n.map_markers, pinCount, MapPalette.shared),
          Divider(height: 16, color: _overlayBorderColor),
          _buildLegendItem(
            Icons.person,
            context.l10n.map_chat,
            MapPalette.selected,
          ),
          _buildLegendItem(
            Icons.router,
            context.l10n.map_repeater,
            MapPalette.repeater,
          ),
          _buildLegendItem(
            Icons.meeting_room,
            context.l10n.map_room,
            MapPalette.router,
          ),
          _buildLegendItem(
            Icons.sensors,
            context.l10n.map_sensor,
            MapPalette.sensor,
          ),
          _buildLegendItem(
            Icons.flag,
            context.l10n.map_pinDm,
            MapPalette.shared,
          ),
          if (settings.mapShowGuessedLocations && guessedCount > 0)
            _buildLegendItem(
              Icons.not_listed_location,
              context.l10n.map_guessedLocation,
              _overlayMutedTextColor,
            ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: _overlaySecondaryTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$value',
            style: MeshTheme.mono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _overlayPrimaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedNodeCard(
    BuildContext context,
    Contact contact,
    MeshCoreConnector connector,
  ) {
    final color = _markerColor(contact);
    final age = _ageOf(contact);
    final pos = contact.hasLocation
        ? LatLng(contact.latitude!, contact.longitude!)
        : _selectedGuessPos;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, 32 * t),
          child: Opacity(opacity: 1 - t, child: child),
        ),
        child: MeshCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          color: _overlayPanelColor,
          borderColor: _overlayBorderColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarCircle(
                    name: contact.name,
                    size: 38,
                    color: color,
                    icon: _getNodeIcon(contact.type),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                contact.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _overlayPrimaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (contact.isFavorite) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: MapPalette.stale,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            StatusChip(
                              label: _ageLabel(age),
                              color: _ageColor(age),
                              fontSize: 9.5,
                              pulse: age == _NodeAge.online,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                contact.typeLabel(context.l10n),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _overlaySecondaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (pos != null)
                    IconButton(
                      color: _overlayPrimaryTextColor,
                      icon: const Icon(Icons.center_focus_strong, size: 20),
                      tooltip: context.l10n.map_centerOnNode,
                      onPressed: () => _mapController.move(pos, max(_zoom, 15)),
                    ),
                  IconButton(
                    color: _overlayPrimaryTextColor,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _clearSelection,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _miniMeta(
                    context.l10n.map_lastSeen,
                    _formatLastSeen(contact.lastSeen),
                  ),
                  _miniMeta(
                    context.l10n.map_path,
                    contact.pathLabel(
                      context.l10n,
                      pathHashByteWidth: connector.pathHashByteWidth,
                    ),
                  ),
                  _miniMeta('ID', contact.publicKeyHex.substring(0, 12)),
                  if (pos != null)
                    _miniMeta(
                      context.l10n.map_location,
                      '${contact.hasLocation ? '' : '~'}${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ..._selectedNodeActions(context, contact, connector),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: MapPalette.selected,
                    ),
                    onPressed: () => _showNodeInfo(
                      context,
                      contact,
                      guessedPosition: contact.hasLocation
                          ? null
                          : _selectedGuessPos,
                    ),
                    child: Text(context.l10n.map_details),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniMeta(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: MeshTheme.accentLabel(
            color: _overlayMutedTextColor,
            fontSize: 8,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: MeshTheme.mono(
            fontSize: 11.5,
            color: _overlayPrimaryTextColor,
          ),
        ),
      ],
    );
  }

  List<Widget> _selectedNodeActions(
    BuildContext context,
    Contact contact,
    MeshCoreConnector connector,
  ) {
    Widget action(String label, IconData icon, VoidCallback onPressed) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 12.5)),
        ),
      );
    }

    switch (contact.type) {
      case advTypeChat:
        return [
          action(context.l10n.contacts_openChat, Icons.chat_bubble_outline, () {
            if (!contact.isActive) {
              connector.importDiscoveredContact(contact);
            }
            final unread = connector.getUnreadCountForContactKey(
              contact.publicKeyHex,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatScreen(contact: contact, initialUnreadCount: unread),
              ),
            );
          }),
        ];
      case advTypeRepeater:
        return [
          action(context.l10n.map_manageRepeater, Icons.cell_tower, () {
            if (!contact.isActive) {
              connector.importDiscoveredContact(contact);
            }
            _showRepeaterLogin(context, contact);
          }),
        ];
      case advTypeRoom:
        return [
          action(context.l10n.map_joinRoom, Icons.meeting_room, () {
            if (!contact.isActive) {
              connector.importDiscoveredContact(contact);
            }
            _showRoomLogin(context, contact);
          }),
        ];
      default:
        return const [];
    }
  }

  List<_SharedMarker> _collectSharedMarkers(
    MeshCoreConnector connector,
    int markerSignature,
  ) {
    final locale = Localizations.localeOf(context);
    if (_sharedMarkersCacheSignature == markerSignature &&
        _sharedMarkersCacheLocale == locale) {
      return _cachedSharedMarkers;
    }

    // Build a _SharedMarker per message (history empty), grouped by dedupe key.
    // Afterwards pick the latest per key and fill its history from older ones.
    final updatesByKey = <String, List<_SharedMarker>>{};
    final selfName = connector.selfName ?? 'Me';

    void addUpdate(_SharedMarker update) {
      (updatesByKey[update.id] ??= <_SharedMarker>[]).add(update);
    }

    for (final contact in connector.contacts) {
      final messages = connector.getMessages(contact);
      for (final message in messages) {
        final payload = parseMarkerText(message.text);
        if (payload == null) continue;
        final fromName = message.isOutgoing ? selfName : contact.name;
        final key = buildSharedMarkerKey(
          sourceId: contact.publicKeyHex,
          label: payload.label,
          fromName: fromName,
          flags: payload.flags,
          isChannel: false,
        );
        addUpdate(
          _SharedMarker(
            id: key,
            position: payload.position,
            label: payload.label.isEmpty
                ? context.l10n.map_sharedPin
                : payload.label,
            flags: payload.flags,
            fromName: fromName,
            sourceLabel: contact.name,
            timestamp: message.timestamp,
            isChannel: false,
            isPublicChannel: false,
          ),
        );
      }
    }

    for (final channel in connector.channels.where((c) => !c.isEmpty)) {
      final isPublic = _isPublicChannel(channel);
      final messages = connector.getChannelMessages(channel);
      for (final message in messages) {
        final payload = parseMarkerText(message.text);
        if (payload == null) continue;
        final key = buildSharedMarkerKey(
          sourceId: 'channel:${channel.index}',
          label: payload.label,
          fromName: message.senderName,
          flags: payload.flags,
          isChannel: true,
        );
        addUpdate(
          _SharedMarker(
            id: key,
            position: payload.position,
            label: payload.label.isEmpty
                ? context.l10n.map_sharedPin
                : payload.label,
            flags: payload.flags,
            fromName: message.senderName,
            sourceLabel: channel.name.isEmpty
                ? 'Channel ${channel.index}'
                : channel.name,
            timestamp: message.timestamp,
            isChannel: true,
            isPublicChannel: isPublic,
          ),
        );
      }
    }

    final markers = <_SharedMarker>[];
    updatesByKey.forEach((_, updates) {
      updates.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final latest = updates.last;
      // History: older positions, drop consecutive duplicates at same position.
      final history = <LatLng>[];
      for (var i = 0; i < updates.length - 1; i++) {
        final p = updates[i].position;
        if (history.isEmpty ||
            history.last.latitude != p.latitude ||
            history.last.longitude != p.longitude) {
          history.add(p);
        }
      }
      markers.add(latest.copyWithHistory(history));
    });

    markers.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _sharedMarkersCacheSignature = markerSignature;
    _sharedMarkersCacheLocale = locale;
    _cachedSharedMarkers = List.unmodifiable(markers);
    return _cachedSharedMarkers;
  }

  Marker _buildSharedMarker(_SharedMarker marker) {
    final markerColor = marker.isChannel
        ? (marker.isPublicChannel ? MapPalette.cluster : MapPalette.router)
        : MapPalette.shared;
    return Marker(
      point: marker.position,
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () async {
          if (_removedMarkerIds.contains(marker.id)) {
            setState(() {
              _removedMarkerIds.remove(marker.id);
            });
            await _markerService.saveRemovedIds(_removedMarkerIds);
          }
          _showMarkerInfo(marker);
        },
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: markerColor,
                border: Border.all(color: MapPalette.markerOutline, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: MapPalette.markerShadow,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.flag, color: Colors.white, size: 19),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepeaterLogin(BuildContext context, Contact repeater) {
    showDialog(
      context: context,
      builder: (context) => RepeaterLoginDialog(
        repeater: repeater,
        onLogin: (password, isAdmin) {
          // Navigate to repeater hub screen after successful login
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RepeaterHubScreen(
                repeater: repeater,
                password: password,
                isAdmin: isAdmin,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRoomLogin(BuildContext context, Contact room) {
    showDialog(
      context: context,
      builder: (context) => RoomLoginDialog(
        room: room,
        // onLogin(password, isAdmin) isAdmin not used for room caht screen
        onLogin: (password, _) {
          final connector = context.read<MeshCoreConnector>();
          final unread = connector.getUnreadCountForContactKey(
            room.publicKeyHex,
          );
          connector.markContactRead(room.publicKeyHex);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatScreen(contact: room, initialUnreadCount: unread),
            ),
          );
        },
      ),
    );
  }

  void _showNodeInfo(
    BuildContext context,
    Contact contact, {
    LatLng? guessedPosition,
  }) {
    final connector = context.read<MeshCoreConnector>();
    showMeshSheet(
      context,
      builder: (sheetContext) {
        final actions = <Widget>[];
        if (contact.type == advTypeChat) {
          actions.add(
            FilledButton(
              onPressed: () {
                if (!contact.isActive) {
                  connector.importDiscoveredContact(contact);
                }
                final unread = connector.getUnreadCountForContactKey(
                  contact.publicKeyHex,
                );
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      contact: contact,
                      initialUnreadCount: unread,
                    ),
                  ),
                );
              },
              child: Text(context.l10n.contacts_openChat),
            ),
          );
        }
        if (contact.type == advTypeRepeater) {
          actions.add(
            FilledButton(
              onPressed: () {
                if (!contact.isActive) {
                  connector.importDiscoveredContact(contact);
                }
                Navigator.pop(sheetContext);
                _showRepeaterLogin(context, contact);
              },
              child: Text(context.l10n.map_manageRepeater),
            ),
          );
        }
        if (contact.type == advTypeRoom) {
          actions.add(
            FilledButton(
              onPressed: () {
                if (!contact.isActive) {
                  connector.importDiscoveredContact(contact);
                }
                Navigator.pop(sheetContext);
                _showRoomLogin(context, contact);
              },
              child: Text(context.l10n.map_joinRoom),
            ),
          );
        }
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BottomSheetHeader(
                  title: contact.name,
                  subtitle: contact.typeLabel(context.l10n),
                  trailing: Icon(
                    _getNodeIcon(contact.type),
                    color: _getNodeColor(contact.type),
                    size: 20,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        context.l10n.map_path,
                        contact.pathLabel(
                          context.l10n,
                          pathHashByteWidth: connector.pathHashByteWidth,
                        ),
                      ),
                      if (contact.hasLocation)
                        _buildInfoRow(
                          context.l10n.map_location,
                          '${contact.latitude!.toStringAsFixed(6)}, ${contact.longitude!.toStringAsFixed(6)}',
                        )
                      else if (guessedPosition != null)
                        _buildInfoRow(
                          context.l10n.map_estLocation,
                          '~${guessedPosition.latitude.toStringAsFixed(6)}, ${guessedPosition.longitude.toStringAsFixed(6)}',
                        ),
                      _buildInfoRow(
                        context.l10n.map_lastSeen,
                        _formatLastSeen(contact.lastSeen),
                      ),
                      _buildInfoRow(
                        context.l10n.map_publicKey,
                        contact.publicKeyHex,
                      ),
                      const SizedBox(height: 16),
                      ...actions,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleQuickSwitch(int index, BuildContext context) {
    if (index == 2) return;
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const ContactsScreen(hideBackButton: true)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const ChannelsScreen(hideBackButton: true)),
        );
        break;
    }
  }

  Future<void> _disconnect(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.common_disconnect),
        content: Text(context.l10n.map_disconnectConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.common_disconnect),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await connector.disconnect();
    }
  }

  void _showMarkerInfo(_SharedMarker marker) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          marker.label.isEmpty ? context.l10n.map_sharedPin : marker.label,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context.l10n.map_from, marker.fromName),
            _buildInfoRow(context.l10n.map_source, marker.sourceLabel),
            _buildInfoRow(
              context.l10n.map_sharedAt,
              _formatLastSeen(marker.timestamp),
            ),
            _buildInfoRow(
              context.l10n.map_location,
              '${marker.position.latitude.toStringAsFixed(6)}, ${marker.position.longitude.toStringAsFixed(6)}',
            ),
            if (marker.flags.isNotEmpty)
              _buildInfoRow(context.l10n.map_flags, marker.flags),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _hiddenMarkerIds.add(marker.id);
              });
              Navigator.pop(dialogContext);
            },
            child: Text(context.l10n.common_hide),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              setState(() {
                _hiddenMarkerIds.add(marker.id);
                _removedMarkerIds.add(marker.id);
              });
              await _markerService.saveRemovedIds(_removedMarkerIds);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(context.l10n.common_remove),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: MeshTheme.mono(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return context.l10n.time_justNow;
    } else if (difference.inMinutes < 60) {
      return context.l10n.time_minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return context.l10n.time_hoursAgo(difference.inHours);
    } else {
      return context.l10n.time_daysAgo(difference.inDays);
    }
  }

  void _showShareMarkerAtPositionSheet({
    required BuildContext context,
    required MeshCoreConnector connector,
    required LatLng position,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.place),
              title: Text(context.l10n.map_shareMarkerHere),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareMarker(
                  context: context,
                  connector: connector,
                  position: position,
                  defaultLabel: context.l10n.map_pointOfInterest,
                  flags: 'poi',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: Text(context.l10n.map_setAsMyLocation),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final successMsg = context.l10n.settings_locationUpdated;
                Navigator.pop(sheetContext);
                if (!connector.isConnected) return;
                await connector.setNodeLocation(
                  lat: position.latitude,
                  lon: position.longitude,
                );
                await connector.refreshDeviceInfo();
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(content: Text(successMsg)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(context.l10n.common_cancel),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareMarker({
    required BuildContext context,
    required MeshCoreConnector connector,
    required LatLng position,
    required String defaultLabel,
    required String flags,
  }) async {
    if (!connector.isConnected) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.map_connectToShareMarkers),
      );
      return;
    }

    final label = await _promptForLabel(context, defaultLabel);
    if (label == null || !mounted) return;

    final markerText = _formatMarkerMessage(position, label, flags);
    if (!mounted) return;

    await _showRecipientSheet(
      // ignore: use_build_context_synchronously
      context: context,
      connector: connector,
      markerText: markerText,
    );
  }

  Future<String?> _promptForLabel(
    BuildContext context,
    String defaultLabel,
  ) async {
    final controller = TextEditingController(text: defaultLabel);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.map_pinLabel),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.l10n.map_label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () {
              final label = controller.text.trim().replaceAll('|', '/');
              Navigator.pop(
                dialogContext,
                label.isEmpty ? defaultLabel : label,
              );
            },
            child: Text(context.l10n.common_continue),
          ),
        ],
      ),
    );
  }

  String _formatMarkerMessage(LatLng position, String label, String flags) {
    final lat = position.latitude.toStringAsFixed(6);
    final lon = position.longitude.toStringAsFixed(6);
    return 'm:$lat,$lon|$label|$flags';
  }

  Future<void> _showRecipientSheet({
    required BuildContext context,
    required MeshCoreConnector connector,
    required String markerText,
  }) async {
    if (!connector.isLoadingChannels && connector.channels.isEmpty) {
      connector.getChannels();
    }
    String query = '';

    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Consumer<MeshCoreConnector>(
            builder: (consumerContext, liveConnector, child) {
              final allContacts = liveConnector.contacts
                  .where(
                    (contact) =>
                        contact.type != advTypeRepeater &&
                        contact.type != advTypeRoom,
                  )
                  .toList();
              return SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          context.l10n.map_sendToContact,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText:
                                context.l10n.contacts_searchContactsNoNumber,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              query = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      ...allContacts
                          .where(
                            (contact) =>
                                query.isEmpty ||
                                matchesContactQuery(contact, query),
                          )
                          .map((contact) {
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(contact.name),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                liveConnector.sendMessage(contact, markerText);
                              },
                            );
                          }),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          context.l10n.map_sendToChannel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (liveConnector.isLoadingChannels)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: LinearProgressIndicator(),
                        )
                      else if (liveConnector.channels
                          .where((c) => !c.isEmpty)
                          .isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(context.l10n.map_noChannelsAvailable),
                        )
                      else
                        ...liveConnector.channels.where((c) => !c.isEmpty).map((
                          channel,
                        ) {
                          final isPublic = _isPublicChannel(channel);
                          final label = channel.name.isEmpty
                              ? 'Channel ${channel.index}'
                              : channel.name;
                          return ListTile(
                            leading: Icon(
                              isPublic ? Icons.public : Icons.tag,
                              color: isPublic
                                  ? MapPalette.cluster
                                  : MapPalette.repeater,
                            ),
                            title: Text(label),
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              final canSend = isPublic
                                  ? await _confirmPublicShare(context, label)
                                  : true;
                              if (canSend) {
                                liveConnector.sendChannelMessage(
                                  channel,
                                  markerText,
                                );
                              }
                            },
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isPublicChannel(Channel channel) {
    return channel.isPublicChannel;
  }

  Future<bool> _confirmPublicShare(
    BuildContext context,
    String channelLabel,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.map_publicLocationShare),
        content: Text(
          context.l10n.map_publicLocationShareConfirm(channelLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.common_share),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showFilterSheet(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showMeshSheet(
      context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Consumer<AppSettingsService>(
            builder: (consumerContext, service, child) {
              final settings = service.settings;
              final scheme = Theme.of(sheetContext).colorScheme;

              Widget freshnessChip(_Freshness value, String label) {
                final selected = _freshness == value;
                final accent = switch (value) {
                  _Freshness.all => MapPalette.selected,
                  _Freshness.online => MapPalette.online,
                  _Freshness.recent => MapPalette.stale,
                  _Freshness.stale => MapPalette.offline,
                };
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  showCheckmark: true,
                  checkmarkColor: accent,
                  backgroundColor: scheme.surfaceContainerLow,
                  selectedColor: Color.alphaBlend(
                    accent.withValues(alpha: 0.22),
                    scheme.surfaceContainerHigh,
                  ),
                  side: BorderSide(
                    color: selected ? accent : scheme.outline,
                    width: selected ? 1.5 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: selected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setSheetState(() {});
                    setState(() => _freshness = value);
                  },
                );
              }

              return SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BottomSheetHeader(
                          title: sheetContext.l10n.map_filterNodes,
                        ),
                        SectionHeader(sheetContext.l10n.map_activity),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              freshnessChip(
                                _Freshness.all,
                                sheetContext.l10n.time_allTime,
                              ),
                              freshnessChip(
                                _Freshness.online,
                                sheetContext.l10n.map_online,
                              ),
                              freshnessChip(
                                _Freshness.recent,
                                sheetContext.l10n.map_recent,
                              ),
                              freshnessChip(
                                _Freshness.stale,
                                sheetContext.l10n.map_stale,
                              ),
                            ],
                          ),
                        ),
                        SectionHeader(
                          sheetContext.l10n.map_lastSeenTime,
                          trailing: Text(
                            _getTimeFilterLabel(settings.mapTimeFilterHours),
                            style: MeshTheme.mono(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Slider(
                            value: _hoursToSliderValue(
                              settings.mapTimeFilterHours,
                            ),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            onChanged: (value) {
                              final hours = _sliderValueToHours(value);
                              service.setMapTimeFilterHours(hours);
                            },
                          ),
                        ),
                        SectionHeader(sheetContext.l10n.map_nodeTypes),
                        SwitchListTile(
                          title: Text(sheetContext.l10n.map_chatNodes),
                          value: settings.mapShowChatNodes,
                          dense: true,
                          onChanged: (value) =>
                              service.setMapShowChatNodes(value),
                        ),
                        SwitchListTile(
                          title: Text(sheetContext.l10n.map_repeaters),
                          value: settings.mapShowRepeaters,
                          dense: true,
                          onChanged: (value) =>
                              service.setMapShowRepeaters(value),
                        ),
                        SwitchListTile(
                          title: Text(sheetContext.l10n.map_otherNodes),
                          value: settings.mapShowOtherNodes,
                          dense: true,
                          onChanged: (value) =>
                              service.setMapShowOtherNodes(value),
                        ),
                        SectionHeader(sheetContext.l10n.map_markers),
                        SwitchListTile(
                          title: Text(sheetContext.l10n.map_showSharedMarkers),
                          value: settings.mapShowMarkers,
                          dense: true,
                          onChanged: (value) =>
                              service.setMapShowMarkers(value),
                        ),
                        SwitchListTile(
                          title: Text(
                            sheetContext.l10n.map_showGuessedLocations,
                          ),
                          value: settings.mapShowGuessedLocations,
                          dense: true,
                          onChanged: (value) =>
                              service.setMapShowGuessedLocations(value),
                        ),
                        SwitchListTile(
                          title: Text(
                            sheetContext.l10n.map_showDiscoveryContacts,
                          ),
                          value: settings.mapShowDiscoveryContacts,
                          dense: true,
                          onChanged: (value) =>
                              service.setMapShowDiscoveryContacts(value),
                        ),
                        SwitchListTile(
                          title: Text(sheetContext.l10n.map_showOverlaps),
                          value: settings.mapShowOverlaps,
                          dense: true,
                          onChanged: (value) =>
                              service.setMapShowOverlaps(value),
                        ),
                        SectionHeader(sheetContext.l10n.map_keyPrefix),
                        SwitchListTile(
                          title: Text(sheetContext.l10n.map_filterByKeyPrefix),
                          value: settings.mapKeyPrefixEnabled,
                          dense: true,
                          onChanged: (value) =>
                              service.setMapKeyPrefixEnabled(value),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          child: TextFormField(
                            initialValue: settings.mapKeyPrefix,
                            enabled: settings.mapKeyPrefixEnabled,
                            decoration: InputDecoration(
                              labelText: sheetContext.l10n.map_publicKeyPrefix,
                              hintText:
                                  sheetContext.l10n.map_publicKeyPrefixHint,
                              isDense: true,
                            ),
                            style: MeshTheme.mono(fontSize: 13),
                            onChanged: (value) =>
                                service.setMapKeyPrefix(value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Convert hours to slider value (0-100) with exponential scaling
  double _hoursToSliderValue(double hours) {
    if (hours == 0) return 100; // All time

    // Map hours exponentially
    // 0-24h: 0-40
    // 24h-7d: 40-60
    // 7d-30d: 60-80
    // 30d-6mo: 80-99
    // All time: 100

    if (hours <= 24) {
      return (hours / 24) * 40;
    } else if (hours <= 168) {
      // 7 days
      return 40 + ((hours - 24) / (168 - 24)) * 20;
    } else if (hours <= 720) {
      // 30 days
      return 60 + ((hours - 168) / (720 - 168)) * 20;
    } else if (hours <= 4380) {
      // 6 months
      return 80 + ((hours - 720) / (4380 - 720)) * 19;
    } else {
      return 100;
    }
  }

  // Convert slider value (0-100) to hours with exponential scaling
  double _sliderValueToHours(double value) {
    if (value >= 99.5) return 0; // All time

    if (value <= 40) {
      return (value / 40) * 24; // 0-24 hours
    } else if (value <= 60) {
      return 24 + ((value - 40) / 20) * (168 - 24); // 1-7 days
    } else if (value <= 80) {
      return 168 + ((value - 60) / 20) * (720 - 168); // 7-30 days
    } else {
      return 720 + ((value - 80) / 19) * (4380 - 720); // 30 days - 6 months
    }
  }

  String _getTimeFilterLabel(double hours) {
    if (hours == 0) return context.l10n.time_allTime;

    if (hours < 1) {
      return '${(hours * 60).round()} ${context.l10n.time_minutes}';
    } else if (hours < 24) {
      final h = hours.round();
      return '$h ${h == 1 ? context.l10n.time_hour : context.l10n.time_hours}';
    } else if (hours < 168) {
      final days = (hours / 24).round();
      return '$days ${days == 1 ? context.l10n.time_day : context.l10n.time_days}';
    } else if (hours < 720) {
      final weeks = (hours / 168).round();
      return '$weeks ${weeks == 1 ? context.l10n.time_week : context.l10n.time_weeks}';
    } else if (hours < 4380) {
      final months = (hours / 730).round();
      return '$months ${months == 1 ? context.l10n.time_month : context.l10n.time_months}';
    } else {
      return context.l10n.time_allTime;
    }
  }

  void _addToPath(BuildContext context, Contact contact, {LatLng? position}) {
    final connector = context.read<MeshCoreConnector>();
    final hopWidth = min(
      connector.pathHashByteWidth.clamp(1, pubKeySize),
      contact.publicKey.length,
    ).toInt();
    final hopPrefix = contact.publicKey.sublist(0, hopWidth);
    for (final existingHop in PathHelper.splitPathBytes(
      _pathTrace,
      connector.pathHashByteWidth,
    )) {
      if (listEquals(existingHop, hopPrefix)) {
        return;
      }
    }
    setState(() {
      _pathTrace.addAll(hopPrefix); // Add the hop-width pubkey prefix.
      _pathTraceHopWidths.add(hopWidth);
      _pathTraceContacts.add(
        contact.copyWith(
          latitude: position?.latitude ?? contact.latitude,
          longitude: position?.longitude ?? contact.longitude,
        ),
      ); // Add contact to path trace contacts
      _points.add(position ?? LatLng(contact.latitude!, contact.longitude!));
    });
  }

  void _startPath(LatLng position) {
    setState(() {
      _isBuildingPathTrace = true;
      _pathTrace.clear();
      _pathTraceHopWidths.clear();
      _pathTraceContacts.clear();
      _points.clear();
      _polylines.clear();
      _points.add(position);
    });
  }

  void _removePath() {
    setState(() {
      final recordedHopWidth = _pathTraceHopWidths.isNotEmpty
          ? _pathTraceHopWidths.removeLast()
          : context.read<MeshCoreConnector>().pathHashByteWidth.clamp(
              1,
              pubKeySize,
            );
      final hopByteCount = min(recordedHopWidth, _pathTrace.length).toInt();
      _pathTraceContacts.removeLast();
      // A path trace hop can be wider than one byte; remove the full hash prefix.
      _pathTrace.removeRange(
        _pathTrace.length - hopByteCount,
        _pathTrace.length,
      );
      _points.removeLast(); // Remove last point from points list
      _polylines.clear(); // Clear polylines
    });
  }

  Widget _buildPathTraceOverlay() {
    final l10n = context.l10n;
    final isImperial =
        context.read<AppSettingsService>().settings.unitSystem ==
        UnitSystem.imperial;
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _overlayPanelColor,
          borderRadius: BorderRadius.circular(MeshRadii.md),
          border: Border.all(color: _overlayBorderColor),
          boxShadow: [
            BoxShadow(
              color: _overlayShadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MeshRadii.md),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.contacts_pathTrace,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _overlayPrimaryTextColor,
                  ),
                ),
                if (_pathTrace.isEmpty) const SizedBox(height: 8),
                if (_pathTrace.isEmpty)
                  Text(
                    l10n.map_tapToAdd,
                    style: TextStyle(
                      fontSize: 12,
                      color: _overlaySecondaryTextColor,
                    ),
                  ),
                const SizedBox(height: 6),
                if (_pathTrace.isNotEmpty)
                  Text(
                    "${l10n.path_currentPathLabel} ${formatDistance(getPathDistanceMeters(_points), isImperial: isImperial)}",
                    style: MeshTheme.mono(
                      fontSize: 12,
                      color: _overlaySecondaryTextColor,
                    ),
                  ),
                SelectableText(
                  PathHelper.splitPathBytes(
                    _pathTrace,
                    context.read<MeshCoreConnector>().pathHashByteWidth,
                  ).map(PathHelper.formatHopHex).join(','),
                  style: MeshTheme.mono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MapPalette.selected,
                  ),
                ),
                // const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 1,
                  runSpacing: 1,
                  children: [
                    if (_pathTrace.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          final hashW = context
                              .read<MeshCoreConnector>()
                              .pathHashByteWidth;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PathTraceMapScreen(
                                title: l10n.contacts_pathTrace,
                                path: Uint8List.fromList(_pathTrace),
                                flipPathAround: false,
                                pathHashByteWidth: hashW,
                                pathContacts: _pathTraceContacts,
                              ),
                            ),
                          );
                          setState(() {
                            _isBuildingPathTrace = false;
                          });
                        },
                        tooltip: l10n.map_runTrace,
                        icon: const Icon(Icons.arrow_forward_outlined),
                      ),
                    if (_pathTrace.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PathTraceMapScreen(
                                title: l10n.contacts_pathTrace,
                                path: Uint8List.fromList(_pathTrace),
                                flipPathAround: true,
                                pathHashByteWidth: context
                                    .read<MeshCoreConnector>()
                                    .pathHashByteWidth,
                                pathContacts: _pathTraceContacts,
                              ),
                            ),
                          );
                          setState(() {
                            _isBuildingPathTrace = false;
                          });
                        },
                        tooltip: l10n.map_runTraceWithReturnPath,
                        icon: const Icon(Icons.replay),
                      ),
                    if (_pathTrace.isNotEmpty)
                      IconButton(
                        onPressed: _removePath,
                        tooltip: l10n.map_removeLast,
                        icon: const Icon(Icons.undo),
                      ),
                    if (_pathTrace.isEmpty)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isBuildingPathTrace = false;
                            _pathTrace.clear();
                            _pathTraceHopWidths.clear();
                            _points.clear();
                            _polylines.clear();
                          });
                          showDismissibleSnackBar(
                            context,
                            content: Text(l10n.map_pathTraceCancelled),
                          );
                        },
                        tooltip: l10n.common_cancel,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _NodeAge { online, recent, stale }

enum _Freshness { all, online, recent, stale }

int _bytesSignature(Iterable<int>? bytes) {
  if (bytes == null) return 0;
  return Object.hashAll(bytes);
}

int _mapContactSignature(Contact contact) {
  return Object.hash(
    contact.publicKeyHex,
    contact.name,
    contact.type,
    contact.flags,
    contact.pathLength,
    _bytesSignature(contact.path),
    contact.pathOverride,
    _bytesSignature(contact.pathOverrideBytes),
    contact.latitude,
    contact.longitude,
    contact.lastSeen.millisecondsSinceEpoch,
    contact.lastMessageAt.millisecondsSinceEpoch,
    contact.isActive,
  );
}

class _MapConnectorSnapshot {
  final MeshCoreConnector connector;
  final int contactsSignature;
  final int markerSignature;
  final int batterySignature;
  final int uiSignature;

  const _MapConnectorSnapshot({
    required this.connector,
    required this.contactsSignature,
    required this.markerSignature,
    required this.batterySignature,
    required this.uiSignature,
  });

  factory _MapConnectorSnapshot.fromConnector(MeshCoreConnector connector) {
    final allContacts = connector.allContacts;
    final contactsSignature = Object.hashAll(
      allContacts.map(_mapContactSignature),
    );
    final batterySignature = Object.hashAll(
      allContacts
          .where((contact) => contact.type == advTypeRepeater)
          .map(
            (contact) => Object.hash(
              contact.publicKeyHex,
              connector.getRepeaterBatteryMillivolts(contact.publicKeyHex),
            ),
          ),
    );

    final markerParts = <Object?>[connector.selfName];
    for (final contact in connector.contacts) {
      markerParts.add(contact.publicKeyHex);
      markerParts.add(contact.name);
      for (final message in connector.getMessages(contact)) {
        if (!message.text.trimLeft().startsWith('m:')) continue;
        markerParts.add(
          Object.hash(
            message.messageId,
            message.text,
            message.timestamp.millisecondsSinceEpoch,
            message.isOutgoing,
          ),
        );
      }
    }
    for (final channel in connector.channels) {
      markerParts.add(
        Object.hash(
          channel.index,
          channel.name,
          channel.isPublicChannel,
          channel.isEmpty,
        ),
      );
      for (final message in connector.getChannelMessages(channel)) {
        if (!message.text.trimLeft().startsWith('m:')) continue;
        markerParts.add(
          Object.hash(
            message.messageId,
            message.text,
            message.senderName,
            message.timestamp.millisecondsSinceEpoch,
          ),
        );
      }
    }

    return _MapConnectorSnapshot(
      connector: connector,
      contactsSignature: contactsSignature,
      markerSignature: Object.hashAll(markerParts),
      batterySignature: batterySignature,
      uiSignature: Object.hash(
        connector.isConnected,
        connector.selfLatitude,
        connector.selfLongitude,
        connector.currentFreqHz,
        connector.currentBwHz,
        connector.currentSf,
        connector.currentTxPower,
        connector.getTotalContactsUnreadCount(),
        connector.getTotalChannelsUnreadCount(),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _MapConnectorSnapshot &&
        contactsSignature == other.contactsSignature &&
        markerSignature == other.markerSignature &&
        batterySignature == other.batterySignature &&
        uiSignature == other.uiSignature;
  }

  @override
  int get hashCode => Object.hash(
    contactsSignature,
    markerSignature,
    batterySignature,
    uiSignature,
  );
}

class _NodeMarkersCacheKey {
  final int contactsSignature;
  final int visibleContactsSignature;
  final int batterySignature;
  final _Freshness freshness;
  final double timeFilterHours;
  final bool keyPrefixEnabled;
  final String keyPrefix;
  final bool showDiscoveryContacts;
  final int batteryChemistrySignature;
  final bool showLabels;
  final String? selectedKey;
  final double zoom;
  final bool overlapsMode;
  final bool showRepeaters;
  final bool showChatNodes;
  final bool showOtherNodes;
  final bool isBuildingPathTrace;

  const _NodeMarkersCacheKey({
    required this.contactsSignature,
    required this.visibleContactsSignature,
    required this.batterySignature,
    required this.freshness,
    required this.timeFilterHours,
    required this.keyPrefixEnabled,
    required this.keyPrefix,
    required this.showDiscoveryContacts,
    required this.batteryChemistrySignature,
    required this.showLabels,
    required this.selectedKey,
    required this.zoom,
    required this.overlapsMode,
    required this.showRepeaters,
    required this.showChatNodes,
    required this.showOtherNodes,
    required this.isBuildingPathTrace,
  });

  @override
  bool operator ==(Object other) {
    return other is _NodeMarkersCacheKey &&
        contactsSignature == other.contactsSignature &&
        visibleContactsSignature == other.visibleContactsSignature &&
        batterySignature == other.batterySignature &&
        freshness == other.freshness &&
        timeFilterHours == other.timeFilterHours &&
        keyPrefixEnabled == other.keyPrefixEnabled &&
        keyPrefix == other.keyPrefix &&
        showDiscoveryContacts == other.showDiscoveryContacts &&
        batteryChemistrySignature == other.batteryChemistrySignature &&
        showLabels == other.showLabels &&
        selectedKey == other.selectedKey &&
        zoom == other.zoom &&
        overlapsMode == other.overlapsMode &&
        showRepeaters == other.showRepeaters &&
        showChatNodes == other.showChatNodes &&
        showOtherNodes == other.showOtherNodes &&
        isBuildingPathTrace == other.isBuildingPathTrace;
  }

  @override
  int get hashCode => Object.hash(
    contactsSignature,
    visibleContactsSignature,
    batterySignature,
    freshness,
    timeFilterHours,
    keyPrefixEnabled,
    keyPrefix,
    showDiscoveryContacts,
    batteryChemistrySignature,
    showLabels,
    selectedKey,
    zoom,
    overlapsMode,
    showRepeaters,
    showChatNodes,
    showOtherNodes,
    isBuildingPathTrace,
  );
}

class _GuessedLocation {
  final Contact contact;
  final LatLng position;
  final bool highConfidence;

  _GuessedLocation({
    required this.contact,
    required this.position,
    required this.highConfidence,
  });
}

class MarkerPayload {
  final LatLng position;
  final String label;
  final String flags;

  MarkerPayload({
    required this.position,
    required this.label,
    required this.flags,
  });
}

/// Parse a shared marker text message of the form
/// `m:<lat>,<lon>|<label>|<flags>` and return a [MarkerPayload].
MarkerPayload? parseMarkerText(String text) {
  final trimmed = text.trim();
  final match = RegExp(
    r'm:([\-0-9.]+),([\-0-9.]+)\|([^|]*)\|(.*)',
  ).firstMatch(trimmed);
  if (match == null) return null;
  final lat = double.tryParse(match.group(1) ?? '');
  final lon = double.tryParse(match.group(2) ?? '');
  if (lat == null || lon == null) return null;
  final label = (match.group(3) ?? '').trim();
  final flags = (match.group(4) ?? '').trim();
  return MarkerPayload(position: LatLng(lat, lon), label: label, flags: flags);
}

/// Build a normalized dedupe key for shared markers.
/// Keeps the same algorithm previously present in both chat and map screens.
String buildSharedMarkerKey({
  required String sourceId,
  required String label,
  required String fromName,
  required String flags,
  required bool isChannel,
}) {
  final normalizedLabel = label.trim().toLowerCase();
  final normalizedFrom = fromName.trim().toLowerCase();
  final normalizedFlags = flags.trim().toLowerCase();
  final scope = isChannel ? 'ch' : 'dm';
  return '$scope|$sourceId|$normalizedFrom|$normalizedLabel|$normalizedFlags';
}

class _SharedMarker {
  final String id;
  final LatLng position;
  final String label;
  final String flags;
  final String fromName;
  final String sourceLabel;
  final DateTime timestamp;
  final bool isChannel;
  final bool isPublicChannel;
  final List<LatLng> history;

  _SharedMarker({
    required this.id,
    required this.position,
    required this.label,
    required this.flags,
    required this.fromName,
    required this.sourceLabel,
    required this.timestamp,
    required this.isChannel,
    required this.isPublicChannel,
    this.history = const [],
  });

  _SharedMarker copyWithHistory(List<LatLng> newHistory) {
    return _SharedMarker(
      id: id,
      position: position,
      label: label,
      flags: flags,
      fromName: fromName,
      sourceLabel: sourceLabel,
      timestamp: timestamp,
      isChannel: isChannel,
      isPublicChannel: isPublicChannel,
      history: newHistory,
    );
  }
}
