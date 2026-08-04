import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meshcore_open/utils/app_logger.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../services/repeater_command_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/routing_sheet.dart';
import '../helpers/snack_bar_builder.dart';

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
  static const int _statusPayloadOffset = 8;
  static const int _statusStatsSize = 52;
  static const int _statusResponseBytes =
      _statusPayloadOffset + _statusStatsSize;
  Uint8List _tagData = Uint8List(4);
  int _neighborCount = 0;

  bool _isLoading = false;
  bool _isLoaded = false;
  bool _hasData = false;
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

      if (frame[0] == respCodeSent) {
        _tagData = frame.sublist(2, 6);
      }

      // Check if it's a binary response
      if (frame[0] == pushCodeBinaryResponse &&
          listEquals(frame.sublist(2, 6), _tagData)) {
        _handleNeighborsResponse(connector, frame.sublist(6));
      }
    });
  }

  String fmtDuration(double seconds) {
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(1)}s';
    }

    final int m = (seconds ~/ 60).toInt();
    final double s = seconds - (60 * m);

    if (m < 60) {
      return '${m}m ${s.toStringAsFixed(0)}s';
    }

    final int h = m ~/ 60;
    final int m2 = m % 60;

    return '${h}h ${m2}m';
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
      final parsedNeighbors = parseNeighborsData(buffer, buffer.readUInt16LE());
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

      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.neighbors_receivedData),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      );
      _statusTimeout?.cancel();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoaded = true;
        _hasData = true;
      });
    } catch (e) {
      appLogger.error('Error handling neighbors response: $e');
    }
  }

  Future<void> _loadNeighbors() async {
    if (_commandService == null) return;

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
          0x0F,
          0x00,
          0x00,
          0x00,
          _reqNeighborsKeyLen,
        ]),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.neighbors_repeatersNeighbors,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadNeighbors,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (!_isLoaded &&
                  !_hasData &&
                  (_parsedNeighbors == null || _parsedNeighbors!.isEmpty))
                EmptyState(icon: Icons.wifi_find, title: l10n.neighbors_noData),
              if (_isLoaded ||
                  _hasData &&
                      !(_parsedNeighbors == null || _parsedNeighbors!.isEmpty))
                _buildNeighborsList(connector),
            ],
          ),
        ),
      ),
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
      fmtDuration(lastHeardSeconds + 0.0),
    );

    return MeshCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 4),
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
                    fontSize: 12,
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: snrColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
