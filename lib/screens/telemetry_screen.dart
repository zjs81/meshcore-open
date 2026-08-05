import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../models/app_settings.dart';
import '../storage/prefs_manager.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../services/app_settings_service.dart';
import '../services/repeater_command_service.dart';
import '../utils/app_logger.dart';
import '../widgets/routing_sheet.dart';
import '../helpers/cayenne_lpp.dart';
import '../utils/battery_utils.dart';
import '../helpers/snack_bar_builder.dart';
import '../widgets/sync_progress_overlay.dart';
import '../widgets/telemetry_location_map.dart';
import '../theme/mesh_theme.dart';
import '../widgets/mesh_ui.dart';

class TelemetryScreen extends StatefulWidget {
  final Contact contact;
  final bool isSelf;

  const TelemetryScreen({super.key, required this.contact, this.isSelf = false});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  static const int _autoRefreshDefaultIntervalSeconds = 20;
  static const int _autoRefreshDefaultQuantity = 10;
  static const int _autoRefreshMinIntervalSeconds = 10;
  static const int _autoRefreshMaxIntervalSeconds = 300;
  static const int _autoRefreshMinQuantity = 1;
  static const int _autoRefreshMaxQuantity = 10;

  int _tagData = 0;

  bool _isLoading = false;
  bool _isLoaded = false;
  bool _hasData = false;
  Timer? _statusTimeout;
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;
  PathSelection? _pendingStatusSelection;
  List<Map<String, dynamic>>? _parsedTelemetry;
  final TextEditingController _autoRefreshIntervalController =
      TextEditingController(text: '$_autoRefreshDefaultIntervalSeconds');
  final TextEditingController _autoRefreshQuantityController =
      TextEditingController(text: '$_autoRefreshDefaultQuantity');
  Timer? _autoRefreshTimer;
  bool _isAutoRefreshEnabled = false;
  bool _activeTelemetryRequestIsAutoRefresh = false;
  bool _autoRefreshLastAttemptFailed = false;
  int _autoRefreshCurrentAttempt = 0;
  int _autoRefreshTotalAttempts = 0;
  int _autoRefreshIntervalSeconds = _autoRefreshDefaultIntervalSeconds;

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
    _loadAutoRefreshSettings();
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
          final isAutoRefreshRequest = _activeTelemetryRequestIsAutoRefresh;
          _statusTimeout = Timer(Duration(milliseconds: _tripTime), () {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _isLoaded = false;
              if (isAutoRefreshRequest && _isAutoRefreshEnabled) {
                _autoRefreshLastAttemptFailed = true;
              }
            });
            if (!isAutoRefreshRequest) {
              showDismissibleSnackBar(
                context,
                content: Text(context.l10n.telemetry_requestTimeout),
                backgroundColor: Theme.of(context).colorScheme.error,
              );
            }
            if (isAutoRefreshRequest && _isAutoRefreshEnabled) {
              _scheduleNextAutoRefreshAttempt();
            }
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
    if (batteryMv != null && !widget.isSelf) {
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      connector.updateRepeaterBatterySnapshot(
        widget.contact.publicKeyHex,
        batteryMv,
        source: 'telemetry',
      );
    }
    if (!mounted) return;
    final isAutoRefreshRequest = _activeTelemetryRequestIsAutoRefresh;
    setState(() {
      _parsedTelemetry = parsedTelemetry;
      if (isAutoRefreshRequest) {
        _autoRefreshLastAttemptFailed = false;
      }
      _activeTelemetryRequestIsAutoRefresh = false;
    });

    if (!isAutoRefreshRequest) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.telemetry_receivedData),
      );
    }
    _statusTimeout?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isLoaded = true;
      _hasData = true;
    });
    if (isAutoRefreshRequest) {
      _scheduleNextAutoRefreshAttempt();
    }
  }

  Future<void> _loadTelemetry({bool isAutoRefresh = false}) async {
    if (_commandService == null) return;

    setState(() {
      _isLoading = true;
      _isLoaded = false;
      _activeTelemetryRequestIsAutoRefresh = isAutoRefresh;
    });
    try {
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      Uint8List frame;
      if (widget.isSelf) {
        // ask the connected node for its own telemetry, no mesh path involved
        frame = buildSendTelemetryReq(null);
        final isAutoRefreshRequest = _activeTelemetryRequestIsAutoRefresh;
        _statusTimeout?.cancel();
        _statusTimeout = Timer(const Duration(seconds: 5), () {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isLoaded = false;
            if (isAutoRefreshRequest && _isAutoRefreshEnabled) {
              _autoRefreshLastAttemptFailed = true;
            }
            _activeTelemetryRequestIsAutoRefresh = false;
          });
          if (!isAutoRefreshRequest) {
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.telemetry_requestTimeout),
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          }
          if (isAutoRefreshRequest && _isAutoRefreshEnabled) {
            _scheduleNextAutoRefreshAttempt();
          }
          _recordTelemetryResult(false);
        });
      } else {
        final selection = await connector.preparePathForContactSend(
          _resolveContact(connector),
        );
        _pendingStatusSelection = selection;
        if (widget.contact.type != advTypeChat) {
          frame = buildSendBinaryReq(
            widget.contact.publicKey,
            payload: buildTelemetryBinaryPayload(),
          );
        } else {
          frame = buildSendTelemetryReq(widget.contact.publicKey);
        }
      }
      await connector.sendFrame(frame);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoaded = false;
          if (isAutoRefresh) {
            _autoRefreshLastAttemptFailed = true;
          }
          _activeTelemetryRequestIsAutoRefresh = false;
        });
        if (isAutoRefresh) {
          _scheduleNextAutoRefreshAttempt();
        }

        if (!isAutoRefresh) {
          showDismissibleSnackBar(
            context,
            content: Text(context.l10n.telemetry_errorLoading(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      }
    }
  }

  void _loadAutoRefreshSettings() {
    final prefs = PrefsManager.instance;
    final contactKey = widget.contact.publicKeyHex;
    final interval =
        (prefs.getInt(_autoRefreshIntervalKey(contactKey)) ??
                _autoRefreshDefaultIntervalSeconds)
            .clamp(
              _autoRefreshMinIntervalSeconds,
              _autoRefreshMaxIntervalSeconds,
            )
            .toInt();
    final quantity =
        (prefs.getInt(_autoRefreshQuantityKey(contactKey)) ??
                _autoRefreshDefaultQuantity)
            .clamp(_autoRefreshMinQuantity, _autoRefreshMaxQuantity)
            .toInt();

    _autoRefreshIntervalSeconds = interval;
    _autoRefreshIntervalController.text = interval.toString();
    _autoRefreshQuantityController.text = quantity.toString();
  }

  Future<void> _saveAutoRefreshSettings() async {
    final contactKey = widget.contact.publicKeyHex;
    final interval = _clampControllerValue(
      controller: _autoRefreshIntervalController,
      min: _autoRefreshMinIntervalSeconds,
      max: _autoRefreshMaxIntervalSeconds,
      fallback: _autoRefreshIntervalSeconds,
    );
    final quantity = _clampControllerValue(
      controller: _autoRefreshQuantityController,
      min: _autoRefreshMinQuantity,
      max: _autoRefreshMaxQuantity,
      fallback: _autoRefreshDefaultQuantity,
    );

    final prefs = PrefsManager.instance;
    await prefs.setInt(_autoRefreshIntervalKey(contactKey), interval);
    await prefs.setInt(_autoRefreshQuantityKey(contactKey), quantity);
  }

  String _autoRefreshIntervalKey(String contactKey) {
    return 'telemetry_auto_refresh_interval_$contactKey';
  }

  String _autoRefreshQuantityKey(String contactKey) {
    return 'telemetry_auto_refresh_quantity_$contactKey';
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
    unawaited(_saveAutoRefreshSettings());
    _frameSubscription?.cancel();
    _commandService?.dispose();
    _statusTimeout?.cancel();
    _autoRefreshTimer?.cancel();
    _autoRefreshIntervalController.dispose();
    _autoRefreshQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final connector = context.watch<MeshCoreConnector>();
    final settings = context.watch<AppSettingsService>().settings;
    final isImperialUnits = settings.unitSystem == UnitSystem.imperial;
    final contact = connector.contacts.firstWhere(
      (c) => c.publicKeyHex == widget.contact.publicKeyHex,
      orElse: () => widget.contact,
    );
    final isFloodMode = contact.pathOverride == -1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
        centerTitle: true,
        bottom: const SyncProgressAppBarBottom(),
        actions: [
          if (!widget.isSelf)
            IconButton(
              icon: Icon(isFloodMode ? Icons.waves : Icons.route),
              tooltip: l10n.repeater_routingMode,
              onPressed: () =>
                  ContactRoutingSheet.show(context, contact: widget.contact),
            ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: (_isLoading || _isAutoRefreshEnabled)
                ? null
                : () => _loadTelemetry(),
            tooltip: l10n.repeater_refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () =>
              _isAutoRefreshEnabled ? Future.value() : _loadTelemetry(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!_isLoaded &&
                  !_hasData &&
                  (_parsedTelemetry == null || _parsedTelemetry!.isEmpty))
                Center(
                  child: Text(
                    l10n.telemetry_noData,
                    style: TextStyle(
                      fontSize: 16,
                      color: scheme.onSurfaceVariant,
                    ),
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
              _buildAutoRefreshCard(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title, padding: const EdgeInsets.fromLTRB(16, 16, 16, 8)),
        MeshCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in channelData.entries)
                _buildTelemetryField(entry, channel, isImperialUnits),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryField(
    MapEntry<String, dynamic> entry,
    int channel,
    bool isImperialUnits,
  ) {
    if (entry.key == 'gps') {
      return _buildGpsInfo(entry.value);
    }

    final display = _formatTelemetryField(
      entry.key,
      entry.value,
      channel,
      isImperialUnits,
    );
    return _buildInfoRow(display.label, display.value);
  }

  _TelemetryFieldDisplay _formatTelemetryField(
    String key,
    dynamic value,
    int channel,
    bool isImperialUnits,
  ) {
    final l10n = context.l10n;
    final text = _telemetryValueText(value);

    switch (key) {
      case 'digitalInput':
        return _TelemetryFieldDisplay(l10n.telemetry_digitalInputLabel, text);
      case 'digitalOutput':
        return _TelemetryFieldDisplay(l10n.telemetry_digitalOutputLabel, text);
      case 'analogInput':
        return _TelemetryFieldDisplay(
          l10n.telemetry_analogInputLabel,
          l10n.telemetry_analogValue(text),
        );
      case 'analogOutput':
        return _TelemetryFieldDisplay(
          l10n.telemetry_analogOutputLabel,
          l10n.telemetry_analogValue(text),
        );
      case 'generic':
        return _TelemetryFieldDisplay(l10n.telemetry_genericLabel, text);
      case 'luminosity':
        return _TelemetryFieldDisplay(
          l10n.telemetry_luminosityLabel,
          l10n.telemetry_luminosityValue(text),
        );
      case 'presence':
        return _TelemetryFieldDisplay(l10n.telemetry_presenceLabel, text);
      case 'temperature':
        return _TelemetryFieldDisplay(
          channel == 1
              ? l10n.telemetry_mcuTemperatureLabel
              : l10n.telemetry_temperatureLabel,
          _temperatureText(value, isImperialUnits),
        );
      case 'humidity':
        return _TelemetryFieldDisplay(l10n.telemetry_humidityLabel, text);
      case 'accelerometer':
        return _TelemetryFieldDisplay(
          l10n.telemetry_accelerometerLabel,
          _telemetryAxisText(value),
        );
      case 'pressure':
        return _TelemetryFieldDisplay(
          l10n.telemetry_pressureLabel,
          l10n.telemetry_pressureValue(text),
        );
      case 'altitude':
        return _TelemetryFieldDisplay(
          l10n.telemetry_altitudeLabel,
          l10n.telemetry_altitudeValue(text),
        );
      case 'voltage':
        return _TelemetryFieldDisplay(
          channel == 1
              ? l10n.telemetry_batteryLabel
              : l10n.telemetry_voltageLabel,
          channel == 1
              ? _batteryText(value)
              : l10n.telemetry_voltageValue(text),
        );
      case 'current':
        return _TelemetryFieldDisplay(
          l10n.telemetry_currentLabel,
          l10n.telemetry_currentValue(text),
        );
      case 'frequency':
        return _TelemetryFieldDisplay(
          l10n.telemetry_frequencyLabel,
          l10n.telemetry_frequencyValue(text),
        );
      case 'percentage':
        return _TelemetryFieldDisplay(
          l10n.telemetry_percentageLabel,
          l10n.telemetry_percentageValue(text),
        );
      case 'concentration':
        return _TelemetryFieldDisplay(
          l10n.telemetry_concentrationLabel,
          l10n.telemetry_concentrationValue(text),
        );
      case 'power':
        return _TelemetryFieldDisplay(
          l10n.telemetry_powerLabel,
          l10n.telemetry_powerValue(text),
        );
      case 'distance':
        return _TelemetryFieldDisplay(
          l10n.telemetry_distanceLabel,
          l10n.telemetry_distanceValue(text),
        );
      case 'energy':
        return _TelemetryFieldDisplay(
          l10n.telemetry_energyLabel,
          l10n.telemetry_energyValue(text),
        );
      case 'direction':
        return _TelemetryFieldDisplay(
          l10n.telemetry_directionLabel,
          l10n.telemetry_directionValue(text),
        );
      case 'time':
        return _TelemetryFieldDisplay(
          l10n.telemetry_timeLabel,
          _telemetryTimeText(value),
        );
      case 'gyrometer':
        return _TelemetryFieldDisplay(
          l10n.telemetry_gyrometerLabel,
          _telemetryAxisText(value),
        );
      case 'colour':
        return _TelemetryFieldDisplay(
          l10n.telemetry_colourLabel,
          _telemetryColorText(value),
        );
      case 'switch':
        return _TelemetryFieldDisplay(l10n.telemetry_switchLabel, text);
      case 'polyline':
        return _TelemetryFieldDisplay(
          l10n.telemetry_polylineLabel,
          _telemetryMapText(value),
        );
      default:
        return _TelemetryFieldDisplay(key, text);
    }
  }

  Widget _buildAutoRefreshCard() {
    final l10n = context.l10n;
    final counterText = _autoRefreshCounterText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          l10n.common_autoRefresh,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        ),
        MeshCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAutoRefreshNumberField(
                controller: _autoRefreshIntervalController,
                label: l10n.common_interval,
                min: _autoRefreshMinIntervalSeconds,
                max: _autoRefreshMaxIntervalSeconds,
                fallback: _autoRefreshIntervalSeconds,
              ),
              const SizedBox(height: 12),
              _buildAutoRefreshNumberField(
                controller: _autoRefreshQuantityController,
                label: l10n.telemetry_autoFetchQuantity,
                min: _autoRefreshMinQuantity,
                max: _autoRefreshMaxQuantity,
                fallback: _autoRefreshDefaultQuantity,
              ),
              if (counterText != null) ...[
                const SizedBox(height: 12),
                Text(
                  counterText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _autoRefreshLastAttemptFailed
                        ? Theme.of(context).colorScheme.error
                        : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isLoading && !_isAutoRefreshEnabled
                    ? null
                    : _toggleAutoRefresh,
                child: _isAutoRefreshEnabled
                    ? SizedBox(
                        width: double.infinity,
                        height: 20,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(child: Text(l10n.common_disable)),
                            Positioned(
                              right: 0,
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(l10n.common_enable),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoRefreshNumberField({
    required TextEditingController controller,
    required String label,
    required int min,
    required int max,
    required int fallback,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isAutoRefreshEnabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onEditingComplete: () {
        _clampControllerValue(
          controller: controller,
          min: min,
          max: max,
          fallback: fallback,
        );
        unawaited(_saveAutoRefreshSettings());
        FocusScope.of(context).unfocus();
      },
      onSubmitted: (_) => unawaited(_saveAutoRefreshSettings()),
      onTapOutside: (_) {
        unawaited(_saveAutoRefreshSettings());
        FocusScope.of(context).unfocus();
      },
    );
  }

  String? _autoRefreshCounterText() {
    if (!_isAutoRefreshEnabled && _autoRefreshCurrentAttempt == 0) return null;
    final counter = '$_autoRefreshCurrentAttempt/$_autoRefreshTotalAttempts';
    if (_autoRefreshLastAttemptFailed) {
      return '${context.l10n.telemetry_error}: $counter';
    }
    return counter;
  }

  void _toggleAutoRefresh() {
    if (_isAutoRefreshEnabled) {
      _stopAutoRefresh();
      return;
    }
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    final interval = _clampControllerValue(
      controller: _autoRefreshIntervalController,
      min: _autoRefreshMinIntervalSeconds,
      max: _autoRefreshMaxIntervalSeconds,
      fallback: _autoRefreshIntervalSeconds,
    );
    final quantity = _clampControllerValue(
      controller: _autoRefreshQuantityController,
      min: _autoRefreshMinQuantity,
      max: _autoRefreshMaxQuantity,
      fallback: _autoRefreshDefaultQuantity,
    );
    unawaited(_saveAutoRefreshSettings());

    setState(() {
      _isAutoRefreshEnabled = true;
      _autoRefreshIntervalSeconds = interval;
      _autoRefreshTotalAttempts = quantity;
      _autoRefreshCurrentAttempt = 0;
      _autoRefreshLastAttemptFailed = false;
    });
    _runAutoRefreshAttempt();
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    if (!mounted) return;
    setState(() {
      _isAutoRefreshEnabled = false;
    });
  }

  Future<void> _runAutoRefreshAttempt() async {
    if (!_isAutoRefreshEnabled || !mounted) return;
    if (_autoRefreshCurrentAttempt >= _autoRefreshTotalAttempts) {
      _stopAutoRefresh();
      return;
    }

    setState(() {
      _autoRefreshCurrentAttempt += 1;
    });
    await _loadTelemetry(isAutoRefresh: true);
  }

  void _scheduleNextAutoRefreshAttempt() {
    if (!_isAutoRefreshEnabled || !mounted) return;
    _autoRefreshTimer?.cancel();
    if (_autoRefreshCurrentAttempt >= _autoRefreshTotalAttempts) {
      _stopAutoRefresh();
      return;
    }
    // Start the interval only after the current request has finished: after a
    // telemetry response, timeout, or send error. This keeps slow replies from
    // shortening the intended pause between requests.
    _autoRefreshTimer = Timer(
      Duration(seconds: _autoRefreshIntervalSeconds),
      _runAutoRefreshAttempt,
    );
  }

  int _clampControllerValue({
    required TextEditingController controller,
    required int min,
    required int max,
    required int fallback,
  }) {
    final parsed = int.tryParse(controller.text);
    final value = (parsed ?? fallback).clamp(min, max).toInt();
    controller.text = value.toString();
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    return value;
  }

  Widget _buildGpsInfo(dynamic value) {
    final latitude = _readGpsValue(value, 'latitude');
    final longitude = _readGpsValue(value, 'longitude');
    final altitude = _readGpsValue(value, 'altitude');
    final isValidPosition = _isValidGpsPosition(latitude, longitude);
    final gpsText = isValidPosition
        ? [
            latitude!.toStringAsFixed(5),
            longitude!.toStringAsFixed(5),
            if (altitude != null) '${altitude.toStringAsFixed(1)} m',
          ].join(', ')
        : value.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(context.l10n.telemetry_gpsLabel, gpsText),
        if (isValidPosition)
          TelemetryLocationMap(
            // The map renders only after bounds validation, keeping malformed
            // Cayenne payloads from creating an invalid FlutterMap center.
            latitude: latitude!,
            longitude: longitude!,
            label: widget.contact.name,
            contactType: widget.contact.type,
            contactPublicKeyHex: widget.contact.publicKeyHex,
          ),
      ],
    );
  }

  double? _readGpsValue(dynamic value, String key) {
    if (value is! Map) return null;
    final rawValue = value[key];
    if (rawValue is num) return rawValue.toDouble();
    return null;
  }

  bool _isValidGpsPosition(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    const double epsilon = 1e-6;
    return (latitude.abs() > epsilon || longitude.abs() > epsilon) &&
        latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
  }

  String _telemetryValueText(dynamic value) {
    if (value == null) return context.l10n.common_notAvailable;
    if (value is double) {
      return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    }
    if (value is num) {
      return value.toString();
    }
    return value.toString();
  }

  String _telemetryAxisText(dynamic value) {
    if (value is! Map) return _telemetryValueText(value);
    final x = _telemetryValueText(value['x']);
    final y = _telemetryValueText(value['y']);
    final z = _telemetryValueText(value['z']);
    return 'X: $x, Y: $y, Z: $z';
  }

  String _telemetryColorText(dynamic value) {
    if (value is! Map) return _telemetryValueText(value);
    final red = _telemetryValueText(value['red']);
    final green = _telemetryValueText(value['green']);
    final blue = _telemetryValueText(value['blue']);
    return 'R: $red, G: $green, B: $blue';
  }

  String _telemetryMapText(dynamic value) {
    if (value is! Map) return _telemetryValueText(value);
    return value.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }

  String _telemetryTimeText(dynamic value) {
    if (value is! num || value <= 0) return _telemetryValueText(value);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      value.toInt() * 1000,
      isUtc: true,
    ).toLocal();
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );
    return '${localizations.formatFullDate(dateTime)} $time';
  }

  Widget _buildInfoRow(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: MeshTheme.mono(fontSize: 13, color: scheme.onSurface),
            textAlign: TextAlign.end,
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

class _TelemetryFieldDisplay {
  final String label;
  final String value;

  const _TelemetryFieldDisplay(this.label, this.value);
}
