import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../models/app_settings.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../services/app_settings_service.dart';
import '../services/repeater_command_service.dart';
import '../widgets/path_management_dialog.dart';
import '../helpers/cayenne_lpp.dart';
import '../utils/battery_utils.dart';

class TelemetryScreen extends StatefulWidget {
  final Contact repeater;
  final String password;

  const TelemetryScreen({
    super.key,
    required this.repeater,
    required this.password,
  });

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  static const int _statusPayloadOffset = 8;
  static const int _statusStatsSize = 52;
  static const int _statusResponseBytes =
      _statusPayloadOffset + _statusStatsSize;
  Uint8List _tagData = Uint8List(4);

  bool _isLoading = false;
  bool _isLoaded = false;
  bool _hasData = false;
  Timer? _statusTimeout;
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;
  PathSelection? _pendingStatusSelection;
  List<Map<String, dynamic>>? _parsedTelemetry;

  @override
  void initState() {
    super.initState();
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _commandService = RepeaterCommandService(connector);
    _setupMessageListener();
    _loadTelemetry();
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

      final response = parseBinaryResponsePacket(frame);
      if (response != null && listEquals(response.tag, _tagData)) {
        if (!mounted) return;
        _handleStatusResponse(response.payload);
      }
    });
  }

  void _handleStatusResponse(Uint8List frame) {
    final parsedTelemetry = CayenneLpp.parseByChannel(frame);
    final batteryMv = _extractTelemetryBatteryMillivolts(parsedTelemetry);
    if (batteryMv != null) {
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      connector.updateRepeaterBatterySnapshot(
        widget.repeater.publicKeyHex,
        batteryMv,
        source: 'telemetry',
      );
    }
    if (!mounted) return;
    setState(() {
      _parsedTelemetry = parsedTelemetry;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.telemetry_receivedData),
        backgroundColor: Colors.green,
      ),
    );
    _statusTimeout?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isLoaded = true;
      _hasData = true;
    });
  }

  Contact _resolveRepeater(MeshCoreConnector connector) {
    return connector.contacts.firstWhere(
      (c) => c.publicKeyHex == widget.repeater.publicKeyHex,
      orElse: () => widget.repeater,
    );
  }

  Future<void> _loadTelemetry() async {
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
      final frame = buildSendBinaryReq(
        repeater.publicKey,
        payload: Uint8List.fromList([reqTypeGetTelemetry]),
      );
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
          _isLoaded = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.telemetry_requestTimeout),
            backgroundColor: Colors.red,
          ),
        );
        _recordStatusResult(false);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoaded = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.telemetry_errorLoading(e.toString())),
            backgroundColor: Colors.red,
          ),
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
    final settings = context.watch<AppSettingsService>().settings;
    final isImperialUnits = settings.unitSystem == UnitSystem.imperial;
    final repeater = _resolveRepeater(connector);
    final isFloodMode = repeater.pathOverride == -1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.repeater_telemetry,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
            onPressed: _isLoading ? null : _loadTelemetry,
            tooltip: l10n.repeater_refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadTelemetry,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!_isLoaded &&
                  !_hasData &&
                  (_parsedTelemetry == null || _parsedTelemetry!.isEmpty))
                Center(
                  child: Text(
                    l10n.telemetry_noData,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              if ((_isLoaded || _hasData) &&
                  _parsedTelemetry != null &&
                  _parsedTelemetry!.isNotEmpty)
                for (final entry in _parsedTelemetry ?? [])
                  _buildChannelInfoCard(
                    entry['values'],
                    l10n.telemetry_channelTitle(entry['channel']),
                    entry['channel'],
                    isImperialUnits,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelInfoCard(
    Map<String, dynamic> channelData,
    String title,
    int channel,
    bool isImperialUnits,
  ) {
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
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            for (final entry in channelData.entries)
              if (entry.key == 'voltage' && channel == 1)
                _buildInfoRow(
                  l10n.telemetry_batteryLabel,
                  _batteryText(entry.value),
                )
              else if (entry.key == 'voltage')
                _buildInfoRow(
                  l10n.telemetry_voltageLabel,
                  l10n.telemetry_voltageValue(entry.value.toString()),
                )
              else if (entry.key == 'temperature' && channel == 1)
                _buildInfoRow(
                  l10n.telemetry_mcuTemperatureLabel,
                  _temperatureText(entry.value, isImperialUnits),
                )
              else if (entry.key == 'temperature')
                _buildInfoRow(
                  l10n.telemetry_temperatureLabel,
                  _temperatureText(entry.value, isImperialUnits),
                )
              else if (entry.key == 'current' && channel == 1)
                _buildInfoRow(
                  l10n.telemetry_currentLabel,
                  l10n.telemetry_currentValue(entry.value.toString()),
                )
              else
                _buildInfoRow(entry.key, entry.value.toString()),
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

  int? _extractTelemetryBatteryMillivolts(List<Map<String, dynamic>> entries) {
    for (final entry in entries) {
      if (entry['channel'] != 1) continue;
      final values = entry['values'];
      if (values is! Map<String, dynamic>) continue;
      final voltage = values['voltage'];
      if (voltage is num) return (voltage.toDouble() * 1000).round();
    }
    return null;
  }

  String _batteryText(double? telemetryVolts) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final batteryMv =
        connector.getRepeaterBatteryMillivolts(widget.repeater.publicKeyHex) ??
        (telemetryVolts == null ? null : (telemetryVolts * 1000).round());
    if (batteryMv == null) return l10n.common_notAvailable;
    final chemistry = _batteryChemistry();
    final percent = estimateBatteryPercentFromMillivolts(batteryMv, chemistry);
    final volts = (batteryMv / 1000).toStringAsFixed(2);
    return l10n.telemetry_batteryValue(percent, volts);
  }

  String _batteryChemistry() {
    final settingsService = context.read<AppSettingsService>();
    return settingsService.batteryChemistryForRepeater(
      widget.repeater.publicKeyHex,
    );
  }

  String _temperatureText(double? tempC, bool isImperialUnits) {
    final l10n = context.l10n;
    if (tempC == null) return l10n.common_notAvailable;
    final tempF = (tempC * 9 / 5) + 32;
    if (isImperialUnits) {
      return '${tempF.toStringAsFixed(1)}°F';
    }
    return '${tempC.toStringAsFixed(1)}°C';
  }
}
