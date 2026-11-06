import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/display_path.dart';
import '../models/path_playback.dart';
import '../theme/mesh_theme.dart';

/// Shared UI for the path map screens (live path trace and received-message
/// path map): packet-flow animation overlays, single/combined view toggle,
/// playback controls, and the multi-path summary/legend.

enum PathViewMode { single, combined }

const Color kPrimaryPathColor = MeshPalette.blue;
const List<Color> kAlternatePathColors = [
  Color(0xFF8B5CF6), // purple
  MeshPalette.signal, // green
  MeshPalette.warn, // amber
  MeshPalette.magenta,
];

double getPathDistanceMeters(List<LatLng> points) {
  if (points.length <= 1) return 0.0;

  double distanceMeters = 0.0;
  final distanceCalculator = Distance();

  for (int i = 0; i < points.length - 1; i++) {
    distanceMeters += distanceCalculator(points[i], points[i + 1]);
  }

  return distanceMeters;
}

String formatDistance(
  double distanceMeters, {
  required bool isImperial,
  AppLocalizations? l10n,
}) {
  if (isImperial) {
    return '(${(distanceMeters / 1609.34).toStringAsFixed(2)} ${l10n?.units_mi ?? 'mi'})';
  }
  return '(${(distanceMeters / 1000).toStringAsFixed(2)} ${l10n?.units_km ?? 'km'})';
}

String formatLastObserved(BuildContext context, DateTime timestamp) {
  final l10n = context.l10n;
  final diff = DateTime.now().difference(timestamp);
  if (diff.isNegative || diff.inMinutes < 5) return l10n.contacts_lastSeenNow;
  if (diff.inMinutes < 60) return l10n.contacts_lastSeenMinsAgo(diff.inMinutes);
  if (diff.inHours < 24) {
    return diff.inHours == 1
        ? l10n.contacts_lastSeenHourAgo
        : l10n.contacts_lastSeenHoursAgo(diff.inHours);
  }
  return diff.inDays == 1
      ? l10n.contacts_lastSeenDayAgo
      : l10n.contacts_lastSeenDaysAgo(diff.inDays);
}

/// Polylines for the visible paths: shared-segment halos (combined view),
/// dashed runs for estimated segments, dimming for unfocused paths and for
/// the selected path while its packet animation is running.
List<Polyline> buildMultiPathPolylines({
  required List<DisplayPath> visible,
  required DisplayPath? selected,
  required bool combined,
  required bool animating,
}) {
  final lines = <Polyline>[];

  if (combined && visible.length > 1) {
    final counts = <String, int>{};
    for (final path in visible) {
      for (var i = 0; i < path.points.length - 1; i++) {
        counts.update(
          _segmentKey(path.points[i], path.points[i + 1]),
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final drawn = <String>{};
    for (final path in visible) {
      for (var i = 0; i < path.points.length - 1; i++) {
        final key = _segmentKey(path.points[i], path.points[i + 1]);
        if ((counts[key] ?? 0) < 2 || !drawn.add(key)) continue;
        lines.add(
          Polyline(
            points: [path.points[i], path.points[i + 1]],
            strokeWidth: 11,
            color: MapPalette.markerOutline.withValues(alpha: 0.22),
          ),
        );
      }
    }
  }

  void addPath(DisplayPath path, {required bool isSelected}) {
    final dimmedByFocus = combined && !isSelected;
    final alpha = dimmedByFocus ? 0.38 : (isSelected && animating ? 0.30 : 1.0);
    final width = isSelected ? 5.0 : 3.0;
    var i = 0;
    while (i < path.segmentEstimated.length) {
      final dashed = path.segmentEstimated[i];
      var j = i;
      while (j < path.segmentEstimated.length &&
          path.segmentEstimated[j] == dashed) {
        j++;
      }
      lines.add(
        Polyline(
          points: path.points.sublist(i, j + 1),
          strokeWidth: width,
          color: path.color.withValues(alpha: alpha),
          pattern: dashed
              ? StrokePattern.dashed(segments: const [10, 7])
              : const StrokePattern.solid(),
        ),
      );
      i = j;
    }
  }

  for (final path in visible) {
    if (path.id != selected?.id) addPath(path, isSelected: false);
  }
  if (selected != null && visible.any((p) => p.id == selected.id)) {
    addPath(selected, isSelected: true);
  }

  return lines;
}

String _segmentKey(LatLng a, LatLng b) {
  final ka =
      '${a.latitude.toStringAsFixed(6)},${a.longitude.toStringAsFixed(6)}';
  final kb =
      '${b.latitude.toStringAsFixed(6)},${b.longitude.toStringAsFixed(6)}';
  return ka.compareTo(kb) <= 0 ? '$ka|$kb' : '$kb|$ka';
}

/// Bright traversed portion plus the glow on the active segment.
List<Polyline> buildPacketTrailPolylines(
  PathPlaybackController playback,
  Color color,
) {
  if (!playback.started || !playback.hasPath) return const [];
  final seg = playback.currentSegment;
  final traversed = <LatLng>[
    ...playback.points.take(seg + 1),
    playback.position,
  ];
  return [
    Polyline(
      points: [playback.points[seg], playback.position],
      strokeWidth: 8,
      color: MapPalette.markerOutline.withValues(alpha: 0.45),
    ),
    Polyline(points: traversed, strokeWidth: 5, color: color),
  ];
}

/// The moving packet dot and the pulse ring at the hop it just reached.
List<Marker> buildPacketMarkers(PathPlaybackController playback, Color color) {
  if (!playback.started || !playback.hasPath) return const [];
  final markers = <Marker>[];

  final dwell = playback.dwellProgress;
  if (dwell != null) {
    final reached = playback.points[playback.reachedPointIndex];
    markers.add(
      Marker(
        point: reached,
        width: 56,
        height: 56,
        child: IgnorePointer(
          child: Center(
            child: Container(
              width: 24 + 28 * dwell,
              height: 24 + 28 * dwell,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 1.0 - dwell),
                  width: 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  markers.add(
    Marker(
      point: playback.position,
      width: 24,
      height: 24,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: MapPalette.markerOutline, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.7),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  return markers;
}

/// Bottom sheet listing the paths that pass through a shared node.
void showSharedNodeSheet(
  BuildContext context, {
  required String title,
  required List<DisplayPath> paths,
  required ValueChanged<DisplayPath> onSelect,
}) {
  final l10n = context.l10n;
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
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
              l10n.pathMap_sharedNodeCount(paths.length),
              style: TextStyle(fontSize: 12, color: MeshPalette.ink3),
            ),
          ),
          const SizedBox(height: 8),
          for (final path in paths)
            ListTile(
              dense: true,
              leading: _colorDot(path.color),
              title: Text(
                path.label,
                style: MeshTheme.mono(fontSize: 13, color: MeshPalette.ink),
              ),
              trailing: Text(
                l10n.pathMap_hopCount(path.totalTransmissions),
                style: MeshTheme.mono(fontSize: 12, color: MeshPalette.ink3),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                onSelect(path);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _colorDot(Color color) => Container(
  width: 10,
  height: 10,
  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
);

/// Floating Single/Combined toggle for the top of a path map Stack.
class PathViewModeToggle extends StatelessWidget {
  final PathViewMode mode;
  final ValueChanged<PathViewMode> onChanged;

  const PathViewModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MeshPalette.bg1.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(MeshRadii.pill),
          ),
          child: SegmentedButton<PathViewMode>(
            style: const ButtonStyle(
              visualDensity: VisualDensity(horizontal: -3, vertical: -3),
            ),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: PathViewMode.single,
                label: Text(l10n.pathMap_viewSingle),
              ),
              ButtonSegment(
                value: PathViewMode.combined,
                label: Text(l10n.pathMap_viewCombined),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ),
      ),
    );
  }
}

/// Compact playback control row: animation toggle, step/play/replay buttons,
/// follow-packet lock, speed chip, and the live "Hop x of y · from → to"
/// label.
class PathAnimationControls extends StatelessWidget {
  final PathPlaybackController playback;
  final DisplayPath? selected;
  final bool animationEnabled;
  final VoidCallback onToggleAnimation;
  final bool followEnabled;
  final VoidCallback onToggleFollow;

  const PathAnimationControls({
    super.key,
    required this.playback,
    required this.selected,
    required this.animationEnabled,
    required this.onToggleAnimation,
    required this.followEnabled,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: playback,
      builder: (context, _) {
        final l10n = context.l10n;
        final enabled = animationEnabled && playback.hasPath;
        final path = selected;
        String? hopLabel;
        if (animationEnabled &&
            playback.started &&
            playback.hasPath &&
            path != null) {
          final seg = playback.currentSegment;
          final row = seg < path.rowForSegment.length
              ? path.rowForSegment[seg]
              : 0;
          final from = path.pointLabels[seg];
          final to = path.pointLabels[seg + 1];
          hopLabel =
              '${l10n.pathMap_hopOf(row + 1, path.totalTransmissions)} · $from → $to';
        }

        Widget controlButton({
          required IconData icon,
          required String tooltip,
          VoidCallback? onPressed,
          Color? color,
        }) => IconButton(
          icon: Icon(icon, size: 24, color: color),
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 12, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  controlButton(
                    icon: Icons.animation,
                    tooltip: animationEnabled
                        ? l10n.pathMap_animationOff
                        : l10n.pathMap_animationOn,
                    color: animationEnabled
                        ? MeshPalette.blue
                        : MeshPalette.ink4,
                    onPressed: onToggleAnimation,
                  ),
                  controlButton(
                    icon: Icons.skip_previous,
                    tooltip: l10n.pathMap_stepBack,
                    onPressed: enabled && playback.started
                        ? playback.stepBack
                        : null,
                  ),
                  controlButton(
                    icon: playback.playing ? Icons.pause : Icons.play_arrow,
                    tooltip: playback.playing
                        ? l10n.pathMap_pause
                        : l10n.pathMap_play,
                    onPressed: enabled ? playback.togglePlay : null,
                  ),
                  controlButton(
                    icon: Icons.skip_next,
                    tooltip: l10n.pathMap_stepForward,
                    onPressed: enabled ? playback.stepForward : null,
                  ),
                  controlButton(
                    icon: Icons.replay,
                    tooltip: l10n.pathMap_replay,
                    onPressed: enabled ? playback.replay : null,
                  ),
                  controlButton(
                    icon: followEnabled ? Icons.lock : Icons.lock_open,
                    tooltip: followEnabled
                        ? l10n.pathMap_unfollowPacket
                        : l10n.pathMap_followPacket,
                    color: followEnabled ? MeshPalette.blue : null,
                    onPressed: enabled ? onToggleFollow : null,
                  ),
                  TextButton(
                    onPressed: enabled ? playback.cycleSpeed : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(
                      playback.speed == 0.5
                          ? '0.5×'
                          : '${playback.speed.toInt()}×',
                      style: MeshTheme.mono(fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (hopLabel != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    hopLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MeshTheme.mono(
                      fontSize: 12,
                      color: MeshPalette.ink2,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Marker/line style legend swatches.
class PathMiniLegend extends StatelessWidget {
  final bool combined;
  final bool showInferred;

  const PathMiniLegend({
    super.key,
    required this.combined,
    this.showInferred = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget item(Widget swatch, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: MeshPalette.ink3),
          ),
        ),
      ],
    );
    Widget dashSample() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 5,
            height: 3,
            margin: const EdgeInsets.only(right: 2),
            color: MeshPalette.ink3,
          ),
      ],
    );
    return Wrap(
      spacing: 12,
      runSpacing: 2,
      children: [
        item(_colorDot(MeshPalette.signal), l10n.pathTrace_legendGpsConfirmed),
        if (showInferred)
          item(_colorDot(MeshPalette.warn), l10n.pathTrace_legendInferred),
        if (combined) ...[
          item(
            Container(
              width: 14,
              height: 6,
              decoration: BoxDecoration(
                color: MapPalette.markerOutline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            l10n.pathMap_legendShared,
          ),
          item(dashSample(), l10n.pathMap_legendEstimated),
        ],
      ],
    );
  }
}

/// "Observed paths: N" header plus one selectable row per path with hop
/// count, distance, GPS-confirmed count, last-observed time, and an eye
/// toggle for visibility.
class PathSummaryList extends StatelessWidget {
  final List<DisplayPath> paths;
  final String selectedId;
  final Set<String> hiddenIds;
  final bool isImperial;
  final ValueChanged<DisplayPath> onSelect;
  final ValueChanged<DisplayPath> onToggleVisibility;
  final VoidCallback onShowAll;

  const PathSummaryList({
    super.key,
    required this.paths,
    required this.selectedId,
    required this.hiddenIds,
    required this.isImperial,
    required this.onSelect,
    required this.onToggleVisibility,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
          child: Row(
            children: [
              Text(
                l10n.pathMap_observedPaths(paths.length),
                style: MeshTheme.accentLabel(color: MeshPalette.ink3),
              ),
              const Spacer(),
              if (hiddenIds.isNotEmpty)
                TextButton(
                  onPressed: onShowAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 26),
                  ),
                  child: Text(
                    l10n.pathMap_showAllPaths,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        for (final path in paths) _buildRow(context, path),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildRow(BuildContext context, DisplayPath path) {
    final l10n = context.l10n;
    final isSelected = path.id == selectedId;
    final hidden = hiddenIds.contains(path.id);
    final timestamp = path.record?.timestamp;
    final parts = <String>[
      '${l10n.pathMap_hopCount(path.totalTransmissions)} ${formatDistance(path.distanceMeters, isImperial: isImperial, l10n: l10n)}',
      l10n.pathMap_gpsCount(path.gpsConfirmedHops, path.hopBytes.length),
      if (timestamp != null) formatLastObserved(context, timestamp),
    ];

    return InkWell(
      onTap: () => onSelect(path),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? MeshPalette.bg3 : Colors.transparent,
          borderRadius: BorderRadius.circular(MeshRadii.sm),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: hidden ? 0.45 : 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _colorDot(path.color),
                  const SizedBox(width: 8),
                  Text(
                    path.label,
                    style: MeshTheme.mono(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: MeshPalette.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Opacity(
                opacity: hidden ? 0.45 : 1,
                child: Text(
                  parts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MeshTheme.mono(fontSize: 12, color: MeshPalette.ink3),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                hidden ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: hidden ? MeshPalette.ink4 : MeshPalette.ink3,
              ),
              tooltip: hidden ? l10n.pathMap_showPath : l10n.pathMap_hidePath,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => onToggleVisibility(path),
            ),
          ],
        ),
      ),
    );
  }
}
