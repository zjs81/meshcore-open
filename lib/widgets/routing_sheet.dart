import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../utils/platform_info.dart';
import '../helpers/path_helper.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/path_history.dart';
import '../screens/path_trace_map.dart';
import '../services/path_history_service.dart';
import 'path_editor_sheet.dart';

enum _RoutingMode { auto, flood, manual }

enum _PathQuality { strong, good, fair, proven, flood, untested }

class ContactRoutingSheet {
  static Future<void> show(BuildContext context, {required Contact contact}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _RoutingSheetBody(
          contact: contact,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _RoutingSheetBody extends StatefulWidget {
  final Contact contact;
  final ScrollController scrollController;

  const _RoutingSheetBody({
    required this.contact,
    required this.scrollController,
  });

  @override
  State<_RoutingSheetBody> createState() => _RoutingSheetBodyState();
}

class _RoutingSheetBodyState extends State<_RoutingSheetBody> {
  int _resolveContactIndex = -1;
  String? _syncStatus;

  Contact _resolveContact(MeshCoreConnector connector) {
    if (_resolveContactIndex >= 0 &&
        _resolveContactIndex < connector.contacts.length &&
        connector.contacts[_resolveContactIndex].publicKeyHex ==
            widget.contact.publicKeyHex) {
      return connector.contacts[_resolveContactIndex];
    }
    _resolveContactIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.contact.publicKeyHex,
    );
    if (_resolveContactIndex == -1) {
      return widget.contact;
    }
    return connector.contacts[_resolveContactIndex];
  }

  _RoutingMode _modeOf(Contact contact) {
    final override = contact.pathOverride;
    if (override == null) return _RoutingMode.auto;
    return override < 0 ? _RoutingMode.flood : _RoutingMode.manual;
  }

  Future<void> _selectMode(
    MeshCoreConnector connector,
    Contact contact,
    _RoutingMode mode,
  ) async {
    switch (mode) {
      case _RoutingMode.auto:
        setState(() => _syncStatus = null);
        await connector.setPathOverride(contact, pathLen: null);
      case _RoutingMode.flood:
        setState(() => _syncStatus = null);
        await connector.setPathOverride(contact, pathLen: -1);
      case _RoutingMode.manual:
        await _editManualPath(connector, contact);
    }
  }

  Future<void> _editManualPath(
    MeshCoreConnector connector,
    Contact contact,
  ) async {
    final override = contact.pathOverride;
    final initial = override != null && override > 0
        ? (contact.pathOverrideBytes ?? Uint8List(0))
        : (contact.pathLength > 0 ? contact.path : Uint8List(0));
    final available = connector.allContacts
        .where((c) => c.publicKeyHex != contact.publicKeyHex)
        .toList();
    final result = await PathEditorSheet.show(
      context,
      availableContacts: available,
      initialPath: initial,
      pathHashByteWidth: connector.pathHashByteWidth,
    );
    if (result == null || !mounted) return;
    final hopCount = result.length ~/ connector.pathHashByteWidth;
    await connector.setPathOverride(
      contact,
      pathLen: hopCount,
      pathBytes: result,
    );
    await _verifyPath(connector, contact, result);
  }

  Future<void> _applyHistoryPath(
    MeshCoreConnector connector,
    Contact contact,
    PathRecord record,
  ) async {
    final bytes = Uint8List.fromList(record.pathBytes);
    final hopCount = bytes.length ~/ connector.pathHashByteWidth;
    await connector.setPathOverride(
      contact,
      pathLen: hopCount,
      pathBytes: bytes,
    );
    await _verifyPath(connector, contact, bytes);
  }

  Future<void> _verifyPath(
    MeshCoreConnector connector,
    Contact contact,
    Uint8List bytes,
  ) async {
    if (!mounted) return;
    if (!connector.isConnected) {
      setState(() => _syncStatus = context.l10n.chat_pathSavedLocally);
      return;
    }
    setState(() => _syncStatus = null);
    final verified = await connector.verifyContactPathOnDevice(contact, bytes);
    if (!mounted) return;
    setState(
      () => _syncStatus = verified
          ? context.l10n.chat_pathDeviceConfirmed
          : context.l10n.chat_pathDeviceNotConfirmed,
    );
  }

  Future<void> _forgetPath(MeshCoreConnector connector, Contact contact) async {
    await connector.clearContactPath(contact);
    if (!mounted) return;
    setState(() => _syncStatus = context.l10n.chat_pathCleared);
  }

  _PathQuality _qualityOf(
    MeshCoreConnector connector,
    PathRecord record,
    List<DirectRepeater> ranked,
  ) {
    if (record.pathBytes.isNotEmpty) {
      for (var i = 0; i < ranked.length && i < 3; i++) {
        if (ranked[i].matchesPathStart(
          record.pathBytes,
          connector.pathHashByteWidth,
        )) {
          return switch (i) {
            0 => _PathQuality.strong,
            1 => _PathQuality.good,
            _ => _PathQuality.fair,
          };
        }
      }
    }
    if (record.successCount > 0) return _PathQuality.proven;
    if (record.wasFloodDiscovery) return _PathQuality.flood;
    return _PathQuality.untested;
  }

  String _qualityLabel(BuildContext context, _PathQuality quality) {
    final l10n = context.l10n;
    return switch (quality) {
      _PathQuality.strong => l10n.routing_qualityStrong,
      _PathQuality.good => l10n.routing_qualityGood,
      _PathQuality.fair => l10n.routing_qualityFair,
      _PathQuality.proven => l10n.routing_qualityWorked,
      _PathQuality.flood => l10n.routing_qualityFlood,
      _PathQuality.untested => l10n.routing_qualityUntested,
    };
  }

  IconData _qualityIcon(_PathQuality quality) {
    return switch (quality) {
      _PathQuality.strong => Icons.signal_cellular_alt,
      _PathQuality.good => Icons.signal_cellular_alt_2_bar,
      _PathQuality.fair => Icons.signal_cellular_alt_1_bar,
      _PathQuality.proven => Icons.check_circle_outline,
      _PathQuality.flood => Icons.waves,
      _PathQuality.untested => Icons.route,
    };
  }

  String _relativeTime(BuildContext context, DateTime time) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return l10n.time_justNow;
    if (diff.inMinutes < 60) return l10n.time_minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.time_hoursAgo(diff.inHours);
    return l10n.time_daysAgo(diff.inDays);
  }

  String _modeHint(BuildContext context, _RoutingMode mode) {
    final l10n = context.l10n;
    return switch (mode) {
      _RoutingMode.auto => l10n.routing_modeAutoHint,
      _RoutingMode.flood => l10n.routing_modeFloodHint,
      _RoutingMode.manual => l10n.routing_modeManualHint,
    };
  }

  String _routeText(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
    _RoutingMode mode,
  ) {
    final l10n = context.l10n;
    switch (mode) {
      case _RoutingMode.flood:
        return l10n.routing_floodBroadcast;
      case _RoutingMode.manual:
        final bytes = contact.pathOverrideBytes ?? Uint8List(0);
        if (bytes.isEmpty) return l10n.routing_directNoHops;
        return PathHelper.resolvePathNames(
          bytes,
          connector.allContacts,
          connector.pathHashByteWidth,
        );
      case _RoutingMode.auto:
        if (contact.pathLength < 0) return l10n.routing_noPathYet;
        if (contact.pathLength == 0) return l10n.routing_directNoHops;
        if (contact.path.isEmpty) {
          return l10n.chat_hopsCount(contact.pathLength);
        }
        return PathHelper.resolvePathNames(
          contact.path,
          connector.allContacts,
          connector.pathHashByteWidth,
        );
    }
  }

  Uint8List _displayBytes(Contact contact, _RoutingMode mode) {
    return switch (mode) {
      _RoutingMode.flood => Uint8List(0),
      _RoutingMode.manual => contact.pathOverrideBytes ?? Uint8List(0),
      _RoutingMode.auto => contact.path,
    };
  }

  void _openPathTrace(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
    List<int> pathBytes,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PathTraceMapScreen(
          title: context.l10n.contacts_repeaterPathTrace,
          path: Uint8List.fromList(pathBytes),
          flipPathAround: true,
          targetContact: contact,
          pathHashByteWidth: connector.pathHashByteWidth,
        ),
      ),
    );
  }

  void _showPathDetail(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
    List<int> pathBytes,
  ) {
    final l10n = context.l10n;
    final formattedPath = PathHelper.splitPathBytes(
      pathBytes,
      connector.pathHashByteWidth,
    ).map(PathHelper.formatHopHex).join(',');
    final resolvedNames = PathHelper.resolvePathNames(
      pathBytes,
      connector.allContacts,
      connector.pathHashByteWidth,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.chat_fullPath),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(formattedPath),
            const SizedBox(height: 8),
            SelectableText(
              resolvedNames,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                _openPathTrace(dialogContext, connector, contact, pathBytes),
            child: Text(l10n.contacts_pathTrace),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  Widget _currentRouteCard(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
    _RoutingMode mode,
    ({
      int successCount,
      int failureCount,
      int lastTripTimeMs,
      DateTime? lastUsed,
    })?
    floodStats,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayBytes = _displayBytes(contact, mode);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  mode == _RoutingMode.flood ? Icons.waves : Icons.route,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.routing_currentRoute,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _routeText(context, connector, contact, mode),
              style: theme.textTheme.bodyMedium,
            ),
            if (mode == _RoutingMode.flood &&
                floodStats != null &&
                (floodStats.successCount > 0 || floodStats.failureCount > 0))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _floodStatsLine(context, floodStats),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_syncStatus != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _syncStatus!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.tertiary,
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                if (displayBytes.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(l10n.contacts_pathTrace),
                    onPressed: () => _openPathTrace(
                      context,
                      connector,
                      contact,
                      displayBytes,
                    ),
                  ),
                if (mode == _RoutingMode.manual)
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(l10n.routing_editPath),
                    onPressed: () => _editManualPath(connector, contact),
                  ),
                if (mode == _RoutingMode.auto && contact.pathLength >= 0)
                  TextButton.icon(
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: Text(l10n.routing_forgetPath),
                    onPressed: () => _forgetPath(connector, contact),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _floodStatsLine(
    BuildContext context,
    ({
      int successCount,
      int failureCount,
      int lastTripTimeMs,
      DateTime? lastUsed,
    })
    stats,
  ) {
    final l10n = context.l10n;
    final parts = <String>[
      l10n.routing_deliveryCounts(stats.successCount, stats.failureCount),
      if (stats.lastTripTimeMs > 0)
        '${(stats.lastTripTimeMs / 1000).toStringAsFixed(1)}s',
      if (stats.lastUsed != null)
        l10n.routing_lastWorked(_relativeTime(context, stats.lastUsed!)),
    ];
    return parts.join(' • ');
  }

  Widget _floodTile(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
    _RoutingMode mode,
    ({
      int successCount,
      int failureCount,
      int lastTripTimeMs,
      DateTime? lastUsed,
    })
    stats,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.surfaceContainerHighest,
          child: Icon(Icons.waves, size: 18, color: scheme.onSurfaceVariant),
        ),
        title: Text(l10n.routing_floodDelivery),
        subtitle: Text(
          _floodStatsLine(context, stats),
          style: const TextStyle(fontSize: 11),
        ),
        trailing: mode == _RoutingMode.flood
            ? Icon(
                Icons.check_circle,
                color: scheme.primary,
                semanticLabel: l10n.routing_inUse,
              )
            : null,
        onTap: mode == _RoutingMode.flood
            ? null
            : () => _selectMode(connector, contact, _RoutingMode.flood),
      ),
    );
  }

  Widget _pathRecordTile(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
    _RoutingMode mode,
    PathHistoryService pathService,
    PathRecord record,
    _PathQuality quality,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (Color bg, Color fg) = switch (quality) {
      _PathQuality.strong => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      _PathQuality.good => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _PathQuality.fair => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      _PathQuality.proven => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    final hasBytes = record.pathBytes.isNotEmpty;
    final inUse =
        hasBytes &&
        ((mode == _RoutingMode.manual &&
                listEquals(record.pathBytes, contact.pathOverrideBytes)) ||
            (mode == _RoutingMode.auto &&
                listEquals(record.pathBytes, contact.path)));

    final title = hasBytes
        ? PathHelper.resolvePathNames(
            record.pathBytes,
            connector.allContacts,
            connector.pathHashByteWidth,
          )
        : l10n.chat_hopsCount(record.hopCount);
    final displayHopCount = hasBytes
        ? PathHelper.splitPathBytes(
            record.pathBytes,
            connector.pathHashByteWidth,
          ).length
        : record.hopCount;

    final line1 =
        '${l10n.chat_hopsCount(displayHopCount)} • ${_qualityLabel(context, quality)}';
    final line2Parts = <String>[
      record.timestamp != null
          ? l10n.routing_lastWorked(_relativeTime(context, record.timestamp!))
          : l10n.routing_neverWorked,
      if (record.tripTimeMs > 0)
        '${(record.tripTimeMs / 1000).toStringAsFixed(1)}s',
      l10n.routing_deliveryCounts(record.successCount, record.failureCount),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: PlatformInfo.isDesktop && hasBytes
          ? (_) =>
                _showPathDetail(context, connector, contact, record.pathBytes)
          : null,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          enabled: hasBytes,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: bg,
            child: Icon(
              _qualityIcon(quality),
              size: 18,
              color: fg,
              semanticLabel: _qualityLabel(context, quality),
            ),
          ),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '$line1\n${line2Parts.join(' • ')}',
            style: const TextStyle(fontSize: 11),
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (inUse)
                Tooltip(
                  message: l10n.routing_inUse,
                  child: Icon(
                    Icons.check_circle,
                    color: scheme.primary,
                    semanticLabel: l10n.routing_inUse,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: l10n.chat_removePath,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => pathService.removePathRecord(
                  contact.publicKeyHex,
                  record.pathBytes,
                ),
              ),
            ],
          ),
          onTap: hasBytes && !inUse
              ? () => _applyHistoryPath(connector, contact, record)
              : null,
          onLongPress: hasBytes
              ? () => _showPathDetail(
                  context,
                  connector,
                  contact,
                  record.pathBytes,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Consumer2<MeshCoreConnector, PathHistoryService>(
      builder: (context, connector, pathService, _) {
        final contact = _resolveContact(connector);
        final mode = _modeOf(contact);
        final floodStats = pathService.getFloodStats(contact.publicKeyHex);
        final hasFloodStats =
            floodStats != null &&
            (floodStats.successCount > 0 || floodStats.failureCount > 0);

        final rankedRepeaters = List.of(connector.directRepeaters)
          ..sort((a, b) => b.ranking.compareTo(a.ranking));
        final entries =
            pathService
                .getRecentPaths(contact.publicKeyHex)
                .map(
                  (r) => (
                    quality: _qualityOf(connector, r, rankedRepeaters),
                    record: r,
                  ),
                )
                .toList()
              ..sort((a, b) {
                final byQuality = a.quality.index.compareTo(b.quality.index);
                if (byQuality != 0) return byQuality;
                final aTime =
                    a.record.timestamp ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final bTime =
                    b.record.timestamp ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return bTime.compareTo(aTime);
              });

        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.routing_title, style: theme.textTheme.titleLarge),
            Text(
              contact.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<_RoutingMode>(
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size.fromHeight(44)),
              ),
              segments: [
                ButtonSegment(
                  value: _RoutingMode.auto,
                  icon: const Icon(Icons.auto_mode),
                  label: Text(l10n.routing_modeAuto),
                ),
                ButtonSegment(
                  value: _RoutingMode.flood,
                  icon: const Icon(Icons.waves),
                  label: Text(l10n.routing_modeFlood),
                ),
                ButtonSegment(
                  value: _RoutingMode.manual,
                  icon: const Icon(Icons.edit_road),
                  label: Text(l10n.routing_modeManual),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) =>
                  _selectMode(connector, contact, selection.first),
            ),
            const SizedBox(height: 8),
            Text(
              _modeHint(context, mode),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _currentRouteCard(context, connector, contact, mode, floodStats),
            const SizedBox(height: 16),
            Text(l10n.routing_knownPaths, style: theme.textTheme.titleSmall),
            Text(
              l10n.routing_knownPathsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (hasFloodStats)
              _floodTile(context, connector, contact, mode, floodStats),
            if (entries.isEmpty && !hasFloodStats)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.chat_noPathHistoryYet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ...entries.map(
              (entry) => _pathRecordTile(
                context,
                connector,
                contact,
                mode,
                pathService,
                entry.record,
                entry.quality,
              ),
            ),
          ],
        );
      },
    );
  }
}
