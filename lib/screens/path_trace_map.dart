import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/l10n.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:meshcore_open/utils/app_logger.dart';
import 'package:meshcore_open/widgets/snr_indicator.dart';
import 'package:provider/provider.dart';

double getPathDistanceMeters(List<LatLng> points) {
  if (points.length <= 1) return 0.0;

  double distanceMeters = 0.0;
  final distanceCalculator = Distance();

  for (int i = 0; i < points.length - 1; i++) {
    distanceMeters += distanceCalculator(points[i], points[i + 1]);
  }

  return distanceMeters;
}

String formatDistance(double distanceMeters, {required bool isImperial}) {
  if (isImperial) {
    return '(${(distanceMeters / 1609.34).toStringAsFixed(2)} mi)';
  }
  return '(${(distanceMeters / 1000).toStringAsFixed(2)} km)';
}

class PathTraceData {
  final Uint8List pathData;
  final List<double> snrData;
  final Map<int, Contact> pathContacts;

  PathTraceData({
    required this.pathData,
    required this.snrData,
    required this.pathContacts,
  });
}

class PathTraceMapScreen extends StatefulWidget {
  final String title;
  final Uint8List path;
  final int? repeaterId;
  final bool flipPathRound;
  final bool reversePathRound;
  final Contact? targetContact;

  const PathTraceMapScreen({
    super.key,
    required this.title,
    required this.path,
    this.repeaterId,
    this.flipPathRound = false,
    this.reversePathRound = false,
    this.targetContact,
  });

  @override
  State<PathTraceMapScreen> createState() => _PathTraceMapScreenState();
}

class _PathTraceMapScreenState extends State<PathTraceMapScreen> {
  static const double _labelZoomThreshold = 8.5;

  StreamSubscription<Uint8List>? _frameSubscription;
  Timer? _timeoutTimer;

  bool _isLoading = false;
  bool _failed2Loaded = false;
  bool _hasData = false;
  PathTraceData? _traceData;
  // Inferred positions for hops that have no GPS location, keyed by hop byte.
  Map<int, LatLng> _inferredHopPositions = {};
  // Endpoint position for the target contact (GPS or guessed).
  LatLng? _targetContactPosition;
  bool _targetContactIsGuessed = false;
  List<LatLng> _points = <LatLng>[];
  List<Polyline> _polylines = [];
  LatLng? _initialCenter = LatLng(0, 0);
  double _initialZoom = 2.0;
  LatLngBounds? _bounds;
  ValueKey<String> _mapKey = const ValueKey('initial');
  double _pathDistanceMeters = 0.0;
  bool _showNodeLabels = true;

  String _formatPathPrefixes(Uint8List pathBytes) {
    return pathBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(',');
  }

  @override
  void initState() {
    super.initState();
    _setupFrameListener();
    _doPathTrace();
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Uint8List buildPath(Uint8List pathBytes) {
    Uint8List traceBytes;

    if (pathBytes.isEmpty) {
      traceBytes = Uint8List(1);
      traceBytes[0] = widget.targetContact?.publicKey[0] ?? 0;
      return traceBytes;
    }

    if (widget.targetContact?.type == advTypeRepeater ||
        widget.targetContact?.type == advTypeRoom) {
      final len = (pathBytes.length + pathBytes.length + 1);
      traceBytes = Uint8List(len);
      traceBytes[pathBytes.length] = widget.targetContact?.publicKey[0] ?? 0;
      for (int i = 0; i < pathBytes.length; i++) {
        traceBytes[i] = pathBytes[i];
        if (i < pathBytes.length) {
          traceBytes[len - 1 - i] = pathBytes[i];
        }
      }
    } else {
      if (pathBytes.length < 2) {
        return pathBytes[0] == 0 ? Uint8List(0) : pathBytes;
      }
      final len = (pathBytes.length + pathBytes.length - 1);
      traceBytes = Uint8List(len);
      for (int i = 0; i < pathBytes.length; i++) {
        traceBytes[i] = pathBytes[i];
        if (i < pathBytes.length - 1) {
          traceBytes[len - 1 - i] = pathBytes[i];
        }
      }
    }
    return traceBytes;
  }

  Future<void> _doPathTrace() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _failed2Loaded = false;
      });
    }

    final Uint8List path;

    Uint8List pathTmp = widget.reversePathRound
        ? Uint8List.fromList(widget.path.reversed.toList())
        : widget.path;

    if (widget.flipPathRound) {
      path = buildPath(pathTmp);
    } else {
      path = pathTmp;
    }

    appLogger.info(
      'Initiating path trace with path: ${_formatPathPrefixes(path)}',
      tag: 'PathTraceMapScreen',
    );

    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final frame = buildTraceReq(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      0, //flags
      0, //auth
      payload: path,
    );
    connector.sendFrame(frame);
  }

  void _setupFrameListener() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    Uint8List tagData = Uint8List(4);
    // Listen for incoming text messages from the repeater
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      final frameBuffer = BufferReader(frame);
      try {
        final code = frameBuffer.readUInt8();

        if (code == respCodeSent) {
          frameBuffer.skipBytes(1); //reserved
          tagData = frameBuffer.readBytes(4);
          final timeoutMilliseconds = frameBuffer.readUInt32LE();

          // Start timeout timer for trace response
          _timeoutTimer?.cancel();
          _timeoutTimer = Timer(
            Duration(milliseconds: timeoutMilliseconds),
            () {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _failed2Loaded = true;
              });
            },
          );
        }

        if (code == respCodeErr) {
          _timeoutTimer?.cancel();
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _failed2Loaded = true;
          });
        }

        // Check if it's a binary response
        if (frame.length > 8 &&
            code == pushCodeTraceData &&
            listEquals(frame.sublist(4, 8), tagData)) {
          _timeoutTimer?.cancel();
          if (!mounted) return;
          frameBuffer.skipBytes(3); //reserved + path length + flag
          if (listEquals(frameBuffer.readBytes(4), tagData)) {
            _handleTraceResponse(frame);
          }
        }
      } catch (e) {
        _timeoutTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _failed2Loaded = true;
        });
        // Handle any parsing errors gracefully
        appLogger.error('Error parsing frame: $e', tag: 'PathTraceMapScreen');
      }
    });
  }

  Future<void> _handleTraceResponse(Uint8List frame) async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);

    final buffer = BufferReader(frame);
    try {
      buffer.skipBytes(2); // Skip push code and reserved byte
      int pathLength = buffer.readUInt8();
      buffer.skipBytes(5); // Skip Flag byte and tag data
      buffer.skipBytes(4); // Skip auth code
      Uint8List pathData = buffer.readBytes(pathLength);
      List<double> snrData = buffer
          .readRemainingBytes()
          .map((snr) => snr.toSigned(8).toDouble() / 4)
          .toList();

      Map<int, Contact> pathContacts = {};
      final contacts = <Contact>[
        ...connector.contacts,
        ...connector.discoveredContacts,
      ];
      contacts.where((c) => c.type != advTypeChat).forEach((repeater) {
        for (var repeaterData in pathData) {
          if (listEquals(
            repeater.publicKey.sublist(0, 1),
            Uint8List.fromList([repeaterData]),
          )) {
            pathContacts[repeaterData] = repeater;
          }
        }
      });

      // For hops with no GPS contact, infer position from other contacts
      // with known GPS that share the same last-hop byte.
      final Map<int, LatLng> inferredPositions = {};
      for (final hop in pathData) {
        final contact = pathContacts[hop];
        if (contact != null && contact.hasLocation) continue;
        final peers = connector.contacts
            .where(
              (c) => c.hasLocation && c.path.isNotEmpty && c.path.last == hop,
            )
            .toList();
        if (peers.isNotEmpty) {
          final lat =
              peers.map((c) => c.latitude!).reduce((a, b) => a + b) /
              peers.length;
          final lon =
              peers.map((c) => c.longitude!).reduce((a, b) => a + b) /
              peers.length;
          inferredPositions[hop] = LatLng(lat, lon);
        }
      }

      setState(() {
        _isLoading = false;
        _hasData = true;
        _inferredHopPositions = inferredPositions;
        _traceData = PathTraceData(
          pathData: pathData,
          snrData: snrData,
          pathContacts: pathContacts,
        );
        // Compute endpoint position for the target contact.
        LatLng? targetPos;
        bool targetGuessed = false;
        final target = widget.targetContact;
        if (target != null) {
          if (target.hasLocation) {
            targetPos = LatLng(target.latitude!, target.longitude!);
          } else if (pathData.isNotEmpty) {
            // Infer from the last hop: average GPS contacts sharing that hop.
            // For a round-trip path (flipPathRound), the target-side hop sits
            // in the middle of the symmetric sequence; .last is the local side.
            final lastHop = (widget.flipPathRound && pathData.length > 1)
                ? pathData[(pathData.length - 1) ~/ 2]
                : pathData.last;
            final peers = connector.contacts
                .where(
                  (c) =>
                      c.hasLocation &&
                      c.path.isNotEmpty &&
                      c.path.last == lastHop,
                )
                .toList();
            if (peers.isNotEmpty) {
              final lat =
                  peers.map((c) => c.latitude!).reduce((a, b) => a + b) /
                  peers.length;
              final lon =
                  peers.map((c) => c.longitude!).reduce((a, b) => a + b) /
                  peers.length;
              const offsetDeg = 0.003;
              final angle = (target.publicKey[1] / 255.0) * 2 * pi;
              targetPos = LatLng(
                lat + offsetDeg * cos(angle),
                lon + offsetDeg * sin(angle),
              );
              targetGuessed = true;
            }
          }
        }
        _targetContactPosition = targetPos;
        _targetContactIsGuessed = targetGuessed;

        _points = <LatLng>[];
        _points.add(LatLng(connector.selfLatitude!, connector.selfLongitude!));
        for (final hop in _traceData!.pathData) {
          final contact = _traceData!.pathContacts[hop];
          if (contact != null && contact.hasLocation) {
            _points.add(LatLng(contact.latitude!, contact.longitude!));
          } else {
            final inferred = inferredPositions[hop];
            if (inferred != null) _points.add(inferred);
          }
        }
        if (targetPos != null) _points.add(targetPos);
        _polylines = _points.length > 1
            ? [
                Polyline(
                  points: _points,
                  strokeWidth: 4,
                  color: Colors.blueAccent,
                ),
              ]
            : <Polyline>[];

        _initialCenter = _points.isNotEmpty
            ? _points.first
            : const LatLng(0, 0);
        _initialZoom = _points.isNotEmpty ? 13.0 : 2.0;
        _bounds = _points.length > 1 ? LatLngBounds.fromPoints(_points) : null;
        _mapKey = ValueKey(
          '${context.l10n.pathTrace_you},${_formatPathPrefixes(_traceData!.pathData)}',
        );
        _pathDistanceMeters = getPathDistanceMeters(_points);
      });
    } catch (e) {
      appLogger.error(
        'Error handling trace response: $e',
        tag: 'PathTraceMapScreen',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _failed2Loaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final settings = context.watch<AppSettingsService>().settings;
        final isImperial = settings.unitSystem == UnitSystem.imperial;
        final tileCache = context.read<MapTileCacheService>();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ],
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _doPathTrace,
                tooltip: context.l10n.pathTrace_refreshTooltip,
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Stack(
              children: [
                if (!_hasData)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoading) const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        if (!_isLoading && _failed2Loaded)
                          Text(context.l10n.pathTrace_notAvailable),
                      ],
                    ),
                  ),
                if (_hasData) _buildMapPathTrace(context, tileCache),
                if (_points.isEmpty &&
                    !_hasData &&
                    !_isLoading &&
                    !_failed2Loaded)
                  Center(
                    child: Card(
                      color: Colors.white.withValues(alpha: 0.9),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          context.l10n.channelPath_noRepeaterLocations,
                        ),
                      ),
                    ),
                  ),
                if (_hasData)
                  _buildLegendCard(context, _traceData!, isImperial),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Marker> _buildHopMarkers(
    List<int> pathData, {
    required bool showLabels,
  }) {
    final markers = <Marker>[];
    for (final hop in pathData) {
      final contact = _traceData!.pathContacts[hop];
      final inferred = _inferredHopPositions[hop];
      final hasGps = contact != null && contact.hasLocation;
      if (!hasGps && inferred == null) continue;
      final point = hasGps
          ? LatLng(contact.latitude!, contact.longitude!)
          : inferred!;
      final label = hop.toRadixString(16).padLeft(2, '0').toUpperCase();
      markers.add(
        Marker(
          point: point,
          width: 35,
          height: 35,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hasGps
                  ? Colors.green
                  : Colors.orange.withValues(alpha: 0.75),
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
            child: Text(
              hasGps ? label : '~$label',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
      if (showLabels) {
        markers.add(
          _buildNodeLabelMarker(
            point: point,
            label: contact?.name ?? '~$label',
          ),
        );
      }
    }

    final selfLat = context.read<MeshCoreConnector>().selfLatitude;
    final selfLon = context.read<MeshCoreConnector>().selfLongitude;
    if (selfLat != null && selfLon != null) {
      final selfPoint = LatLng(selfLat, selfLon);
      markers.add(
        Marker(
          point: selfPoint,
          width: 35,
          height: 35,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue,
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
            child: Text(
              context.l10n.pathTrace_you,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
      if (showLabels) {
        markers.add(
          _buildNodeLabelMarker(
            point: selfPoint,
            label: context.l10n.pathTrace_you,
          ),
        );
      }
    }

    // Add target contact endpoint marker.
    final targetPos = _targetContactPosition;
    if (targetPos != null) {
      final isGuessed = _targetContactIsGuessed;
      final targetName = widget.targetContact?.name ?? '?';
      markers.add(
        Marker(
          point: targetPos,
          width: 35,
          height: 35,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isGuessed
                  ? Colors.purple.withValues(alpha: 0.55)
                  : Colors.red,
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
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ),
      );
      if (showLabels) {
        markers.add(
          _buildNodeLabelMarker(
            point: targetPos,
            label: isGuessed ? '~$targetName' : targetName,
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

  String formatDirectionText(PathTraceData pathTraceData, int index) {
    if (index == 0 || index == pathTraceData.snrData.length - 1) {
      if (index == 0) {
        return context.l10n.pathTrace_you;
      } else {
        final contactName = pathTraceData
            .pathContacts[pathTraceData.pathData[pathTraceData.pathData.length -
                1]]
            ?.name;
        final hex = pathTraceData.pathData[pathTraceData.pathData.length - 1]
            .toRadixString(16)
            .padLeft(2, '0')
            .toUpperCase();
        return contactName != null
            ? "$hex: $contactName"
            : "$hex: ${context.l10n.channelPath_unknownRepeater}";
      }
    } else {
      final contactName =
          pathTraceData.pathContacts[pathTraceData.pathData[index - 1]]?.name;
      final hex = pathTraceData.pathData[index - 1]
          .toRadixString(16)
          .padLeft(2, '0')
          .toUpperCase();
      return contactName != null
          ? "$hex: $contactName"
          : "$hex: ${context.l10n.channelPath_unknownRepeater}";
    }
  }

  String formatDirectionSubText(PathTraceData pathTraceData, int index) {
    if (index == 0 || index == pathTraceData.snrData.length - 1) {
      if (index == 0) {
        final contactName =
            pathTraceData.pathContacts[pathTraceData.pathData[0]]?.name;
        final hex = pathTraceData.pathData[0]
            .toRadixString(16)
            .padLeft(2, '0')
            .toUpperCase();
        return contactName != null
            ? "$hex: $contactName"
            : "$hex: ${context.l10n.channelPath_unknownRepeater}";
      } else {
        return context.l10n.pathTrace_you;
      }
    } else {
      final contactName =
          pathTraceData.pathContacts[pathTraceData.pathData[index]]?.name;
      final hex = pathTraceData.pathData[index]
          .toRadixString(16)
          .padLeft(2, '0')
          .toUpperCase();
      return contactName != null
          ? "$hex: $contactName"
          : "$hex: ${context.l10n.channelPath_unknownRepeater}";
    }
  }

  Widget _buildMapPathTrace(
    BuildContext context,
    MapTileCacheService tileCache,
  ) {
    return FlutterMap(
      key: _mapKey,
      options: MapOptions(
        interactionOptions: InteractionOptions(flags: ~InteractiveFlag.rotate),
        initialCenter: _initialCenter!,
        initialZoom: _initialZoom,
        initialCameraFit: _bounds == null
            ? null
            : CameraFit.bounds(
                bounds: _bounds!,
                padding: const EdgeInsets.all(64),
                maxZoom: 16,
              ),
        minZoom: 2.0,
        maxZoom: 18.0,
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
          userAgentPackageName: MapTileCacheService.userAgentPackageName,
          maxZoom: 19,
        ),
        if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),
        if (_traceData!.pathData.isNotEmpty)
          MarkerLayer(
            markers: _buildHopMarkers(
              _traceData!.pathData,
              showLabels: _showNodeLabels,
            ),
          ),
      ],
    );
  }

  Widget _buildLegendCard(
    BuildContext context,
    PathTraceData pathTraceData,
    bool isImperial,
  ) {
    final l10n = context.l10n;
    final maxHeight = MediaQuery.of(context).size.height * 0.35;
    final estimatedHeight = 72.0 + (pathTraceData.pathData.length * 56.0);
    final cardHeight = max(96.0, min(maxHeight, estimatedHeight));

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SizedBox(
        height: cardHeight,
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${l10n.channelPath_repeaterHops} ${formatDistance(_pathDistanceMeters, isImperial: isImperial)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: pathTraceData.pathData.isEmpty
                    ? Center(
                        child: Text(l10n.channelPath_noHopDetailsAvailable),
                      )
                    : Scrollbar(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: pathTraceData.pathData.length + 1,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final snrUi = snrUiFromSNR(
                              index < pathTraceData.snrData.length
                                  ? pathTraceData.snrData[index]
                                  : null,
                              context.read<MeshCoreConnector>().currentSf,
                            );
                            return Column(
                              children: [
                                ListTile(
                                  leading:
                                      index >= pathTraceData.snrData.length / 2
                                      ? Icon(Icons.call_received)
                                      : Icon(Icons.call_made),
                                  title: Text(
                                    formatDirectionText(pathTraceData, index),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    formatDirectionSubText(
                                      pathTraceData,
                                      index,
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        snrUi.icon,
                                        color: snrUi.color,
                                        size: 18.0,
                                      ),
                                      Text(
                                        snrUi.text,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: snrUi.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    // Handle item tap
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
