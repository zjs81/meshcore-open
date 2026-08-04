import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/path_helper.dart';
import 'package:meshcore_open/l10n/l10n.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/display_path.dart';
import 'package:meshcore_open/models/path_history.dart';
import 'package:meshcore_open/models/path_playback.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/utils/app_logger.dart';
import 'package:meshcore_open/widgets/path_map_ui.dart';
import 'package:meshcore_open/widgets/snr_indicator.dart';
import 'package:provider/provider.dart';
import '../theme/mesh_theme.dart';

export 'package:meshcore_open/widgets/path_map_ui.dart'
    show formatDistance, getPathDistanceMeters;

class PathTraceData {
  final List<Uint8List> pathData;
  final List<double> snrData;
  final Map<String, Contact> pathContacts;

  PathTraceData({
    required this.pathData,
    required this.snrData,
    required this.pathContacts,
  });
}

String _hopKey(Uint8List hopBytes) => PathHelper.formatHopHex(hopBytes);

Uint8List _lastHopChunk(Uint8List path, int hopWidth) {
  if (path.isEmpty) return Uint8List(0);
  final width = hopWidth.clamp(1, path.length).toInt();
  return Uint8List.fromList(path.sublist(path.length - width));
}

bool _matchesHopPrefix(Uint8List a, Uint8List b) {
  if (a.isEmpty || b.isEmpty) return false;
  final width = min(a.length, b.length);
  return listEquals(a.sublist(0, width), b.sublist(0, width));
}

class PathTraceMapScreen extends StatefulWidget {
  final String title;
  final Uint8List path;
  final int? repeaterId;
  final bool flipPathAround;
  final bool reversePathAround;
  final Contact? targetContact;
  final int pathHashByteWidth;
  final List<Contact>? pathContacts;

  const PathTraceMapScreen({
    super.key,
    required this.title,
    required this.path,
    this.repeaterId,
    this.flipPathAround = false,
    this.reversePathAround = false,
    this.targetContact,
    this.pathHashByteWidth = pathHashSize,
    this.pathContacts,
  });

  @override
  State<PathTraceMapScreen> createState() => _PathTraceMapScreenState();
}

class _PathTraceMapScreenState extends State<PathTraceMapScreen>
    with SingleTickerProviderStateMixin {
  static const double _labelZoomThreshold = 8.5;
  static const double _mapMinZoom = 2.0;
  static const double _mapMaxZoom = 18.0;
  //miles to meters conversion for filtering out repeaters that are too far from the last known GPS hop to be a likely match, to avoid false matches that throw off the inferred positions of other hops in the path
  static const double _maxRepeaterMatchDistanceMeters = 40 * 1609.344;

  final MapController _mapController = MapController();
  StreamSubscription<Uint8List>? _frameSubscription;
  Timer? _timeoutTimer;

  bool _isLoading = false;
  bool _failed2Loaded = false;
  bool _hasData = false;
  PathTraceData? _traceData;
  // Inferred positions for hops that have no GPS location, keyed by hop prefix.
  Map<String, LatLng> _inferredHopPositions = {};
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
  Contact? _targetContact;
  Uint8List? _sentTagBytes;
  // Live path resolved at trace time; used by the response handler for
  // endpoint inference so it matches the path that was actually traced.
  Uint8List _tracedPath = Uint8List(0);

  // Packet-flow animation + multi-path view state.
  late final PathPlaybackController _playback;
  PathHistoryService? _pathHistory;
  PathViewMode _viewMode = PathViewMode.single;
  List<DisplayPath> _displayPaths = [];
  List<Uint8List> _primaryOutboundHops = [];
  String _selectedPathId = 'primary';
  final Set<String> _hiddenPathIds = {};
  bool _panelCollapsed = false;
  bool _animationEnabled = true;
  bool _followPacket = false;

  String _formatPathPrefixes(Uint8List pathBytes, [int? hashByteWidth]) {
    return PathHelper.splitPathBytes(
      pathBytes,
      hashByteWidth ?? widget.pathHashByteWidth,
    ).map(PathHelper.formatHopHex).join(',');
  }

  int _traceHashByteWidth(int pathHashByteWidth) {
    final width = pathHashByteWidth.clamp(1, pubKeySize).toInt();
    if (width <= 1) return 1;
    if (width == 2) return 2;
    // Trace packets encode hash width as 1 << flags, so 3-byte path hashes
    // must be traced with a 4-byte public-key prefix.
    return 4;
  }

  int _traceFlagsForHashWidth(int traceHashByteWidth) {
    if (traceHashByteWidth <= 1) return 0;
    if (traceHashByteWidth == 2) return 1;
    return 2;
  }

  Uint8List _reversePathByHop(Uint8List pathBytes, int hopWidth) {
    final reversedHops = PathHelper.splitPathBytes(
      pathBytes,
      hopWidth,
    ).reversed;
    final bytes = <int>[];
    for (final hop in reversedHops) {
      bytes.addAll(hop);
    }
    return Uint8List.fromList(bytes);
  }

  Uint8List? _expandHopForTrace(
    Uint8List hop,
    int traceHashByteWidth,
    MeshCoreConnector connector,
  ) {
    if (hop.length == traceHashByteWidth) return hop;

    final candidates = <Contact>[
      ...?widget.pathContacts,
      if (widget.targetContact != null) widget.targetContact!,
      ...connector.allContactsUnfiltered,
    ];
    for (final contact in candidates) {
      if (contact.publicKey.length < traceHashByteWidth) continue;
      if (!listEquals(contact.publicKey.sublist(0, hop.length), hop)) continue;
      return Uint8List.fromList(
        contact.publicKey.sublist(0, traceHashByteWidth),
      );
    }
    return null;
  }

  Uint8List? _tracePathFromBytes(
    Uint8List pathBytes,
    int traceHashByteWidth,
    MeshCoreConnector connector,
  ) {
    final hops = PathHelper.splitPathBytes(pathBytes, widget.pathHashByteWidth);
    final traceBytes = <int>[];
    for (final hop in hops) {
      final traceHop = _expandHopForTrace(hop, traceHashByteWidth, connector);
      if (traceHop == null) return null;
      traceBytes.addAll(traceHop);
    }
    return Uint8List.fromList(traceBytes);
  }

  @override
  void initState() {
    super.initState();
    _playback = PathPlaybackController(this);
    _playback.addListener(_followPacketCamera);
    _pathHistory = context.read<PathHistoryService>();
    _pathHistory!.addListener(_onPathHistoryChanged);
    _setupFrameListener();
    _doPathTrace();
  }

  @override
  void dispose() {
    _pathHistory?.removeListener(_onPathHistoryChanged);
    _playback.dispose();
    _mapController.dispose();
    _frameSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _onPathHistoryChanged() {
    if (!mounted || !_hasData) return;
    setState(() {
      _rebuildDisplayPaths(context.read<MeshCoreConnector>());
    });
  }

  /// Keeps the camera centered on the packet while the follow lock is on.
  void _followPacketCamera() {
    if (!_followPacket ||
        !_animationEnabled ||
        !_playback.started ||
        !_playback.hasPath ||
        !mounted ||
        !_hasData) {
      return;
    }
    _mapController.move(_playback.position, _mapController.camera.zoom);
  }

  void _toggleFollowPacket() {
    setState(() {
      _followPacket = !_followPacket;
    });
    _followPacketCamera();
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

  void _resetMapView() {
    final bounds = _bounds;
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(64),
          maxZoom: 16,
        ),
      );
      return;
    }
    final center = _initialCenter;
    if (center != null) {
      _mapController.move(center, _initialZoom);
    }
  }

  Widget _buildDesktopMapControls() {
    return Positioned(
      top: 16,
      left: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MeshPalette.bg1.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(MeshRadii.md),
          border: Border.all(color: MeshPalette.line2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MeshRadii.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: context.l10n.map_zoomIn,
                onPressed: () => _zoomMapBy(1),
              ),
              IconButton(
                icon: const Icon(Icons.remove),
                tooltip: context.l10n.map_zoomOut,
                onPressed: () => _zoomMapBy(-1),
              ),
              IconButton(
                icon: const Icon(Icons.my_location),
                tooltip: context.l10n.map_centerMap,
                onPressed: _resetMapView,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Uint8List? buildPath(
    Uint8List pathBytes,
    int traceHashByteWidth,
    MeshCoreConnector connector,
  ) {
    final pathHops = PathHelper.splitPathBytes(
      pathBytes,
      widget.pathHashByteWidth,
    );
    final hopWidth = traceHashByteWidth.clamp(1, pubKeySize).toInt();

    // Compute targetPrefix if targetContact is provided
    Uint8List? targetPrefix;
    if (widget.targetContact != null) {
      final pk = widget.targetContact!.publicKey;
      if (pk.isNotEmpty) {
        final len = pk.length >= hopWidth ? hopWidth : pk.length;
        targetPrefix = Uint8List.fromList(pk.sublist(0, len));
      }
    }

    final outboundHops = <Uint8List>[];
    for (final hop in pathHops) {
      final traceHop = _expandHopForTrace(hop, traceHashByteWidth, connector);
      if (traceHop == null) return null;
      outboundHops.add(traceHop);
    }
    if (targetPrefix != null) {
      // Check if targetPrefix is already the last hop in pathHops to avoid duplication
      bool alreadyEndedWithTarget = false;
      if (outboundHops.isNotEmpty) {
        if (listEquals(outboundHops.last, targetPrefix)) {
          alreadyEndedWithTarget = true;
        }
      }
      if (!alreadyEndedWithTarget) {
        outboundHops.add(targetPrefix);
      }
    }

    if (outboundHops.isEmpty) {
      return Uint8List(0);
    }

    final mirroredHops = <Uint8List>[...outboundHops];
    if (outboundHops.length > 1) {
      mirroredHops.addAll(
        outboundHops.sublist(0, outboundHops.length - 1).reversed,
      );
    }

    final traceBytes = <int>[];
    for (final hop in mirroredHops) {
      traceBytes.addAll(hop);
    }
    return Uint8List.fromList(traceBytes);
  }

  /// Resolves the path bytes to trace. When tracing a specific contact's
  /// route (flipPathAround), re-read that contact's live forced/auto path from
  /// the connector so a path the user just changed (force flood / set path /
  /// reset to auto) is honored immediately, instead of the value captured when
  /// this screen was first pushed.
  Uint8List _resolveLivePath(MeshCoreConnector connector) {
    final target = widget.targetContact;
    if (!widget.flipPathAround || target == null) {
      return widget.path;
    }
    final live = connector.allContactsUnfiltered.firstWhere(
      (c) => c.publicKeyHex == target.publicKeyHex,
      orElse: () => target,
    );
    return live.pathBytesForDisplay;
  }

  Future<void> _doPathTrace() async {
    _playback.stop();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _failed2Loaded = false;
      });
    }

    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final traceHashByteWidth = _traceHashByteWidth(widget.pathHashByteWidth);
    final livePath = _resolveLivePath(connector);
    _tracedPath = livePath;

    final pathTmp = widget.reversePathAround
        ? _reversePathByHop(livePath, widget.pathHashByteWidth)
        : livePath;

    final path = widget.flipPathAround
        ? buildPath(pathTmp, traceHashByteWidth, connector)
        : _tracePathFromBytes(pathTmp, traceHashByteWidth, connector);

    if (path == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _failed2Loaded = true;
      });
      return;
    }

    appLogger.info(
      'Initiating path trace with path: '
      '${_formatPathPrefixes(path, traceHashByteWidth)}',
      tag: 'PathTraceMapScreen',
      noNotify: !mounted,
    );

    final sentTag = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _sentTagBytes = Uint8List(4)
      ..[0] = sentTag & 0xFF
      ..[1] = (sentTag >> 8) & 0xFF
      ..[2] = (sentTag >> 16) & 0xFF
      ..[3] = (sentTag >> 24) & 0xFF;

    final flags = _traceFlagsForHashWidth(traceHashByteWidth);
    final tracePayload = path.isEmpty ? Uint8List.fromList([0x00]) : path;

    final frame = buildTraceReq(
      sentTag,
      0, // auth
      flags, // flag
      payload: tracePayload,
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
        if (frame.length >= 12 &&
            code == pushCodeTraceData &&
            (listEquals(frame.sublist(4, 8), _sentTagBytes) ||
                listEquals(frame.sublist(4, 8), tagData))) {
          _timeoutTimer?.cancel();
          if (!mounted) return;
          _handleTraceResponse(frame);
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
      final pathLenByte = buffer.readUInt8();
      final flags = buffer.readUInt8();
      buffer.skipBytes(4); // Skip tag data
      buffer.skipBytes(4); // Skip auth code
      var width = _traceHashByteWidth(1 << (flags & 0x03));
      var pathLength = pathLenByte == 0xFF ? 0 : pathLenByte;
      if (pathLength > buffer.remaining && (pathLenByte & 0xC0) != 0) {
        final packedWidth = ((pathLenByte & 0xC0) >> 6) + 1;
        final packedLength = (pathLenByte & 0x3F) * packedWidth;
        if (packedLength <= buffer.remaining) {
          width = packedWidth;
          pathLength = packedLength;
        }
      }
      final pathBytes = buffer.readBytes(pathLength);
      final pathData = PathHelper.splitPathBytes(pathBytes, width);
      // Firmware emits (path_len >> path_sz) hop SNRs plus 1 final SNR (to this node).
      final snrCount = (pathLength ~/ width) + 1;
      List<double> snrData = buffer
          .readBytes(snrCount)
          .map((snr) => snr.toSigned(8).toDouble() / 4)
          .toList();

      Map<String, Contact> pathContacts = {};
      Contact lastContact = Contact(
        path: Uint8List(0),
        pathLength: 0,
        publicKey: connector.selfPublicKey ?? Uint8List(0),
        name: context.l10n.pathTrace_you,
        type: advTypeChat,
        latitude: connector.selfLatitude,
        longitude: connector.selfLongitude,
        lastSeen: DateTime.now(),
      );
      if (widget.pathContacts != null) {
        final hopWidth = width.clamp(1, pubKeySize).toInt();
        pathContacts = {
          for (var c in widget.pathContacts!)
            if (c.publicKey.length >= hopWidth)
              _hopKey(Uint8List.fromList(c.publicKey.sublist(0, hopWidth))): c,
        };
      } else {
        final contacts = connector.allContactsUnfiltered;
        contacts.where((c) => c.type != advTypeChat).forEach((repeater) {
          if (lastContact.latitude != null &&
              lastContact.longitude != null &&
              repeater.hasLocation &&
              lastContact.hasLocation &&
              Distance().distance(
                    LatLng(lastContact.latitude!, lastContact.longitude!),
                    LatLng(repeater.latitude!, repeater.longitude!),
                  ) >
                  _maxRepeaterMatchDistanceMeters) {
            return; //skip reapeaters that are far away from the last one with known GPS, to avoid false matches
          }
          for (final repeaterData in pathData) {
            final hopWidth = repeaterData.length;
            if (repeater.publicKey.length < hopWidth) continue;
            if (listEquals(
              repeater.publicKey.sublist(0, hopWidth),
              repeaterData,
            )) {
              pathContacts[_hopKey(repeaterData)] = repeater;
              lastContact = repeater;
            }
          }
        });
      }

      // For hops with no GPS contact, infer position from other contacts
      // with known GPS that share the same last-hop byte.
      final Map<String, LatLng> inferredPositions = {};
      for (final hop in pathData) {
        final hopKey = _hopKey(hop);
        final contact = pathContacts[hopKey];
        if (contact != null && contact.hasLocation) continue;
        final peers = connector.contacts
            .where(
              (c) =>
                  c.hasLocation &&
                  c.path.isNotEmpty &&
                  _matchesHopPrefix(
                    _lastHopChunk(c.path, widget.pathHashByteWidth),
                    hop,
                  ),
            )
            .toList();
        if (peers.isNotEmpty) {
          final lat =
              peers.map((c) => c.latitude!).reduce((a, b) => a + b) /
              peers.length;
          final lon =
              peers.map((c) => c.longitude!).reduce((a, b) => a + b) /
              peers.length;
          inferredPositions[hopKey] = LatLng(lat, lon);
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
        _targetContact = widget.targetContact;

        if (_targetContact != null) {
          final tc = _targetContact!;
          if (tc.hasLocation) {
            targetPos = LatLng(tc.latitude!, tc.longitude!);
          } else if (pathData.length > 1 || _tracedPath.isNotEmpty) {
            // Infer from the last hop: average GPS contacts sharing that hop.
            // For a round-trip path (flipPathAround/reversePathAround), the target-side hop
            // sits in the middle of the symmetric sequence; .last is the local side.
            final tracedHops = PathHelper.splitPathBytes(
              _tracedPath,
              widget.pathHashByteWidth,
            );
            final hopsForEndpoint = tracedHops.isNotEmpty
                ? tracedHops
                : pathData;
            final lastHop = widget.reversePathAround
                ? hopsForEndpoint.first
                : hopsForEndpoint.last;
            final lastHopKey = _hopKey(lastHop);

            final peers = connector.allContacts
                .where(
                  (c) =>
                      c.hasLocation &&
                      c.path.isNotEmpty &&
                      _matchesHopPrefix(
                        _lastHopChunk(c.path, widget.pathHashByteWidth),
                        lastHop,
                      ),
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
              final angle = (tc.publicKey[1] / 255.0) * 2 * pi;
              targetPos = LatLng(
                lat + offsetDeg * cos(angle),
                lon + offsetDeg * sin(angle),
              );
              targetGuessed = true;
            } else if (inferredPositions.containsKey(lastHopKey)) {
              final lat = inferredPositions[lastHopKey]!.latitude;
              final lon = inferredPositions[lastHopKey]!.longitude;
              const offsetDeg = 0.003;
              final angle = (tc.publicKey[1] / 255.0) * 2 * pi;
              targetPos = LatLng(
                lat + offsetDeg * cos(angle),
                lon + offsetDeg * sin(angle),
              );
              targetGuessed = true;
            } else {
              // As a last resort, just place it at the same position as the last hop.
              final contact = pathContacts[lastHopKey];
              if (contact != null && contact.hasLocation) {
                const offsetDeg = 0.003;
                final angle = (tc.publicKey[1] / 255.0) * 2 * pi;
                targetPos = LatLng(
                  contact.latitude! + offsetDeg * cos(angle),
                  contact.longitude! + offsetDeg * sin(angle),
                );
                targetGuessed = true;
              }
            }
          }
        }
        _targetContactPosition = targetPos;
        _targetContactIsGuessed = targetGuessed;

        _points = <LatLng>[];
        _points.add(LatLng(connector.selfLatitude!, connector.selfLongitude!));
        String hopLast = '';
        String hopLastLast = '';
        for (final hop in _traceData!.pathData) {
          final hopKey = _hopKey(hop);
          if (hopKey == hopLastLast && widget.flipPathAround) {
            break; //skip duplicate hops in round-trip paths
          }
          final contact = _traceData!.pathContacts[hopKey];
          if (contact != null && contact.hasLocation) {
            _points.add(LatLng(contact.latitude!, contact.longitude!));
          } else {
            final inferred = inferredPositions[hopKey];
            if (inferred != null) _points.add(inferred);
          }
          hopLastLast = hopLast;
          hopLast = hopKey;
        }
        if (targetPos != null) {
          if (_targetContact != null && _targetContact!.type == advTypeChat) {
            _points.add(targetPos);
          }
        }
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
          '${context.l10n.pathTrace_you},${_traceData!.pathData.map(PathHelper.formatHopHex).join(',')}',
        );
        _pathDistanceMeters = getPathDistanceMeters(_points);
        _primaryOutboundHops = _outboundHops(pathData);
        _rebuildDisplayPaths(connector);
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

  /// Outbound hop bytes of the traced path, mirroring the round-trip
  /// dedup logic used when building [_points].
  List<Uint8List> _outboundHops(List<Uint8List> pathData) {
    final hops = <Uint8List>[];
    var hopLast = '';
    var hopLastLast = '';
    for (final hop in pathData) {
      final hopKey = _hopKey(hop);
      if (hopKey == hopLastLast && widget.flipPathAround) break;
      hops.add(hop);
      hopLastLast = hopLast;
      hopLast = hopKey;
    }
    return hops;
  }

  Contact? _contactForHop(Uint8List hop, MeshCoreConnector connector) {
    final traced = _traceData?.pathContacts[_hopKey(hop)];
    if (traced != null) return traced;
    for (final c in connector.allContactsUnfiltered) {
      if (c.type != advTypeChat &&
          c.publicKey.length >= hop.length &&
          listEquals(c.publicKey.sublist(0, hop.length), hop)) {
        return c;
      }
    }
    return null;
  }

  LatLng? _inferredPositionForHop(Uint8List hop, MeshCoreConnector connector) {
    final hopKey = _hopKey(hop);
    final cached = _inferredHopPositions[hopKey];
    if (cached != null) return cached;
    final peers = connector.contacts
        .where(
          (c) =>
              c.hasLocation &&
              c.path.isNotEmpty &&
              _matchesHopPrefix(
                _lastHopChunk(c.path, widget.pathHashByteWidth),
                hop,
              ),
        )
        .toList();
    if (peers.isEmpty) return null;
    final lat =
        peers.map((c) => c.latitude!).reduce((a, b) => a + b) / peers.length;
    final lon =
        peers.map((c) => c.longitude!).reduce((a, b) => a + b) / peers.length;
    final pos = LatLng(lat, lon);
    _inferredHopPositions[hopKey] = pos;
    return pos;
  }

  String _pathKeyForHops(List<Uint8List> hops) {
    return hops.map(PathHelper.formatHopHex).join(',');
  }

  /// Rebuilds the renderable paths: the traced path as primary plus up to
  /// four distinct alternates from the target contact's path history.
  void _rebuildDisplayPaths(MeshCoreConnector connector) {
    final paths = <DisplayPath>[];
    final primary = _buildDisplayPath(
      id: 'primary',
      label: context.l10n.pathMap_primary,
      color: kPrimaryPathColor,
      isPrimary: true,
      hops: _primaryOutboundHops,
      connector: connector,
    );
    if (primary != null) paths.add(primary);

    final target = widget.targetContact;
    final history = _pathHistory;
    if (target != null && history != null) {
      final seen = <String>{_pathKeyForHops(_primaryOutboundHops)};
      var altIndex = 0;
      for (final record in history.getRecentPaths(target.publicKeyHex)) {
        if (record.pathBytes.isEmpty) continue;
        final recordHops = PathHelper.splitPathBytes(
          record.pathBytes,
          widget.pathHashByteWidth,
        );
        if (!seen.add(_pathKeyForHops(recordHops))) continue;
        if (altIndex >= kAlternatePathColors.length) break;
        final alt = _buildDisplayPath(
          id: 'alt-${_pathKeyForHops(recordHops)}',
          label: context.l10n.pathMap_alternate(altIndex + 1),
          color: kAlternatePathColors[altIndex],
          isPrimary: false,
          hops: recordHops,
          record: record,
          connector: connector,
        );
        if (alt != null) {
          paths.add(alt);
          altIndex++;
        }
      }
    }

    _displayPaths = paths;
    _hiddenPathIds.removeWhere((id) => !paths.any((p) => p.id == id));
    if (!paths.any((p) => p.id == _selectedPathId)) {
      _selectedPathId = paths.isNotEmpty ? paths.first.id : 'primary';
    }
    if (paths.length < 2) _viewMode = PathViewMode.single;
    _syncPlaybackToSelection();
  }

  DisplayPath? _buildDisplayPath({
    required String id,
    required String label,
    required Color color,
    required bool isPrimary,
    required List<Uint8List> hops,
    required MeshCoreConnector connector,
    PathRecord? record,
  }) {
    final selfLat = connector.selfLatitude;
    final selfLon = connector.selfLongitude;
    if (selfLat == null || selfLon == null) return null;

    final points = <LatLng>[LatLng(selfLat, selfLon)];
    final labels = <String>[context.l10n.pathTrace_you];
    final confirmed = <bool>[true];
    final hopOrdinals = <int>[-1];
    final gapBefore = <bool>[false];
    int gpsConfirmedHops = 0;
    int unresolvedHops = 0;
    bool pendingGap = false;

    for (var i = 0; i < hops.length; i++) {
      final hop = hops[i];
      final hex = PathHelper.formatHopHex(hop);
      final contact = _contactForHop(hop, connector);
      LatLng? pos;
      var isGps = false;
      if (contact != null && contact.hasLocation) {
        pos = LatLng(contact.latitude!, contact.longitude!);
        isGps = true;
        gpsConfirmedHops++;
      } else {
        pos = _inferredPositionForHop(hop, connector);
      }
      if (pos == null) {
        unresolvedHops++;
        pendingGap = true;
        continue;
      }
      points.add(pos);
      labels.add(contact?.name ?? '~$hex');
      confirmed.add(isGps);
      hopOrdinals.add(i);
      gapBefore.add(pendingGap);
      pendingGap = false;
    }

    // Append the chat-target endpoint the same way the traced path does.
    final target = widget.targetContact;
    final targetPos = _targetContactPosition;
    final hasTargetEndpoint =
        target != null && target.type == advTypeChat && targetPos != null;
    if (hasTargetEndpoint) {
      points.add(targetPos);
      labels.add(target.name);
      confirmed.add(!_targetContactIsGuessed);
      hopOrdinals.add(hops.length);
      gapBefore.add(pendingGap);
      pendingGap = false;
    }

    if (points.length < 2) return null;

    final segmentEstimated = <bool>[];
    final rowForSegment = <int>[];
    for (var i = 0; i < points.length - 1; i++) {
      segmentEstimated.add(
        !confirmed[i] || !confirmed[i + 1] || gapBefore[i + 1],
      );
      rowForSegment.add(hopOrdinals[i + 1] < 0 ? 0 : hopOrdinals[i + 1]);
    }

    return DisplayPath(
      id: id,
      label: label,
      color: color,
      isPrimary: isPrimary,
      hopBytes: List<Uint8List>.from(hops),
      points: points,
      pointLabels: labels,
      pointConfirmed: confirmed,
      segmentEstimated: segmentEstimated,
      rowForSegment: rowForSegment,
      totalTransmissions: hops.length + (hasTargetEndpoint ? 1 : 0),
      hasTargetEndpoint: hasTargetEndpoint,
      gpsConfirmedHops: gpsConfirmedHops,
      unresolvedHops: unresolvedHops,
      distanceMeters: getPathDistanceMeters(points),
      record: record,
    );
  }

  DisplayPath? get _selectedPath {
    if (_displayPaths.isEmpty) return null;
    return _displayPaths.firstWhere(
      (p) => p.id == _selectedPathId,
      orElse: () => _displayPaths.first,
    );
  }

  List<DisplayPath> get _visiblePaths {
    if (_viewMode == PathViewMode.single) {
      final selected = _selectedPath;
      return selected != null ? [selected] : const [];
    }
    return _displayPaths.where((p) => !_hiddenPathIds.contains(p.id)).toList();
  }

  /// Updates the playback path, but only when the selected path's geometry
  /// actually changed, so unrelated path-history updates don't reset a
  /// running animation.
  void _syncPlaybackToSelection() {
    final points = _selectedPath?.points ?? const <LatLng>[];
    if (points.length == _playback.points.length) {
      var same = true;
      for (var i = 0; i < points.length; i++) {
        if (points[i] != _playback.points[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    _playback.setPath(points);
  }

  void _selectPath(DisplayPath path) {
    setState(() {
      _selectedPathId = path.id;
      _hiddenPathIds.remove(path.id);
      _syncPlaybackToSelection();
    });
  }

  void _togglePathVisibility(DisplayPath path) {
    setState(() {
      if (!_hiddenPathIds.remove(path.id)) {
        _hiddenPathIds.add(path.id);
        if (path.id == _selectedPathId) {
          final visible = _displayPaths.where(
            (p) => !_hiddenPathIds.contains(p.id),
          );
          if (visible.isNotEmpty) {
            _selectedPathId = visible.first.id;
            _syncPlaybackToSelection();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final settings = context.watch<AppSettingsService>().settings;
        final isImperial = settings.unitSystem == UnitSystem.imperial;
        final tileCache = context.read<MapTileCacheService>();
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            centerTitle: true,
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
                        if (_isLoading)
                          CircularProgressIndicator(color: MeshPalette.blue),
                        const SizedBox(height: 16),
                        if (!_isLoading && _failed2Loaded)
                          Text(
                            context.l10n.pathTrace_notAvailable,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                if (_hasData)
                  _buildMapPathTrace(context, tileCache, _targetContact),
                if (_hasData && _isDesktopPlatform(defaultTargetPlatform))
                  _buildDesktopMapControls(),
                if (_hasData && _displayPaths.length > 1)
                  PathViewModeToggle(
                    mode: _viewMode,
                    onChanged: (mode) => setState(() => _viewMode = mode),
                  ),
                if (_points.isEmpty &&
                    !_hasData &&
                    !_isLoading &&
                    !_failed2Loaded)
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(MeshRadii.md),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          context.l10n.channelPath_noRepeaterLocations,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                if (_hasData)
                  _buildBottomPanel(context, _traceData!, isImperial),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Marker> _buildHopMarkers(
    List<Uint8List> pathData, {
    required bool showLabels,
    required Contact? target,
  }) {
    final markers = <Marker>[];
    String hopLast = '';
    String hopLastLast = '';
    for (final hop in pathData) {
      final hopKey = _hopKey(hop);
      final contact = _traceData!.pathContacts[hopKey];
      final inferred = _inferredHopPositions[hopKey];
      final hasGps = contact != null && contact.hasLocation;
      if (hopKey == hopLastLast && widget.flipPathAround) {
        continue; //skip duplicate hops in round-trip paths
      }
      if (!hasGps && inferred == null) {
        hopLastLast = hopLast;
        hopLast = hopKey;
        continue; //skip hops with no GPS and no inferred position
      }
      final point = hasGps
          ? LatLng(contact.latitude!, contact.longitude!)
          : inferred!;
      final label = PathHelper.formatHopHex(hop);
      final shortLabel = label.length > 2 ? label.substring(0, 2) : label;
      final fullLabel = label.length > 2
          ? (contact?.name != null ? '$label: ${contact!.name}' : label)
          : (contact?.name ?? label);

      markers.add(
        Marker(
          point: point,
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasGps
                    ? MeshPalette.signal.withValues(alpha: 0.18)
                    : MeshPalette.warn.withValues(alpha: 0.18),
                border: Border.all(
                  color: hasGps
                      ? MeshPalette.signal.withValues(alpha: 0.7)
                      : MeshPalette.warn.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: hasGps
                        ? MeshPalette.signal.withValues(alpha: 0.3)
                        : MeshPalette.warn.withValues(alpha: 0.3),
                    blurRadius: 5,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                shortLabel,
                style: MeshTheme.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: hasGps ? MeshPalette.signal : MeshPalette.warn,
                ),
              ),
            ),
          ),
        ),
      );
      if (showLabels) {
        markers.add(_buildNodeLabelMarker(point: point, label: fullLabel));
      }
      hopLastLast = hopLast;
      hopLast = hopKey;
    }

    _addEndpointMarkers(markers, showLabels: showLabels, target: target);

    return markers;
  }

  /// Self and target endpoint markers, shared by single and combined views.
  void _addEndpointMarkers(
    List<Marker> markers, {
    required bool showLabels,
    required Contact? target,
  }) {
    final selfLat = context.read<MeshCoreConnector>().selfLatitude;
    final selfLon = context.read<MeshCoreConnector>().selfLongitude;
    if (selfLat != null && selfLon != null) {
      final selfPoint = LatLng(selfLat, selfLon);
      markers.add(
        Marker(
          point: selfPoint,
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MeshPalette.blue.withValues(alpha: 0.18),
                border: Border.all(
                  color: MeshPalette.blue.withValues(alpha: 0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: MeshPalette.blue.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                context.l10n.pathTrace_you,
                style: MeshTheme.mono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: MeshPalette.blue,
                ),
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
    if (targetPos != null && target != null && target.type == advTypeChat) {
      final isGuessed = _targetContactIsGuessed;
      final targetName = target.name;
      markers.add(
        Marker(
          point: targetPos,
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isGuessed
                    ? MeshPalette.magenta.withValues(alpha: 0.18)
                    : MeshPalette.alert.withValues(alpha: 0.18),
                border: Border.all(
                  color: isGuessed
                      ? MeshPalette.magenta.withValues(alpha: 0.7)
                      : MeshPalette.alert.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isGuessed
                        ? MeshPalette.magenta.withValues(alpha: 0.3)
                        : MeshPalette.alert.withValues(alpha: 0.3),
                    blurRadius: 5,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person,
                color: isGuessed ? MeshPalette.magenta : MeshPalette.alert,
                size: 18,
              ),
            ),
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
  }

  /// Markers for the union of hops across all visible paths, with a badge on
  /// repeaters used by more than one path.
  List<Marker> _buildCombinedHopMarkers({
    required bool showLabels,
    required Contact? target,
  }) {
    final connector = context.read<MeshCoreConnector>();
    final markers = <Marker>[];

    // Hop prefix -> paths that use it, in display order.
    final hopPaths = <String, List<DisplayPath>>{};
    final hopsByKey = <String, Uint8List>{};
    for (final path in _visiblePaths) {
      for (final hop in path.hopBytes) {
        final hopKey = _hopKey(hop);
        hopsByKey[hopKey] = hop;
        final list = hopPaths.putIfAbsent(hopKey, () => []);
        if (!list.contains(path)) list.add(path);
      }
    }

    for (final entry in hopPaths.entries) {
      final hopKey = entry.key;
      final hop = hopsByKey[hopKey];
      if (hop == null) continue;
      final paths = entry.value;
      final contact = _contactForHop(hop, connector);
      final hasGps = contact != null && contact.hasLocation;
      final point = hasGps
          ? LatLng(contact.latitude!, contact.longitude!)
          : _inferredPositionForHop(hop, connector);
      if (point == null) continue;
      final label = PathHelper.formatHopHex(hop);
      final baseColor = hasGps ? MeshPalette.signal : MeshPalette.warn;
      final shared = paths.length > 1;

      markers.add(
        Marker(
          point: point,
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => _showSharedNodeSheet(hop, contact, paths),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor.withValues(alpha: 0.18),
                    border: Border.all(
                      color: baseColor.withValues(alpha: 0.7),
                      width: shared ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasGps ? label : '~$label',
                    style: MeshTheme.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: baseColor,
                    ),
                  ),
                ),
                if (shared)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MeshPalette.bg1,
                        border: Border.all(color: MeshPalette.line3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${paths.length}',
                        style: MeshTheme.mono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: MeshPalette.ink,
                        ),
                      ),
                    ),
                  ),
              ],
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

    _addEndpointMarkers(markers, showLabels: showLabels, target: target);

    return markers;
  }

  void _showSharedNodeSheet(
    Uint8List hop,
    Contact? contact,
    List<DisplayPath> paths,
  ) {
    final hex = PathHelper.formatHopHex(hop);
    showSharedNodeSheet(
      context,
      title:
          '$hex: ${contact?.name ?? context.l10n.channelPath_unknownRepeater}',
      paths: paths,
      onSelect: _selectPath,
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
                color: MeshPalette.bg.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(MeshRadii.xs),
                border: Border.all(color: MeshPalette.line, width: 0.5),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MeshTheme.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: MeshPalette.ink2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String formatDirectionText(PathTraceData pathTraceData, int index) {
    if (pathTraceData.pathData.isEmpty) {
      return context.l10n.pathTrace_you;
    }
    if (index < 0 || index > pathTraceData.pathData.length) {
      return context.l10n.pathTrace_you;
    }

    if (index == 0 || index == pathTraceData.pathData.length) {
      if (index == 0) {
        return context.l10n.pathTrace_you;
      } else {
        final hop = pathTraceData.pathData.last;
        final contactName = pathTraceData.pathContacts[_hopKey(hop)]?.name;
        final hex = PathHelper.formatHopHex(hop);
        return contactName != null
            ? "$hex: $contactName"
            : "$hex: ${context.l10n.channelPath_unknownRepeater}";
      }
    } else {
      final hop = pathTraceData.pathData[index - 1];
      final contactName = pathTraceData.pathContacts[_hopKey(hop)]?.name;
      final hex = PathHelper.formatHopHex(hop);
      return contactName != null
          ? "$hex: $contactName"
          : "$hex: ${context.l10n.channelPath_unknownRepeater}";
    }
  }

  String formatDirectionSubText(PathTraceData pathTraceData, int index) {
    if (pathTraceData.pathData.isEmpty) {
      return context.l10n.pathTrace_you;
    }
    if (index < 0 || index > pathTraceData.pathData.length) {
      return context.l10n.pathTrace_you;
    }

    if (index == 0 || index == pathTraceData.pathData.length) {
      if (index == 0) {
        final hop = pathTraceData.pathData.first;
        final contactName = pathTraceData.pathContacts[_hopKey(hop)]?.name;
        final hex = PathHelper.formatHopHex(hop);
        return contactName != null
            ? "$hex: $contactName"
            : "$hex: ${context.l10n.channelPath_unknownRepeater}";
      } else {
        return context.l10n.pathTrace_you;
      }
    } else {
      final hop = pathTraceData.pathData[index];
      final contactName = pathTraceData.pathContacts[_hopKey(hop)]?.name;
      final hex = PathHelper.formatHopHex(hop);
      return contactName != null
          ? "$hex: $contactName"
          : "$hex: ${context.l10n.channelPath_unknownRepeater}";
    }
  }

  Widget _buildMapPathTrace(
    BuildContext context,
    MapTileCacheService tileCache,
    Contact? target,
  ) {
    final isDesktop = _isDesktopPlatform(defaultTargetPlatform);
    return FlutterMap(
      key: _mapKey,
      mapController: _mapController,
      options: MapOptions(
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
        initialCenter: _initialCenter!,
        initialZoom: _initialZoom,
        initialCameraFit: _bounds == null
            ? null
            : CameraFit.bounds(
                bounds: _bounds!,
                padding: const EdgeInsets.all(64),
                maxZoom: 16,
              ),
        minZoom: _mapMinZoom,
        maxZoom: _mapMaxZoom,
        onPositionChanged: (camera, hasGesture) {
          if (!mounted) return;
          // A manual pan/zoom releases the follow lock.
          if (hasGesture && _followPacket) {
            setState(() {
              _followPacket = false;
            });
          }
          final shouldShow = camera.zoom >= _labelZoomThreshold;
          if (shouldShow != _showNodeLabels) {
            setState(() {
              _showNodeLabels = shouldShow;
            });
          }
        },
      ),
      children: [
        tileCache.buildTileLayer(context),
        AnimatedBuilder(
          animation: _playback,
          builder: (context, _) {
            final lines = _buildDisplayPolylines();
            if (lines.isEmpty) return const SizedBox.shrink();
            return PolylineLayer(polylines: lines);
          },
        ),
        if (_viewMode == PathViewMode.combined)
          MarkerLayer(
            markers: _buildCombinedHopMarkers(
              showLabels: _showNodeLabels,
              target: target,
            ),
          )
        else if (_traceData!.pathData.isNotEmpty)
          MarkerLayer(
            markers: _buildHopMarkers(
              _traceData!.pathData,
              showLabels: _showNodeLabels,
              target: target,
            ),
          ),
        AnimatedBuilder(
          animation: _playback,
          builder: (context, _) {
            final markers = _buildPacketMarkers();
            if (markers.isEmpty) return const SizedBox.shrink();
            return MarkerLayer(markers: markers);
          },
        ),
      ],
    );
  }

  /// Polylines for the visible paths. While the packet animation is running,
  /// the selected path's base line is dimmed and the traversed portion plus
  /// the active segment are redrawn brightly by the playback overlay.
  List<Polyline> _buildDisplayPolylines() {
    final visible = _visiblePaths;
    if (_displayPaths.isEmpty) return List.of(_polylines);
    if (visible.isEmpty) return const [];

    final selected = _selectedPath;
    final animating =
        _animationEnabled && _playback.started && _playback.hasPath;

    final lines = buildMultiPathPolylines(
      visible: visible,
      selected: selected,
      combined: _viewMode == PathViewMode.combined,
      animating: animating,
    );
    if (animating && selected != null) {
      lines.addAll(buildPacketTrailPolylines(_playback, selected.color));
    }
    return lines;
  }

  List<Marker> _buildPacketMarkers() {
    final selected = _selectedPath;
    if (!_animationEnabled || selected == null) return const [];
    return buildPacketMarkers(_playback, selected.color);
  }

  Widget _buildBottomPanel(
    BuildContext context,
    PathTraceData pathTraceData,
    bool isImperial,
  ) {
    final l10n = context.l10n;
    final selected = _selectedPath;
    final combined = _viewMode == PathViewMode.combined;
    final maxHeight =
        MediaQuery.of(context).size.height * (combined ? 0.45 : 0.35);

    double cardHeight;
    if (_panelCollapsed) {
      cardHeight = 128;
    } else {
      final summaryHeight = combined ? 34.0 + _displayPaths.length * 36.0 : 0;
      final hopRows = combined
          ? (selected?.totalTransmissions ?? 0)
          : pathTraceData.pathData.length + 1;
      final estimatedHeight = 132.0 + summaryHeight + hopRows * 56.0;
      cardHeight = max(176.0, min(maxHeight, estimatedHeight));
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SizedBox(
        height: cardHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MeshPalette.bg1.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(MeshRadii.md),
            border: Border.all(color: MeshPalette.line2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MeshRadii.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.channelPath_repeaterHops} ${formatDistance(selected?.distanceMeters ?? _pathDistanceMeters, isImperial: isImperial)}',
                              style: MeshTheme.mono(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: MeshPalette.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            PathMiniLegend(combined: combined),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _panelCollapsed
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 20,
                        ),
                        tooltip: _panelCollapsed
                            ? l10n.pathMap_expandPanel
                            : l10n.pathMap_collapsePanel,
                        onPressed: () =>
                            setState(() => _panelCollapsed = !_panelCollapsed),
                      ),
                    ],
                  ),
                ),
                PathAnimationControls(
                  playback: _playback,
                  selected: selected,
                  animationEnabled: _animationEnabled,
                  onToggleAnimation: () => setState(() {
                    _animationEnabled = !_animationEnabled;
                    if (!_animationEnabled) _playback.stop();
                  }),
                  followEnabled: _followPacket,
                  onToggleFollow: _toggleFollowPacket,
                ),
                if (!_panelCollapsed) ...[
                  if (selected != null && selected.unresolvedHops > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                      child: Text(
                        l10n.pathMap_partialAnimation(selected.unresolvedHops),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: MeshPalette.warn,
                        ),
                      ),
                    ),
                  if (combined)
                    PathSummaryList(
                      paths: _displayPaths,
                      selectedId: _selectedPathId,
                      hiddenIds: _hiddenPathIds,
                      isImperial: isImperial,
                      onSelect: _selectPath,
                      onToggleVisibility: _togglePathVisibility,
                      onShowAll: () => setState(_hiddenPathIds.clear),
                    ),
                  const Divider(height: 1),
                  Expanded(child: _buildHopList(pathTraceData, selected)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHopList(PathTraceData pathTraceData, DisplayPath? selected) {
    final useSnrList =
        _viewMode == PathViewMode.single && (selected?.isPrimary ?? true);
    return ValueListenableBuilder<int>(
      valueListenable: _playback.activeSegment,
      builder: (context, activeSegment, _) {
        int highlightRow = -1;
        if (_animationEnabled &&
            selected != null &&
            activeSegment >= 0 &&
            activeSegment < selected.rowForSegment.length) {
          highlightRow = selected.rowForSegment[activeSegment];
        }
        if (useSnrList) {
          return _buildSnrHopList(pathTraceData, highlightRow);
        }
        if (selected == null) {
          return Center(
            child: Text(context.l10n.channelPath_noHopDetailsAvailable),
          );
        }
        return _buildGenericHopList(selected, pathTraceData, highlightRow);
      },
    );
  }

  Widget _buildSnrHopList(PathTraceData pathTraceData, int highlightRow) {
    final l10n = context.l10n;
    if (pathTraceData.pathData.isEmpty) {
      return Center(child: Text(l10n.channelPath_noHopDetailsAvailable));
    }
    return Scrollbar(
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
          return ListTile(
            tileColor: index == highlightRow
                ? kPrimaryPathColor.withValues(alpha: 0.14)
                : null,
            leading: index >= pathTraceData.snrData.length / 2
                ? Icon(Icons.call_received)
                : Icon(Icons.call_made),
            title: Text(
              formatDirectionText(pathTraceData, index),
              style: MeshTheme.mono(fontSize: 13, color: MeshPalette.ink),
            ),
            subtitle: Text(
              formatDirectionSubText(pathTraceData, index),
              style: MeshTheme.mono(fontSize: 12, color: MeshPalette.ink3),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(snrUi.icon, color: snrUi.color, size: 18.0),
                Text(
                  snrUi.text,
                  style: MeshTheme.mono(fontSize: 10, color: snrUi.color),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenericHopList(
    DisplayPath path,
    PathTraceData pathTraceData,
    int highlightRow,
  ) {
    final connector = context.read<MeshCoreConnector>();
    final l10n = context.l10n;

    final hopUseCount = <String, int>{};
    if (_viewMode == PathViewMode.combined) {
      for (final p in _visiblePaths) {
        for (final hopKey in p.hopBytes.map(PathHelper.formatHopHex).toSet()) {
          hopUseCount.update(hopKey, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    return Scrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: path.totalTransmissions,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          String title;
          String subtitle;
          Widget? trailing;
          if (index < path.hopBytes.length) {
            final hop = path.hopBytes[index];
            final hex = PathHelper.formatHopHex(hop);
            final contact = _contactForHop(hop, connector);
            title = contact != null
                ? '$hex: ${contact.name}'
                : '$hex: ${l10n.channelPath_unknownRepeater}';
            final hasGps = contact != null && contact.hasLocation;
            final inferred =
                !hasGps && _inferredPositionForHop(hop, connector) != null;
            final status = hasGps
                ? l10n.pathTrace_legendGpsConfirmed
                : inferred
                ? l10n.pathTrace_legendInferred
                : l10n.pathMap_noLocation;
            final sharedCount = hopUseCount[_hopKey(hop)] ?? 0;
            subtitle = sharedCount > 1
                ? '$status · ${l10n.pathMap_sharedNodeCount(sharedCount)}'
                : status;
            if (path.isPrimary && index < pathTraceData.snrData.length) {
              final snrUi = snrUiFromSNR(
                pathTraceData.snrData[index],
                connector.currentSf,
              );
              trailing = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(snrUi.icon, color: snrUi.color, size: 18.0),
                  Text(
                    snrUi.text,
                    style: MeshTheme.mono(fontSize: 10, color: snrUi.color),
                  ),
                ],
              );
            }
          } else {
            title = widget.targetContact?.name ?? '';
            subtitle = _targetContactIsGuessed
                ? l10n.pathTrace_legendInferred
                : l10n.pathTrace_legendGpsConfirmed;
          }
          return ListTile(
            dense: true,
            tileColor: index == highlightRow
                ? path.color.withValues(alpha: 0.14)
                : null,
            leading: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: path.color, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: MeshTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: path.color,
                ),
              ),
            ),
            title: Text(
              title,
              style: MeshTheme.mono(fontSize: 13, color: MeshPalette.ink),
            ),
            subtitle: Text(
              subtitle,
              style: MeshTheme.mono(fontSize: 11, color: MeshPalette.ink3),
            ),
            trailing: trailing,
          );
        },
      ),
    );
  }
}
