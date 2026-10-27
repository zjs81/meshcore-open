import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/network_map/network_map_api_client.dart';
import '../theme/mesh_theme.dart';
import 'mesh_ui.dart';

enum NetworkMapLoadState { idle, loading, ready, zoomIn, error }

/// Fetches the online network map for the visible area.
///
/// Requests are debounced while the map moves; a response that arrives after
/// a newer request started is dropped.
class NetworkMapOnlineController extends ChangeNotifier {
  static const Duration _debounce = Duration(milliseconds: 600);

  final NetworkMapApiClient _client;
  final LayerHitNotifier<NetworkMapRepeater> hitNotifier = ValueNotifier(null);

  List<NetworkMapRepeater> _repeaters = const [];
  List<NetworkMapLink> _links = const [];
  NetworkMapLoadState _state = NetworkMapLoadState.idle;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;

  NetworkMapOnlineController({NetworkMapApiClient? client})
    : _client = client ?? NetworkMapApiClient();

  List<NetworkMapRepeater> get repeaters => _repeaters;
  List<NetworkMapLink> get links => _links;
  NetworkMapLoadState get state => _state;

  void requestBounds(LatLngBounds bounds) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => _load(bounds));
  }

  /// Drops any pending or in-flight request (the online layer was hidden).
  void cancel() {
    _timer?.cancel();
    _generation++;
  }

  Future<void> _load(LatLngBounds bounds) async {
    final boxes = NetworkMapBbox.forVisibleArea(
      west: bounds.west,
      south: bounds.south,
      east: bounds.east,
      north: bounds.north,
    );
    final generation = ++_generation;
    if (boxes == null) {
      _setState(NetworkMapLoadState.zoomIn);
      return;
    }
    _setState(NetworkMapLoadState.loading);
    try {
      final results = await Future.wait([
        Future.wait(boxes.map(_client.fetchRepeaters)),
        Future.wait(boxes.map((b) => _client.fetchLinks(b))),
      ]);
      if (_disposed || generation != _generation) return;
      // Two boxes (antimeridian) can both return items on the seam.
      _repeaters = {
        for (final r in results[0].expand((l) => l as List<NetworkMapRepeater>))
          r.key: r,
      }.values.toList();
      _links = {
        for (final l in results[1].expand((l) => l as List<NetworkMapLink>))
          '${l.a}:${l.b}': l,
      }.values.toList();
      _setState(NetworkMapLoadState.ready);
    } catch (_) {
      if (_disposed || generation != _generation) return;
      _setState(NetworkMapLoadState.error);
    }
  }

  void _setState(NetworkMapLoadState value) {
    _state = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    hitNotifier.dispose();
    _client.close();
    super.dispose();
  }
}

Color networkMapStatusColor(NetworkMapRepeaterStatus status) {
  return switch (status) {
    NetworkMapRepeaterStatus.active => MapPalette.online,
    NetworkMapRepeaterStatus.recent => MapPalette.stale,
    NetworkMapRepeaterStatus.stale => MapPalette.offline,
  };
}



/// Above this many in-view repeaters, hexagons and marker shadows are skipped.
const int networkMapDenseNodeCount = 30;

/// Above this many in-view links, each line is one stroke at half width
const int networkMapDenseLinkCount = 70;


/// Full style is a 3.5 px confirmed stroke or a 2.5 px unconfirmed stroke,
/// each with a 1 px border. Simple style keeps the pattern and drops the
/// border, so the painter records the line once, at half the stroke width.
Polyline _onlineLinkPolyline(NetworkMapLink link, {required bool simple}) {
  final confirmed = link.confirmed;
  final strokeWidth = confirmed ? 3.5 : 2.5;
  return Polyline(
    points: [link.aCell.center, link.bCell.center],
    strokeWidth: simple ? strokeWidth / 2 : strokeWidth,
    color: MapPalette.router.withValues(alpha: confirmed ? 0.85 : 0.6),
    borderStrokeWidth: simple ? 0 : 1,
    borderColor: MapPalette.markerOutline.withValues(alpha: 0.7),
    pattern: confirmed
        ? const StrokePattern.solid()
        : StrokePattern.dashed(segments: const [10, 8]),
  );
}



/// Map layers for the online network: links, repeater hexagons and a
/// tappable center marker so small cells stay visible when zoomed out.
///
/// Keys in [localMarkerKeys] are already drawn by the local layer, so only
/// their hexagon outline is added.
List<Widget> buildNetworkMapOnlineLayers({
  required NetworkMapOnlineController controller,
  required Set<String> localMarkerKeys,
  required ValueChanged<NetworkMapRepeater> onTap,
}) {
  final repeaters = controller.repeaters;
  final links = controller.links;
  final dropHexagons = repeaters.length > networkMapDenseNodeCount;
  final simpleLines = links.length > networkMapDenseLinkCount;
  return [
    PolylineLayer(
      polylines: [
        for (final link in links)
          _onlineLinkPolyline(link, simple: simpleLines),
      ],
    ),
    if (!dropHexagons)
      GestureDetector(
        onTap: () {
          final hits = controller.hitNotifier.value?.hitValues;
          if (hits != null && hits.isNotEmpty) onTap(hits.first);
        },
        child: PolygonLayer<NetworkMapRepeater>(
          hitNotifier: controller.hitNotifier,
          polygons: [
            for (final repeater in repeaters)
              if (repeater.cell.boundary.length >= 3)
                Polygon<NetworkMapRepeater>(
                  points: repeater.cell.boundary,
                  hitValue: repeater,
                  color: localMarkerKeys.contains(repeater.key)
                      ? null
                      : networkMapStatusColor(
                          repeater.status,
                        ).withValues(alpha: 0.22),
                  borderColor: networkMapStatusColor(repeater.status),
                  borderStrokeWidth: 2.5,
                  pattern: repeater.confirmed
                      ? const StrokePattern.solid()
                      : StrokePattern.dashed(segments: const [8, 6]),
                ),
          ],
        ),
      ),
    MarkerLayer(
      markers: [
        for (final repeater in repeaters)
          if (!localMarkerKeys.contains(repeater.key))
            Marker(
              point: repeater.cell.center,
              width: 34,
              height: 34,
              child: GestureDetector(
                onTap: () => onTap(repeater),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: networkMapStatusColor(repeater.status),
                    border: Border.all(
                      color: MapPalette.markerOutline,
                      width: 2.5,
                    ),
                    boxShadow: dropHexagons
                        ? null
                        : const [
                            BoxShadow(
                              color: MapPalette.markerShadow,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    repeater.type == advTypeRoom
                        ? Icons.meeting_room
                        : Icons.router,
                    color: MapPalette.markerOutline,
                    size: 20,
                  ),
                ),
              ),
            ),
      ],
    ),
  ];
}

enum NetworkMapReach { heard, nearby, far }

/// Distance under which a repeater counts as "in your area".
const double networkMapNearbyKm = 50;

NetworkMapReach networkMapReachFor({
  required bool heardByRadio,
  required LatLng? self,
  required LatLng cell,
}) {
  if (heardByRadio) return NetworkMapReach.heard;
  if (self != null &&
      const Distance().as(LengthUnit.Kilometer, self, cell) <=
          networkMapNearbyKm) {
    return NetworkMapReach.nearby;
  }
  return NetworkMapReach.far;
}

/// Details for a repeater from the online map, with "Add to contacts" and
/// "Manage". [onManage] runs the regular login → repeater hub flow.
Future<void> showNetworkMapRepeaterSheet(
  BuildContext context, {
  required MeshCoreConnector connector,
  required NetworkMapRepeater repeater,
  required void Function(Contact contact) onManage,
}) {
  return showMeshSheet<void>(
    context,
    builder: (sheetContext) => _NetworkMapRepeaterSheet(
      connector: connector,
      repeater: repeater,
      onManage: (contact) {
        Navigator.pop(sheetContext);
        onManage(contact);
      },
    ),
  );
}

class _NetworkMapRepeaterSheet extends StatefulWidget {
  final MeshCoreConnector connector;
  final NetworkMapRepeater repeater;
  final void Function(Contact contact) onManage;

  const _NetworkMapRepeaterSheet({
    required this.connector,
    required this.repeater,
    required this.onManage,
  });

  @override
  State<_NetworkMapRepeaterSheet> createState() =>
      _NetworkMapRepeaterSheetState();
}

class _NetworkMapRepeaterSheetState extends State<_NetworkMapRepeaterSheet> {
  static const Duration _recentlyHeard = Duration(hours: 24);
  bool _busy = false;

  NetworkMapRepeater get _repeater => widget.repeater;

  Contact? get _savedContact =>
      widget.connector.getContactByPubKeyHex(_repeater.key);

  bool get _heardByRadio {
    if (_savedContact != null) return true;
    final cutoff = DateTime.now().subtract(_recentlyHeard);
    return widget.connector.discoveredContacts.any(
      (c) => c.publicKeyHex == _repeater.key && c.lastSeen.isAfter(cutoff),
    );
  }

  /// The saved contact, adding it first if needed. Null (with a message) when
  /// it cannot be added.
  Future<Contact?> _ensureContact() async {
    final existing = _savedContact;
    if (existing != null) return existing;
    final connector = widget.connector;
    final l10n = context.l10n;
    if (!connector.isConnected) {
      _snack(l10n.settings_notConnectedError);
      return null;
    }
    if (connector.contactsStorageFull ||
        connector.contacts.length >= connector.maxContacts) {
      _snack(l10n.contacts_storageFull);
      return null;
    }
    // Flood route, no location (the cell is only an approximation) and an
    // unknown advert time so the firmware's replay guard accepts the next
    // real advert.
    final contact = Contact(
      publicKey: hexToPubKey(_repeater.key),
      name: _repeater.name ?? _repeater.key.substring(0, 8),
      type: _repeater.type,
      pathLength: -1,
      path: Uint8List(0),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    setState(() => _busy = true);
    final ok = await connector.importDiscoveredContact(contact);
    if (!mounted) return null;
    setState(() => _busy = false);
    if (!ok) {
      _snack(l10n.networkMap_addFailed);
      return null;
    }
    return _savedContact ?? contact;
  }

  void _snack(String message) {
    showDismissibleSnackBar(context, content: Text(message));
  }

  Future<void> _add() async {
    final contact = await _ensureContact();
    if (contact != null && mounted) {
      _snack(context.l10n.networkMap_addedToContacts);
    }
  }

  Future<void> _manage() async {
    final contact = await _ensureContact();
    if (contact != null && mounted) widget.onManage(contact);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final repeater = _repeater;
    final inContacts = _savedContact != null;
    final statusColor = networkMapStatusColor(repeater.status);
    final selfLat = widget.connector.selfLatitude;
    final selfLon = widget.connector.selfLongitude;
    final reach = networkMapReachFor(
      heardByRadio: _heardByRadio,
      self: selfLat != null && selfLon != null && (selfLat != 0 || selfLon != 0)
          ? LatLng(selfLat, selfLon)
          : null,
      cell: repeater.cell.center,
    );
    final (reachLabel, reachColor, reachIcon) = switch (reach) {
      NetworkMapReach.heard => (
        l10n.networkMap_heardByRadio,
        MapPalette.online,
        Icons.hearing,
      ),
      NetworkMapReach.nearby => (
        l10n.networkMap_inYourArea,
        MapPalette.selected,
        Icons.near_me,
      ),
      NetworkMapReach.far => (
        l10n.networkMap_farAway,
        MapPalette.stale,
        Icons.warning_amber_rounded,
      ),
    };
    final statusLabel = switch (repeater.status) {
      NetworkMapRepeaterStatus.active => l10n.networkMap_statusActive,
      NetworkMapRepeaterStatus.recent => l10n.networkMap_statusRecent,
      NetworkMapRepeaterStatus.stale => l10n.networkMap_statusStale,
    };
    final lastSeen = repeater.lastSeen;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BottomSheetHeader(
              title: repeater.name ?? l10n.networkMap_unnamed,
              subtitle: repeater.type == advTypeRoom
                  ? l10n.contact_typeRoom
                  : l10n.contact_typeRepeater,
              trailing: Icon(
                repeater.type == advTypeRoom
                    ? Icons.meeting_room
                    : Icons.router,
                color: statusColor,
                size: 26,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: reachLabel,
                        color: reachColor,
                        icon: reachIcon,
                        fontSize: 15,
                      ),
                      if (inContacts)
                        StatusChip(
                          label: l10n.networkMap_inYourContacts,
                          color: MapPalette.repeater,
                          icon: Icons.check_circle,
                          fontSize: 15,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  row(l10n.networkMap_status, statusLabel),
                  row(
                    l10n.networkMap_reports,
                    repeater.confirmed
                        ? l10n.networkMap_confirmed
                        : l10n.networkMap_singleSource,
                  ),
                  if (lastSeen != null)
                    row(
                      l10n.map_lastSeen,
                      networkMapTimeAgo(context, lastSeen),
                    ),
                  row(
                    l10n.map_location,
                    repeater.isEstimated
                        ? l10n.networkMap_locationEstimated
                        : l10n.networkMap_locationAdvertised,
                  ),
                  const SizedBox(height: 16),
                  if (!inContacts) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _busy ? null : _add,
                        icon: const Icon(Icons.person_add_alt_1, size: 22),
                        label: Text(l10n.networkMap_addToContacts),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _manage,
                      icon: const Icon(Icons.admin_panel_settings, size: 22),
                      label: Text(l10n.networkMap_manage),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Just now", "5m ago", "3h ago", "2d ago".
String networkMapTimeAgo(BuildContext context, DateTime time) {
  final l10n = context.l10n;
  final difference = DateTime.now().difference(time);
  if (difference.inSeconds < 60) return l10n.time_justNow;
  if (difference.inMinutes < 60) {
    return l10n.time_minutesAgo(difference.inMinutes);
  }
  if (difference.inHours < 24) return l10n.time_hoursAgo(difference.inHours);
  return l10n.time_daysAgo(difference.inDays);
}
