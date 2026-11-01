import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/utils/app_logger.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../services/repeater_command_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/confirm_clear_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/neighbors_map_view.dart';
import '../widgets/routing_sheet.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/app_localizations.dart';
import '../widgets/repeater_login_dialog.dart';
import 'repeater_hub_screen.dart';

class NeighborsScreen extends StatefulWidget {
  final Contact repeater;
  final String password;

  const NeighborsScreen({
    super.key,
    required this.repeater,
    required this.password,
  });

  @override
  State<NeighborsScreen> createState() => _NeighborsScreenState();
}

class _NeighborsScreenState extends State<NeighborsScreen> {
  static const int _reqNeighborsKeyLen = 4;
  // Firmware packs results into a 130-byte buffer (simple_repeater/MyMesh.cpp).
  static const int _reqNeighborsPageSize = 130 ~/ (_reqNeighborsKeyLen + 5);
  static const int _statusPayloadOffset = 8;
  static const int _statusStatsSize = 52;
  static const int _statusResponseBytes =
      _statusPayloadOffset + _statusStatsSize;
  Uint8List _tagData = Uint8List(4);
  bool _awaitingSent = false;
  int _neighborCount = 0;
  int _pageOffset = 0;

  bool _isLoading = false;
  bool _isLoaded = false;
  bool _hasData = false;
  bool _isDiscovering = false;
  bool _isErasing = false;
  Timer? _statusTimeout;
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;
  PathSelection? _pendingStatusSelection;
  List<Map<String, dynamic>>? _parsedNeighbors;

  int _resolveRepeaterIndex = -1;

  Contact _resolveRepeater(MeshCoreConnector connector) {
    if (_resolveRepeaterIndex >= 0 &&
        _resolveRepeaterIndex < connector.contacts.length &&
        connector.contacts[_resolveRepeaterIndex].publicKeyHex ==
            widget.repeater.publicKeyHex) {
      return connector.contacts[_resolveRepeaterIndex];
    }
    _resolveRepeaterIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.repeater.publicKeyHex,
    );
    if (_resolveRepeaterIndex == -1) {
      return widget.repeater;
    }
    return connector.contacts[_resolveRepeaterIndex];
  }

  @override
  void initState() {
    super.initState();
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _commandService = RepeaterCommandService(connector);
    _setupMessageListener();
    _loadNeighbors();
    _hasData = false;
  }

  void _setupMessageListener() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);

    // Listen for incoming text messages from the repeater
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;

      if (frame[0] == respCodeSent && _awaitingSent && frame.length >= 6) {
        _awaitingSent = false;
        _tagData = frame.sublist(2, 6);
      }

      if (frame[0] == respCodeContactMsgRecv ||
          frame[0] == respCodeContactMsgRecvV3) {
        final parsed = parseContactMessageText(frame);
        if (parsed == null) return;
        if (!_matchesRepeaterPrefix(parsed.senderPrefix)) return;
        _commandService?.handleResponse(widget.repeater, parsed.text);
        return;
      }

      // Check if it's a binary response
      if (frame[0] == pushCodeBinaryResponse &&
          frame.length >= 6 &&
          listEquals(frame.sublist(2, 6), _tagData)) {
        _handleNeighborsResponse(connector, frame.sublist(6));
      }
    });
  }

  bool _matchesRepeaterPrefix(Uint8List prefix) {
    final target = widget.repeater.publicKey;
    if (target.length < 6 || prefix.length < 6) return false;
    for (int i = 0; i < 6; i++) {
      if (prefix[i] != target[i]) return false;
    }
    return true;
  }

  static String fmtDuration(AppLocalizations l10n, double seconds) {
    if (seconds < 60) {
      return l10n.neighbors_durationSeconds(seconds.toStringAsFixed(1));
    }

    final int m = (seconds ~/ 60).toInt();
    final double s = seconds - (60 * m);

    if (m < 60) {
      return l10n.neighbors_durationMinutes(m, s.toStringAsFixed(0));
    }

    final int h = m ~/ 60;
    final int m2 = m % 60;

    return l10n.neighbors_durationHours(h, m2);
  }

  static List<Map<String, dynamic>> parseNeighborsData(
    BufferReader buffer,
    int resultsCount,
  ) {
    final Map<int, Map<String, dynamic>> neighbors = {};
    try {
      for (var i = 0; i < resultsCount; i++) {
        final neighborData = neighbors.putIfAbsent(
          i,
          () => {
            'contact': null,
            'publicKey': <Uint8List>{},
            'lastHeard': <int>{},
            'snr': <double>{},
          },
        );
        neighborData['publicKey'] = buffer.readBytes(_reqNeighborsKeyLen);
        neighborData['lastHeard'] = buffer.readUInt32LE();
        neighborData['snr'] = buffer.readInt8() / 4.0;
      }

      return neighbors.values.toList();
    } catch (e) {
      appLogger.error(
        'Error parsing neighbors data: $e',
        tag: 'NeighborsScreen',
      );
      return [];
    }
  }

  void _handleNeighborsResponse(MeshCoreConnector connector, Uint8List frame) {
    final buffer = BufferReader(frame);
    final contacts = connector.allContactsUnfiltered;
    try {
      final neighborCount = buffer.readUInt16LE();
      final page = parseNeighborsData(buffer, buffer.readUInt16LE());
      // Dedupe by pubkey prefix: paging windows or repeated pushes must never
      // list the same neighbor twice.
      final parsedNeighbors = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final entry in [
        if (_pageOffset > 0) ...?_parsedNeighbors,
        ...page,
      ]) {
        if (seen.add((entry['publicKey'] as Uint8List).join(','))) {
          parsedNeighbors.add(entry);
        }
      }
      contacts.where((c) => c.type == advTypeRepeater).forEach((repeater) {
        for (var neighborData in parsedNeighbors) {
          final publicKey = neighborData['publicKey'];
          if (listEquals(
            repeater.publicKey.sublist(0, _reqNeighborsKeyLen),
            publicKey,
          )) {
            neighborData['contact'] = repeater;
          }
        }
      });

      setState(() {
        _parsedNeighbors = parsedNeighbors;
        _neighborCount = neighborCount;
      });

      _tagData = Uint8List(4);
      _statusTimeout?.cancel();
      _recordStatusResult(true);
      if (!mounted) return;
      if (page.isNotEmpty && parsedNeighbors.length < neighborCount) {
        _loadNeighbors(offset: parsedNeighbors.length);
        return;
      }
      setState(() {
        _isLoading = false;
        _isLoaded = true;
        _hasData = true;
      });
    } catch (e) {
      appLogger.error('Error handling neighbors response: $e');
    }
  }

  Future<void> _loadNeighbors({int offset = 0}) async {
    if (_commandService == null) return;

    _pageOffset = offset;
    setState(() {
      _isLoading = true;
      _isLoaded = false;
    });
    try {
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      final repeater = _resolveRepeater(connector);
      final selection = await connector.preparePathForContactSend(repeater);
      _pendingStatusSelection = selection;

      //[version][number of requested neighbors][offset_16bit][order by][len of public key]
      final frame = buildSendBinaryReq(
        repeater.publicKey,
        payload: Uint8List.fromList([
          reqTypeGetNeighbors,
          0x00,
          _reqNeighborsPageSize,
          offset & 0xFF,
          (offset >> 8) & 0xFF,
          0x00,
          _reqNeighborsKeyLen,
        ]),
      );
      _awaitingSent = true;
      await connector.sendFrame(frame);

      final pathLengthValue = selection.useFlood ? -1 : selection.hopCount;
      final messageBytes = frame.length >= _statusResponseBytes
          ? frame.length
          : _statusResponseBytes;
      final timeoutMs = connector.calculateTimeout(
        pathLength: pathLengthValue,
        messageBytes: messageBytes,
      );
      _statusTimeout?.cancel();
      _statusTimeout = Timer(Duration(milliseconds: timeoutMs), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isLoaded = false;
        });
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.neighbors_requestTimedOut),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
        _recordStatusResult(false);
      });
    } catch (e) {
      _awaitingSent = false;
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoaded = false;
        });

        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.neighbors_errorLoading(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  void _recordStatusResult(bool success) {
    final selection = _pendingStatusSelection;
    if (selection == null) return;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);
    connector.recordRepeaterPathResult(repeater, selection, success, null);
    _pendingStatusSelection = null;
  }

  /// Tell the repeater itself to broadcast a zero-hop neighbor discovery
  /// request (`discover.neighbors`, MyMesh.cpp sendNodeDiscoverReq) rather
  /// than making the connected companion do it. Waits for the repeater's
  /// reply; without a reply within the normal command timeout the request
  /// is reported as timed out instead of retried.
  Future<void> _sendDiscovery() async {
    if (_commandService == null) return;
    final l10n = context.l10n;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);
    setState(() => _isDiscovering = true);
    try {
      await _commandService!.sendCommand(
        repeater,
        'discover.neighbors',
        retries: 1,
      );
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.neighbors_discoverySent),
      );
    } catch (e) {
      if (!mounted) return;
      final isTimeout = e.toString().contains('Command timeout');
      showDismissibleSnackBar(
        context,
        content: Text(
          isTimeout
              ? l10n.neighbors_requestTimedOut
              : l10n.neighbors_discoveryFailed(e.toString()),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _isDiscovering = false);
    }
  }

  /// Erase the repeater's whole neighbor list. The firmware's
  /// `neighbor.remove` treats an empty pubkey prefix as matching every
  /// entry, so the command is sent with no argument (trailing space).
  Future<void> _confirmEraseAll() async {
    if (_commandService == null) return;
    final l10n = context.l10n;
    final confirmed = await showConfirmClearDialog(
      context,
      title: l10n.neighbors_eraseTooltip,
      message: l10n.neighbors_eraseConfirm,
    );
    if (!confirmed || !mounted) return;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);
    setState(() => _isErasing = true);
    try {
      await _commandService!.sendCommand(repeater, 'neighbor.remove ');
      if (!mounted) return;
      setState(() {
        _parsedNeighbors = null;
        _neighborCount = 0;
        _hasData = false;
        _isLoaded = false;
      });
      showDismissibleSnackBar(context, content: Text(l10n.neighbors_erased));
    } catch (e) {
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.neighbors_eraseFailed(e.toString())),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _isErasing = false);
    }
  }

  /// Neighbor entries with a resolved contact that carries a position, for
  /// the map tab. Distance is only measured when the repeater itself has a
  /// location; without one the links still draw, just unmeasured.
  List<NeighborLink> _buildLinks(MeshCoreConnector connector) {
    final parsed = _parsedNeighbors;
    if (parsed == null) return const [];
    final repeater = _resolveRepeater(connector);
    final repeaterPoint = repeater.hasLocation
        ? LatLng(repeater.latitude!, repeater.longitude!)
        : null;
    final distance = Distance();
    final links = <NeighborLink>[];
    for (final entry in parsed) {
      final contact = entry['contact'] as Contact?;
      if (contact == null || !contact.hasLocation) continue;
      final point = LatLng(contact.latitude!, contact.longitude!);
      links.add(
        NeighborLink(
          neighbor: contact,
          point: point,
          snr: entry['snr'] as double,
          lastHeardSeconds: entry['lastHeard'] as int,
          distanceMeters: repeaterPoint == null
              ? null
              : distance(repeaterPoint, point),
        ),
      );
    }
    return links;
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _commandService?.dispose();
    _statusTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);
    final isFloodMode = repeater.pathOverride == -1;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.neighbors_repeatersNeighbors,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                repeater.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(isFloodMode ? Icons.waves : Icons.route),
              tooltip: l10n.repeater_routingMode,
              onPressed: () =>
                  ContactRoutingSheet.show(context, contact: repeater),
            ),
            IconButton(
              icon: _isDiscovering
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.radar),
              tooltip: l10n.neighbors_discoverTooltip,
              onPressed: _isDiscovering ? null : _sendDiscovery,
            ),
            IconButton(
              icon: _isErasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep),
              tooltip: l10n.neighbors_eraseTooltip,
              onPressed: _isErasing ? null : _confirmEraseAll,
            ),
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadNeighbors,
              tooltip: l10n.repeater_refresh,
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.neighbors_tabList),
              Tab(text: l10n.neighbors_tabMap),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(
            children: [
              RefreshIndicator(
                onRefresh: _loadNeighbors,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // First request still in flight: show progress, not "no data".
                    if (_isLoading && _parsedNeighbors == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              l10n.common_loading,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    else if (!_isLoaded &&
                        !_hasData &&
                        (_parsedNeighbors == null || _parsedNeighbors!.isEmpty))
                      EmptyState(
                        icon: Icons.wifi_find,
                        title: l10n.neighbors_noData,
                      ),
                    if (_isLoaded ||
                        _hasData &&
                            !(_parsedNeighbors == null ||
                                _parsedNeighbors!.isEmpty))
                      _buildNeighborsList(connector),
                  ],
                ),
              ),
              _buildMapView(connector),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(MeshCoreConnector connector) {
    if (_parsedNeighbors == null) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return EmptyState(
        icon: Icons.wifi_find,
        title: context.l10n.neighbors_noData,
      );
    }
    final links = _buildLinks(connector);
    return NeighborsMapView(
      repeater: _resolveRepeater(connector),
      links: links,
      hiddenCount: _parsedNeighbors!.length - links.length,
    );
  }

  Widget _buildNeighborsList(MeshCoreConnector connector) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          '${l10n.repeater_neighbors} — $_neighborCount',
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
        ),
        for (var i = 0; i < _parsedNeighbors!.length; i++)
          ListEntrance(
            index: i,
            child: _buildNeighborRow(_parsedNeighbors![i], connector.currentSf),
          ),
      ],
    );
  }

  Widget _buildNeighborRow(Map<String, dynamic> data, int? spreadingFactor) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final Contact? contact = data['contact'] as Contact?;
    final double snr = data['snr'] as double;
    final int lastHeardSeconds = data['lastHeard'] as int;

    final name = contact != null
        ? contact.name
        : l10n.neighbors_unknownContact(
            '<${pubKeyToHex(data['publicKey'] as Uint8List)}>',
          );

    final snrColor = MeshTheme.snrColor(snr, blocked: false);
    final heardLabel = l10n.neighbors_heardAgo(
      fmtDuration(l10n, lastHeardSeconds + 0.0),
    );
    // Only repeaters saved on the radio can be logged into.
    final canOpen = contact != null && contact.isActive;

    return MeshCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 4),
      onTap: canOpen ? () => _openNeighbor(contact) : null,
      child: Row(
        children: [
          AvatarCircle(
            name: name,
            size: 40,
            color: contact != null ? MeshPalette.warn : scheme.onSurfaceVariant,
            icon: contact != null ? Icons.cell_tower : Icons.device_unknown,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  heardLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SignalBars(snr: snr, height: 16),
              const SizedBox(height: 4),
              Text(
                '${snr.toStringAsFixed(1)} dB',
                style: MeshTheme.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: snrColor,
                ),
              ),
            ],
          ),
          if (canOpen) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 24, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
    );
  }

  /// Opens a resolved neighbor the same way the contacts list does:
  /// repeaters go through the login dialog to the repeater hub.
  void _openNeighbor(Contact contact) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => RepeaterLoginDialog(
        repeater: contact,
        onLogin: (password, isAdmin) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RepeaterHubScreen(
                repeater: contact,
                password: password,
                isAdmin: isAdmin,
              ),
            ),
          );
        },
      ),
    );
  }
}
