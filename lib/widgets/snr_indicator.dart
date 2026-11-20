import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/path_helper.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../theme/mesh_theme.dart';
import 'map_location_picker.dart' show fetchPhonePosition;
import 'mesh_ui.dart';
import 'node_info_sheet.dart';
import 'signal_ui.dart';
import '../theme/theme_icons.dart';

bool _isValidSelfLocation(double lat, double lon) {
  const double epsilon = 1e-6;
  return (lat.abs() > epsilon || lon.abs() > epsilon) &&
      lat >= -90.0 &&
      lat <= 90.0 &&
      lon >= -180.0 &&
      lon <= 180.0;
}

Contact? _getRepeaterPrefixMatchNearLocation(
  List<Contact> contacts,
  List<int> pubkeyPrefix, {
  String? contactKeyHex,
  LatLng? searchPoint,
  bool preferFavorites = false,
}) {
  if (contactKeyHex != null) {
    for (final c in contacts) {
      if (c.publicKeyHex == contactKeyHex) {
        return c;
      }
    }
  }

  final candidates = contacts
      .where(
        (c) =>
            c.publicKey.length >= pubkeyPrefix.length &&
            listEquals(
              c.publicKey.sublist(0, pubkeyPrefix.length),
              pubkeyPrefix,
            ) &&
            (c.type == advTypeRepeater || c.type == advTypeRoom),
      )
      .toList();

  if (candidates.isEmpty) return null;

  candidates.sort((a, b) {
    if (preferFavorites) {
      final favA = a.isFavorite ? 1 : 0;
      final favB = b.isFavorite ? 1 : 0;
      final favCompare = favB.compareTo(favA);
      if (favCompare != 0) return favCompare;
    }

    final seenCompare = b.lastSeen.compareTo(a.lastSeen);
    if (seenCompare != 0) return seenCompare;

    return a.publicKeyHex.compareTo(b.publicKeyHex);
  });

  if (searchPoint == null) {
    return candidates.first;
  }

  final distance = Distance();
  Contact best = candidates.first;
  var bestDistance = double.infinity;

  for (final c in candidates) {
    if (c.hasLocation && c.latitude != null && c.longitude != null) {
      final d = distance(searchPoint, LatLng(c.latitude!, c.longitude!));
      if (d < bestDistance) {
        bestDistance = d;
        best = c;
      }
    }
  }

  return best;
}

class SNRUi {
  final IconData icon;
  final Color color;
  final String text;
  const SNRUi(this.icon, this.color, this.text);
}

List<double> getSNRfromSF(int spreadingFactor) {
  switch (spreadingFactor) {
    case 7:
      return [4.0, -2.0, -4.0, -6.0];
    case 8:
      return [4.0, -4.0, -6.0, -8.0];
    case 9:
      return [4.0, -6.0, -8.0, -10.0];
    case 10:
      return [4.0, -8.0, -10.0, -13.0];
    case 11:
      return [4.0, -10.0, -12.5, -15.0];
    case 12:
      return [4.0, -12.5, -15.0, -18.0];
    default:
      return []; // Or throw Exception('Invalid SF: $spreadingFactor');
  }
}

SNRUi snrUiFromSNR(double? snr, int? spreadingFactor) {
  if (snr == null ||
      spreadingFactor == null ||
      spreadingFactor < 7 ||
      spreadingFactor > 12) {
    return const SNRUi(Icons.signal_cellular_off, Colors.grey, '—');
  }

  final snrLevels = getSNRfromSF(spreadingFactor);

  String text = '${snr.toStringAsFixed(1)} dB';
  final tier = snr >= snrLevels[0]
      ? 0
      : snr >= snrLevels[1]
      ? 1
      : snr >= snrLevels[2]
      ? 2
      : snr >= snrLevels[3]
      ? 3
      : 4;
  final signalUi = signalUiForStrengthTier(tier);

  return SNRUi(
    signalUi.icon,
    MeshTheme.gradientAt(MeshTheme.snrGradientPosition(snr)),
    text,
  );
}

class SNRIndicator extends StatefulWidget {
  final MeshCoreConnector connector;

  const SNRIndicator({super.key, required this.connector});

  @override
  State<SNRIndicator> createState() => _SNRIndicatorState();
}

class _SNRIndicatorState extends State<SNRIndicator> {
  @override
  Widget build(BuildContext context) {
    final directRepeaters = widget.connector.directRepeaters;
    final directBestRepeaters = List.of(directRepeaters)
      ..sort((a, b) => (b.ranking).compareTo(a.ranking));
    final directRepeater = directBestRepeaters.isEmpty
        ? null
        : directBestRepeaters.first;

    final snrUi = snrUiFromSNR(
      directBestRepeaters.isNotEmpty ? directRepeater!.snr : null,
      widget.connector.currentSf,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      child: InkWell(
        onTap: directRepeater != null
            ? () => _showFullPathDialog(context)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(snrUi.icon, size: 18, color: snrUi.color),
              Text(
                snrUi.text,
                style: TextStyle(fontSize: 12, color: snrUi.color),
              ),
              if (directRepeater != null)
                Text(
                  '${directRepeaters.length}: ${directRepeater.pubkeyPrefixHex}: ${_formatLastUpdated(directRepeater.lastUpdated)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullPathDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          _NearbyRepeatersDialog(connector: widget.connector),
    );
  }
}

String _formatLastUpdated(DateTime lastSeen) {
  final now = DateTime.now();
  final diff = now.difference(lastSeen);
  if (diff.isNegative) {
    return "0s";
  }
  if (diff.inMinutes < 1) {
    return "${diff.inSeconds}s";
  }
  if (diff.inMinutes < 60) {
    return "${diff.inMinutes}m";
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return "${hours}h";
  }
  final days = diff.inDays;
  return "${days}d";
}

String _formatDistance(double meters, AppLocalizations l10n, bool isImperial) {
  if (isImperial) {
    final miles = meters / 1609.344;
    return '${miles.toStringAsFixed(2)} ${l10n.units_mi}';
  }
  if (meters < 1000) {
    return '${meters.toStringAsFixed(0)} ${l10n.units_m}';
  }
  return '${(meters / 1000).toStringAsFixed(2)} ${l10n.units_km}';
}

String? _formatDistanceToRepeater(
  LatLng? referencePoint,
  Contact? contact,
  AppLocalizations l10n,
  bool isImperial,
) {
  if (referencePoint == null ||
      contact == null ||
      !contact.hasLocation ||
      contact.latitude == null ||
      contact.longitude == null) {
    return null;
  }
  final meters = Distance()(
    referencePoint,
    LatLng(contact.latitude!, contact.longitude!),
  );
  return _formatDistance(meters, l10n, isImperial);
}

void _showUnknownRepeaterSheet(
  BuildContext context,
  DirectRepeater repeater,
  String prefixLabel,
) {
  showMeshSheet<void>(
    context,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BottomSheetHeader(
                title: prefixLabel,
                subtitle: l10n.snrIndicator_unknownRepeater,
                trailing: ThemedIcon(
                  ThemeIconSlot.mapRepeater,
                  color: mapNodeTypeColor(advTypeRepeater),
                  size: 20,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NodeInfoRow(
                      label: l10n.map_publicKeyPrefix,
                      value: repeater.pubkeyPrefixHex,
                    ),
                    NodeInfoRow(
                      label: l10n.repeater_lastSnr,
                      value: '${repeater.snr.toStringAsFixed(1)} dB',
                    ),
                    NodeInfoRow(
                      label: l10n.snrIndicator_packets,
                      value: l10n.snrIndicator_packetCount(
                        repeater.packetCount,
                      ),
                    ),
                    NodeInfoRow(
                      label: l10n.map_lastSeen,
                      value: formatNodeLastSeen(l10n, repeater.lastUpdated),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.snrIndicator_unknownRepeaterHint,
                      style: TextStyle(
                        fontSize: 15,
                        color: scheme.onSurfaceVariant,
                      ),
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
}

class _NearbyRepeatersDialog extends StatefulWidget {
  final MeshCoreConnector connector;

  const _NearbyRepeatersDialog({required this.connector});

  @override
  State<_NearbyRepeatersDialog> createState() => _NearbyRepeatersDialogState();
}

class _NearbyRepeatersDialogState extends State<_NearbyRepeatersDialog> {
  LatLng? _phonePosition;
  Timer? _minuteTicker;

  @override
  void initState() {
    super.initState();
    widget.connector.addListener(_onConnectorChanged);
    _minuteTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    unawaited(
      fetchPhonePosition().then((position) {
        if (!mounted) return;
        setState(() {
          _phonePosition = position;
        });
      }),
    );
  }

  void _onConnectorChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _minuteTicker?.cancel();
    widget.connector.removeListener(_onConnectorChanged);
    super.dispose();
  }

  /// Phone position when available, otherwise the companion radio location.
  LatLng? _referencePoint() {
    final phone = _phonePosition;
    if (phone != null) return phone;
    final lat = widget.connector.selfLatitude;
    final lon = widget.connector.selfLongitude;
    if (lat != null && lon != null && _isValidSelfLocation(lat, lon)) {
      return LatLng(lat, lon);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isImperial =
        context.watch<AppSettingsService>().settings.unitSystem ==
        UnitSystem.imperial;
    final repeaters = List.of(widget.connector.directRepeaters)
      ..sort((a, b) => b.ranking.compareTo(a.ranking));
    final referencePoint = _referencePoint();

    return AlertDialog(
      title: Text(l10n.snrIndicator_nearByRepeaters),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.snrIndicator_nearByRepeatersDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Scrollbar(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: repeaters.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final repeater = repeaters[index];
                    final contact = _getRepeaterPrefixMatchNearLocation(
                      widget.connector.allContacts,
                      repeater.pubkeyPrefix,
                      contactKeyHex: repeater.contactKeyHex,
                      searchPoint: referencePoint,
                      preferFavorites: true,
                    );

                    final name = contact?.name;
                    final prefixLabel = PathHelper.formatHopHex(
                      repeater.pubkeyPrefix,
                    );
                    final snrColor = MeshTheme.snrColor(
                      repeater.snr,
                      blocked: false,
                    );
                    final colorScheme = Theme.of(context).colorScheme;
                    final distanceLabel = _formatDistanceToRepeater(
                      referencePoint,
                      contact,
                      l10n,
                      isImperial,
                    );

                    return Semantics(
                      button: true,
                      hint: l10n.map_details,
                      child: InkWell(
                        onTap: () => contact != null
                            ? showNodeInfoSheet(context, contact)
                            : _showUnknownRepeaterSheet(
                                context,
                                repeater,
                                prefixLabel,
                              ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                AvatarCircle(
                                  name: name ?? prefixLabel,
                                  size: 36,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name ?? prefixLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 8,
                                            color: snrColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              [
                                                '${repeater.snr.toStringAsFixed(1)} dB',
                                                ?distanceLabel,
                                                _formatLastUpdated(
                                                  repeater.lastUpdated,
                                                ),
                                              ].join(' • '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: MeshTheme.mono(
                                                fontSize: 12,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _SnrTimelineChart(
                                              events: repeater.recentEvents(),
                                              emptyColor: colorScheme.outline,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.snrIndicator_packetCount(
                                              repeater.packetCount,
                                            ),
                                            style: MeshTheme.mono(
                                              fontSize: 11,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  size: 24,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_close),
        ),
      ],
    );
  }
}

class _SnrTimelineChart extends StatelessWidget {
  final List<RepeaterPacketEvent> events;
  final Color emptyColor;

  const _SnrTimelineChart({required this.events, required this.emptyColor});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.snrIndicator_snrOverTime,
      child: CustomPaint(
        size: const Size(double.infinity, 34),
        painter: _SnrTimelinePainter(events: events, emptyColor: emptyColor),
      ),
    );
  }
}

class _SnrTimelinePainter extends CustomPainter {
  final List<RepeaterPacketEvent> events;
  final Color emptyColor;

  _SnrTimelinePainter({required this.events, required this.emptyColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (events.isEmpty) return;

    final baseline = Paint()
      ..color = emptyColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      baseline,
    );

    final end = DateTime.now();
    final windowMs = const Duration(
      minutes: DirectRepeater.packetWindowMinutes,
    ).inMilliseconds;
    double x(DateTime at) {
      final elapsed = windowMs - end.difference(at).inMilliseconds;
      return (size.width * elapsed / windowMs).clamp(0.0, size.width);
    }

    var minSnr = events.first.snr;
    var maxSnr = events.first.snr;
    for (final event in events) {
      if (event.snr < minSnr) minSnr = event.snr;
      if (event.snr > maxSnr) maxSnr = event.snr;
    }
    if (maxSnr - minSnr < 2) {
      final mid = (minSnr + maxSnr) / 2;
      minSnr = mid - 1;
      maxSnr = mid + 1;
    }
    const top = 2.0;
    final bottom = size.height - 3.0;
    double y(double snr) =>
        top + (maxSnr - snr) / (maxSnr - minSnr) * (bottom - top);

    final line = Paint()
      ..strokeWidth = 1.5
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..isAntiAlias = true;

    for (var i = 0; i < events.length - 1; i++) {
      line.color = MeshTheme.snrColor(events[i].snr, blocked: false);
      canvas.drawLine(
        Offset(x(events[i].at), y(events[i].snr)),
        Offset(x(events[i + 1].at), y(events[i + 1].snr)),
        line,
      );
    }
    for (final event in events) {
      dot.color = MeshTheme.snrColor(event.snr, blocked: false);
      canvas.drawCircle(Offset(x(event.at), y(event.snr)), 1.8, dot);
    }
  }

  @override
  bool shouldRepaint(_SnrTimelinePainter oldDelegate) {
    return !identical(oldDelegate.events, events) ||
        oldDelegate.emptyColor != emptyColor;
  }
}
