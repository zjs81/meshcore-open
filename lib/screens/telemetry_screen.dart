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
import '../utils/app_logger.dart';
import '../widgets/path_management_dialog.dart';
import '../helpers/cayenne_lpp.dart';
import '../utils/battery_utils.dart';
import '../helpers/snack_bar_builder.dart';

class TelemetryScreen extends StatefulWidget {
  final Contact contact;

  const TelemetryScreen({super.key, required this.contact});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  int _tagData = 0;

  bool _isLoading = false;
  bool _isLoaded = false;
  bool _hasData = false;
  Timer? _statusTimeout;
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;
  PathSelection? _pendingStatusSelection;
  List<Map<String, dynamic>>? _parsedTelemetry;

  int _tripTime = 0;

  int _resolveContactIndex = -1;

  Contact _resolveContact(MeshCoreConnector connector) {
    if (_resolveContactIndex >= 0 &&
        _resolveContactIndex < connector.contacts.length &&
        connector.contacts[_resolveContactIndex].publicKeyHex ==
            widget.contact.publicKeyHex) {
      return connector.contacts[_resolveContactIndex];
    }
    _resolveContactIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.contact.publicKeyHex,
    );
    if (_resolveContactIndex == -1) {
      return widget.contact;
    }
    return connector.contacts[_resolveContactIndex];
  }

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
      final reader = BufferReader(frame);
      try {
        final cmd = reader.readByte();
        if (cmd == respCodeSent) {
          reader.skipBytes(1); // Skip the reserved byte
          _tagData = reader.readUInt32LE();
          _tripTime = reader.readUInt32LE();
          _statusTimeout?.cancel();
          _statusTimeout = Timer(Duration(milliseconds: _tripTime), () {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _isLoaded = false;
            });
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.telemetry_requestTimeout),
              backgroundColor: Colors.red,
            );
            _recordTelemetryResult(false);
          });
        }

        // Check if it's a binary response
        if (cmd == pushCodeBinaryResponse) {
          if (!mounted) return;
          reader.skipBytes(1); // Skip the reserved byte
          if (reader.readUInt32LE() != _tagData) return;
          _handleTelemetryResponse(reader.readRemainingBytes());
        }

        // Check if it's a telemetry response (for chat contacts)
        if (cmd == pushCodeTelemetryResponse) {
          reader.skipBytes(1); // Skip the reserved byte
          final pubkey = reader.readBytes(6);
          if (!mounted) return;
          if (!listEquals(widget.contact.publicKey.sublist(0, 6), pubkey)) {
            return;
          }
          _handleTelemetryResponse(reader.readRemainingBytes());
        }
      } catch (e) {
        appLogger.error('Error parsing incoming frame: $e');
        // If parsing fails, ignore the frame
      }
    });
  }

  void _handleTelemetryResponse(Uint8List frame) {
    final parsedTelemetry = CayenneLpp.parseByChannel(frame);
    final batteryMv = _extractTelemetryBatteryMillivolts(parsedTelemetry);
    if (batteryMv != null) {
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      connector.updateRepeaterBatterySnapshot(
        widget.contact.publicKeyHex,
        batteryMv,
        source: 'telemetry',
      );
    }
    if (!mounted) return;
    setState(() {
      _parsedTelemetry = parsedTelemetry;
    });

    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.telemetry_receivedData),
      backgroundColor: Colors.green,
    );
    _statusTimeout?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isLoaded = true;
      _hasData = true;
    });
  }

  Future<void> _loadTelemetry() async {
    if (_commandService == null) return;

    setState(() {
      _isLoading = true;
      _isLoaded = false;
    });
    try {
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      final selection = await connector.preparePathForContactSend(
        _resolveContact(connector),
      );
      _pendingStatusSelection = selection;
      Uint8List frame;
      if (widget.contact.type != advTypeChat) {
        frame = buildSendBinaryReq(
          widget.contact.publicKey,
          payload: Uint8List.fromList([reqTypeGetTelemetry]),
        );
      } else {
        frame = buildSendTelemetryReq(widget.contact.publicKey);
      }
      await connector.sendFrame(frame);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoaded = false;
        });

        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.telemetry_errorLoading(e.toString())),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _recordTelemetryResult(bool success) {
    final selection = _pendingStatusSelection;
    if (selection == null) return;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    connector.recordRepeaterPathResult(
      widget.contact,
      selection,
      success,
      null,
    );
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
    final isFloodMode = widget.contact.pathOverride == -1;

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
              widget.contact.name,
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
                await connector.setPathOverride(widget.contact, pathLen: -1);
              } else {
                await connector.setPathOverride(widget.contact, pathLen: null);
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
                PathManagementDialog.show(context, contact: widget.contact),
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
        connector.getRepeaterBatteryMillivolts(widget.contact.publicKeyHex) ??
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
      widget.contact.publicKeyHex,
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
