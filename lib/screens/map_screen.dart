import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:meshcore_open/widgets/app_bar.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../connector/meshcore_protocol.dart';
import '../models/app_settings.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../services/path_history_service.dart';
import '../services/map_marker_service.dart';
import '../services/map_tile_cache_service.dart';
import '../utils/contact_search.dart';
import '../utils/route_transitions.dart';
import '../widgets/quick_switch_bar.dart';
import '../icons/los_icon.dart';
import 'channels_screen.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import '../widgets/repeater_login_dialog.dart';
import '../widgets/room_login_dialog.dart';
import 'repeater_hub_screen.dart';
import 'settings_screen.dart';
import 'line_of_sight_map_screen.dart';

class MapScreen extends StatefulWidget {
  final LatLng? highlightPosition;
  final String? highlightLabel;
  final double highlightZoom;
  final bool hideBackButton;

  const MapScreen({
    super.key,
    this.highlightPosition,
    this.highlightLabel,
    this.highlightZoom = 15.0,
    this.hideBackButton = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Zoom level at which node labels start to appear
  static const double _labelZoomThreshold = 12.0;

  final MapController _mapController = MapController();
  final MapMarkerService _markerService = MapMarkerService();
  final Set<String> _hiddenMarkerIds = {};
  Set<String> _removedMarkerIds = {};
  bool _isBuildingPathTrace = false;
  bool _isSelectingPoi = false;
  bool _hasInitializedMap = false;
  bool _removedMarkersLoaded = false;
  final List<int> _pathTrace = [];
  final List<LatLng> _points = [];
  final List<Polyline> _polylines = [];
  bool _legendExpanded = false;
  bool _showNodeLabels = true;
  List<_GuessedLocation> _cachedGuessedLocations = [];
  String _guessedLocationsCacheKey = '';

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

  @override
  Widget build(BuildContext context) {
    return Consumer3<MeshCoreConnector, AppSettingsService, PathHistoryService>(
      builder: (context, connector, settingsService, pathHistory, child) {
        final tileCache = context.read<MapTileCacheService>();
        final settings = settingsService.settings;
        final allContacts = <Contact>[
          ...connector.contacts,
          ...connector.discoveredContacts.where((c) => !c.isActive),
        ];

        final contacts = settings.mapShowDiscoveryContacts
            ? allContacts
            : allContacts.where((c) => c.isActive).toList();

        final highlightPosition = widget.highlightPosition;
        final sharedMarkers = settings.mapShowMarkers
            ? _collectSharedMarkers(connector)
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

        // Filter by key prefix
        final keyPrefix = settings.mapKeyPrefix.trim();
        final filteredByKeyPrefix =
            (settings.mapKeyPrefixEnabled && keyPrefix.isNotEmpty)
            ? filteredByTime.where((c) {
                return c.publicKeyHex.toLowerCase().startsWith(
                  keyPrefix.toLowerCase(),
                );
              }).toList()
            : filteredByTime;

        // Filter by location
        final contactsWithLocation = filteredByKeyPrefix.where((c) {
          if (!c.hasLocation) {
            return false;
          }
          return _checkLocationPlausibility(c.latitude!, c.longitude!);
        }).toList();

        // All contacts with a known location — used as anchors regardless of
        // time/key-prefix filters so that repeaters are always available.
        final allContactsWithLocation = allContacts
            .where(
              (c) =>
                  c.hasLocation &&
                  _checkLocationPlausibility(c.latitude!, c.longitude!),
            )
            .toList();

        // Compute guessed locations with caching
        final maxRangeKm = _estimateLoRaRangeKm(connector);
        final filteredKeys = filteredByKeyPrefix
            .map((c) => '${c.publicKeyHex}:${c.path.join("-")}')
            .join(',');
        final anchorKeys = allContactsWithLocation
            .map(
              (c) =>
                  '${c.publicKeyHex}:${c.latitude}:${c.longitude}:${c.path.isNotEmpty ? c.path.last : ""}',
            )
            .join(',');
        final cacheKey =
            '$filteredKeys|$anchorKeys|${pathHistory.version}:${connector.currentSf}:${connector.currentBwHz}:${connector.currentTxPower}:${settings.mapShowGuessedLocations}';
        if (cacheKey != _guessedLocationsCacheKey) {
          _guessedLocationsCacheKey = cacheKey;
          _cachedGuessedLocations = settings.mapShowGuessedLocations
              ? _computeGuessedLocations(
                  filteredByKeyPrefix,
                  allContactsWithLocation,
                  pathHistory,
                  maxRangeKm,
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
                    color: Colors.blueAccent,
                  ),
                ]
              : <Polyline>[],
        );

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
          if (hasMapContent) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _mapController.move(center, initialZoom);
              }
            });
          }
        }

        final allowBack = !connector.isConnected;

        return PopScope(
          canPop: allowBack,
          child: Scaffold(
            appBar: AppBar(
              title: AppBarTitle(context.l10n.map_title),
              centerTitle: true,
              automaticallyImplyLeading: false,
              actions: [
                if (!_isBuildingPathTrace)
                  IconButton(
                    icon: const Icon(Icons.radar),
                    onPressed: () => _startPath(),
                    tooltip: context.l10n.contacts_pathTrace,
                  ),
                if (!_isBuildingPathTrace)
                  IconButton(
                    icon: const LosIcon(),
                    onPressed: () {
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
                            color: Colors.teal,
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
                    tooltip: context.l10n.map_lineOfSight,
                  ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Colors.red),
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
                    minZoom: 2.0,
                    maxZoom: 18.0,
                    interactionOptions: InteractionOptions(
                      flags: ~InteractiveFlag.rotate,
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
                      }
                    },
                    onLongPress: (_, latLng) {
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
                    },
                    onPositionChanged: (camera, hasGesture) {
                      final shouldShow = camera.zoom >= _labelZoomThreshold;
                      if (shouldShow != _showNodeLabels && mounted) {
                        setState(() {
                          _showNodeLabels = shouldShow;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: kMapTileUrlTemplate,
                      tileProvider: tileCache.tileProvider,
                      userAgentPackageName:
                          MapTileCacheService.userAgentPackageName,
                      maxZoom: 19,
                    ),
                    if (_polylines.isNotEmpty && _isBuildingPathTrace)
                      PolylineLayer(polylines: _polylines),
                    MarkerLayer(
                      markers: [
                        if (highlightPosition != null)
                          Marker(
                            point: highlightPosition,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on_outlined,
                              color: Colors.red[600],
                              size: 34,
                            ),
                          ),
                        if (!_isBuildingPathTrace)
                          ..._buildGuessedMarker(
                            guessedLocations,
                            showLabels: _showNodeLabels,
                          ),
                        ..._buildMarkers(
                          contactsWithLocation,
                          settings,
                          showLabels: _showNodeLabels,
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
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Colors.white,
                                size: 20,
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
                if (!_isBuildingPathTrace)
                  _buildLegend(
                    contactsWithLocation,
                    settings,
                    sharedMarkers.length,
                    guessedLocations.length,
                  ),
                if (_isBuildingPathTrace) _buildPathTraceOverlay(),
              ],
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: QuickSwitchBar(
                selectedIndex: 2,
                onDestinationSelected: (index) =>
                    _handleQuickSwitch(index, context),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showFilterDialog(context, settingsService),
              tooltip: context.l10n.map_filterNodes,
              child: const Icon(Icons.filter_list),
            ),
          ),
        );
      },
    );
  }

  List<_GuessedLocation> _computeGuessedLocations(
    List<Contact> allContacts,
    List<Contact> withLocation,
    PathHistoryService pathHistory,
    double? maxRangeKm,
  ) {
    // Index known-location repeaters by their 1-byte hash.
    // null value = two repeaters share the same hash byte (ambiguous collision).
    final repeaterByHash = <int, Contact?>{};
    for (final c in withLocation) {
      if (c.type == advTypeRepeater) {
        if (repeaterByHash.containsKey(c.publicKey[0])) {
          repeaterByHash[c.publicKey[0]] =
              null; // collision: can't disambiguate
        } else {
          repeaterByHash[c.publicKey[0]] = c;
        }
      }
    }

    final result = <_GuessedLocation>[];

    for (final contact in allContacts) {
      if (contact.hasLocation) continue;

      final anchorSet = <LatLng>{};

      // Collect the contact-side (last-hop) repeater from every known path.
      // path = [device-side hop, ..., contact-side hop]
      // Only path.last is actually within radio range of the contact — using
      // earlier bytes would anchor against our own side of the network.
      final pathSets = <List<int>>[
        contact.path.toList(),
        ...pathHistory
            .getRecentPaths(contact.publicKeyHex)
            .map((r) => r.pathBytes),
      ];
      final lastHopBytes = <int>{};
      for (final pathBytes in pathSets) {
        if (pathBytes.isEmpty) continue;
        final lastHop = pathBytes.last;
        lastHopBytes.add(lastHop);
        final r = repeaterByHash[lastHop];
        if (r != null) anchorSet.add(LatLng(r.latitude!, r.longitude!));
      }

      // Fallback: for any last-hop byte with no GPS repeater, average the
      // positions of contacts with known GPS that share the same last hop.
      // Those contacts are all adjacent to the same unknown repeater, so their
      // centroid is a reasonable proxy for its location.
      for (final byte in lastHopBytes) {
        if (repeaterByHash.containsKey(byte)) continue;
        for (final c in withLocation) {
          if (c.path.isNotEmpty && c.path.last == byte) {
            anchorSet.add(LatLng(c.latitude!, c.longitude!));
          }
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
        // Offset single-anchor guesses so they don't overlap the repeater marker.
        // Use the contact's public key byte as a deterministic angle seed.
        const offsetDeg = 0.003; // ~330 m at the equator
        final angle = (contact.publicKey[1] / 255.0) * 2 * pi;
        position = LatLng(
          anchors[0].latitude + offsetDeg * cos(angle),
          anchors[0].longitude + offsetDeg * sin(angle),
        );

        if (!_checkLocationPlausibility(
          position.latitude,
          position.longitude,
        )) {
          continue; // discard implausible guesses near (0, 0)
        }
      } else {
        double lat = 0, lon = 0;
        for (final a in anchors) {
          lat += a.latitude;
          lon += a.longitude;
        }
        position = LatLng(lat / anchors.length, lon / anchors.length);
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
      final color = _getNodeColor(guess.contact.type);
      final marker = Marker(
        point: guess.position,
        width: 35,
        height: 35,
        child: GestureDetector(
          onTap: () => _showNodeInfo(
            context,
            guess.contact,
            guessedPosition: guess.position,
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: guess.highConfidence ? 0.55 : 0.30,
              ),
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
            child: const Icon(
              Icons.not_listed_location,
              color: Colors.white,
              size: 20,
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

  List<Marker> _buildMarkers(
    List<Contact> contacts,
    settings, {
    required bool showLabels,
  }) {
    final markers = <Marker>[];

    for (final contact in contacts) {
      if (!contact.hasLocation) continue;

      // Apply node type filters
      if (contact.type == advTypeRepeater &&
          (!settings.mapShowRepeaters && !_isBuildingPathTrace)) {
        continue;
      }
      if (contact.type == advTypeChat &&
          !(settings.mapShowChatNodes && !_isBuildingPathTrace)) {
        continue;
      }
      if (contact.type != advTypeChat &&
          contact.type != advTypeRepeater &&
          (!settings.mapShowOtherNodes && !_isBuildingPathTrace)) {
        continue;
      }

      final marker = Marker(
        point: LatLng(contact.latitude!, contact.longitude!),
        width: 35,
        height: 35,
        child: GestureDetector(
          onLongPress: () =>
              _isBuildingPathTrace ? _showNodeInfo(context, contact) : null,
          onTap: () => _isBuildingPathTrace
              ? _addToPath(context, contact)
              : _showNodeInfo(context, contact),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getNodeColor(contact.type),
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
                child: Icon(
                  _getNodeIcon(contact.type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );

      markers.add(marker);
      if (showLabels) {
        markers.add(
          _buildNodeLabelMarker(
            point: LatLng(contact.latitude!, contact.longitude!),
            label: contact.name,
          ),
        );
      }
    }

    return markers;
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

  Widget _buildLegend(
    List<Contact> contactsWithLocation,
    settings,
    int markerCount,
    int guessedCount,
  ) {
    int nodeCount = 0;
    for (final contact in contactsWithLocation) {
      // Apply node type filters
      if (contact.type == advTypeRepeater && !settings.mapShowRepeaters) {
        continue;
      }
      if (contact.type == advTypeChat && !settings.mapShowChatNodes) continue;
      if (contact.type != advTypeChat &&
          contact.type != advTypeRepeater &&
          !settings.mapShowOtherNodes) {
        continue;
      }
      nodeCount++;
    }

    return Positioned(
      top: 16,
      right: 16,
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _legendExpanded = !_legendExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.map_nodesCount(
                            nodeCount +
                                (settings.mapShowGuessedLocations
                                    ? guessedCount
                                    : 0),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          context.l10n.map_pinsCount(markerCount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _legendExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    _buildLegendItem(
                      Icons.person,
                      context.l10n.map_chat,
                      Colors.blue,
                    ),
                    _buildLegendItem(
                      Icons.router,
                      context.l10n.map_repeater,
                      Colors.green,
                    ),
                    _buildLegendItem(
                      Icons.meeting_room,
                      context.l10n.map_room,
                      Colors.purple,
                    ),
                    _buildLegendItem(
                      Icons.sensors,
                      context.l10n.map_sensor,
                      Colors.orange,
                    ),
                    _buildLegendItem(
                      Icons.flag,
                      context.l10n.map_pinDm,
                      Colors.blue,
                    ),
                    _buildLegendItem(
                      Icons.flag,
                      context.l10n.map_pinPrivate,
                      Colors.purple,
                    ),
                    _buildLegendItem(
                      Icons.flag,
                      context.l10n.map_pinPublic,
                      Colors.orange,
                    ),
                    if (settings.mapShowGuessedLocations && guessedCount > 0)
                      _buildLegendItem(
                        Icons.not_listed_location,
                        context.l10n.map_guessedLocation,
                        Colors.grey,
                      ),
                  ],
                ),
              ),
              crossFadeState: _legendExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  List<_SharedMarker> _collectSharedMarkers(MeshCoreConnector connector) {
    final markers = <_SharedMarker>[];
    final selfName = connector.selfName ?? 'Me';

    for (final contact in connector.contacts) {
      final messages = connector.getMessages(contact);
      for (final message in messages) {
        final payload = _parseMarkerText(message.text);
        if (payload == null) continue;
        final fromName = message.isOutgoing ? selfName : contact.name;
        final id = _buildMarkerId(
          sourceId: contact.publicKeyHex,
          timestamp: message.timestamp,
          text: message.text,
        );
        markers.add(
          _SharedMarker(
            id: id,
            position: payload.position,
            label: payload.label,
            flags: payload.flags,
            fromName: fromName,
            sourceLabel: contact.name,
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
        final payload = _parseMarkerText(message.text);
        if (payload == null) continue;
        final id = _buildMarkerId(
          sourceId: 'channel:${channel.index}',
          timestamp: message.timestamp,
          text: message.text,
        );
        markers.add(
          _SharedMarker(
            id: id,
            position: payload.position,
            label: payload.label,
            flags: payload.flags,
            fromName: message.senderName,
            sourceLabel: channel.name.isEmpty
                ? 'Channel ${channel.index}'
                : channel.name,
            isChannel: true,
            isPublicChannel: isPublic,
          ),
        );
      }
    }

    return markers;
  }

  _MarkerPayload? _parseMarkerText(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('m:')) return null;

    final parts = trimmed.substring(2).split('|');
    if (parts.isEmpty) return null;
    final coords = parts[0].split(',');
    if (coords.length != 2) return null;
    final lat = double.tryParse(coords[0].trim());
    final lon = double.tryParse(coords[1].trim());
    if (lat == null || lon == null) return null;

    final label = parts.length > 1 ? parts[1].trim() : '';
    final flags = parts.length > 2 ? parts[2].trim() : '';
    return _MarkerPayload(
      position: LatLng(lat, lon),
      label: label.isEmpty ? context.l10n.map_sharedPin : label,
      flags: flags,
    );
  }

  String _buildMarkerId({
    required String sourceId,
    required DateTime timestamp,
    required String text,
  }) {
    return '$sourceId|${timestamp.millisecondsSinceEpoch}|$text';
  }

  Marker _buildSharedMarker(_SharedMarker marker) {
    final markerColor = marker.isChannel
        ? (marker.isPublicChannel ? Colors.orange : Colors.purple)
        : Colors.blue;
    return Marker(
      point: marker.position,
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () => _showMarkerInfo(marker),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: markerColor,
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
              child: const Icon(Icons.flag, color: Colors.white, size: 20),
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
        onLogin: (password) {
          // Navigate to repeater hub screen after successful login
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RepeaterHubScreen(repeater: repeater, password: password),
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
        onLogin: (password) {
          // Navigate to chat screen after successful login
          context.read<MeshCoreConnector>().markContactRead(room.publicKeyHex);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen(contact: room)),
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNodeIcon(contact.type),
              color: _getNodeColor(contact.type),
            ),
            const SizedBox(width: 8),
            Expanded(child: SelectableText(contact.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', contact.typeLabel),
            _buildInfoRow('Path', contact.pathLabel),
            if (contact.hasLocation)
              _buildInfoRow(
                'Location',
                '${contact.latitude!.toStringAsFixed(6)}, ${contact.longitude!.toStringAsFixed(6)}',
              )
            else if (guessedPosition != null)
              _buildInfoRow(
                'Est. Location',
                '~${guessedPosition.latitude.toStringAsFixed(6)}, ${guessedPosition.longitude.toStringAsFixed(6)}',
              ),
            _buildInfoRow(
              context.l10n.map_lastSeen,
              _formatLastSeen(contact.lastSeen),
            ),
            _buildInfoRow('Public Key', contact.publicKeyHex),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_close),
          ),
          if (contact.type ==
              advTypeChat) // Only show chat button for chat nodes
            TextButton(
              onPressed: () {
                if (!contact.isActive) {
                  connector.importDiscoveredContact(contact);
                }
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(contact: contact),
                  ),
                );
              },
              child: Text(context.l10n.contacts_openChat),
            ),
          if (contact.type == advTypeRepeater)
            TextButton(
              onPressed: () {
                if (!contact.isActive) {
                  connector.importDiscoveredContact(contact);
                }
                Navigator.pop(dialogContext);
                _showRepeaterLogin(context, contact);
              },
              child: Text(context.l10n.map_manageRepeater),
            ),
          if (contact.type == advTypeRoom)
            TextButton(
              onPressed: () {
                if (!contact.isActive) {
                  connector.importDiscoveredContact(contact);
                }
                Navigator.pop(dialogContext);
                _showRoomLogin(context, contact);
              },
              child: Text(context.l10n.map_joinRoom),
            ),
        ],
      ),
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
        title: Text(marker.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context.l10n.map_from, marker.fromName),
            _buildInfoRow(context.l10n.map_source, marker.sourceLabel),
            _buildInfoRow(
              'Location',
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
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(value, style: const TextStyle(fontSize: 14)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.map_connectToShareMarkers)),
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
                              color: isPublic ? Colors.orange : Colors.blue,
                            ),
                            title: Text(label),
                            subtitle: isPublic
                                ? Text(context.l10n.channels_publicChannel)
                                : null,
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

  void _showFilterDialog(
    BuildContext context,
    AppSettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.map_filterNodes),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SingleChildScrollView(
          child: Consumer<AppSettingsService>(
            builder: (consumerContext, service, child) {
              final settings = service.settings;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.map_nodeTypes,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    title: Text(context.l10n.map_showGuessedLocations),
                    value: settings.mapShowGuessedLocations,
                    onChanged: (value) {
                      service.setMapShowGuessedLocations(value ?? true);
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
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.map_keyPrefix,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: Text(context.l10n.map_filterByKeyPrefix),
                    value: settings.mapKeyPrefixEnabled,
                    onChanged: (value) {
                      service.setMapKeyPrefixEnabled(value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextFormField(
                    initialValue: settings.mapKeyPrefix,
                    enabled: settings.mapKeyPrefixEnabled,
                    decoration: InputDecoration(
                      labelText: context.l10n.map_publicKeyPrefix,
                      hintText: 'e.g. ab12',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      service.setMapKeyPrefix(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.map_markers,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: Text(context.l10n.map_showSharedMarkers),
                    value: settings.mapShowMarkers,
                    onChanged: (value) {
                      service.setMapShowMarkers(value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.map_lastSeenTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTimeFilterLabel(settings.mapTimeFilterHours),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Slider(
                    value: _hoursToSliderValue(settings.mapTimeFilterHours),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      final hours = _sliderValueToHours(value);
                      service.setMapTimeFilterHours(hours);
                    },
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

  void _addToPath(BuildContext context, Contact contact) {
    setState(() {
      _pathTrace.add(
        contact.publicKey[0],
      ); // Add first 16 bytes of public key to path trace
      _points.add(LatLng(contact.latitude!, contact.longitude!));
    });
  }

  void _startPath() {
    setState(() {
      _isBuildingPathTrace = true;
      _pathTrace.clear();
      _points.clear();
      _polylines.clear();
    });
  }

  void _removePath() {
    setState(() {
      _pathTrace.removeLast(); // Remove last node from path trace
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.contacts_pathTrace,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_pathTrace.isEmpty) const SizedBox(height: 8),
              if (_pathTrace.isEmpty)
                Text(l10n.map_tapToAdd, style: TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              if (_pathTrace.isNotEmpty)
                Text(
                  "${l10n.path_currentPathLabel} ${formatDistance(getPathDistanceMeters(_points), isImperial: isImperial)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              SelectableText(
                _pathTrace
                    .map((b) => b.toRadixString(16).padLeft(2, '0'))
                    .join(','),
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_pathTrace.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PathTraceMapScreen(
                              title: l10n.contacts_pathTrace,
                              path: Uint8List.fromList(_pathTrace),
                            ),
                          ),
                        );
                        setState(() {
                          _isBuildingPathTrace = false;
                        });
                      },
                      child: Text(l10n.map_runTrace),
                    ),
                  if (_pathTrace.isNotEmpty)
                    ElevatedButton(
                      onPressed: _removePath,
                      child: Text(l10n.map_removeLast),
                    ),
                  if (_pathTrace.isEmpty)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isBuildingPathTrace = false;
                          _pathTrace.clear();
                          _points.clear();
                          _polylines.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.map_pathTraceCancelled)),
                        );
                      },
                      child: Text(l10n.common_cancel),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _MarkerPayload {
  final LatLng position;
  final String label;
  final String flags;

  _MarkerPayload({
    required this.position,
    required this.label,
    required this.flags,
  });
}

class _SharedMarker {
  final String id;
  final LatLng position;
  final String label;
  final String flags;
  final String fromName;
  final String sourceLabel;
  final bool isChannel;
  final bool isPublicChannel;

  _SharedMarker({
    required this.id,
    required this.position,
    required this.label,
    required this.flags,
    required this.fromName,
    required this.sourceLabel,
    required this.isChannel,
    required this.isPublicChannel,
  });
}
