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

/// Left edge of the [PathMapDesktopControls] column plus its 48px buttons
/// and a gap; overlays at the top of the map start here on desktop so they
/// don't cover the zoom buttons.
const double kPathMapDesktopControlsInset = 16 + 48 + 8;

/// Horizontal inset for overlays stacked at the top of a path map: clears
/// the desktop zoom controls, otherwise the usual 16px margin.
double pathMapTopOverlayInset([TargetPlatform? platform]) =>
    isDesktopMapPlatform(platform) ? kPathMapDesktopControlsInset : 16;

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
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 16,
      left: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(MeshRadii.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MeshRadii.md),
          child: IconTheme(
            data: IconThemeData(color: scheme.onSurface),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  color: scheme.onSurface,
                  tooltip: l10n.map_zoomIn,
                  onPressed: onZoomIn,
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  color: scheme.onSurface,
                  tooltip: l10n.map_zoomOut,
                  onPressed: onZoomOut,
                ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  color: scheme.onSurface,
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

/// Collapsible bottom panel shared by the path map screens: header
/// with distance and legend, playback controls, warnings, optional
/// multi-path summary, and the hop list.
///
/// Uses the theme's card surface and sets text/icon/divider colours from the
/// [ColorScheme] so the panel matches light, dark and custom themes.
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

  /// Grows the panel to the full map height so the hop list is readable when
  /// the map is of little use (e.g. repeaters without locations).
  final bool expanded;
  final VoidCallback? onToggleExpanded;

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
    this.expanded = false,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final maxHeight =
        MediaQuery.of(context).size.height * (combined ? 0.45 : 0.35);
    const hopRowHeight = 60.0;
    final isExpanded = expanded && !collapsed && onToggleExpanded != null;

    double? cardHeight;
    if (!collapsed && !isExpanded) {
      final summaryHeight = combined ? 34.0 + pathCount * 40.0 : 0.0;
      final noteHeight = showNoSelfGpsNote ? 22.0 : 0.0;
      final estimatedHeight =
          150.0 + summaryHeight + noteHeight + hopRowCount * hopRowHeight;
      cardHeight = max(196.0, min(maxHeight, estimatedHeight));
    }

    final warnStyle = TextStyle(fontSize: 12, color: scheme.tertiary);
    final unresolved = selected?.unresolvedHops ?? 0;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      top: isExpanded ? 16 : null,
      child: SizedBox(
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(MeshRadii.md),
            border: Border.all(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: scheme.onSurface),
            child: IconTheme(
              data: IconThemeData(color: scheme.onSurface),
              child: DividerTheme(
                data: DividerThemeData(color: scheme.outlineVariant),
                child: ListTileTheme(
                  data: ListTileThemeData(
                    iconColor: scheme.onSurfaceVariant,
                    textColor: scheme.onSurface,
                  ),
                  child: TextButtonTheme(
                    data: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: isExpanded
                                  ? constraints.maxHeight * 0.4
                                  : max(
                                      0.0,
                                      constraints.maxHeight -
                                          (collapsed
                                              ? 0.0
                                              : hopRowHeight + 1.0),
                                    ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onVerticalDragEnd: (details) =>
                                        _handleHeaderDrag(
                                          details.primaryVelocity ?? 0,
                                          isExpanded,
                                        ),
                                    child: Padding(
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
                                          if (onToggleExpanded != null &&
                                              !collapsed)
                                            IconButton(
                                              icon: Icon(
                                                isExpanded
                                                    ? Icons.close_fullscreen
                                                    : Icons.open_in_full,
                                              ),
                                              color: scheme.onSurface,
                                              tooltip: isExpanded
                                                  ? l10n.pathMap_showMap
                                                  : l10n.pathMap_expandHopList,
                                              onPressed: onToggleExpanded,
                                            ),
                                          IconButton(
                                            icon: Icon(
                                              collapsed
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                            ),
                                            color: scheme.onSurface,
                                            tooltip: collapsed
                                                ? l10n.pathMap_expandPanel
                                                : l10n.pathMap_collapsePanel,
                                            onPressed: onToggleCollapsed,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // The map is covered while expanded, so
                                  // the animation controls are pointless.
                                  if (!isExpanded)
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
                                            Icon(
                                              Icons.gps_off,
                                              size: 16,
                                              color: scheme.tertiary,
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

  /// Swipe up on the header grows the panel (collapsed -> normal ->
  /// expanded); swipe down shrinks it the other way.
  void _handleHeaderDrag(double velocity, bool isExpanded) {
    const minVelocity = 150.0;
    if (velocity < -minVelocity) {
      if (collapsed) {
        onToggleCollapsed();
      } else if (!isExpanded) {
        onToggleExpanded?.call();
      }
    } else if (velocity > minVelocity) {
      if (isExpanded) {
        onToggleExpanded?.call();
      } else if (!collapsed) {
        onToggleCollapsed();
      }
    }
  }
}
