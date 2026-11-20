import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/helpers/path_helper.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/network_map_fill.dart';
import '../helpers/path_hop_resolver.dart';
import '../helpers/snack_bar_builder.dart';
import '../services/map_tile_cache_service.dart';
import '../services/app_settings_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/channel_message.dart';
import '../models/app_settings.dart';
import '../models/contact.dart';
import '../models/display_path.dart';
import '../models/path_playback.dart';
import '../services/network_map/network_map_api_client.dart';
import '../storage/region_store.dart';
import '../theme/mesh_theme.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/map_location_picker.dart' show fetchPhonePosition;
import '../widgets/mesh_ui.dart';
import '../widgets/path_map_scaffold.dart';
import '../widgets/path_map_ui.dart';
import '../widgets/set_my_location_dialog.dart';
import '../widgets/signal_ui.dart';

class ChannelMessagePathScreen extends StatefulWidget {
  final ChannelMessage message;
  final bool channelMessage;
  const ChannelMessagePathScreen({
    super.key,
    required this.message,
    this.channelMessage = false,
  });

  @override
  State<ChannelMessagePathScreen> createState() =>
      _ChannelMessagePathScreenState();
}

class _ChannelMessagePathScreenState extends State<ChannelMessagePathScreen> {
  /// Explicit user picks for ambiguous hop prefixes: hop hex -> public key.
  final Map<String, String> _forcedSelection = {};

  /// Network map repeaters matched to hops that no local contact could place.
  Map<String, List<NetworkMapRepeater>> _networkFill = const {};
  String? _networkFetchKey;

  // Phone GPS fix used as the path anchor when the setting opts into it.
  LatLng? _phonePosition;

  @override
  void initState() {
    super.initState();
    _refreshPhoneAnchor();
  }

  /// Fetches the phone's GPS fix once so the anchor can use it when the
  /// setting is on.
  void _refreshPhoneAnchor() {
    if (!context.read<AppSettingsService>().settings.usePhoneGpsForPathAnchor) {
      return;
    }
    fetchPhonePosition().then((position) {
      if (!mounted || position == null) return;
      setState(() => _phonePosition = position);
    });
  }

  /// The path anchor: the phone's GPS fix when the setting is on and a fix
  /// was acquired, otherwise the radio's reported (set) position.
  LatLng? _selfAnchor(MeshCoreConnector connector) {
    final phone = _phonePosition;
    if (context.read<AppSettingsService>().settings.usePhoneGpsForPathAnchor &&
        phone != null) {
      return phone;
    }
    return plausibleSelfPoint(connector);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final l10n = context.l10n;
        final primaryPathTmp = _selectPrimaryPath(
          widget.message.pathBytes,
          widget.message.pathVariants,
        );

        final hashByteWidth =
            (widget.message.pathHashWidth ?? connector.pathHashByteWidth)
                .clamp(1, 4)
                .toInt();
        final reverseOrientation =
            !widget.channelMessage && !widget.message.isOutgoing;
        final primaryPath = _orientPathBytes(
          primaryPathTmp,
          hashByteWidth,
          reverse: reverseOrientation,
        );
        final lastHopSignal = widget.message.signalFor(primaryPathTmp);
        final selfPoint = _selfAnchor(connector);
        final hops = _buildPathHops(
          primaryPath,
          connector.allContacts,
          selfPoint,
          l10n,
          hashByteWidth,
          resolveFromEnd: !widget.message.isOutgoing,
          forcedSelection: _forcedSelection,
          networkFill: _networkFill,
          anchorAtStart: widget.message.isOutgoing,
        );
        final lastHeardLabel = hops.isEmpty ? null : hops.last.displayLabel;
        _maybeFetchNetworkFill(primaryPath, hops, selfPoint);
        final hasHopDetails = primaryPath.isNotEmpty;

        // Convert observed path byte length to hop count using the packet width.
        // Legacy messages fall back to the current connector width.
        // Reported path length (V3+) is already stored as a hop count; preserve
        // the negative flood sentinel when present.
        final observedHopCount = _hopCountFromBytes(
          primaryPath.length,
          hashByteWidth,
        );
        final reportedHopCount = widget.message.pathLength;
        final effectiveHopCount = observedHopCount > 0
            ? observedHopCount
            : reportedHopCount;

        final extraPaths = _otherPaths(
          primaryPath,
          widget.message.pathVariants,
        );
        final uniquePathCount =
            extraPaths.length + (primaryPath.isEmpty ? 0 : 1);
        return Scaffold(
          appBar: AppBar(
            title: AdaptiveAppBarTitle(l10n.channelPath_title),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: l10n.channelPath_copyPath,
                onPressed: primaryPath.isEmpty
                    ? null
                    : () => _copyPath(
                        context,
                        _formatPathPrefixes(primaryPath, hashByteWidth),
                      ),
              ),
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
                        _openPathMap(
                          context,
                          channelMessage: widget.channelMessage,
                        );
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
                  effectiveHopCount: effectiveHopCount,
                  uniquePathCount: uniquePathCount,
                  hashByteWidth: hashByteWidth,
                  hops: hops,
                  selfPoint: selfPoint,
                  lastHeardLabel: lastHeardLabel,
                  lastHeardSignal: lastHopSignal,
                ),
                const SizedBox(height: 16),
                if (extraPaths.isNotEmpty) ...[
                  SectionHeader(
                    l10n.channelPath_otherObservedPaths,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  ),
                  const SizedBox(height: 8),
                  _buildPathVariants(
                    context,
                    extraPaths,
                    hashByteWidth,
                    reverseOrientation,
                    selfPoint,
                    connector.allContacts,
                  ),
                  const SizedBox(height: 16),
                ],
                SectionHeader(
                  l10n.channelPath_repeaterHops,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                ),
                if (!hasHopDetails)
                  _buildNoHopCard(context, l10n)
                else ...[
                  if (hops.any((hop) => hop.ambiguous))
                    _buildShortestPathNote(context, l10n),
                  _buildHopTimeline(context, hops, l10n, signal: lastHopSignal),
                ],
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
    required int? effectiveHopCount,
    required int uniquePathCount,
    required int hashByteWidth,
    required List<_PathHop> hops,
    required LatLng? selfPoint,
    String? lastHeardLabel,
    PathSignal? lastHeardSignal,
  }) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isImperial =
        context.watch<AppSettingsService>().settings.unitSystem ==
        UnitSystem.imperial;
    final routeChip = effectiveHopCount == null
        ? null
        : effectiveHopCount < 0
        ? const RouteChip(isDirect: false)
        : RouteChip(isDirect: true, hops: effectiveHopCount);

    final overallDistance = _overallDistanceMeters(
      hops,
      selfPoint,
      anchorAtStart: widget.message.isOutgoing,
    );
    final travelTime = _travelTime(widget.message);

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
            widget.message.senderName,
            scheme: scheme,
          ),
          _buildDetailRow(
            context,
            l10n.channelPath_timeLabel,
            _formatTime(context, widget.message.displayTime),
            scheme: scheme,
          ),
          if (travelTime != null)
            _buildDetailRow(
              context,
              l10n.channelPath_travelLabel,
              _formatTravelTime(travelTime, l10n),
              scheme: scheme,
            ),
          if (uniquePathCount > 1)
            _buildDetailRow(
              context,
              l10n.channelPath_uniquePathsLabel,
              uniquePathCount.toString(),
              scheme: scheme,
            ),
          _buildDetailRow(
            context,
            l10n.channelPath_hashWidthLabel,
            l10n.channelPath_hashWidthValue(hashByteWidth),
            scheme: scheme,
          ),
          if (overallDistance != null)
            _buildDetailRow(
              context,
              l10n.channelPath_distanceLabel,
              formatDistance(
                overallDistance,
                isImperial: isImperial,
                l10n: l10n,
              ),
              scheme: scheme,
            ),
          _buildDetailRow(
            context,
            l10n.channelPath_pathLabelTitle,
            _formatPathLabel(effectiveHopCount, l10n),
            scheme: scheme,
          ),
          if (lastHeardLabel != null)
            _buildDetailRow(
              context,
              l10n.channelPath_lastHeardLabel,
              '',
              scheme: scheme,
              valueWidget: Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(lastHeardLabel),
                  if (lastHeardSignal != null && !lastHeardSignal.isEmpty)
                    SignalText(
                      snrDb: lastHeardSignal.snrDb,
                      rssiDbm: lastHeardSignal.rssiDbm,
                    ),
                ],
              ),
            ),
          if (widget.message.region?.isNotEmpty ?? false)
            _buildDetailRow(
              context,
              l10n.settings_regionName,
              widget.message.region == kUnscopedRegion
                  ? l10n.chat_regionUnscoped
                  : widget.message.region!,
              scheme: scheme,
            ),
        ],
      ),
    );
  }

  /// Total straight-line distance across all locatable nodes of the path,
  /// including self when known, or null when fewer than two are placed.
  double? _overallDistanceMeters(
    List<_PathHop> hops,
    LatLng? selfPoint, {
    required bool anchorAtStart,
  }) {
    final points = <LatLng>[
      if (anchorAtStart) ?selfPoint,
      for (final hop in hops)
        if (hop.position != null) hop.position!,
      if (!anchorAtStart) ?selfPoint,
    ];
    if (points.length < 2) return null;
    return getPathDistanceMeters(points);
  }

  /// Estimated one-way travel time: sender timestamp versus the local clock
  /// when the message was received. Only meaningful for incoming messages;
  /// returns null when the sender clock runs ahead of the local one.
  Duration? _travelTime(ChannelMessage message) {
    if (message.isOutgoing) return null;
    final travel = message.receivedAt.difference(message.timestamp);
    return travel.isNegative ? null : travel;
  }

  void _maybeFetchNetworkFill(
    Uint8List path,
    List<_PathHop> hops,
    LatLng? selfPoint,
  ) {
    final unresolved = <String>{
      for (final hop in hops)
        if (hop.position == null) PathHelper.formatHopHex(hop.hopBytes!),
    };
    if (unresolved.isEmpty) return;
    final anchors = <LatLng>[
      ?selfPoint,
      for (final hop in hops)
        if (hop.position != null) hop.position!,
    ];
    if (anchors.isEmpty) return;
    final key = '${path.join(',')}|${anchors.length}';
    if (_networkFetchKey == key) return;
    _networkFetchKey = key;
    fetchNetworkMapForHops(hopHexes: unresolved, anchors: anchors).then((
      result,
    ) {
      if (!mounted) return;
      setState(() {
        _networkFill = result;
      });
    });
  }

  void _showHopCandidates(BuildContext context, _PathHop hop) {
    _showHopCandidatesPicker(
      context,
      hop: hop,
      onSelect: (hopHex, pubKeyHex) {
        setState(() {
          _forcedSelection[hopHex] = pubKeyHex;
        });
      },
    );
  }

  Widget _buildPathVariants(
    BuildContext context,
    List<Uint8List> variants,
    int hashByteWidth,
    bool reverseOrientation,
    LatLng? selfPoint,
    List<Contact> contacts,
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
              channelMessage: widget.channelMessage,
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
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      _buildLastHeardLine(
                        variants[i],
                        hashByteWidth,
                        reverseOrientation,
                        selfPoint,
                        contacts,
                        l10n,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: l10n.channelPath_copyPath,
                  onPressed: () => _copyPath(
                    context,
                    _formatPathPrefixes(variants[i], hashByteWidth),
                  ),
                ),
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

  Widget _buildLastHeardLine(
    Uint8List pathBytes,
    int hashByteWidth,
    bool reverseOrientation,
    LatLng? selfPoint,
    List<Contact> contacts,
    AppLocalizations l10n,
  ) {
    final oriented = _orientPathBytes(
      pathBytes,
      hashByteWidth,
      reverse: reverseOrientation,
    );
    final hops = _buildPathHops(
      oriented,
      contacts,
      selfPoint,
      l10n,
      hashByteWidth,
      resolveFromEnd: !widget.message.isOutgoing,
      forcedSelection: _forcedSelection,
      networkFill: _networkFill,
      anchorAtStart: widget.message.isOutgoing,
    );
    if (hops.isEmpty) return const SizedBox.shrink();
    final signal = widget.message.signalFor(pathBytes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Text(
          '${l10n.channelPath_lastHeardLabel}: ${hops.last.displayLabel}',
          style: MeshTheme.mono(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (signal != null && !signal.isEmpty) ...[
          const SizedBox(height: 2),
          SignalText(snrDb: signal.snrDb, rssiDbm: signal.rssiDbm),
        ],
      ],
    );
  }

  Future<void> _copyPath(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.channelPath_pathCopied),
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
    AppLocalizations l10n, {
    PathSignal? signal,
  }) {
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
                signal: i == hops.length - 1 ? signal : null,
                inboundDistanceMeters: i == 0 ? hops[i].distanceMeters : null,
                connectorDistanceMeters: i == hops.length - 1
                    ? null
                    : hops[i + 1].distanceMeters,
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
    PathSignal? signal,
    double? inboundDistanceMeters,
    double? connectorDistanceMeters,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final hexPrefix = _formatPrefix(hop.prefix);
    final isImperial =
        context.watch<AppSettingsService>().settings.unitSystem ==
        UnitSystem.imperial;
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
                if (inboundDistanceMeters != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatDistanceLabel(
                          inboundDistanceMeters,
                          isImperial: isImperial,
                          l10n: l10n,
                        ),
                        style: MeshTheme.mono(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 2,
                    height: 6,
                    child: ColoredBox(color: MeshPalette.blueLine),
                  ),
                ],
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AvatarCircle(name: hop.displayLabel, size: 36),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: MeshPalette.blueDim,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.surfaceContainerLow,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hop.index.toString(),
                            style: const TextStyle(
                              color: MeshPalette.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: connectorDistanceMeters == null
                          ? Container(width: 2, color: MeshPalette.blueLine)
                          : Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: MeshPalette.blueLine,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      formatDistanceLabel(
                                        connectorDistanceMeters,
                                        isImperial: isImperial,
                                        l10n: l10n,
                                      ),
                                      style: MeshTheme.mono(
                                        fontSize: 10,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: MeshPalette.blueLine,
                                  ),
                                ),
                              ],
                            ),
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
              child: InkWell(
                onTap: hop.selectable
                    ? () => _showHopCandidates(context, hop)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            hop.displayLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hop.ambiguous) ...[
                          const SizedBox(width: 6),
                          _tagChip(
                            l10n.channelPath_ambiguousTag,
                            MeshPalette.warn,
                          ),
                        ],
                        if (hop.fromNetworkMap) ...[
                          const SizedBox(width: 6),
                          _tagChip(
                            l10n.channelPath_networkMapTag,
                            MeshPalette.blue,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hexPrefix,
                      style: MeshTheme.mono(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locationText,
                      style: MeshTheme.mono(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (signal != null && !signal.isEmpty) ...[
                      const SizedBox(height: 2),
                      SignalText(snrDb: signal.snrDb, rssiDbm: signal.rssiDbm),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, Color color) {
    return _tagChipWidget(label, color);
  }

  String _formatTime(BuildContext context, DateTime time) {
    final localizations = MaterialLocalizations.of(context);
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(time),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    if (DateTime.now().difference(time).inDays > 0) {
      return '${localizations.formatShortMonthDay(time)} $timeLabel';
    }
    return context.l10n.channelPath_timeOnly(timeLabel);
  }

  String _formatPathLabel(int? hopCount, AppLocalizations l10n) {
    if (hopCount == null) return l10n.channelPath_unknownPath;
    if (hopCount < 0) return l10n.channelPath_floodPath;
    if (hopCount == 0) return l10n.channelPath_directPath;
    return l10n.chat_hopsCount(hopCount);
  }

  Widget _buildShortestPathNote(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.channelPath_shortestPathNote,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    required ColorScheme scheme,
    Widget? valueWidget,
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
          Expanded(child: valueWidget ?? Text(value)),
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
          message: widget.message,
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
  static const double _labelZoomThreshold = kPathMapLabelZoomThreshold;

  final MapController _mapController = MapController();
  Uint8List? _selectedPath;
  bool _showNodeLabels = true;
  bool _didReceivePositionUpdate = false;
  int? _focusedHopIndex;

  /// Explicit user picks for ambiguous hop prefixes: hop hex -> public key.
  final Map<String, String> _forcedSelection = {};

  /// Network map repeaters matched to hops that no local contact could place.
  Map<String, List<NetworkMapRepeater>> _networkFill = const {};
  String? _networkFetchKey;

  // Packet-flow animation + multi-path view state.
  late final PathPlaybackController _playback;
  PathViewMode _viewMode = PathViewMode.single;
  final Set<String> _hiddenPathIds = {};
  bool _panelCollapsed = false;
  bool _panelExpanded = false;
  bool _animationEnabled = true;
  bool _followPacket = false;

  // Resolved paths, reused across connector notifications until the inputs
  // they depend on (selection, contacts, self position) change.
  _PathMapModel? _model;
  Object? _modelKey;
  DisplayPath? _syncedDisplay;
  bool _playbackSyncPending = false;

  // Phone GPS fix used as the path anchor when the setting opts into it.
  LatLng? _phonePosition;

  @override
  void initState() {
    super.initState();
    _selectedPath = widget.initialPath;
    _playback = PathPlaybackController(this);
    _playback.addListener(_followPacketCamera);
    _refreshPhoneAnchor();
  }

  /// Fetches the phone's GPS fix once so the anchor can use it when the
  /// setting is on.
  void _refreshPhoneAnchor() {
    if (!context.read<AppSettingsService>().settings.usePhoneGpsForPathAnchor) {
      return;
    }
    fetchPhonePosition().then((position) {
      if (!mounted || position == null) return;
      setState(() => _phonePosition = position);
    });
  }

  /// The path anchor: the phone's GPS fix when the setting is on and a fix
  /// was acquired, otherwise the radio's reported (set) position.
  LatLng? _selfAnchor(MeshCoreConnector connector) {
    final phone = _phonePosition;
    if (context.read<AppSettingsService>().settings.usePhoneGpsForPathAnchor &&
        phone != null) {
      return phone;
    }
    return plausibleSelfPoint(connector);
  }

  /// Keeps the camera centered on the packet while the follow lock is on.
  void _followPacketCamera() {
    if (!mounted) return;
    followPacketCamera(
      _mapController,
      _playback,
      enabled: _followPacket && _animationEnabled,
    );
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
    required List<_PathHop> hops,
    required LatLng? selfPoint,
  }) {
    final l10n = context.l10n;

    final points = <LatLng>[];
    final labels = <String>[];
    final confirmed = <bool>[];
    final rowIdx = <int>[];
    final gapBefore = <bool>[];
    var pendingGap = false;
    var locatedHops = 0;

    void addSelf() {
      if (selfPoint == null) return;
      points.add(selfPoint);
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

  /// Returns the resolved paths for the current selection, recomputing them
  /// (hop resolution, display paths, polyline) only when an input changed.
  _PathMapModel _resolveModel(MeshCoreConnector connector) {
    final l10n = context.l10n;
    final width = (widget.message.pathHashWidth ?? connector.pathHashByteWidth)
        .clamp(1, 4)
        .toInt();
    final selfPoint = _selfAnchor(connector);
    final contacts = connector.allContacts;
    final key = (
      widget.message,
      widget.channelMessage,
      _selectedPath?.join(','),
      width,
      contactListSignature(contacts),
      selfPoint,
      l10n.localeName,
      _forcedSelection.entries.map((e) => '${e.key}=${e.value}').join(','),
      _networkFill.entries.map((e) => '${e.key}:${e.value.length}').join(','),
    );
    final cached = _model;
    if (cached != null && key == _modelKey) return cached;

    final primaryPath = _selectPrimaryPath(
      widget.message.pathBytes,
      widget.message.pathVariants,
    );
    final observedPaths = _buildObservedPaths(
      primaryPath,
      widget.message.pathVariants,
    );
    final selectedPathTmp = _resolveSelectedPath(
      _selectedPath,
      observedPaths,
      primaryPath,
    );
    final selectedPath = _orientPath(selectedPathTmp, width);

    // Match on the unoriented bytes — observedPaths stores them as
    // recorded, while selectedPath may be reversed for display.
    final selectedIndex = _indexForPath(selectedPathTmp, observedPaths);
    final resolveFromEnd = !widget.message.isOutgoing;
    final hops = _buildPathHops(
      selectedPath,
      contacts,
      selfPoint,
      l10n,
      width,
      resolveFromEnd: resolveFromEnd,
      forcedSelection: _forcedSelection,
      networkFill: _networkFill,
      anchorAtStart: widget.message.isOutgoing,
    );

    // Renderable paths for the animation and combined view.
    final entries = <_ObservedPathEntry>[];
    _ObservedPathEntry? selectedEntry;
    for (var i = 0; i < observedPaths.length; i++) {
      final pathHops = i == selectedIndex
          ? hops
          : _buildPathHops(
              _orientPath(observedPaths[i].pathBytes, width),
              contacts,
              selfPoint,
              l10n,
              width,
              resolveFromEnd: resolveFromEnd,
              forcedSelection: _forcedSelection,
              networkFill: _networkFill,
              anchorAtStart: widget.message.isOutgoing,
            );
      final display = _buildDisplayPath(
        index: i,
        isPrimary: observedPaths[i].isPrimary,
        hops: pathHops,
        selfPoint: selfPoint,
      );
      if (display == null) continue;
      final entry = _ObservedPathEntry(
        index: i,
        observedBytes: observedPaths[i].pathBytes,
        display: display,
        hops: pathHops,
      );
      entries.add(entry);
      if (i == selectedIndex) selectedEntry = entry;
    }

    // Self sits at the sending end for outgoing messages, the receiving end
    // otherwise; it is omitted without a GPS fix.
    final points = <LatLng>[
      if (widget.message.isOutgoing) ?selfPoint,
      for (final hop in hops)
        if (hop.hasLocation) hop.position!,
      if (!widget.message.isOutgoing) ?selfPoint,
    ];

    final initialZoom = points.isNotEmpty ? 13.0 : 2.0;
    final model = _PathMapModel(
      observedPaths: observedPaths,
      selectedIndex: selectedIndex,
      width: width,
      selectedPath: selectedPath,
      hops: hops,
      entries: entries,
      selectedEntry: selectedEntry,
      points: points,
      polylines: points.length > 1
          ? [Polyline(points: points, strokeWidth: 4, color: MeshPalette.blue)]
          : const <Polyline>[],
      initialCenter: points.isNotEmpty ? points.first : const LatLng(0, 0),
      initialZoom: initialZoom,
      bounds: points.length > 1 ? LatLngBounds.fromPoints(points) : null,
      pathDistance: getPathDistanceMeters(points),
      hasSelfPoint: selfPoint != null,
    );
    _model = model;
    _modelKey = key;
    return model;
  }

  /// Updates the playback path after this frame when the selected path
  /// changed. Geometry is compared before resetting, so rebuilds don't
  /// restart a running animation.
  void _schedulePlaybackSync(DisplayPath? selected) {
    if (identical(selected, _syncedDisplay)) return;
    _syncedDisplay = selected;
    if (_playbackSyncPending) return;
    _playbackSyncPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playbackSyncPending = false;
      if (!mounted) return;
      syncPlaybackPath(_playback, _syncedDisplay?.points ?? const <LatLng>[]);
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

  void _maybeFetchNetworkFill(
    Uint8List path,
    List<_PathHop> hops,
    List<LatLng> anchors,
  ) {
    final unresolved = <String>{
      for (final hop in hops)
        if (hop.position == null) PathHelper.formatHopHex(hop.hopBytes!),
    };
    if (unresolved.isEmpty || anchors.length < 2) return;
    final key = '${path.join(',')}|${anchors.length}';
    if (_networkFetchKey == key) return;
    _networkFetchKey = key;
    fetchNetworkMapForHops(hopHexes: unresolved, anchors: anchors).then((
      result,
    ) {
      if (!mounted) return;
      setState(() {
        _networkFill = result;
      });
    });
  }

  void _showHopCandidates(BuildContext context, _PathHop hop) {
    _showHopCandidatesPicker(
      context,
      hop: hop,
      onSelect: (hopHex, pubKeyHex) {
        setState(() {
          _forcedSelection[hopHex] = pubKeyHex;
        });
      },
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
        final model = _resolveModel(connector);
        final observedPaths = model.observedPaths;
        final selectedIndex = model.selectedIndex;
        final width = model.width;
        final hops = model.hops;
        final entries = model.entries;
        final points = model.points;
        _maybeFetchNetworkFill(model.selectedPath, model.hops, points);

        final effectiveMode = entries.length > 1
            ? _viewMode
            : PathViewMode.single;
        final selectedEntry = model.selectedEntry;
        final selectedDisplay = selectedEntry?.display;
        final visibleEntries = effectiveMode == PathViewMode.single
            ? [?selectedEntry]
            : entries
                  .where((e) => !_hiddenPathIds.contains(e.display.id))
                  .toList();
        final visibleDisplays = visibleEntries.map((e) => e.display).toList();
        _schedulePlaybackSync(selectedDisplay);

        if (!_didReceivePositionUpdate) {
          _showNodeLabels = model.initialZoom >= _labelZoomThreshold;
        }
        final mapKey = ValueKey(
          '${_formatPathPrefixes(model.selectedPath, width)},${context.l10n.pathTrace_you}',
        );

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
                  options: buildPathMapOptions(
                    initialCenter: model.initialCenter,
                    initialZoom: model.initialZoom,
                    bounds: model.bounds,
                    onLongPress: (_, point) =>
                        confirmAndSetMyLocation(context, connector, point),
                    onSecondaryTap: (_, point) =>
                        confirmAndSetMyLocation(context, connector, point),
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
                          lines = model.polylines;
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
                    if (effectiveMode == PathViewMode.single)
                      MarkerLayer(
                        markers: _buildSegmentDistanceLabels(
                          selectedDisplay?.points ?? points,
                          isImperial,
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
                if (isDesktopMapPlatform())
                  PathMapDesktopControls(
                    onZoomIn: () => zoomMapBy(_mapController, 1),
                    onZoomOut: () => zoomMapBy(_mapController, -1),
                    onReset: () => resetMapView(
                      _mapController,
                      bounds: model.bounds,
                      center: model.initialCenter,
                      zoom: model.initialZoom,
                    ),
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
                  pathDistance: model.pathDistance,
                  hasSelfPoint: model.hasSelfPoint,
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
                border: Border.all(color: MapPalette.markerOutline, width: 2),
                boxShadow: [_markerShadow],
              ),
              alignment: Alignment.center,
              child: Text(
                hop.index.toString(),
                style: const TextStyle(
                  color: MapPalette.textPrimary,
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
          buildPathNodeLabelMarker(
            point: point,
            label: hop.contact?.name ?? _formatPrefix(hop.prefix),
          ),
        );
      }
    }

    markers.addAll(_buildSelfMarkers(showLabels: showLabels));

    return markers;
  }

  /// Distance labels drawn at the midpoint of each segment between located
  /// nodes of the selected path.
  List<Marker> _buildSegmentDistanceLabels(
    List<LatLng> points,
    bool isImperial,
  ) {
    if (points.length < 2) return const [];
    final l10n = context.l10n;
    final distance = Distance();
    return [
      for (var i = 0; i < points.length - 1; i++)
        Marker(
          point: LatLng(
            (points[i].latitude + points[i + 1].latitude) / 2,
            (points[i].longitude + points[i + 1].longitude) / 2,
          ),
          width: 90,
          height: 22,
          child: IgnorePointer(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: MeshPalette.bg1.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(MeshRadii.xs),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Text(
                    formatDistanceLabel(
                      distance(points[i], points[i + 1]),
                      isImperial: isImperial,
                      l10n: l10n,
                    ),
                    style: MeshTheme.mono(fontSize: 10, color: MeshPalette.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  List<Marker> _buildSelfMarkers({required bool showLabels}) {
    final selfPoint = _selfAnchor(context.read<MeshCoreConnector>());
    if (selfPoint == null) return const [];
    final markers = <Marker>[];
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
              border: Border.all(color: MapPalette.markerOutline, width: 2),
              boxShadow: [_markerShadow],
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(3),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                context.l10n.pathTrace_you,
                style: const TextStyle(
                  color: MapPalette.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
                      color: MapPalette.markerOutline,
                      width: shared ? 2.5 : 2,
                    ),
                    boxShadow: [_markerShadow],
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: MapPalette.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (shared)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PathSharedCountBadge(count: node.paths.length),
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

  Widget _buildLegendCard(
    BuildContext context,
    List<_PathHop> hops,
    bool isImperial, {
    required List<_ObservedPathEntry> entries,
    required _ObservedPathEntry? selectedEntry,
    required PathViewMode effectiveMode,
    required double pathDistance,
    required bool hasSelfPoint,
  }) {
    final l10n = context.l10n;
    final combined = effectiveMode == PathViewMode.combined;
    final selectedDisplay = selectedEntry?.display;

    final hopUseCount = <int, int>{};
    if (combined) {
      for (final entry in entries) {
        if (_hiddenPathIds.contains(entry.display.id)) continue;
        for (final prefix in entry.hops.map((h) => h.prefix).toSet()) {
          hopUseCount.update(prefix, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    return PathMapBottomPanel(
      header: Row(
        children: [
          Expanded(
            child: Text(
              l10n.channelPath_repeaterHops,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            formatDistance(
              selectedDisplay?.distanceMeters ?? pathDistance,
              isImperial: isImperial,
              l10n: l10n,
            ),
            style: MeshTheme.mono(fontSize: 12, color: MeshPalette.ink2),
          ),
        ],
      ),
      combined: combined,
      showInferredLegend: false,
      collapsed: _panelCollapsed,
      onToggleCollapsed: () => setState(() {
        _panelCollapsed = !_panelCollapsed;
        // Reopening a collapsed panel returns to the normal height.
        if (_panelCollapsed) _panelExpanded = false;
      }),
      expanded: _panelExpanded,
      onToggleExpanded: () => setState(() => _panelExpanded = !_panelExpanded),
      playback: _playback,
      selected: selectedDisplay,
      animationEnabled: _animationEnabled,
      onToggleAnimation: () => setState(() {
        _animationEnabled = !_animationEnabled;
        if (!_animationEnabled) _playback.stop();
      }),
      followEnabled: _followPacket,
      onToggleFollow: _toggleFollowPacket,
      showNoSelfGpsNote: !hasSelfPoint,
      pathCount: entries.length,
      hopRowCount: hops.length,
      summary: combined
          ? PathSummaryList(
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
                  _togglePathVisibility(display, entries, selectedDisplay),
              onShowAll: () => setState(_hiddenPathIds.clear),
            )
          : null,
      hopList: _buildHopListView(
        hops,
        selectedDisplay,
        hopUseCount,
        isImperial: isImperial,
      ),
    );
  }

  Widget _buildHopListView(
    List<_PathHop> hops,
    DisplayPath? selectedDisplay,
    Map<int, int> hopUseCount, {
    required bool isImperial,
  }) {
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
              onTap: hop.selectable
                  ? () => _showHopCandidates(context, hop)
                  : hop.hasLocation
                  ? () => _onHopTapped(hop)
                  : null,
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
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: MeshPalette.blueDim.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MeshPalette.blueDim.withValues(alpha: 0.5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          hop.index.toString(),
                          style: const TextStyle(
                            color: MeshPalette.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
                                  hop.displayLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hop.ambiguous) ...[
                                const SizedBox(width: 6),
                                _tagChipWidget(
                                  l10n.channelPath_ambiguousTag,
                                  MeshPalette.warn,
                                ),
                              ],
                              if (hop.fromNetworkMap) ...[
                                const SizedBox(width: 6),
                                _tagChipWidget(
                                  l10n.channelPath_networkMapTag,
                                  MeshPalette.blue,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            [
                              hop.hasLocation
                                  ? '${hop.position!.latitude.toStringAsFixed(5)}, '
                                        '${hop.position!.longitude.toStringAsFixed(5)}'
                                  : context.l10n.channelPath_noLocationData,
                              if (hop.distanceMeters != null)
                                formatDistance(
                                  hop.distanceMeters!,
                                  isImperial: isImperial,
                                  l10n: l10n,
                                ),
                              if (sharedCount > 1)
                                context.l10n.pathMap_sharedNodeCount(
                                  sharedCount,
                                ),
                            ].join(' · '),
                            style: MeshTheme.mono(
                              fontSize: 12,
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

final BoxShadow _markerShadow = BoxShadow(
  color: MapPalette.markerShadow.withValues(alpha: 0.3),
  blurRadius: 4,
  offset: Offset(0, 2),
);

/// Resolved map state for the current selection, cached between rebuilds.
class _PathMapModel {
  final List<_ObservedPath> observedPaths;
  final int selectedIndex;
  final int width;
  final Uint8List selectedPath;
  final List<_PathHop> hops;
  final List<_ObservedPathEntry> entries;
  final _ObservedPathEntry? selectedEntry;
  final List<LatLng> points;
  final List<Polyline> polylines;
  final LatLng initialCenter;
  final double initialZoom;
  final LatLngBounds? bounds;
  final double pathDistance;
  final bool hasSelfPoint;

  const _PathMapModel({
    required this.observedPaths,
    required this.selectedIndex,
    required this.width,
    required this.selectedPath,
    required this.hops,
    required this.entries,
    required this.selectedEntry,
    required this.points,
    required this.polylines,
    required this.initialCenter,
    required this.initialZoom,
    required this.bounds,
    required this.pathDistance,
    required this.hasSelfPoint,
  });
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
  final String hopHex;
  final List<Contact> candidates;
  final List<NetworkMapRepeater> networkMatches;
  final bool ambiguous;
  final double? distanceMeters;
  final LatLng? previousPosition;
  final bool fromNetworkMap;

  const _PathHop({
    required this.index,
    required this.prefix,
    required this.contact,
    required this.position,
    required this.l10n,
    this.hopBytes,
    this.hopHex = '',
    this.candidates = const [],
    this.networkMatches = const [],
    this.ambiguous = false,
    this.distanceMeters,
    this.previousPosition,
    this.fromNetworkMap = false,
  });

  bool get hasLocation => position != null;

  /// Tapping lets the user pick which repeater a duplicated prefix belongs
  /// to, so it is offered whenever there is more than one option.
  bool get selectable => candidates.length > 1 || networkMatches.isNotEmpty;

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
  List<Contact> contacts,
  LatLng? endpoint,
  AppLocalizations l10n,
  int hashByteWidth, {
  bool resolveFromEnd = false,
  Map<String, String> forcedSelection = const {},
  Map<String, List<NetworkMapRepeater>> networkFill = const {},
  bool anchorAtStart = false,
}) {
  if (pathBytes.isEmpty) return const [];
  final width = hashByteWidth.clamp(1, 4).toInt();
  final resolutions = PathHopResolver.resolveDetailed(
    pathBytes: pathBytes,
    contacts: contacts,
    endpoint: endpoint,
    resolveFromEnd: resolveFromEnd,
    pathHashByteWidth: width,
    forcedSelection: forcedSelection,
  );

  final hopChunks = PathHelper.splitPathBytes(pathBytes, width);
  final distance = Distance();
  final hops = <_PathHop>[];
  var previousPosition = anchorAtStart ? endpoint : null;
  for (var i = 0; i < hopChunks.length; i++) {
    final hopBytes = hopChunks[i];
    final resolution = i < resolutions.length ? resolutions[i] : null;
    final contact = resolution?.selected;
    final matches =
        networkFill[PathHelper.formatHopHex(hopBytes)] ??
        const <NetworkMapRepeater>[];
    var resolvedPosition = _resolvePosition(contact);
    var fromNetworkMap = false;
    if (resolvedPosition == null && matches.isNotEmpty) {
      final forcedKey = forcedSelection[PathHelper.formatHopHex(hopBytes)]
          ?.toLowerCase();
      NetworkMapRepeater? chosen;
      for (final repeater in matches) {
        if (repeater.key == contact?.publicKeyHex.toLowerCase() ||
            repeater.key == forcedKey) {
          chosen = repeater;
          break;
        }
      }
      resolvedPosition = (chosen ?? matches.first).cell.center;
      fromNetworkMap = true;
    }
    double? hopDistance;
    final previousOfHop = previousPosition;
    if (resolvedPosition != null && previousOfHop != null) {
      hopDistance = distance(previousOfHop, resolvedPosition);
    }
    if (resolvedPosition != null) previousPosition = resolvedPosition;
    hops.add(
      _PathHop(
        index: i + 1,
        prefix: hopBytes.isNotEmpty ? hopBytes[0] : 0,
        contact: contact,
        position: resolvedPosition,
        l10n: l10n,
        hopBytes: hopBytes,
        hopHex: PathHelper.formatHopHex(hopBytes),
        candidates: resolution?.candidates ?? const [],
        networkMatches: matches,
        ambiguous: resolution?.ambiguous ?? false,
        distanceMeters: hopDistance,
        previousPosition: previousOfHop,
        fromNetworkMap: fromNetworkMap,
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

String _formatTravelTime(Duration travel, AppLocalizations l10n) {
  if (travel.inMilliseconds > 99999) return l10n.chat_latencyUnsynced;
  return l10n.chat_latencyMilliseconds(travel.inMilliseconds);
}

String _resolveName(Contact? contact, AppLocalizations l10n) {
  if (contact == null) return l10n.channelPath_unknownRepeater;
  final name = contact.name.trim();
  if (name.isEmpty || name.toLowerCase() == 'unknown') {
    return l10n.channelPath_unknownRepeater;
  }
  return name;
}

Widget _tagChipWidget(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(MeshRadii.xs),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(label, style: MeshTheme.mono(fontSize: 10, color: color)),
  );
}

/// Bottom sheet listing every repeater that could own an ambiguous hop
/// prefix — local contacts plus network-map matches — and letting the user
/// pin one. Active repeaters are listed first in their own section so the
/// likelier owner is at the top of a scrollable list.
void _showHopCandidatesPicker(
  BuildContext context, {
  required _PathHop hop,
  required void Function(String hopHex, String pubKeyHex) onSelect,
}) {
  final l10n = context.l10n;
  final distance = Distance();
  final maxHeight = MediaQuery.of(context).size.height * 0.85;
  final active = hop.candidates.where((c) => c.isActive).toList();
  final inactive = hop.candidates.where((c) => !c.isActive).toList();

  Widget sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Text(
        label,
        style: MeshTheme.accentLabel(fontSize: 11, color: MeshPalette.ink3),
      ),
    );
  }

  Widget candidateTile(BuildContext sheetContext, Contact candidate) {
    return ListTile(
      dense: true,
      leading: AvatarCircle(name: candidate.name, size: 32),
      title: Text(candidate.name),
      subtitle: Text(
        _candidateSubtitle(candidate, hop, distance, l10n),
        style: MeshTheme.mono(fontSize: 12),
      ),
      trailing: hop.contact?.publicKeyHex == candidate.publicKeyHex
          ? const Icon(Icons.check, color: MeshPalette.blue)
          : null,
      onTap: () {
        Navigator.pop(sheetContext);
        onSelect(hop.hopHex, candidate.publicKeyHex);
      },
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  l10n.channelPath_hopCandidatesTitle(hop.index),
                  style: MeshTheme.mono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MeshPalette.ink,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  hop.hopHex,
                  style: MeshTheme.mono(fontSize: 12, color: MeshPalette.ink3),
                ),
              ),
              const SizedBox(height: 8),
              if (active.isNotEmpty) ...[
                sectionHeader(l10n.contacts_detailActive),
                for (final candidate in active)
                  candidateTile(sheetContext, candidate),
              ],
              if (inactive.isNotEmpty) ...[
                sectionHeader(l10n.contacts_detailInactive),
                for (final candidate in inactive)
                  candidateTile(sheetContext, candidate),
              ],
              if (hop.networkMatches.isNotEmpty) ...[
                sectionHeader(l10n.channelPath_networkMapTag),
                for (final repeater in hop.networkMatches)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.public),
                    title: Text(
                      '${(repeater.name?.isNotEmpty ?? false) ? repeater.name! : repeater.key.substring(0, 8)}'
                      ' · ${l10n.channelPath_networkMapTag}',
                    ),
                    subtitle: Text(
                      '${repeater.cell.center.latitude.toStringAsFixed(4)}, '
                      '${repeater.cell.center.longitude.toStringAsFixed(4)}',
                      style: MeshTheme.mono(fontSize: 12),
                    ),
                    trailing: hop.contact?.publicKeyHex == repeater.key
                        ? const Icon(Icons.check, color: MeshPalette.blue)
                        : null,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onSelect(hop.hopHex, repeater.key);
                    },
                  ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

String _candidateSubtitle(
  Contact candidate,
  _PathHop hop,
  Distance distance,
  AppLocalizations l10n,
) {
  final position = _resolvePosition(candidate);
  final previous = hop.previousPosition;
  if (previous != null && position != null) {
    return formatDistance(
      distance(previous, position),
      isImperial: false,
      l10n: l10n,
    );
  }
  if (position == null) return l10n.channelPath_noLocationData;
  return '${position.latitude.toStringAsFixed(4)}, '
      '${position.longitude.toStringAsFixed(4)}';
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
