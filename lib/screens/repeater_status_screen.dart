import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../services/app_settings_service.dart';
import '../services/repeater_command_service.dart';
import '../utils/battery_utils.dart';
import '../widgets/path_management_dialog.dart';
import '../helpers/snack_bar_builder.dart';

class RepeaterStatusScreen extends StatefulWidget {
  final Contact repeater;
  final String password;

  const RepeaterStatusScreen({
    super.key,
    required this.repeater,
    required this.password,
  });

  @override
  State<RepeaterStatusScreen> createState() => _RepeaterStatusScreenState();
}

class _RepeaterStatusScreenState extends State<RepeaterStatusScreen> {
  static const int _statusPayloadOffset = 8;
  static const int _statusStatsSize = 52;
  static const int _statusResponseBytes =
      _statusPayloadOffset + _statusStatsSize;

  bool _isLoading = false;
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;
  Timer? _statusTimeout;
  DateTime? _statusRequestedAt;
  int? _batteryMv;
  int? _uptimeSecs;
  int? _queueLen;
  int? _debugFlags;
  int? _lastRssi;
  double? _lastSnr;
  int? _noiseFloor;
  int? _txAirSecs;
  int? _rxAirSecs;
  int? _packetsSent;
  int? _packetsRecv;
  int? _floodTx;
  int? _directTx;
  int? _floodRx;
  int? _directRx;
  int? _dupFlood;
  int? _dupDirect;
  PathSelection? _pendingStatusSelection;

  @override
  void initState() {
    super.initState();
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _commandService = RepeaterCommandService(connector);
    _setupMessageListener();
    _loadStatus();
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _commandService?.dispose();
    _statusTimeout?.cancel();
    super.dispose();
  }

  void _setupMessageListener() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);

    // Listen for incoming text messages from the repeater
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;

      // Check if it's a text message response
      if (frame[0] == pushCodeStatusResponse) {
        _handleStatusResponse(frame);
      } else if (frame[0] == respCodeContactMsgRecv ||
          frame[0] == respCodeContactMsgRecvV3) {
        _handleTextMessageResponse(frame);
      }
    });
  }

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

  void _handleTextMessageResponse(Uint8List frame) {
    final parsed = parseContactMessageText(frame);
    if (parsed == null) return;
    if (!_matchesRepeaterPrefix(parsed.senderPrefix)) return;

    // Notify command service of response (for retry handling)
    _commandService?.handleResponse(widget.repeater, parsed.text);

    // Parse status responses
    _parseStatusResponse(parsed.text);
    _recordStatusResult(true);
  }

  void _handleStatusResponse(Uint8List frame) {
    if (frame.length < 8) return;
    final prefix = frame.sublist(2, 8);
    if (!_matchesRepeaterPrefix(prefix)) return;

    if (frame.length < _statusResponseBytes) return;

    final data = ByteData.sublistView(
      frame,
      _statusPayloadOffset,
      _statusResponseBytes,
    );
    int offset = 0;

    final batteryMv = data.getUint16(offset, Endian.little);
    offset += 2;
    final queueLen = data.getUint16(offset, Endian.little);
    offset += 2;
    final noiseFloor = data.getInt16(offset, Endian.little);
    offset += 2;
    final lastRssi = data.getInt16(offset, Endian.little);
    offset += 2;
    final packetsRecv = data.getUint32(offset, Endian.little);
    offset += 4;
    final packetsSent = data.getUint32(offset, Endian.little);
    offset += 4;
    final txAirSecs = data.getUint32(offset, Endian.little);
    offset += 4;
    final uptimeSecs = data.getUint32(offset, Endian.little);
    offset += 4;
    final floodTx = data.getUint32(offset, Endian.little);
    offset += 4;
    final directTx = data.getUint32(offset, Endian.little);
    offset += 4;
    final floodRx = data.getUint32(offset, Endian.little);
    offset += 4;
    final directRx = data.getUint32(offset, Endian.little);
    offset += 4;
    final errEvents = data.getUint16(offset, Endian.little);
    offset += 2;
    final lastSnrRaw = data.getInt16(offset, Endian.little);
    offset += 2;
    final directDups = data.getUint16(offset, Endian.little);
    offset += 2;
    final floodDups = data.getUint16(offset, Endian.little);
    offset += 2;
    final rxAirSecs = data.getUint32(offset, Endian.little);

    _statusTimeout?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _batteryMv = batteryMv;
      _queueLen = queueLen;
      _noiseFloor = noiseFloor;
      _lastRssi = lastRssi;
      _packetsRecv = packetsRecv;
      _packetsSent = packetsSent;
      _txAirSecs = txAirSecs;
      _rxAirSecs = rxAirSecs;
      _uptimeSecs = uptimeSecs;
      _floodTx = floodTx;
      _directTx = directTx;
      _floodRx = floodRx;
      _directRx = directRx;
      _debugFlags = errEvents;
      _lastSnr = lastSnrRaw / 4.0;
      _dupDirect = directDups;
      _dupFlood = floodDups;
    });
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    connector.updateRepeaterBatterySnapshot(
      widget.repeater.publicKeyHex,
      batteryMv,
      source: 'status_binary',
    );
    _recordStatusResult(true);
  }

  bool _matchesRepeaterPrefix(Uint8List prefix) {
    final target = widget.repeater.publicKey;
    if (target.length < 6 || prefix.length < 6) return false;
    for (int i = 0; i < 6; i++) {
      if (prefix[i] != target[i]) return false;
    }
    return true;
  }

  void _parseStatusResponse(String response) {
    final trimmed = response.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final data = jsonDecode(trimmed) as Map<String, dynamic>;
        if (data.containsKey('battery_mv')) {
          _batteryMv = _asInt(data['battery_mv']);
          _uptimeSecs = _asInt(data['uptime_secs']);
          _queueLen = _asInt(data['queue_len']);
          _debugFlags = _asInt(data['errors']);
          final batteryMv = _batteryMv;
          if (batteryMv != null) {
            final connector = Provider.of<MeshCoreConnector>(
              context,
              listen: false,
            );
            connector.updateRepeaterBatterySnapshot(
              widget.repeater.publicKeyHex,
              batteryMv,
              source: 'status_text',
            );
          }
        } else if (data.containsKey('noise_floor')) {
          _noiseFloor = _asInt(data['noise_floor']);
          _lastRssi = _asInt(data['last_rssi']);
          _lastSnr = _asDouble(data['last_snr']);
          _txAirSecs = _asInt(data['tx_air_secs']);
          _rxAirSecs = _asInt(data['rx_air_secs']);
        } else if (data.containsKey('recv') || data.containsKey('sent')) {
          _packetsRecv = _asInt(data['recv']);
          _packetsSent = _asInt(data['sent']);
          _floodTx = _asInt(data['flood_tx']);
          _directTx = _asInt(data['direct_tx']);
          _floodRx = _asInt(data['flood_rx']);
          _directRx = _asInt(data['direct_rx']);
          _dupFlood = _asInt(data['dup_flood']);
          _dupDirect = _asInt(data['dup_direct']);
        }
      } catch (_) {
        // Ignore parse failures for non-JSON responses.
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadStatus() async {
    if (_commandService == null) return;

    setState(() {
      _isLoading = true;
      _statusRequestedAt = DateTime.now();
      _pendingStatusSelection = null;
      _batteryMv = null;
      _uptimeSecs = null;
      _queueLen = null;
      _debugFlags = null;
      _lastRssi = null;
      _lastSnr = null;
      _noiseFloor = null;
      _txAirSecs = null;
      _rxAirSecs = null;
      _packetsSent = null;
      _packetsRecv = null;
      _floodTx = null;
      _directTx = null;
      _floodRx = null;
      _directRx = null;
      _dupFlood = null;
      _dupDirect = null;
    });

    try {
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      final repeater = _resolveRepeater(connector);
      final selection = await connector.preparePathForContactSend(repeater);
      _pendingStatusSelection = selection;
      final frame = buildSendStatusRequestFrame(repeater.publicKey);
      await connector.sendFrame(frame);

      final pathLengthValue = selection.useFlood ? -1 : selection.hopCount;
      var messageBytes = frame.length >= _statusResponseBytes
          ? frame.length
          : _statusResponseBytes;
      if (messageBytes < maxFrameSize) {
        messageBytes = maxFrameSize;
      }
      final timeoutMs = connector.calculateTimeout(
        pathLength: pathLengthValue,
        messageBytes: messageBytes,
      );
      _statusTimeout?.cancel();
      _statusTimeout = Timer(Duration(milliseconds: timeoutMs), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.repeater_statusRequestTimeout),
          backgroundColor: Colors.red,
        );
        _recordStatusResult(false);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.repeater_errorLoadingStatus(e.toString())),
          backgroundColor: Colors.red,
        );
      }
      _recordStatusResult(false);
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);
    final isFloodMode = repeater.pathOverride == -1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.repeater_statusTitle),
            Text(
              repeater.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(isFloodMode ? Icons.waves : Icons.route),
            tooltip: l10n.repeater_routingMode,
            onSelected: (mode) async {
              if (mode == 'flood') {
                await connector.setPathOverride(repeater, pathLen: -1);
              } else {
                await connector.setPathOverride(repeater, pathLen: null);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'auto',
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_mode,
                      size: 20,
                      color: !isFloodMode
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.repeater_autoUseSavedPath,
                      style: TextStyle(
                        fontWeight: !isFloodMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'flood',
                child: Row(
                  children: [
                    Icon(
                      Icons.waves,
                      size: 20,
                      color: isFloodMode
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.repeater_forceFloodMode,
                      style: TextStyle(
                        fontWeight: isFloodMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: l10n.repeater_pathManagement,
            onPressed: () =>
                PathManagementDialog.show(context, contact: repeater),
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStatus,
            tooltip: l10n.repeater_refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadStatus,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSystemInfoCard(),
              const SizedBox(height: 16),
              _buildRadioStatsCard(),
              const SizedBox(height: 16),
              _buildPacketStatsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.repeater_systemInformation,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(l10n.repeater_battery, _batteryText()),
            _buildInfoRow(l10n.repeater_clockAtLogin, _clockText()),
            _buildInfoRow(l10n.repeater_uptime, _formatDuration(_uptimeSecs)),
            _buildInfoRow(l10n.repeater_queueLength, _formatValue(_queueLen)),
            _buildInfoRow(l10n.repeater_debugFlags, _formatValue(_debugFlags)),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioStatsCard() {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.radio,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.repeater_radioStatistics,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(
              l10n.repeater_lastRssi,
              _formatValue(_lastRssi, suffix: ' dB'),
            ),
            _buildInfoRow(l10n.repeater_lastSnr, _formatSnr(_lastSnr)),
            _buildInfoRow(
              l10n.repeater_noiseFloor,
              _formatValue(_noiseFloor, suffix: ' dB'),
            ),
            _buildInfoRow(l10n.repeater_txAirtime, _formatDuration(_txAirSecs)),
            _buildInfoRow(l10n.repeater_rxAirtime, _formatDuration(_rxAirSecs)),
          ],
        ),
      ),
    );
  }

  Widget _buildPacketStatsCard() {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.repeater_packetStatistics,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow(l10n.repeater_sent, _packetTxText()),
            _buildInfoRow(l10n.repeater_received, _packetRxText()),
            _buildInfoRow(l10n.repeater_duplicates, _duplicateText()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _batteryText() {
    final connector = context.watch<MeshCoreConnector>();
    final batteryMv =
        connector.getRepeaterBatteryMillivolts(widget.repeater.publicKeyHex) ??
        _batteryMv;
    if (batteryMv == null) return '—';
    final percent = estimateBatteryPercentFromMillivolts(
      batteryMv,
      _batteryChemistry(),
    );
    final volts = (batteryMv / 1000.0).toStringAsFixed(2);
    return '$percent% / ${volts}V';
  }

  String _batteryChemistry() {
    final settingsService = context.read<AppSettingsService>();
    return settingsService.batteryChemistryForRepeater(
      widget.repeater.publicKeyHex,
    );
  }

  String _clockText() {
    if (_statusRequestedAt == null) return '—';
    final dt = _statusRequestedAt!;
    final date = '${dt.day}/${dt.month}/${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '—';
    final l10n = context.l10n;
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return l10n.repeater_daysHoursMinsSecs(days, hours, minutes, secs);
  }

  String _packetTxText() {
    if (_packetsSent == null) return '—';
    final l10n = context.l10n;
    final flood = _formatValue(_floodTx);
    final direct = _formatValue(_directTx);
    return l10n.repeater_packetTxTotal(_packetsSent!, flood, direct);
  }

  String _packetRxText() {
    if (_packetsRecv == null) return '—';
    final l10n = context.l10n;
    final flood = _formatValue(_floodRx);
    final direct = _formatValue(_directRx);
    return l10n.repeater_packetRxTotal(_packetsRecv!, flood, direct);
  }

  String _duplicateText() {
    final l10n = context.l10n;
    if (_dupFlood != null || _dupDirect != null) {
      final flood = _formatValue(_dupFlood);
      final direct = _formatValue(_dupDirect);
      return l10n.repeater_duplicatesFloodDirect(flood, direct);
    }
    if (_packetsRecv == null || _floodRx == null || _directRx == null) {
      return '—';
    }
    final dupTotal = _packetsRecv! - _floodRx! - _directRx!;
    if (dupTotal < 0) return '—';
    return l10n.repeater_duplicatesTotal(dupTotal);
  }

  String _formatValue(num? value, {String? suffix}) {
    if (value == null) return '—';
    return suffix == null ? value.toString() : '$value$suffix';
  }

  String _formatSnr(double? snr) {
    if (snr == null) return '—';
    return snr.toStringAsFixed(2);
  }
}
