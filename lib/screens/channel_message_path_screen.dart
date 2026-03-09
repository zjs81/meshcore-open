import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../services/map_tile_cache_service.dart';
import '../services/app_settings_service.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/channel_message.dart';
import '../models/app_settings.dart';
import '../models/contact.dart';
import '../widgets/adaptive_app_bar_title.dart';

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

        final primaryPath = !channelMessage && !message.isOutgoing
            ? Uint8List.fromList(primaryPathTmp.reversed.toList())
            : primaryPathTmp;
        final contacts = <Contact>[
          ...connector.contacts,
          ...connector.discoveredContacts,
        ];
        final hops = _buildPathHops(primaryPath, contacts, l10n);
        final hasHopDetails = primaryPath.isNotEmpty;
        final observedLabel = _formatObservedHops(
          primaryPath.length,
          message.pathLength,
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
                      flipPathRound: true,
                      reversePathRound: !message.isOutgoing && !channelMessage,
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
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(context, observedLabel: observedLabel),
                const SizedBox(height: 16),
                if (extraPaths.isNotEmpty) ...[
                  Text(
                    l10n.channelPath_otherObservedPaths,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildPathVariants(context, extraPaths),
                  const SizedBox(height: 16),
                ],
                Text(
                  l10n.channelPath_repeaterHops,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (!hasHopDetails)
                  Text(
                    l10n.channelPath_noHopDetails,
                    style: const TextStyle(color: Colors.grey),
                  )
                else
                  ..._buildHopTiles(context, hops),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, {String? observedLabel}) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.channelPath_messageDetails,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(l10n.channelPath_senderLabel, message.senderName),
            _buildDetailRow(
              l10n.channelPath_timeLabel,
              _formatTime(message.timestamp, l10n),
            ),
            if (message.repeatCount > 0)
              _buildDetailRow(
                l10n.channelPath_repeatsLabel,
                message.repeatCount.toString(),
              ),
            _buildDetailRow(
              l10n.channelPath_pathLabelTitle,
              _formatPathLabel(message.pathLength, l10n),
            ),
            if (observedLabel != null)
              _buildDetailRow(l10n.channelPath_observedLabel, observedLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildPathVariants(BuildContext context, List<Uint8List> variants) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < variants.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              dense: true,
              title: Text(
                l10n.channelPath_observedPathTitle(
                  i + 1,
                  _formatHopCount(variants[i].length, l10n),
                ),
              ),
              subtitle: Text(_formatPathPrefixes(variants[i])),
              trailing: const Icon(Icons.map_outlined, size: 20),
              onTap: () => _openPathMap(
                context,
                initialPath: variants[i],
                channelMessage: channelMessage,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildHopTiles(BuildContext context, List<_PathHop> hops) {
    final l10n = context.l10n;
    return [
      for (final hop in hops)
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              child: Text(
                hop.index.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            title: Text(hop.displayLabel),
            subtitle: Text(
              hop.hasLocation
                  ? '${hop.position!.latitude.toStringAsFixed(5)}, '
                        '${hop.position!.longitude.toStringAsFixed(5)}'
                  : l10n.channelPath_noLocationData,
            ),
          ),
        ),
    ];
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

  String _formatPathLabel(int? pathLength, AppLocalizations l10n) {
    if (pathLength == null) return l10n.channelPath_unknownPath;
    if (pathLength < 0) return l10n.channelPath_floodPath;
    if (pathLength == 0) return l10n.channelPath_directPath;
    return l10n.chat_hopsCount(pathLength);
  }

  String? _formatObservedHops(
    int observedCount,
    int? pathLength,
    AppLocalizations l10n,
  ) {
    if (observedCount <= 0 && (pathLength == null || pathLength <= 0)) {
      return null;
    }
    if (pathLength == null || pathLength < 0) {
      return observedCount > 0 ? l10n.chat_hopsCount(observedCount) : null;
    }
    if (observedCount == 0) {
      return l10n.channelPath_observedZeroOf(pathLength);
    }
    if (observedCount == pathLength) {
      return l10n.chat_hopsCount(observedCount);
    }
    return l10n.channelPath_observedSomeOf(observedCount, pathLength);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
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
    extends State<ChannelMessagePathMapScreen> {
  static const double _labelZoomThreshold = 8.5;

  Uint8List? _selectedPath;
  double _pathDistance = 0.0;
  bool _showNodeLabels = true;
  bool _didReceivePositionUpdate = false;

  @override
  void initState() {
    super.initState();
    _selectedPath = widget.initialPath;
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

  double _getPathDistance(List<LatLng> points) {
    double totalDistance = 0.0;
    final distanceCalculator = Distance();

    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += distanceCalculator(points[i], points[i + 1]);
    }

    return totalDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final settings = context.watch<AppSettingsService>().settings;
        final isImperial = settings.unitSystem == UnitSystem.imperial;
        final tileCache = context.read<MapTileCacheService>();
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

        final selectedPath =
            ((!widget.message.isOutgoing && !widget.channelMessage) ||
                (widget.message.isOutgoing && widget.channelMessage))
            ? Uint8List.fromList(selectedPathTmp.reversed.toList())
            : selectedPathTmp;

        final selectedIndex = _indexForPath(selectedPath, observedPaths);
        final contacts = <Contact>[
          ...connector.contacts,
          ...connector.discoveredContacts,
        ];
        final hops = _buildPathHops(selectedPath, contacts, context.l10n);

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
                  color: Colors.blueAccent,
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
          '${_formatPathPrefixes(selectedPath)},${context.l10n.pathTrace_you}',
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
                    minZoom: 2.0,
                    maxZoom: 18.0,
                    interactionOptions: InteractionOptions(
                      flags: ~InteractiveFlag.rotate,
                    ),
                    onPositionChanged: (camera, hasGesture) {
                      final shouldShow = camera.zoom >= _labelZoomThreshold;
                      if (!_didReceivePositionUpdate ||
                          shouldShow != _showNodeLabels) {
                        if (!mounted) return;
                        setState(() {
                          _didReceivePositionUpdate = true;
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
                    if (polylines.isNotEmpty)
                      PolylineLayer(polylines: polylines),
                    MarkerLayer(
                      markers: _buildHopMarkers(
                        hops,
                        showLabels: _showNodeLabels,
                      ),
                    ),
                  ],
                ),
                if (observedPaths.length > 1)
                  _buildPathSelector(context, observedPaths, selectedIndex, (
                    index,
                  ) {
                    setState(() {
                      _selectedPath = observedPaths[index].pathBytes;
                    });
                  }),
                if (points.isEmpty)
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
                _buildLegendCard(context, hops, isImperial),
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
    ValueChanged<int> onSelected,
  ) {
    final l10n = context.l10n;
    final selectedPath = paths[selectedIndex];
    final label = selectedPath.isPrimary
        ? l10n.channelPath_primaryPath(selectedIndex + 1)
        : l10n.channelPath_pathLabel(selectedIndex + 1);
    return Positioned(
      left: 16,
      right: 16,
      top: 16,
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
                            ' • ${_formatHopCount(paths[i].pathBytes.length, l10n)}',
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
                    _formatPathPrefixes(selectedPath.pathBytes),
                  ),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
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
          width: 35,
          height: 35,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
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
            decoration: BoxDecoration(
              color: Colors.teal,
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

  Widget _buildLegendCard(
    BuildContext context,
    List<_PathHop> hops,
    bool isImperial,
  ) {
    final l10n = context.l10n;
    final maxHeight = MediaQuery.of(context).size.height * 0.35;
    final estimatedHeight = 72.0 + (hops.length * 56.0);
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
                  '${l10n.channelPath_repeaterHops} ${formatDistance(_pathDistance, isImperial: isImperial)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: hops.isEmpty
                    ? Center(
                        child: Text(l10n.channelPath_noHopDetailsAvailable),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: hops.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final hop = hops[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text(
                                hop.index.toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            title: Text(hop.displayLabel),
                            subtitle: Text(
                              hop.hasLocation
                                  ? '${hop.position!.latitude.toStringAsFixed(5)}, '
                                        '${hop.position!.longitude.toStringAsFixed(5)}'
                                  : l10n.channelPath_noLocationData,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathHop {
  final int index;
  final int prefix;
  final Contact? contact;
  final LatLng? position;
  final AppLocalizations l10n;

  const _PathHop({
    required this.index,
    required this.prefix,
    required this.contact,
    required this.position,
    required this.l10n,
  });

  bool get hasLocation => position != null;

  String get displayLabel {
    final prefixLabel = _formatPrefix(prefix);
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
  AppLocalizations l10n,
) {
  final hops = <_PathHop>[];
  for (var i = 0; i < pathBytes.length; i++) {
    final prefix = pathBytes[i];
    final contact = _matchContactForPrefix(contacts, prefix);
    hops.add(
      _PathHop(
        index: i + 1,
        prefix: prefix,
        contact: contact,
        position: _resolvePosition(contact),
        l10n: l10n,
      ),
    );
  }
  return hops;
}

Contact? _matchContactForPrefix(List<Contact> contacts, int prefix) {
  final matches = contacts
      .where(
        (contact) =>
            (contact.type == advTypeRepeater || contact.type == advTypeRoom) &&
            contact.publicKey.isNotEmpty &&
            contact.publicKey[0] == prefix,
      )
      .toList();
  if (matches.isEmpty) return null;

  Contact? pickWhere(bool Function(Contact) predicate) {
    for (final contact in matches) {
      if (predicate(contact)) return contact;
    }
    return null;
  }

  return pickWhere((c) => c.type == advTypeRepeater && _hasValidLocation(c)) ??
      pickWhere((c) => c.type == advTypeRepeater) ??
      pickWhere(_hasValidLocation) ??
      matches.first;
}

LatLng? _resolvePosition(Contact? contact) {
  if (contact == null) return null;
  if (!_hasValidLocation(contact)) return null;
  return LatLng(contact.latitude!, contact.longitude!);
}

bool _hasValidLocation(Contact contact) {
  final lat = contact.latitude;
  final lon = contact.longitude;
  if (lat == null || lon == null) return false;
  if (lat == 0 && lon == 0) return false;
  return true;
}

String _formatPrefix(int prefix) {
  return prefix.toRadixString(16).padLeft(2, '0').toUpperCase();
}

String _formatPathPrefixes(Uint8List pathBytes) {
  return pathBytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(',');
}

String _formatHopCount(int count, AppLocalizations l10n) {
  return l10n.chat_hopsCount(count);
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
