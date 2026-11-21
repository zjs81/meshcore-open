import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/path_helper.dart';
import 'package:meshcore_open/helpers/path_hop_resolver.dart';
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
import 'package:meshcore_open/helpers/snack_bar_builder.dart';
import 'package:meshcore_open/widgets/path_map_scaffold.dart';
import 'package:meshcore_open/widgets/path_map_ui.dart';
import 'package:meshcore_open/widgets/snr_indicator.dart';
import 'package:meshcore_open/widgets/set_my_location_dialog.dart';
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

  /// A previous PUSH_CODE_TRACE_DATA frame to show instead of sending a new
  /// trace when the screen opens.
  final Uint8List? initialTraceFrame;

  /// Called with each trace response frame this screen receives.
  final ValueChanged<Uint8List>? onTraceFrame;

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
    this.initialTraceFrame,
    this.onTraceFrame,
  });

  @override
  State<PathTraceMapScreen> createState() => _PathTraceMapScreenState();
}

class _PathTraceMapScreenState extends State<PathTraceMapScreen>
    with SingleTickerProviderStateMixin {
  static const double _labelZoomThreshold = kPathMapLabelZoomThreshold;
  // Used when the radio never acknowledges the trace request.
  static const Duration _sendAckTimeout = Duration(seconds: 15);

  final MapController _mapController = MapController();
  StreamSubscription<Uint8List>? _frameSubscription;
  Timer? _timeoutTimer;

  bool _isLoading = false;
  bool _awaitingTraceSent = false;
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
  // Tag the radio reported in RESP_CODE_SENT for the current trace; reset
  // on every new trace so a late reply to an earlier one isn't accepted.
  Uint8List? _sentAckTag;
  // Live path resolved at trace time; used by the response handler for
  // endpoint inference so it matches the path that was actually traced.
  Uint8List _tracedPath = Uint8List(0);
  int _tracedPathHashWidth = 1;

  // Packet-flow animation + multi-path view state.
  late final PathPlaybackController _playback;
  PathHistoryService? _pathHistory;
  PathViewMode _viewMode = PathViewMode.single;
  List<DisplayPath> _displayPaths = [];
  List<Uint8List> _primaryOutboundHops = [];
  String _selectedPathId = 'primary';
  final Set<String> _hiddenPathIds = {};
  bool _panelCollapsed = false;
  bool _panelExpanded = false;
  bool _animationEnabled = true;
  bool _followPacket = false;

  // Resolved hop contacts and inferred positions per display path id, used by
  // combined markers and the generic hop list.
  final Map<String, ({List<Contact?> contacts, List<LatLng?> inferred})>
  _resolvedDisplayPaths = {};

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
    MeshCoreConnector connector, {
    int? pathHashByteWidth,
  }) {
    final hops = PathHelper.splitPathBytes(
      pathBytes,
      pathHashByteWidth ?? widget.pathHashByteWidth,
    );
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
    final initialFrame = widget.initialTraceFrame;
    if (initialFrame == null) {
      _doPathTrace();
      return;
    }
    final (livePath, hopWidth) = _resolveLivePath(
      context.read<MeshCoreConnector>(),
    );
    _tracedPath = livePath;
    _tracedPathHashWidth = hopWidth;
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleTraceResponse(initialFrame);
    });
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

  Future<void> _setMyLocation(LatLng point) async {
    final connector = context.read<MeshCoreConnector>();
    final ok = await confirmAndSetMyLocation(context, connector, point);
    if (!ok || !mounted || !_hasData) return;
    // Display paths start at the self position, so redraw them from it.
    setState(() {
      _rebuildDisplayPaths(connector);
    });
  }

  /// Keeps the camera centered on the packet while the follow lock is on.
  void _followPacketCamera() {
    if (!mounted) return;
    followPacketCamera(
      _mapController,
      _playback,
      enabled: _followPacket && _animationEnabled && _hasData,
    );
  }

  void _toggleFollowPacket() {
    setState(() {
      _followPacket = !_followPacket;
    });
    _followPacketCamera();
  }

  void _resetMapView() {
    resetMapView(
      _mapController,
      bounds: _bounds,
      center: _initialCenter,
      zoom: _initialZoom,
    );
  }

  Uint8List? buildPath(
    Uint8List pathBytes,
    int traceHashByteWidth,
    MeshCoreConnector connector, {
    int? pathHashByteWidth,
  }) {
    final pathHops = PathHelper.splitPathBytes(
      pathBytes,
      pathHashByteWidth ?? widget.pathHashByteWidth,
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
  /// this screen was first pushed. Also returns the path's bytes per hop: the
  /// contact's learned width for its device path, the local mode otherwise.
  (Uint8List, int) _resolveLivePath(MeshCoreConnector connector) {
    final target = widget.targetContact;
    if (!widget.flipPathAround || target == null) {
      return (widget.path, widget.pathHashByteWidth);
    }
    final live = connector.allContactsUnfiltered.firstWhere(
      (c) => c.publicKeyHex == target.publicKeyHex,
      orElse: () => target,
    );
    final width = live.pathOverride == null && live.path.isNotEmpty
        ? live.pathHashWidth
        : widget.pathHashByteWidth;
    return (live.pathBytesForDisplay, width);
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
    final (livePath, hopWidth) = _resolveLivePath(connector);
    final traceHashByteWidth = _traceHashByteWidth(hopWidth);
    _tracedPath = livePath;
    _tracedPathHashWidth = hopWidth;

    final pathTmp = widget.reversePathAround
        ? _reversePathByHop(livePath, hopWidth)
        : livePath;

    final path = widget.flipPathAround
        ? buildPath(
            pathTmp,
            traceHashByteWidth,
            connector,
            pathHashByteWidth: hopWidth,
          )
        : _tracePathFromBytes(
            pathTmp,
            traceHashByteWidth,
            connector,
            pathHashByteWidth: hopWidth,
          );

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
    _sentAckTag = null;
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
    if (frame.length > maxFrameSize) {
      // Too many hops for one request (round trips double them); the radio
      // would reject or truncate it.
      appLogger.warn(
        'Path trace request too large: ${frame.length} bytes',
        tag: 'PathTraceMapScreen',
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _failed2Loaded = true;
      });
      return;
    }
    _awaitingTraceSent = true;
    _timeoutTimer?.cancel();
    // Fallback in case RESP_CODE_SENT / RESP_CODE_ERR never arrives; the
    // RESP_CODE_SENT handler replaces it with the radio's own timeout.
    _timeoutTimer = Timer(_sendAckTimeout, () {
      if (!mounted || !_awaitingTraceSent) return;
      _awaitingTraceSent = false;
      setState(() {
        _isLoading = false;
        _failed2Loaded = true;
      });
    });
    try {
      await connector.sendFrame(frame);
    } catch (e) {
      _awaitingTraceSent = false;
      _timeoutTimer?.cancel();
      appLogger.error(
        'Failed to send path trace: $e',
        tag: 'PathTraceMapScreen',
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _failed2Loaded = true;
      });
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.pathTrace_sendFailed(e.toString())),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  void _setupFrameListener() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    // Listen for incoming text messages from the repeater
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      final frameBuffer = BufferReader(frame);
      try {
        final code = frameBuffer.readUInt8();

        if (code == respCodeSent && _awaitingTraceSent) {
          _awaitingTraceSent = false;
          frameBuffer.skipBytes(1); //reserved
          _sentAckTag = frameBuffer.readBytes(4);
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

        if (code == respCodeErr && _awaitingTraceSent) {
          _awaitingTraceSent = false;
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
                listEquals(frame.sublist(4, 8), _sentAckTag))) {
          _timeoutTimer?.cancel();
          widget.onTraceFrame?.call(frame);
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

      setState(() {
        _isLoading = false;
        _hasData = true;
        _targetContact = widget.targetContact;
        _primaryOutboundHops = _outboundHops(pathData);
        _traceData = PathTraceData(
          pathData: pathData,
          snrData: snrData,
          pathContacts: const {},
        );
        _mapKey = ValueKey(
          '${context.l10n.pathTrace_you},${pathData.map(PathHelper.formatHopHex).join(',')}',
        );
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

  (LatLng?, bool) _resolveTargetContactPosition({
    required MeshCoreConnector connector,
    required List<Uint8List> pathData,
    required List<Uint8List> outboundHops,
    required List<Contact?> resolvedOutbound,
    required List<LatLng?> inferredOutbound,
    required Map<String, Contact> pathContacts,
    required Map<String, LatLng> inferredPositions,
    required LatLng? selfPoint,
  }) {
    final tc = _targetContact;
    if (tc == null) return (null, false);
    if (tc.hasLocation) {
      return (LatLng(tc.latitude!, tc.longitude!), false);
    }
    if (pathData.length <= 1 && _tracedPath.isEmpty) {
      return (null, false);
    }

    // Infer from the last hop: average GPS contacts sharing that hop.
    // For a round-trip path (flipPathAround/reversePathAround), the target-side hop
    // sits in the middle of the symmetric sequence; .last is the local side.
    final tracedHops = PathHelper.splitPathBytes(
      _tracedPath,
      _tracedPathHashWidth,
    );
    final hopsForEndpoint = tracedHops.isNotEmpty ? tracedHops : pathData;
    final lastHop = widget.reversePathAround
        ? hopsForEndpoint.first
        : hopsForEndpoint.last;
    final lastHopKey = _hopKey(lastHop);

    final rawPeers = connector.allContacts
        .where(
          (c) =>
              c.hasLocation &&
              c.path.isNotEmpty &&
              _matchesHopPrefix(
                _lastHopChunk(c.path, c.pathHashWidth),
                lastHop,
              ),
        )
        .toList();
    final (anchorPos, anchorGap) = _lastPlausibleAnchor(
      outboundHops: outboundHops,
      resolvedOutbound: resolvedOutbound,
      inferredOutbound: inferredOutbound,
      selfPoint: selfPoint,
    );
    final peers = _filterPlausiblePeers(
      rawPeers,
      prevPos: anchorPos,
      prevMaxMeters: anchorPos != null
          ? anchorGap * PathHopResolver.maxSingleHopDistanceMeters
          : null,
    );
    const offsetDeg = 0.003;
    final angle = (tc.publicKey[1] / 255.0) * 2 * pi;
    if (peers.isNotEmpty) {
      final lat =
          peers.map((c) => c.latitude!).reduce((a, b) => a + b) / peers.length;
      final lon =
          peers.map((c) => c.longitude!).reduce((a, b) => a + b) / peers.length;
      return (
        LatLng(lat + offsetDeg * cos(angle), lon + offsetDeg * sin(angle)),
        true,
      );
    }
    if (inferredPositions.containsKey(lastHopKey)) {
      final inferred = inferredPositions[lastHopKey]!;
      return (
        LatLng(
          inferred.latitude + offsetDeg * cos(angle),
          inferred.longitude + offsetDeg * sin(angle),
        ),
        true,
      );
    }
    // As a last resort, just place it at the same position as the last hop.
    final contact = pathContacts[lastHopKey];
    if (contact != null && contact.hasLocation) {
      return (
        LatLng(
          contact.latitude! + offsetDeg * cos(angle),
          contact.longitude! + offsetDeg * sin(angle),
        ),
        true,
      );
    }
    return (null, false);
  }

  void _syncPrimaryTraceState({
    required MeshCoreConnector connector,
    required PathTraceData traceData,
    required List<Contact?> resolvedOutbound,
    required List<LatLng?> inferredOutbound,
    required LatLng? selfPoint,
  }) {
    final pathContacts = <String, Contact>{};
    for (var i = 0; i < _primaryOutboundHops.length; i++) {
      final contact = resolvedOutbound[i];
      if (contact != null) {
        pathContacts[_hopKey(_primaryOutboundHops[i])] = contact;
      }
    }

    final inferredPositions = <String, LatLng>{};
    for (var i = 0; i < _primaryOutboundHops.length; i++) {
      final inferred = inferredOutbound[i];
      if (inferred != null) {
        inferredPositions[_hopKey(_primaryOutboundHops[i])] = inferred;
      }
    }

    _inferredHopPositions = inferredPositions;
    _traceData = PathTraceData(
      pathData: traceData.pathData,
      snrData: traceData.snrData,
      pathContacts: pathContacts,
    );

    final (targetPos, targetGuessed) = _resolveTargetContactPosition(
      connector: connector,
      pathData: traceData.pathData,
      outboundHops: _primaryOutboundHops,
      resolvedOutbound: resolvedOutbound,
      inferredOutbound: inferredOutbound,
      pathContacts: pathContacts,
      inferredPositions: inferredPositions,
      selfPoint: selfPoint,
    );
    _targetContactPosition = targetPos;
    _targetContactIsGuessed = targetGuessed;

    final points = <LatLng>[?selfPoint];
    String hopLast = '';
    String hopLastLast = '';
    for (final hop in traceData.pathData) {
      final hopKey = _hopKey(hop);
      if (hopKey == hopLastLast && widget.flipPathAround) {
        break; //skip duplicate hops in round-trip paths
      }
      final contact = pathContacts[hopKey];
      if (contact != null && contact.hasLocation) {
        points.add(LatLng(contact.latitude!, contact.longitude!));
      } else {
        final inferred = inferredPositions[hopKey];
        if (inferred != null) points.add(inferred);
      }
      hopLastLast = hopLast;
      hopLast = hopKey;
    }
    if (targetPos != null &&
        _targetContact != null &&
        _targetContact!.type == advTypeChat) {
      points.add(targetPos);
    }

    _points = points;
    _polylines = points.length > 1
        ? [Polyline(points: points, strokeWidth: 4, color: kPrimaryPathColor)]
        : <Polyline>[];
    _initialCenter = points.isNotEmpty ? points.first : const LatLng(0, 0);
    _initialZoom = points.isNotEmpty ? 13.0 : 2.0;
    _bounds = points.length > 1 ? LatLngBounds.fromPoints(points) : null;
    _pathDistanceMeters = getPathDistanceMeters(points);
  }

  LatLng? _contactLatLng(Contact? contact) {
    if (contact == null ||
        !contact.hasLocation ||
        contact.latitude == null ||
        contact.longitude == null) {
      return null;
    }
    return LatLng(contact.latitude!, contact.longitude!);
  }

  List<Contact> _filterPlausiblePeers(
    List<Contact> peers, {
    LatLng? prevPos,
    double? prevMaxMeters,
    LatLng? nextPos,
    double? nextMaxMeters,
  }) {
    if (peers.isEmpty) return const [];
    const distance = Distance();
    var filtered = peers;
    if (prevPos != null && prevMaxMeters != null) {
      filtered = filtered
          .where(
            (c) =>
                distance(prevPos, LatLng(c.latitude!, c.longitude!)) <=
                prevMaxMeters,
          )
          .toList();
    }
    if (nextPos != null && nextMaxMeters != null) {
      filtered = filtered
          .where(
            (c) =>
                distance(nextPos, LatLng(c.latitude!, c.longitude!)) <=
                nextMaxMeters,
          )
          .toList();
    }
    if (prevPos == null && nextPos == null && filtered.length > 1) {
      // Without a neighboring anchor, keep only the largest consistent peer
      // cluster so a single distant prefix match does not skew the average.
      const maxPeerSpreadMeters =
          2 * PathHopResolver.maxSingleHopDistanceMeters;
      var bestCluster = <Contact>[filtered.first];
      for (final seed in filtered) {
        final seedPos = LatLng(seed.latitude!, seed.longitude!);
        final cluster = filtered.where((other) {
          final otherPos = LatLng(other.latitude!, other.longitude!);
          return distance(seedPos, otherPos) <= maxPeerSpreadMeters;
        }).toList();
        if (cluster.length > bestCluster.length ||
            (cluster.length == bestCluster.length &&
                seed.lastSeen.isAfter(bestCluster.first.lastSeen))) {
          bestCluster = cluster;
        }
      }
      return bestCluster;
    }
    return filtered;
  }

  List<LatLng?> _inferHopPositions({
    required List<Uint8List> hops,
    required List<Contact?> resolvedContacts,
    required LatLng? selfPoint,
    required List<Contact> peerContacts,
  }) {
    final inferred = List<LatLng?>.filled(hops.length, null);
    if (hops.isEmpty) return inferred;

    final anchorPositions = <LatLng?>[
      for (var i = 0; i < hops.length; i++)
        i < resolvedContacts.length
            ? _contactLatLng(resolvedContacts[i])
            : null,
    ];

    LatLng? prevPos = selfPoint;
    int prevStep = -1;

    for (var i = 0; i < hops.length; i++) {
      final knownPos = anchorPositions[i];
      if (knownPos != null) {
        prevPos = knownPos;
        prevStep = i;
        continue;
      }

      LatLng? nextPos;
      int? nextStep;
      for (var j = i + 1; j < hops.length; j++) {
        if (anchorPositions[j] != null) {
          nextPos = anchorPositions[j];
          nextStep = j;
          break;
        }
      }

      final hop = hops[i];
      final rawPeers = peerContacts
          .where(
            (c) =>
                c.hasLocation &&
                c.path.isNotEmpty &&
                _matchesHopPrefix(_lastHopChunk(c.path, c.pathHashWidth), hop),
          )
          .toList();
      final plausiblePeers = _filterPlausiblePeers(
        rawPeers,
        prevPos: prevPos,
        prevMaxMeters: prevPos != null
            ? (i - prevStep) * PathHopResolver.maxSingleHopDistanceMeters
            : null,
        nextPos: nextPos,
        nextMaxMeters: nextPos != null && nextStep != null
            ? (nextStep - i) * PathHopResolver.maxSingleHopDistanceMeters
            : null,
      );
      if (plausiblePeers.isNotEmpty) {
        final lat =
            plausiblePeers.map((c) => c.latitude!).reduce((a, b) => a + b) /
            plausiblePeers.length;
        final lon =
            plausiblePeers.map((c) => c.longitude!).reduce((a, b) => a + b) /
            plausiblePeers.length;
        final pos = LatLng(lat, lon);
        inferred[i] = pos;
        prevPos = pos;
        prevStep = i;
      }
    }

    return inferred;
  }

  (LatLng?, int) _lastPlausibleAnchor({
    required List<Uint8List> outboundHops,
    required List<Contact?> resolvedOutbound,
    required List<LatLng?> inferredOutbound,
    required LatLng? selfPoint,
  }) {
    for (var i = outboundHops.length - 1; i >= 0; i--) {
      final pos = _contactLatLng(resolvedOutbound[i]) ?? inferredOutbound[i];
      if (pos != null) {
        return (pos, outboundHops.length - i);
      }
    }
    return (selfPoint, max(1, outboundHops.length));
  }

  String _pathKeyForHops(List<Uint8List> hops) {
    return hops.map(PathHelper.formatHopHex).join(',');
  }

  /// Rebuilds the renderable paths: the traced path as primary plus up to
  /// four distinct alternates from the target contact's path history.
  void _rebuildDisplayPaths(MeshCoreConnector connector) {
    final selfPoint = plausibleSelfPoint(connector);
    final paths = <DisplayPath>[];
    final resolvedMap =
        <String, ({List<Contact?> contacts, List<LatLng?> inferred})>{};

    final resolvedPrimary = PathHopResolver.resolveHops(
      hops: _primaryOutboundHops,
      preferredContacts: widget.pathContacts,
      contacts: connector.allContactsUnfiltered,
      endpoint: selfPoint,
      contactFilter: (c) => c.type != advTypeChat,
    );
    final inferredPrimary = _inferHopPositions(
      hops: _primaryOutboundHops,
      resolvedContacts: resolvedPrimary,
      selfPoint: selfPoint,
      peerContacts: connector.contacts,
    );
    final traceData = _traceData;
    if (traceData != null) {
      _syncPrimaryTraceState(
        connector: connector,
        traceData: traceData,
        resolvedOutbound: resolvedPrimary,
        inferredOutbound: inferredPrimary,
        selfPoint: selfPoint,
      );
    }
    resolvedMap['primary'] = (
      contacts: resolvedPrimary,
      inferred: inferredPrimary,
    );

    final primary = _buildDisplayPath(
      id: 'primary',
      label: context.l10n.pathMap_primary,
      color: kPrimaryPathColor,
      isPrimary: true,
      hops: _primaryOutboundHops,
      resolvedContacts: resolvedPrimary,
      inferredPositions: inferredPrimary,
      selfPoint: selfPoint,
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
          Contact.inferPathHashWidth(record.hopCount, record.pathBytes.length),
        );
        if (!seen.add(_pathKeyForHops(recordHops))) continue;
        if (altIndex >= kAlternatePathColors.length) break;
        final altId = 'alt-${_pathKeyForHops(recordHops)}';
        final altResolved = PathHopResolver.resolveHops(
          hops: recordHops,
          contacts: connector.allContactsUnfiltered,
          endpoint: selfPoint,
          contactFilter: (c) => c.type != advTypeChat,
        );
        final altInferred = _inferHopPositions(
          hops: recordHops,
          resolvedContacts: altResolved,
          selfPoint: selfPoint,
          peerContacts: connector.contacts,
        );
        resolvedMap[altId] = (contacts: altResolved, inferred: altInferred);
        final alt = _buildDisplayPath(
          id: altId,
          label: context.l10n.pathMap_alternate(altIndex + 1),
          color: kAlternatePathColors[altIndex],
          isPrimary: false,
          hops: recordHops,
          resolvedContacts: altResolved,
          inferredPositions: altInferred,
          selfPoint: selfPoint,
          record: record,
        );
        if (alt != null) {
          paths.add(alt);
          altIndex++;
        }
      }
    }

    _resolvedDisplayPaths
      ..clear()
      ..addAll(resolvedMap);
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
    required List<Contact?> resolvedContacts,
    required List<LatLng?> inferredPositions,
    required LatLng? selfPoint,
    PathRecord? record,
  }) {
    // Without a GPS fix for the local radio the path starts at the first
    // located hop instead of a bogus "You" at 0,0.
    final points = <LatLng>[?selfPoint];
    final labels = <String>[if (selfPoint != null) context.l10n.pathTrace_you];
    final confirmed = <bool>[if (selfPoint != null) true];
    final hopOrdinals = <int>[if (selfPoint != null) -1];
    final gapBefore = <bool>[if (selfPoint != null) false];
    int gpsConfirmedHops = 0;
    int unresolvedHops = 0;
    bool pendingGap = false;

    for (var i = 0; i < hops.length; i++) {
      final hop = hops[i];
      final hex = PathHelper.formatHopHex(hop);
      final contact = i < resolvedContacts.length ? resolvedContacts[i] : null;
      LatLng? pos = _contactLatLng(contact);
      var isGps = false;
      if (pos != null) {
        isGps = true;
        gpsConfirmedHops++;
      } else if (i < inferredPositions.length) {
        pos = inferredPositions[i];
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
    syncPlaybackPath(_playback, _selectedPath?.points ?? const <LatLng>[]);
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
                if (_hasData && isDesktopMapPlatform())
                  PathMapDesktopControls(
                    onZoomIn: () => zoomMapBy(_mapController, 1),
                    onZoomOut: () => zoomMapBy(_mapController, -1),
                    onReset: _resetMapView,
                  ),
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
        markers.add(buildPathNodeLabelMarker(point: point, label: fullLabel));
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
    final selfPoint = plausibleSelfPoint(context.read<MeshCoreConnector>());
    if (selfPoint != null) {
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
              padding: const EdgeInsets.all(3),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.l10n.pathTrace_you,
                  style: MeshTheme.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MeshPalette.blue,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      if (showLabels) {
        markers.add(
          buildPathNodeLabelMarker(
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
          buildPathNodeLabelMarker(
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
    final markers = <Marker>[];

    // Hop prefix + resolved position -> paths that use it, in display order.
    final hopNodes =
        <
          String,
          ({
            Uint8List hop,
            Contact? contact,
            LatLng point,
            bool hasGps,
            List<DisplayPath> paths,
          })
        >{};
    for (final path in _visiblePaths) {
      final resolved = _resolvedDisplayPaths[path.id];
      for (var i = 0; i < path.hopBytes.length; i++) {
        final hop = path.hopBytes[i];
        final contact = resolved != null && i < resolved.contacts.length
            ? resolved.contacts[i]
            : null;
        final inferred = resolved != null && i < resolved.inferred.length
            ? resolved.inferred[i]
            : null;
        final gpsPos = _contactLatLng(contact);
        final hasGps = gpsPos != null;
        final point = gpsPos ?? inferred;
        if (point == null) continue;
        final hopKey =
            '${_hopKey(hop)}|${point.latitude.toStringAsFixed(5)},'
            '${point.longitude.toStringAsFixed(5)}';
        final existing = hopNodes[hopKey];
        if (existing == null) {
          hopNodes[hopKey] = (
            hop: hop,
            contact: contact,
            point: point,
            hasGps: hasGps,
            paths: [path],
          );
        } else if (!existing.paths.contains(path)) {
          existing.paths.add(path);
        }
      }
    }

    for (final entry in hopNodes.values) {
      final hop = entry.hop;
      final paths = entry.paths;
      final contact = entry.contact;
      final hasGps = entry.hasGps;
      final point = entry.point;
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
                  padding: const EdgeInsets.all(2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hasGps ? label : '~$label',
                      style: MeshTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: baseColor,
                      ),
                    ),
                  ),
                ),
                if (shared)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PathSharedCountBadge(count: paths.length),
                  ),
              ],
            ),
          ),
        ),
      );
      if (showLabels) {
        markers.add(
          buildPathNodeLabelMarker(
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
    return FlutterMap(
      key: _mapKey,
      mapController: _mapController,
      options: buildPathMapOptions(
        initialCenter: _initialCenter!,
        initialZoom: _initialZoom,
        bounds: _bounds,
        onLongPress: (_, point) => _setMyLocation(point),
        onSecondaryTap: (_, point) => _setMyLocation(point),
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
    final connector = context.read<MeshCoreConnector>();
    final hopRows = combined
        ? (selected?.totalTransmissions ?? 0)
        : pathTraceData.pathData.length + 1;

    return PathMapBottomPanel(
      header: Text(
        '${l10n.channelPath_repeaterHops} ${formatDistance(selected?.distanceMeters ?? _pathDistanceMeters, isImperial: isImperial, l10n: l10n)}',
        style: MeshTheme.mono(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: MeshPalette.ink,
        ),
      ),
      combined: combined,
      showInferredLegend: true,
      collapsed: _panelCollapsed,
      onToggleCollapsed: () => setState(() {
        _panelCollapsed = !_panelCollapsed;
        // Reopening a collapsed panel returns to the normal height.
        if (_panelCollapsed) _panelExpanded = false;
      }),
      expanded: _panelExpanded,
      onToggleExpanded: () => setState(() => _panelExpanded = !_panelExpanded),
      playback: _playback,
      selected: selected,
      animationEnabled: _animationEnabled,
      onToggleAnimation: () => setState(() {
        _animationEnabled = !_animationEnabled;
        if (!_animationEnabled) _playback.stop();
      }),
      followEnabled: _followPacket,
      onToggleFollow: _toggleFollowPacket,
      showNoSelfGpsNote: plausibleSelfPoint(connector) == null,
      pathCount: _displayPaths.length,
      hopRowCount: hopRows,
      summary: combined
          ? PathSummaryList(
              paths: _displayPaths,
              selectedId: _selectedPathId,
              hiddenIds: _hiddenPathIds,
              isImperial: isImperial,
              onSelect: _selectPath,
              onToggleVisibility: _togglePathVisibility,
              onShowAll: () => setState(_hiddenPathIds.clear),
            )
          : null,
      hopList: _buildHopList(pathTraceData, selected),
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
            leading: Icon(
              index >= pathTraceData.snrData.length / 2
                  ? Icons.call_received
                  : Icons.call_made,
              color: MeshPalette.ink2,
            ),
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
                  style: MeshTheme.mono(fontSize: 12, color: snrUi.color),
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
            final resolved = _resolvedDisplayPaths[path.id];
            final contact = resolved != null && index < resolved.contacts.length
                ? resolved.contacts[index]
                : null;
            title = contact != null
                ? '$hex: ${contact.name}'
                : '$hex: ${l10n.channelPath_unknownRepeater}';
            final hasGps = contact != null && contact.hasLocation;
            final inferred =
                !hasGps &&
                resolved != null &&
                index < resolved.inferred.length &&
                resolved.inferred[index] != null;
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
                    style: MeshTheme.mono(fontSize: 12, color: snrUi.color),
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
                  fontSize: 12,
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
              style: MeshTheme.mono(fontSize: 12, color: MeshPalette.ink3),
            ),
            trailing: trailing,
          );
        },
      ),
    );
  }
}
