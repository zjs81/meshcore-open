import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/guessed_location_estimator.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/display_path.dart';
import '../models/path_playback.dart';
import '../theme/mesh_theme.dart';
import 'path_map_ui.dart';

/// Shared map plumbing for the path map screens (live path trace and
/// received-message path map): camera helpers, map options, desktop zoom
/// controls, node labels, and the collapsible bottom panel shell.

const double kPathMapMinZoom = 2.0;
const double kPathMapMaxZoom = 18.0;
const double kPathMapLabelZoomThreshold = 8.5;
const EdgeInsets _fitPadding = EdgeInsets.all(64);

bool isDesktopMapPlatform([TargetPlatform? platform]) {
  final p = platform ?? defaultTargetPlatform;
  return p == TargetPlatform.linux ||
      p == TargetPlatform.windows ||
      p == TargetPlatform.macOS;
}

/// The connected radio's position, or null when it is unknown (disconnected)
/// or not a real fix (SELF_INFO reports 0,0 without GPS).
LatLng? plausibleSelfPoint(MeshCoreConnector connector) {
  final lat = connector.selfLatitude;
  final lon = connector.selfLongitude;
  if (lat == null || lon == null || !isPlausibleLocation(lat, lon)) {
    return null;
  }
  return LatLng(lat, lon);
}

/// Cheap fingerprint of the fields path resolution depends on, used to skip
/// re-resolving hops when the connector notifies for unrelated reasons.
int contactListSignature(List<Contact> contacts) {
  return Object.hash(
    contacts.length,
    Object.hashAll(
      contacts.map(
        (c) => Object.hash(
          Object.hashAll(c.publicKey.take(8)),
          c.type,
          c.name,
          c.latitude,
          c.longitude,
          c.lastSeen,
          c.path.length,
        ),
      ),
    ),
  );
}

bool sameLatLngList(List<LatLng> a, List<LatLng> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Updates the playback path only when its geometry actually changed, so
/// unrelated rebuilds don't reset a running animation.
void syncPlaybackPath(PathPlaybackController playback, List<LatLng> points) {
  if (sameLatLngList(points, playback.points)) return;
  playback.setPath(points);
}

/// Keeps the camera centered on the packet while the follow lock is on.
void followPacketCamera(
  MapController controller,
  PathPlaybackController playback, {
  required bool enabled,
}) {
  if (!enabled || !playback.started || !playback.hasPath) return;
  controller.move(playback.position, controller.camera.zoom);
}

void zoomMapBy(
  MapController controller,
  double delta, {
  double minZoom = kPathMapMinZoom,
  double maxZoom = kPathMapMaxZoom,
}) {
  final camera = controller.camera;
  final nextZoom = (camera.zoom + delta).clamp(minZoom, maxZoom).toDouble();
  controller.move(camera.center, nextZoom);
}

void resetMapView(
  MapController controller, {
  required LatLngBounds? bounds,
  required LatLng? center,
  required double zoom,
}) {
  if (bounds != null) {
    controller.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: _fitPadding, maxZoom: 16),
    );
    return;
  }
  if (center != null) controller.move(center, zoom);
}

/// Map options shared by the path and line-of-sight maps: no rotation,
/// desktop keyboard panning/zooming, and an initial fit to [bounds].
MapOptions buildPathMapOptions({
  required LatLng initialCenter,
  required double initialZoom,
  required LatLngBounds? bounds,
  double minZoom = kPathMapMinZoom,
  double maxZoom = kPathMapMaxZoom,
  PositionCallback? onPositionChanged,
  TapCallback? onLongPress,
  TapCallback? onSecondaryTap,
}) {
  final isDesktop = isDesktopMapPlatform();
  return MapOptions(
    initialCenter: initialCenter,
    initialZoom: initialZoom,
    initialCameraFit: bounds == null
        ? null
        : CameraFit.bounds(bounds: bounds, padding: _fitPadding, maxZoom: 16),
    minZoom: minZoom,
    maxZoom: maxZoom,
    interactionOptions: InteractionOptions(
      flags: ~InteractiveFlag.rotate,
      scrollWheelVelocity: isDesktop ? 0.012 : 0.005,
      cursorKeyboardRotationOptions: CursorKeyboardRotationOptions.disabled(),
      keyboardOptions: isDesktop
          ? const KeyboardOptions(
              enableArrowKeysPanning: true,
              enableWASDPanning: true,
              enableRFZooming: true,
            )
          : const KeyboardOptions.disabled(),
    ),
    onPositionChanged: onPositionChanged,
    onLongPress: onLongPress,
    onSecondaryTap: onSecondaryTap,
  );
}

/// Floating zoom in/out/recenter buttons for desktop platforms.
class PathMapDesktopControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const PathMapDesktopControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          child: IconTheme(
            data: const IconThemeData(color: MeshPalette.ink),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  color: MeshPalette.ink,
                  tooltip: l10n.map_zoomIn,
                  onPressed: onZoomIn,
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  color: MeshPalette.ink,
                  tooltip: l10n.map_zoomOut,
                  onPressed: onZoomOut,
                ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  color: MeshPalette.ink,
                  tooltip: l10n.map_centerMap,
                  onPressed: onReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Name label floating above a node marker.
Marker buildPathNodeLabelMarker({
  required LatLng point,
  required String label,
}) {
  return Marker(
    point: point,
    width: 140,
    height: 26,
    alignment: Alignment.topCenter,
    child: IgnorePointer(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: MeshPalette.bg.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(MeshRadii.xs),
              border: Border.all(color: MeshPalette.line, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MeshTheme.mono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MeshPalette.ink,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Small count badge drawn on markers for repeaters shared by several paths.
class PathSharedCountBadge extends StatelessWidget {
  final int count;

  const PathSharedCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MeshPalette.bg1,
        border: Border.all(color: MeshPalette.line3),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: MeshTheme.mono(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: MeshPalette.ink,
        ),
      ),
    );
  }
}

/// Dark, collapsible bottom panel shared by the path map screens: header
/// with distance and legend, playback controls, warnings, optional
/// multi-path summary, and the hop list.
///
/// Sets dark-panel text/icon/divider colours explicitly so content does not
/// inherit light-theme colours.
class PathMapBottomPanel extends StatelessWidget {
  final Widget header;
  final bool combined;
  final bool showInferredLegend;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final PathPlaybackController playback;
  final DisplayPath? selected;
  final bool animationEnabled;
  final VoidCallback onToggleAnimation;
  final bool followEnabled;
  final VoidCallback onToggleFollow;
  final bool showNoSelfGpsNote;
  final int pathCount;
  final int hopRowCount;
  final Widget? summary;
  final Widget hopList;

  const PathMapBottomPanel({
    super.key,
    required this.header,
    required this.combined,
    required this.showInferredLegend,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.playback,
    required this.selected,
    required this.animationEnabled,
    required this.onToggleAnimation,
    required this.followEnabled,
    required this.onToggleFollow,
    required this.showNoSelfGpsNote,
    required this.pathCount,
    required this.hopRowCount,
    required this.summary,
    required this.hopList,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxHeight =
        MediaQuery.of(context).size.height * (combined ? 0.45 : 0.35);
    const hopRowHeight = 60.0;

    double? cardHeight;
    if (!collapsed) {
      final summaryHeight = combined ? 34.0 + pathCount * 40.0 : 0.0;
      final noteHeight = showNoSelfGpsNote ? 22.0 : 0.0;
      final estimatedHeight =
          150.0 + summaryHeight + noteHeight + hopRowCount * hopRowHeight;
      cardHeight = max(196.0, min(maxHeight, estimatedHeight));
    }

    final warnStyle = const TextStyle(fontSize: 12, color: MeshPalette.warn);
    final unresolved = selected?.unresolvedHops ?? 0;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SizedBox(
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            color: MeshPalette.bg1.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(MeshRadii.md),
            border: Border.all(color: MeshPalette.line2),
          ),
          clipBehavior: Clip.antiAlias,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: MeshPalette.ink),
            child: IconTheme(
              data: const IconThemeData(color: MeshPalette.ink),
              child: DividerTheme(
                data: const DividerThemeData(color: MeshPalette.line),
                child: ListTileTheme(
                  data: const ListTileThemeData(
                    iconColor: MeshPalette.ink2,
                    textColor: MeshPalette.ink,
                  ),
                  child: TextButtonTheme(
                    data: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: MeshPalette.ink,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: max(
                                0.0,
                                constraints.maxHeight -
                                    (collapsed ? 0.0 : hopRowHeight + 1.0),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      4,
                                      0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              header,
                                              const SizedBox(height: 4),
                                              PathMiniLegend(
                                                combined: combined,
                                                showInferred:
                                                    showInferredLegend,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            collapsed
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                          ),
                                          color: MeshPalette.ink,
                                          tooltip: collapsed
                                              ? l10n.pathMap_expandPanel
                                              : l10n.pathMap_collapsePanel,
                                          onPressed: onToggleCollapsed,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PathAnimationControls(
                                    playback: playback,
                                    selected: selected,
                                    animationEnabled: animationEnabled,
                                    onToggleAnimation: onToggleAnimation,
                                    followEnabled: followEnabled,
                                    onToggleFollow: onToggleFollow,
                                  ),
                                  if (!collapsed) ...[
                                    if (showNoSelfGpsNote)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          4,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.gps_off,
                                              size: 16,
                                              color: MeshPalette.warn,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                l10n.pathMap_noSelfGpsFix,
                                                style: warnStyle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (unresolved > 0)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          4,
                                        ),
                                        child: Text(
                                          l10n.pathMap_partialAnimation(
                                            unresolved,
                                          ),
                                          style: warnStyle,
                                        ),
                                      ),
                                    ?summary,
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (!collapsed) ...[
                            const Divider(height: 1),
                            Expanded(child: hopList),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
