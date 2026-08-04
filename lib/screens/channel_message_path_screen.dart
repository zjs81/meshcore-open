import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/helpers/path_helper.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/path_hop_resolver.dart';
import '../services/map_tile_cache_service.dart';
import '../services/app_settings_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/channel_message.dart';
import '../models/app_settings.dart';
import '../models/contact.dart';
import '../models/display_path.dart';
import '../models/path_playback.dart';
import '../theme/mesh_theme.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/path_map_ui.dart';

class ChannelMessagePathScreen extends StatelessWidget {
  final ChannelMessage message;
  final bool channelMessage;
  const ChannelMessagePathScreen({
    super.key,
    required this.message,
    this.channelMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final l10n = context.l10n;
        final primaryPathTmp = _selectPrimaryPath(
          message.pathBytes,
          message.pathVariants,
        );

        final hashByteWidth =
            (message.pathHashWidth ?? connector.pathHashByteWidth)
                .clamp(1, 4)
                .toInt();
        final primaryPath = _orientPathBytes(
          primaryPathTmp,
          hashByteWidth,
          reverse: !channelMessage && !message.isOutgoing,
        );
        final hops = _buildPathHops(
          primaryPath,
          connector,
          l10n,
          hashByteWidth,
          resolveFromEnd: !message.isOutgoing,
        );
        final hasHopDetails = primaryPath.isNotEmpty;

        // Convert observed path byte length to hop count using the packet width.
        // Legacy messages fall back to the current connector width.
        // Reported path length (V3+) is already stored as a hop count; preserve
        // the negative flood sentinel when present.
        final observedHopCount = _hopCountFromBytes(
          primaryPath.length,
          hashByteWidth,
        );
        final reportedHopCount = message.pathLength;
        final effectiveHopCount = observedHopCount > 0
            ? observedHopCount
            : reportedHopCount;

        final observedLabel = _formatObservedHops(
          observedHopCount,
          effectiveHopCount,
          l10n,
        );
        final extraPaths = _otherPaths(primaryPath, message.pathVariants);
        return Scaffold(
          appBar: AppBar(
            title: AdaptiveAppBarTitle(l10n.channelPath_title),
            actions: [
              IconButton(
                icon: const Icon(Icons.radar_outlined),
                tooltip: l10n.channelPath_viewMap,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PathTraceMapScreen(
                      title: context.l10n.contacts_repeaterPathTrace,
                      path: primaryPath,
                      flipPathAround: true,
                      reversePathAround: false,
                      pathHashByteWidth: hashByteWidth,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined),
                tooltip: l10n.channelPath_viewMap,
                onPressed: hasHopDetails
                    ? () {
                        _openPathMap(context, channelMessage: channelMessage);
                      }
                    : null,
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSummaryCard(
                  context,
                  observedLabel: observedLabel,
                  effectiveHopCount: effectiveHopCount,
                ),
                const SizedBox(height: 16),
                if (extraPaths.isNotEmpty) ...[
                  SectionHeader(
                    l10n.channelPath_otherObservedPaths,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  ),
                  const SizedBox(height: 8),
                  _buildPathVariants(context, extraPaths, hashByteWidth),
                  const SizedBox(height: 16),
                ],
                SectionHeader(
                  l10n.channelPath_repeaterHops,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                ),
                if (!hasHopDetails)
                  _buildNoHopCard(context, l10n)
                else
                  _buildHopTimeline(context, hops, l10n),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    String? observedLabel,
    required int? effectiveHopCount,
  }) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final routeChip = effectiveHopCount == null
        ? null
        : effectiveHopCount < 0
        ? const RouteChip(isDirect: false)
        : RouteChip(isDirect: true, hops: effectiveHopCount);

    return MeshCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  l10n.channelPath_messageDetails,
                  padding: EdgeInsets.zero,
                ),
              ),
              ?routeChip,
            ],
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            context,
            l10n.channelPath_senderLabel,
            message.senderName,
            scheme: scheme,
          ),
          _buildDetailRow(
            context,
            l10n.channelPath_timeLabel,
            _formatTime(message.timestamp, l10n),
            scheme: scheme,
          ),
          if (message.repeatCount > 0)
            _buildDetailRow(
              context,
              l10n.channelPath_repeatsLabel,
              message.repeatCount.toString(),
              scheme: scheme,
            ),
          _buildDetailRow(
            context,
            l10n.channelPath_pathLabelTitle,
            _formatPathLabel(effectiveHopCount, l10n),
            scheme: scheme,
          ),
          if (observedLabel != null)
            _buildDetailRow(
              context,
              l10n.channelPath_observedLabel,
              observedLabel,
              scheme: scheme,
            ),
        ],
      ),
    );
  }

  Widget _buildPathVariants(
    BuildContext context,
    List<Uint8List> variants,
    int hashByteWidth,
  ) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < variants.length; i++)
          MeshCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onTap: () => _openPathMap(
              context,
              initialPath: variants[i],
              channelMessage: channelMessage,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.channelPath_observedPathTitle(
                          i + 1,
                          _formatHopCount(
                            variants[i].length,
                            hashByteWidth,
                            l10n,
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatPathPrefixes(variants[i], hashByteWidth),
                        style: MeshTheme.mono(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.map_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNoHopCard(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return MeshCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.route_outlined, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.channelPath_noHopDetails,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHopTimeline(
    BuildContext context,
    List<_PathHop> hops,
    AppLocalizations l10n,
  ) {
    if (hops.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (int i = 0; i < hops.length; i++)
            ListEntrance(
              index: i,
              child: _buildTimelineNode(
                context,
                hops[i],
                l10n,
                isLast: i == hops.length - 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(
    BuildContext context,
    _PathHop hop,
    AppLocalizations l10n, {
    required bool isLast,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final hexPrefix = _formatPrefix(hop.prefix);
    final locationText = hop.hasLocation
        ? '${hop.position!.latitude.toStringAsFixed(5)}, '
              '${hop.position!.longitude.toStringAsFixed(5)}'
        : l10n.channelPath_noLocationData;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AvatarCircle(name: hop.displayLabel, size: 36),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: MeshPalette.blueDim,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.surfaceContainerLow,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          hop.index.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: MeshPalette.blueLine,
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hop.displayLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hexPrefix,
                    style: MeshTheme.mono(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locationText,
                    style: MeshTheme.mono(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      final timeLabel =
          '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      return l10n.channelPath_timeWithDate(time.day, time.month, timeLabel);
    }
    return l10n.channelPath_timeOnly(
      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
    );
  }

  String _formatPathLabel(int? hopCount, AppLocalizations l10n) {
    if (hopCount == null) return l10n.channelPath_unknownPath;
    if (hopCount < 0) return l10n.channelPath_floodPath;
    if (hopCount == 0) return l10n.channelPath_directPath;
    return l10n.chat_hopsCount(hopCount);
  }

  String? _formatObservedHops(
    int observedCount,
    int? targetHopCount,
    AppLocalizations l10n,
  ) {
    if (observedCount <= 0 && (targetHopCount == null || targetHopCount <= 0)) {
      return null;
    }
    if (targetHopCount == null || targetHopCount < 0) {
      return observedCount > 0 ? l10n.chat_hopsCount(observedCount) : null;
    }
    if (observedCount == 0) {
      return l10n.channelPath_observedZeroOf(targetHopCount);
    }
    if (observedCount == targetHopCount) {
      return l10n.chat_hopsCount(observedCount);
    }
    return l10n.channelPath_observedSomeOf(observedCount, targetHopCount);
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    required ColorScheme scheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label.toUpperCase(),
              style: MeshTheme.accentLabel(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _openPathMap(
    BuildContext context, {
    Uint8List? initialPath,
    bool channelMessage = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelMessagePathMapScreen(
          message: message,
          initialPath: initialPath,
          channelMessage: channelMessage,
        ),
      ),
    );
  }
}

class ChannelMessagePathMapScreen extends StatefulWidget {
  final ChannelMessage message;
  final Uint8List? initialPath;
  final bool channelMessage;

  const ChannelMessagePathMapScreen({
    super.key,
    required this.message,
    this.initialPath,
    this.channelMessage = false,
  });

  @override
  State<ChannelMessagePathMapScreen> createState() =>
      _ChannelMessagePathMapScreenState();
}

class _ChannelMessagePathMapScreenState
    extends State<ChannelMessagePathMapScreen>
    with SingleTickerProviderStateMixin {
  static const double _labelZoomThreshold = 8.5;
  static const double _mapMinZoom = 2.0;
  static const double _mapMaxZoom = 18.0;

  final MapController _mapController = MapController();
  Uint8List? _selectedPath;
  double _pathDistance = 0.0;
  bool _showNodeLabels = true;
  bool _didReceivePositionUpdate = false;
  int? _focusedHopIndex;

  // Packet-flow animation + multi-path view state.
  late final PathPlaybackController _playback;
  PathViewMode _viewMode = PathViewMode.single;
  final Set<String> _hiddenPathIds = {};
  bool _panelCollapsed = false;
  bool _animationEnabled = true;
  bool _followPacket = false;

  @override
  void initState() {
    super.initState();
    _selectedPath = widget.initialPath;
    _playback = PathPlaybackController(this);
    _playback.addListener(_followPacketCamera);
  }

  /// Keeps the camera centered on the packet while the follow lock is on.
  void _followPacketCamera() {
    if (!_followPacket ||
        !_animationEnabled ||
        !_playback.started ||
        !_playback.hasPath ||
        !mounted) {
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

  @override
  void didUpdateWidget(ChannelMessagePathMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        !_pathsEqual(
          oldWidget.initialPath ?? Uint8List(0),
          widget.initialPath ?? Uint8List(0),
        )) {
      _selectedPath = widget.initialPath;
    }
  }

  @override
  void dispose() {
    _playback.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Builds a renderable [DisplayPath] for one observed route, oriented in
  /// the direction the packet traveled (sender first, receiver last).
  DisplayPath? _buildDisplayPath({
    required int index,
    required bool isPrimary,
    required Uint8List orientedBytes,
    required List<_PathHop> hops,
    required MeshCoreConnector connector,
  }) {
    final l10n = context.l10n;
    final selfLat = connector.selfLatitude;
    final selfLon = connector.selfLongitude;

    final points = <LatLng>[];
    final labels = <String>[];
    final confirmed = <bool>[];
    final rowIdx = <int>[];
    final gapBefore = <bool>[];
    var pendingGap = false;
    var locatedHops = 0;

    void addSelf() {
      if (selfLat == null || selfLon == null) return;
      points.add(LatLng(selfLat, selfLon));
      labels.add(l10n.pathTrace_you);
      confirmed.add(true);
      rowIdx.add(-1);
      gapBefore.add(pendingGap);
      pendingGap = false;
    }

    final selfFirst = widget.message.isOutgoing;
    if (selfFirst) addSelf();
    for (var i = 0; i < hops.length; i++) {
      final hop = hops[i];
      if (!hop.hasLocation) {
        pendingGap = true;
        continue;
      }
      locatedHops++;
      points.add(hop.position!);
      labels.add(hop.contact?.name ?? _formatPrefix(hop.prefix));
      confirmed.add(true);
      rowIdx.add(i);
      gapBefore.add(pendingGap);
      pendingGap = false;
    }
    if (!selfFirst) addSelf();

    if (points.length < 2) return null;

    final segmentEstimated = <bool>[];
    final rowForSegment = <int>[];
    for (var i = 0; i < points.length - 1; i++) {
      segmentEstimated.add(gapBefore[i + 1]);
      final dest = rowIdx[i + 1];
      rowForSegment.add(dest >= 0 ? dest : (rowIdx[i] >= 0 ? rowIdx[i] : 0));
    }

    return DisplayPath(
      id: 'op-$index',
      label: isPrimary ? l10n.pathMap_primary : l10n.pathMap_alternate(index),
      color: isPrimary
          ? kPrimaryPathColor
          : kAlternatePathColors[(index - 1) % kAlternatePathColors.length],
      isPrimary: isPrimary,
      hopBytes: [
        for (final hop in hops)
          if (hop.hopBytes != null) Uint8List.fromList(hop.hopBytes!),
      ],
      points: points,
      pointLabels: labels,
      pointConfirmed: confirmed,
      segmentEstimated: segmentEstimated,
      rowForSegment: rowForSegment,
      totalTransmissions: hops.length,
      hasTargetEndpoint: false,
      gpsConfirmedHops: locatedHops,
      unresolvedHops: hops.length - locatedHops,
      distanceMeters: getPathDistanceMeters(points),
      record: null,
    );
  }

  /// Updates the playback path after this frame, but only when the selected
  /// path's geometry actually changed, so rebuilds don't reset a running
  /// animation.
  void _schedulePlaybackSync(DisplayPath? selected) {
    final points = selected?.points ?? const <LatLng>[];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    });
  }

  void _selectEntry(_ObservedPathEntry entry) {
    setState(() {
      _selectedPath = entry.observedBytes;
      _hiddenPathIds.remove(entry.display.id);
      _focusedHopIndex = null;
    });
  }

  void _togglePathVisibility(
    DisplayPath path,
    List<_ObservedPathEntry> entries,
    DisplayPath? selected,
  ) {
    setState(() {
      if (!_hiddenPathIds.remove(path.id)) {
        _hiddenPathIds.add(path.id);
        if (path.id == selected?.id) {
          final visible = entries.where(
            (e) => !_hiddenPathIds.contains(e.display.id),
          );
          if (visible.isNotEmpty) {
            _selectedPath = visible.first.observedBytes;
            _focusedHopIndex = null;
          }
        }
      }
    });
  }

  bool _isDesktopPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.linux ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS;
  }

  double _getPathDistance(List<LatLng> points) {
    double totalDistance = 0.0;
    final distanceCalculator = Distance();

    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += distanceCalculator(points[i], points[i + 1]);
    }

    return totalDistance;
  }

  void _focusHop(_PathHop hop) {
    if (!hop.hasLocation) return;
    final targetZoom = _didReceivePositionUpdate
        ? max(_mapController.camera.zoom, 10.0)
        : 12.0;
    _mapController.move(hop.position!, targetZoom);
  }

  void _onHopTapped(_PathHop hop) {
    _focusHop(hop);
    if (!mounted) return;
    setState(() {
      _focusedHopIndex = hop.index;
    });
  }

  void _zoomMapBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta)
        .clamp(_mapMinZoom, _mapMaxZoom)
        .toDouble();
    _mapController.move(camera.center, nextZoom);
  }

  void _resetMapView({
    required LatLng initialCenter,
    required double initialZoom,
    required LatLngBounds? bounds,
  }) {
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
    _mapController.move(initialCenter, initialZoom);
  }

  Widget _buildDesktopMapControls({
    required LatLng initialCenter,
    required double initialZoom,
    required LatLngBounds? bounds,
  }) {
    return Positioned(
      left: 16,
      top: 16,
      child: Card(
        elevation: 4,
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
              onPressed: () => _resetMapView(
                initialCenter: initialCenter,
                initialZoom: initialZoom,
                bounds: bounds,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final settings = context.watch<AppSettingsService>().settings;
        final isImperial = settings.unitSystem == UnitSystem.imperial;
        final tileCache = context.read<MapTileCacheService>();
        final mapScheme = Theme.of(context).colorScheme;
        final primaryPath = _selectPrimaryPath(
          widget.message.pathBytes,
          widget.message.pathVariants,
        );
        final observedPaths = _buildObservedPaths(
          primaryPath,
          widget.message.pathVariants,
        );
        final isDesktop = _isDesktopPlatform(defaultTargetPlatform);
        final selectedPathTmp = _resolveSelectedPath(
          _selectedPath,
          observedPaths,
          primaryPath,
        );

        final width =
            (widget.message.pathHashWidth ?? connector.pathHashByteWidth)
                .clamp(1, 4)
                .toInt();
        final selectedPath = _orientPath(selectedPathTmp, width);

        // Match on the unoriented bytes — observedPaths stores them as
        // recorded, while selectedPath may be reversed for display.
        final selectedIndex = _indexForPath(selectedPathTmp, observedPaths);
        final hops = _buildPathHops(
          selectedPath,
          connector,
          context.l10n,
          width,
          resolveFromEnd: !widget.message.isOutgoing,
        );

        // Renderable paths for the animation and combined view.
        final entries = <_ObservedPathEntry>[];
        for (var i = 0; i < observedPaths.length; i++) {
          final oriented = _orientPath(observedPaths[i].pathBytes, width);
          final pathHops = i == selectedIndex
              ? hops
              : _buildPathHops(
                  oriented,
                  connector,
                  context.l10n,
                  width,
                  resolveFromEnd: !widget.message.isOutgoing,
                );
          final display = _buildDisplayPath(
            index: i,
            isPrimary: observedPaths[i].isPrimary,
            orientedBytes: oriented,
            hops: pathHops,
            connector: connector,
          );
          if (display != null) {
            entries.add(
              _ObservedPathEntry(
                index: i,
                observedBytes: observedPaths[i].pathBytes,
                display: display,
                hops: pathHops,
              ),
            );
          }
        }
        final effectiveMode = entries.length > 1
            ? _viewMode
            : PathViewMode.single;
        _ObservedPathEntry? selectedEntry;
        for (final entry in entries) {
          if (entry.index == selectedIndex) {
            selectedEntry = entry;
            break;
          }
        }
        final selectedDisplay = selectedEntry?.display;
        final visibleEntries = effectiveMode == PathViewMode.single
            ? [?selectedEntry]
            : entries
                  .where((e) => !_hiddenPathIds.contains(e.display.id))
                  .toList();
        final visibleDisplays = visibleEntries.map((e) => e.display).toList();
        _schedulePlaybackSync(selectedDisplay);

        final points = <LatLng>[];

        if ((widget.message.isOutgoing && !widget.channelMessage) ||
            (widget.message.isOutgoing && widget.channelMessage)) {
          points.add(LatLng(connector.selfLatitude!, connector.selfLongitude!));
        }

        for (final hop in hops) {
          if (hop.hasLocation) {
            points.add(hop.position!);
          }
        }

        if ((!widget.message.isOutgoing && !widget.channelMessage) ||
            (!widget.message.isOutgoing && widget.channelMessage)) {
          points.add(LatLng(connector.selfLatitude!, connector.selfLongitude!));
        }

        final polylines = points.length > 1
            ? [
                Polyline(
                  points: points,
                  strokeWidth: 4,
                  color: MeshPalette.blue,
                ),
              ]
            : <Polyline>[];

        final initialCenter = points.isNotEmpty
            ? points.first
            : const LatLng(0, 0);
        final initialZoom = points.isNotEmpty ? 13.0 : 2.0;
        if (!_didReceivePositionUpdate) {
          _showNodeLabels = initialZoom >= _labelZoomThreshold;
        }
        final bounds = points.length > 1
            ? LatLngBounds.fromPoints(points)
            : null;
        final mapKey = ValueKey(
          '${_formatPathPrefixes(selectedPath, width)},${context.l10n.pathTrace_you}',
        );
        _pathDistance = _getPathDistance(points);

        return Scaffold(
          appBar: AppBar(
            title: AdaptiveAppBarTitle(context.l10n.channelPath_mapTitle),
          ),
          body: SafeArea(
            top: false,
            child: Stack(
              children: [
                FlutterMap(
                  key: mapKey,
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: initialZoom,
                    initialCameraFit: bounds == null
                        ? null
                        : CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(64),
                            maxZoom: 16,
                          ),
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
                    onPositionChanged: (camera, hasGesture) {
                      if (!mounted) return;
                      // A manual pan/zoom releases the follow lock.
                      if (hasGesture && _followPacket) {
                        setState(() {
                          _followPacket = false;
                        });
                      }
                      final shouldShow = camera.zoom >= _labelZoomThreshold;
                      if (!_didReceivePositionUpdate ||
                          shouldShow != _showNodeLabels) {
                        setState(() {
                          _didReceivePositionUpdate = true;
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
                        List<Polyline> lines;
                        if (visibleDisplays.isEmpty) {
                          lines = polylines;
                        } else {
                          final animating =
                              _animationEnabled &&
                              _playback.started &&
                              _playback.hasPath;
                          lines = buildMultiPathPolylines(
                            visible: visibleDisplays,
                            selected: selectedDisplay,
                            combined: effectiveMode == PathViewMode.combined,
                            animating: animating,
                          );
                          if (animating && selectedDisplay != null) {
                            lines.addAll(
                              buildPacketTrailPolylines(
                                _playback,
                                selectedDisplay.color,
                              ),
                            );
                          }
                        }
                        if (lines.isEmpty) return const SizedBox.shrink();
                        return PolylineLayer(polylines: lines);
                      },
                    ),
                    if (effectiveMode == PathViewMode.combined)
                      MarkerLayer(
                        markers: _buildCombinedHopMarkers(
                          visibleEntries,
                          showLabels: _showNodeLabels,
                        ),
                      )
                    else
                      MarkerLayer(
                        markers: _buildHopMarkers(
                          hops,
                          showLabels: _showNodeLabels,
                        ),
                      ),
                    AnimatedBuilder(
                      animation: _playback,
                      builder: (context, _) {
                        if (!_animationEnabled || selectedDisplay == null) {
                          return const SizedBox.shrink();
                        }
                        final markers = buildPacketMarkers(
                          _playback,
                          selectedDisplay.color,
                        );
                        if (markers.isEmpty) return const SizedBox.shrink();
                        return MarkerLayer(markers: markers);
                      },
                    ),
                  ],
                ),
                if (isDesktop)
                  _buildDesktopMapControls(
                    initialCenter: initialCenter,
                    initialZoom: initialZoom,
                    bounds: bounds,
                  ),
                if (entries.length > 1)
                  PathViewModeToggle(
                    mode: effectiveMode,
                    onChanged: (mode) => setState(() => _viewMode = mode),
                  ),
                if (observedPaths.length > 1 &&
                    effectiveMode == PathViewMode.single)
                  _buildPathSelector(
                    context,
                    observedPaths,
                    selectedIndex,
                    width,
                    (index) {
                      setState(() {
                        _selectedPath = observedPaths[index].pathBytes;
                        _focusedHopIndex = null;
                      });
                    },
                    topOffset: entries.length > 1 ? 60.0 : 16.0,
                  ),
                if (points.isEmpty)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: mapScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(MeshRadii.md),
                        border: Border.all(color: mapScheme.outlineVariant),
                      ),
                      child: Text(context.l10n.channelPath_noRepeaterLocations),
                    ),
                  ),
                _buildLegendCard(
                  context,
                  hops,
                  isImperial,
                  entries: entries,
                  selectedEntry: selectedEntry,
                  effectiveMode: effectiveMode,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPathSelector(
    BuildContext context,
    List<_ObservedPath> paths,
    int selectedIndex,
    int hashByteWidth,
    ValueChanged<int> onSelected, {
    double topOffset = 16,
  }) {
    final l10n = context.l10n;
    final width = hashByteWidth.clamp(1, 4).toInt();
    final selectedPath = paths[selectedIndex];
    final label = selectedPath.isPrimary
        ? l10n.channelPath_primaryPath(selectedIndex + 1)
        : l10n.channelPath_pathLabel(selectedIndex + 1);
    return Positioned(
      left: 16,
      right: 16,
      top: topOffset,
      child: SafeArea(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.channelPath_observedPathHeader,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selectedIndex,
                    items: [
                      for (int i = 0; i < paths.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(
                            '${paths[i].isPrimary ? l10n.channelPath_primaryPath(i + 1) : l10n.channelPath_pathLabel(i + 1)}'
                            ' • ${_formatHopCount(paths[i].pathBytes.length, width, l10n)}',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      onSelected(value);
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.channelPath_selectedPathLabel(
                    label,
                    _formatPathPrefixes(selectedPath.pathBytes, width),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Marker> _buildHopMarkers(
    List<_PathHop> hops, {
    required bool showLabels,
  }) {
    final markers = <Marker>[];
    for (final hop in hops) {
      if (!hop.hasLocation) continue;
      final point = hop.position!;
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
                color: MeshPalette.blue,
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
                hop.index.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
      if (showLabels) {
        markers.add(
          _buildNodeLabelMarker(
            point: point,
            label: hop.contact?.name ?? _formatPrefix(hop.prefix),
          ),
        );
      }
    }

    markers.addAll(_buildSelfMarkers(showLabels: showLabels));

    return markers;
  }

  List<Marker> _buildSelfMarkers({required bool showLabels}) {
    final selfLat = context.read<MeshCoreConnector>().selfLatitude;
    final selfLon = context.read<MeshCoreConnector>().selfLongitude;
    if (selfLat == null || selfLon == null) return const [];
    final markers = <Marker>[];
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
              color: MeshPalette.signal,
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
    return markers;
  }

  /// Markers for the union of located hops across all visible paths, with a
  /// badge on repeaters used by more than one path.
  List<Marker> _buildCombinedHopMarkers(
    List<_ObservedPathEntry> visibleEntries, {
    required bool showLabels,
  }) {
    final markers = <Marker>[];

    final nodes = <String, _SharedNode>{};
    for (final entry in visibleEntries) {
      final seenInPath = <String>{};
      for (final hop in entry.hops) {
        if (!hop.hasLocation) continue;
        final key =
            '${hop.prefix}|${hop.position!.latitude.toStringAsFixed(5)},'
            '${hop.position!.longitude.toStringAsFixed(5)}';
        if (!seenInPath.add(key)) continue;
        nodes.putIfAbsent(key, () => _SharedNode(hop)).paths.add(entry.display);
      }
    }

    for (final node in nodes.values) {
      final hop = node.hop;
      final point = hop.position!;
      final label = _formatPrefix(hop.prefix);
      final shared = node.paths.length > 1;

      markers.add(
        Marker(
          point: point,
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => showSharedNodeSheet(
              context,
              title: '$label: ${_resolveName(hop.contact, context.l10n)}',
              paths: node.paths,
              onSelect: (display) {
                for (final entry in visibleEntries) {
                  if (entry.display.id == display.id) {
                    _selectEntry(entry);
                    break;
                  }
                }
              },
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: MeshPalette.blue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: shared ? 2.5 : 2,
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
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
                        '${node.paths.length}',
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
            label: hop.contact?.name ?? label,
          ),
        );
      }
    }

    markers.addAll(_buildSelfMarkers(showLabels: showLabels));

    return markers;
  }

  /// Orients recorded path bytes in the direction the packet traveled.
  Uint8List _orientPath(Uint8List bytes, int hashByteWidth) {
    final reverse =
        (!widget.message.isOutgoing && !widget.channelMessage) ||
        (widget.message.isOutgoing && widget.channelMessage);
    return _orientPathBytes(bytes, hashByteWidth, reverse: reverse);
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

  Widget _buildLegendCard(
    BuildContext context,
    List<_PathHop> hops,
    bool isImperial, {
    required List<_ObservedPathEntry> entries,
    required _ObservedPathEntry? selectedEntry,
    required PathViewMode effectiveMode,
  }) {
    final l10n = context.l10n;
    final combined = effectiveMode == PathViewMode.combined;
    final selectedDisplay = selectedEntry?.display;
    final maxHeight =
        MediaQuery.of(context).size.height * (combined ? 0.45 : 0.35);

    double cardHeight;
    if (_panelCollapsed) {
      cardHeight = 128;
    } else {
      final summaryHeight = combined ? 34.0 + entries.length * 36.0 : 0;
      final estimatedHeight = 132.0 + summaryHeight + hops.length * 56.0;
      cardHeight = max(176.0, min(maxHeight, estimatedHeight));
    }

    final hopUseCount = <int, int>{};
    if (combined) {
      for (final entry in entries) {
        if (_hiddenPathIds.contains(entry.display.id)) continue;
        for (final prefix in entry.hops.map((h) => h.prefix).toSet()) {
          hopUseCount.update(prefix, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SizedBox(
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            color: MeshPalette.bg1,
            borderRadius: BorderRadius.circular(MeshRadii.md),
            border: Border.all(color: MeshPalette.line2),
          ),
          clipBehavior: Clip.antiAlias,
          child: DefaultTextStyle(
            style: const TextStyle(color: MeshPalette.ink),
            child: IconTheme(
              data: const IconThemeData(color: MeshPalette.ink),
              child: TextButtonTheme(
                data: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: MeshPalette.ink),
                ),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n.channelPath_repeaterHops,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatDistance(
                                        selectedDisplay?.distanceMeters ??
                                            _pathDistance,
                                        isImperial: isImperial,
                                      ),
                                      style: MeshTheme.mono(
                                        fontSize: 12,
                                        color: MeshPalette.ink2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                PathMiniLegend(
                                  combined: combined,
                                  showInferred: false,
                                ),
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
                            onPressed: () => setState(
                              () => _panelCollapsed = !_panelCollapsed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PathAnimationControls(
                      playback: _playback,
                      selected: selectedDisplay,
                      animationEnabled: _animationEnabled,
                      onToggleAnimation: () => setState(() {
                        _animationEnabled = !_animationEnabled;
                        if (!_animationEnabled) _playback.stop();
                      }),
                      followEnabled: _followPacket,
                      onToggleFollow: _toggleFollowPacket,
                    ),
                    if (!_panelCollapsed) ...[
                      if (selectedDisplay != null &&
                          selectedDisplay.unresolvedHops > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                          child: Text(
                            l10n.pathMap_partialAnimation(
                              selectedDisplay.unresolvedHops,
                            ),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: MeshPalette.warn,
                            ),
                          ),
                        ),
                      if (combined)
                        PathSummaryList(
                          paths: entries.map((e) => e.display).toList(),
                          selectedId: selectedDisplay?.id ?? '',
                          hiddenIds: _hiddenPathIds,
                          isImperial: isImperial,
                          onSelect: (display) {
                            for (final entry in entries) {
                              if (entry.display.id == display.id) {
                                _selectEntry(entry);
                                break;
                              }
                            }
                          },
                          onToggleVisibility: (display) =>
                              _togglePathVisibility(
                                display,
                                entries,
                                selectedDisplay,
                              ),
                          onShowAll: () => setState(_hiddenPathIds.clear),
                        ),
                      const Divider(height: 1),
                      Expanded(
                        child: _buildHopListView(
                          hops,
                          selectedDisplay,
                          hopUseCount,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHopListView(
    List<_PathHop> hops,
    DisplayPath? selectedDisplay,
    Map<int, int> hopUseCount,
  ) {
    final l10n = context.l10n;
    if (hops.isEmpty) {
      return Center(child: Text(l10n.channelPath_noHopDetailsAvailable));
    }
    return ValueListenableBuilder<int>(
      valueListenable: _playback.activeSegment,
      builder: (context, activeSegment, _) {
        int highlightRow = -1;
        if (_animationEnabled &&
            selectedDisplay != null &&
            activeSegment >= 0 &&
            activeSegment < selectedDisplay.rowForSegment.length) {
          highlightRow = selectedDisplay.rowForSegment[activeSegment];
        }
        final highlightColor = (selectedDisplay?.color ?? MeshPalette.blue)
            .withValues(alpha: 0.14);
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: hops.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final hop = hops[index];
            final isFocused = _focusedHopIndex == hop.index;
            final sharedCount = hopUseCount[hop.prefix] ?? 0;
            return InkWell(
              onTap: hop.hasLocation ? () => _onHopTapped(hop) : null,
              child: Container(
                color: index == highlightRow
                    ? highlightColor
                    : isFocused
                    ? MeshPalette.blueBg
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: MeshPalette.blueDim.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MeshPalette.blueDim.withValues(alpha: 0.5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        hop.index.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hop.displayLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [
                              hop.hasLocation
                                  ? '${hop.position!.latitude.toStringAsFixed(5)}, '
                                        '${hop.position!.longitude.toStringAsFixed(5)}'
                                  : context.l10n.channelPath_noLocationData,
                              if (sharedCount > 1)
                                context.l10n.pathMap_sharedNodeCount(
                                  sharedCount,
                                ),
                            ].join(' · '),
                            style: MeshTheme.mono(
                              fontSize: 10,
                              color: MeshPalette.ink3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// One observed route paired with its renderable form and resolved hops.
class _ObservedPathEntry {
  final int index;
  final Uint8List observedBytes;
  final DisplayPath display;
  final List<_PathHop> hops;

  const _ObservedPathEntry({
    required this.index,
    required this.observedBytes,
    required this.display,
    required this.hops,
  });
}

/// A located hop shared across one or more visible paths.
class _SharedNode {
  final _PathHop hop;
  final List<DisplayPath> paths = [];

  _SharedNode(this.hop);
}

class _PathHop {
  final int index;
  final int prefix;
  final Contact? contact;
  final LatLng? position;
  final AppLocalizations l10n;
  final Uint8List? hopBytes;

  const _PathHop({
    required this.index,
    required this.prefix,
    required this.contact,
    required this.position,
    required this.l10n,
    this.hopBytes,
  });

  bool get hasLocation => position != null;

  String get displayLabel {
    final prefixLabel = hopBytes != null && hopBytes!.isNotEmpty
        ? hopBytes!
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join('')
              .toUpperCase()
        : _formatPrefix(prefix);
    return '($prefixLabel) ${_resolveName(contact, l10n)}';
  }
}

class _ObservedPath {
  final Uint8List pathBytes;
  final bool isPrimary;

  const _ObservedPath({required this.pathBytes, required this.isPrimary});
}

List<_PathHop> _buildPathHops(
  Uint8List pathBytes,
  MeshCoreConnector connector,
  AppLocalizations l10n,
  int hashByteWidth, {
  bool resolveFromEnd = false,
}) {
  if (pathBytes.isEmpty) return const [];
  final width = hashByteWidth.clamp(1, 4).toInt();
  final endpoint =
      (connector.selfLatitude != null && connector.selfLongitude != null)
      ? LatLng(connector.selfLatitude!, connector.selfLongitude!)
      : null;
  final resolvedContacts = PathHopResolver.resolve(
    pathBytes: pathBytes,
    contacts: connector.allContacts,
    endpoint: endpoint,
    resolveFromEnd: resolveFromEnd,
    pathHashByteWidth: width,
  );

  final hopChunks = PathHelper.splitPathBytes(pathBytes, width);
  final hops = <_PathHop>[];
  for (var i = 0; i < hopChunks.length; i++) {
    final hopBytes = hopChunks[i];
    final contact = i < resolvedContacts.length ? resolvedContacts[i] : null;
    final resolvedPosition = _resolvePosition(contact);
    hops.add(
      _PathHop(
        index: i + 1,
        prefix: hopBytes.isNotEmpty ? hopBytes[0] : 0,
        contact: contact,
        position: resolvedPosition,
        l10n: l10n,
        hopBytes: hopBytes,
      ),
    );
  }
  return hops;
}

LatLng? _resolvePosition(Contact? contact) {
  if (contact == null) return null;
  if (!contact.hasLocation) return null;
  final latitude = contact.latitude;
  final longitude = contact.longitude;
  if (latitude == null || longitude == null) return null;
  return LatLng(latitude, longitude);
}

String _formatPrefix(int prefix) {
  return prefix.toRadixString(16).padLeft(2, '0').toUpperCase();
}

String _formatPathPrefixes(Uint8List pathBytes, int hashByteWidth) {
  return PathHelper.splitPathBytes(
    pathBytes,
    hashByteWidth,
  ).map(PathHelper.formatHopHex).join(',');
}

Uint8List _orientPathBytes(
  Uint8List pathBytes,
  int hashByteWidth, {
  required bool reverse,
}) {
  if (!reverse || pathBytes.isEmpty) return pathBytes;
  final hops = PathHelper.splitPathBytes(pathBytes, hashByteWidth);
  return Uint8List.fromList([for (final hop in hops.reversed) ...hop]);
}

int _hopCountFromBytes(int byteCount, int hashByteWidth) {
  if (byteCount <= 0) return 0;
  final width = hashByteWidth.clamp(1, 4).toInt();
  return (byteCount + width - 1) ~/ width;
}

String _formatHopCount(
  int byteCount,
  int hashByteWidth,
  AppLocalizations l10n,
) {
  return l10n.chat_hopsCount(_hopCountFromBytes(byteCount, hashByteWidth));
}

String _resolveName(Contact? contact, AppLocalizations l10n) {
  if (contact == null) return l10n.channelPath_unknownRepeater;
  final name = contact.name.trim();
  if (name.isEmpty || name.toLowerCase() == 'unknown') {
    return l10n.channelPath_unknownRepeater;
  }
  return name;
}

Uint8List _selectPrimaryPath(Uint8List pathBytes, List<Uint8List> variants) {
  Uint8List primary = pathBytes;
  for (final variant in variants) {
    if (variant.length > primary.length) {
      primary = variant;
    }
  }
  return primary;
}

List<Uint8List> _otherPaths(Uint8List primary, List<Uint8List> variants) {
  final others = <Uint8List>[];
  for (final variant in variants) {
    if (variant.isEmpty) continue;
    if (!_pathsEqual(primary, variant)) {
      others.add(variant);
    }
  }
  return others;
}

List<_ObservedPath> _buildObservedPaths(
  Uint8List primary,
  List<Uint8List> variants,
) {
  final observed = <_ObservedPath>[];

  void addPath(Uint8List pathBytes, bool isPrimary) {
    if (pathBytes.isEmpty) return;
    for (final existing in observed) {
      if (_pathsEqual(existing.pathBytes, pathBytes)) return;
    }
    observed.add(_ObservedPath(pathBytes: pathBytes, isPrimary: isPrimary));
  }

  addPath(primary, true);
  for (final variant in variants) {
    addPath(variant, false);
  }

  return observed;
}

Uint8List _resolveSelectedPath(
  Uint8List? selected,
  List<_ObservedPath> observedPaths,
  Uint8List fallback,
) {
  if (selected != null) {
    for (final path in observedPaths) {
      if (_pathsEqual(path.pathBytes, selected)) {
        return path.pathBytes;
      }
    }
  }
  if (observedPaths.isNotEmpty) {
    return observedPaths.first.pathBytes;
  }
  return fallback;
}

int _indexForPath(Uint8List selected, List<_ObservedPath> paths) {
  for (int i = 0; i < paths.length; i++) {
    if (_pathsEqual(paths[i].pathBytes, selected)) {
      return i;
    }
  }
  return 0;
}

bool _pathsEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
