import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../models/remote_node_stats.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../services/app_settings_service.dart';
import '../services/repeater_command_service.dart';
import '../theme/mesh_theme.dart';
import '../utils/battery_utils.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/routing_sheet.dart';
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
  static const int _statusResponseBytes = RemoteNodeStats.payloadOffset + 56;

  bool _isLoading = false;
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;
  Timer? _statusTimeout;
  int? _batteryMv;
  int? _uptimeSecs;
  int? _queueLen;
  int? _debugFlags;
  int? _lastRssi;
  double? _lastSnr;
  int? _noiseFloor;
  int? _txAirSecs;
  int? _rxAirSecs;
  int? _recvErrors;
  int? _posted;
  int? _postPushes;
  int? _packetsSent;
  int? _packetsRecv;
  int? _floodTx;
  int? _directTx;
  int? _floodRx;
  int? _directRx;
  int? _dupFlood;
  int? _dupDirect;
  double? _chanUtil;
  PathSelection? _pendingStatusSelection;

  @override
  void initState() {
    super.initState();
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _commandService = RepeaterCommandService(connector);
    _setupMessageListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStatus();
    });
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
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
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
    _commandService?.handleResponse(widget.repeater, parsed.text);
    _parseStatusResponse(parsed.text);
    _recordStatusResult(true);
  }

  void _handleStatusResponse(Uint8List frame) {
    if (frame.length < 8) return;
    final prefix = frame.sublist(2, 8);
    if (!_matchesRepeaterPrefix(prefix)) return;
    final stats = RemoteNodeStats.tryParse(frame, isRoom: _isRoom);
    if (stats == null) return;

    _statusTimeout?.cancel();
    if (!mounted) return;
    final rxAirSecs = stats.rxAirSecs;
    setState(() {
      _isLoading = false;
      _batteryMv = stats.batteryMv;
      _queueLen = stats.queueLen;
      _noiseFloor = stats.noiseFloor;
      _lastRssi = stats.lastRssi;
      _packetsRecv = stats.packetsRecv;
      _packetsSent = stats.packetsSent;
      _txAirSecs = stats.txAirSecs;
      _rxAirSecs = rxAirSecs;
      _recvErrors = stats.recvErrors;
      _posted = stats.posted;
      _postPushes = stats.postPushes;
      _uptimeSecs = stats.uptimeSecs;
      _floodTx = stats.floodTx;
      _directTx = stats.directTx;
      _floodRx = stats.floodRx;
      _directRx = stats.directRx;
      _debugFlags = stats.errEvents;
      _lastSnr = stats.lastSnr;
      _dupDirect = stats.directDups;
      _dupFlood = stats.floodDups;
      _chanUtil = rxAirSecs != null && stats.uptimeSecs > 0
          ? ((stats.txAirSecs + rxAirSecs) / stats.uptimeSecs) * 100
          : null;
    });
    final batteryMv = stats.batteryMv;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    connector.updateRepeaterBatterySnapshot(
      widget.repeater.publicKeyHex,
      batteryMv,
      source: 'status_binary',
    );
    _recordStatusResult(true);
  }

  bool get _isRoom => widget.repeater.type == advTypeRoom;

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
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadStatus() async {
    if (_commandService == null) return;

    setState(() {
      _isLoading = true;
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
      _recvErrors = null;
      _posted = null;
      _postPushes = null;
      _packetsSent = null;
      _packetsRecv = null;
      _floodTx = null;
      _directTx = null;
      _floodRx = null;
      _directRx = null;
      _dupFlood = null;
      _dupDirect = null;
      _chanUtil = null;
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
      if (messageBytes < maxFrameSize) messageBytes = maxFrameSize;
      final timeoutMs = connector.calculateTimeout(
        pathLength: pathLengthValue,
        messageBytes: messageBytes,
      );
      _statusTimeout?.cancel();
      _statusTimeout = Timer(Duration(milliseconds: timeoutMs), () {
        if (!mounted) return;
        setState(() => _isLoading = false);
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.repeater_statusRequestTimeout),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
        _recordStatusResult(false);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.repeater_errorLoadingStatus(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
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
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final dt = connector.repeaterClockAtLogin(widget.repeater.publicKey);
    if (dt == null) return '—';
    final local = dt.toLocal();
    final date = '${local.day}/${local.month}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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

  String _chanUtilText() {
    if (_chanUtil == null) return '—';
    return _formatPercent(_chanUtil);
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

  String _formatPercent(double? p) {
    if (p == null) return '—';
    return '${p.toStringAsFixed(2)}%';
  }

  String _formatSnr(double? snr) {
    if (snr == null) return '—';
    return snr.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);
    final isFloodMode = repeater.pathOverride == -1;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.repeater_statusTitle),
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
            onPressed: _isLoading ? null : _loadStatus,
            tooltip: l10n.repeater_refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadStatus,
          child: _isLoading && _batteryMv == null
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(l10n, repeater.name),
        ),
      ),
    );
  }

  Widget _buildBody(dynamic l10n, String name) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ── System ─────────────────────────────────────────────────────────
        SectionHeader(l10n.repeater_systemInformation),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildStatGrid([
            _StatItem(
              icon: Icons.battery_std,
              label: l10n.repeater_battery,
              value: _batteryText(),
              color: _batteryColor(),
            ),
            _StatItem(
              icon: Icons.timer_outlined,
              label: l10n.repeater_uptime,
              value: _formatDuration(_uptimeSecs),
              color: MeshPalette.blue,
            ),
            _StatItem(
              icon: Icons.schedule,
              label: l10n.repeater_clockAtLogin,
              value: _clockText(),
              color: scheme.onSurfaceVariant,
            ),
            _StatItem(
              icon: Icons.inbox,
              label: l10n.repeater_queueLength,
              value: _formatValue(_queueLen),
              color: scheme.onSurfaceVariant,
            ),
            _StatItem(
              icon: Icons.bug_report_outlined,
              label: l10n.repeater_debugFlags,
              value: _formatValue(_debugFlags),
              color: _debugFlags != null && _debugFlags! > 0
                  ? MeshPalette.warn
                  : scheme.onSurfaceVariant,
            ),
          ]),
        ),

        // ── Radio ──────────────────────────────────────────────────────────
        SectionHeader(l10n.repeater_radioStatistics),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildStatGrid([
            _StatItem(
              icon: Icons.signal_cellular_alt,
              label: l10n.repeater_lastRssi,
              value: _formatValue(_lastRssi, suffix: ' dB'),
              color: MeshPalette.blue,
            ),
            _StatItem(
              icon: Icons.waves,
              label: l10n.repeater_lastSnr,
              value: _formatSnr(_lastSnr),
              color: MeshTheme.snrColor(_lastSnr, blocked: false),
            ),
            _StatItem(
              icon: Icons.noise_control_off,
              label: l10n.repeater_noiseFloor,
              value: _formatValue(_noiseFloor, suffix: ' dB'),
              color: scheme.onSurfaceVariant,
            ),
            _StatItem(
              icon: Icons.upload,
              label: l10n.repeater_txAirtime,
              value: _formatDuration(_txAirSecs),
              color: MeshPalette.warn,
            ),
            if (!_isRoom)
              _StatItem(
                icon: Icons.download,
                label: l10n.repeater_rxAirtime,
                value: _formatDuration(_rxAirSecs),
                color: MeshPalette.signal,
              ),
          ]),
        ),

        // ── Packets ────────────────────────────────────────────────────────
        SectionHeader(l10n.repeater_packetStatistics),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildStatGrid([
            _StatItem(
              icon: Icons.send,
              label: l10n.repeater_sent,
              value: _packetTxText(),
              color: MeshPalette.blue,
            ),
            _StatItem(
              icon: Icons.call_received,
              label: l10n.repeater_received,
              value: _packetRxText(),
              color: MeshPalette.signal,
            ),
            _StatItem(
              icon: Icons.content_copy,
              label: l10n.repeater_duplicates,
              value: _duplicateText(),
              color: scheme.onSurfaceVariant,
            ),
            if (_isRoom) ...[
              _StatItem(
                icon: Icons.forum_outlined,
                label: l10n.room_postsStored,
                value: _formatValue(_posted),
                color: MeshPalette.blue,
              ),
              _StatItem(
                icon: Icons.outbox,
                label: l10n.room_postsPushed,
                value: _formatValue(_postPushes),
                color: MeshPalette.signal,
              ),
            ] else
              _StatItem(
                icon: Icons.error_outline,
                label: l10n.repeater_recvErrors,
                value: _formatValue(_recvErrors),
                color: _recvErrors != null && _recvErrors! > 0
                    ? MeshPalette.warn
                    : scheme.onSurfaceVariant,
              ),
            if (!_isRoom)
              _StatItem(
                icon: Icons.percent,
                label: l10n.repeater_chanUtil,
                value: _chanUtilText(),
                color: _chanUtil != null && _chanUtil! > 80
                    ? MeshPalette.alert
                    : _chanUtil != null && _chanUtil! > 50
                    ? MeshPalette.warn
                    : MeshPalette.signal,
              ),
          ]),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Color _batteryColor() {
    final connector = context.watch<MeshCoreConnector>();
    final batteryMv =
        connector.getRepeaterBatteryMillivolts(widget.repeater.publicKeyHex) ??
        _batteryMv;
    if (batteryMv == null) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
    final percent = estimateBatteryPercentFromMillivolts(
      batteryMv,
      _batteryChemistry(),
    );
    if (percent < 20) return MeshPalette.alert;
    if (percent < 40) return MeshPalette.warn;
    return MeshPalette.signal;
  }

  Widget _buildStatGrid(List<_StatItem> items) {
    final textScaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth / textScaler.scale(1) < 320
            ? 1
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: textScaler.scale(52) + 28,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return StatTile(
              icon: item.icon,
              label: item.label,
              value: item.value,
              color: item.color,
            );
          },
        );
      },
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
