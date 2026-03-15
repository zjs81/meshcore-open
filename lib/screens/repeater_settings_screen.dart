import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../services/app_debug_log_service.dart';
import '../services/repeater_command_service.dart';
import '../widgets/path_management_dialog.dart';

class RepeaterSettingsScreen extends StatefulWidget {
  final Contact repeater;
  final String password;

  const RepeaterSettingsScreen({
    super.key,
    required this.repeater,
    required this.password,
  });

  @override
  State<RepeaterSettingsScreen> createState() => _RepeaterSettingsScreenState();
}

class _RepeaterSettingsScreenState extends State<RepeaterSettingsScreen> {
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _refreshingBasic = false;
  bool _refreshingRadio = false;
  bool _refreshingTxPower = false;
  bool _refreshingLocation = false;
  bool _refreshingRepeat = false;
  bool _refreshingAllowReadOnly = false;
  bool _refreshingAdvertisement = false;
  bool _refreshingAdvanced = false;
  bool _refreshingIntThresh = false;
  bool _refreshingAgcResetInterval = false;
  bool _refreshingFloodMax = false;
  bool _refreshingMultiAcks = false;
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;
  final Set<String> _modifiedSettings = <String>{};
  final Map<String, Object?> _baselineValues = <String, Object?>{};

  // Basic settings
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _guestPasswordController =
      TextEditingController();

  // Advanced settings
  final TextEditingController _intThreshController = TextEditingController();
  final TextEditingController _agcResetIntervalController =
      TextEditingController();
  final TextEditingController _floodMaxController = TextEditingController();
  bool _multiAcksEnabled = false;

  // Radio settings
  final TextEditingController _freqController = TextEditingController();
  final TextEditingController _txPowerController = TextEditingController();
  int? _bandwidth;
  int? _spreadingFactor;
  int? _codingRate;

  // Location settings
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  // Feature toggles
  bool _repeatEnabled = true;
  bool _allowReadOnly = true;
  bool _privacyMode = false;

  // Advertisement settings
  bool _advertEnable = true;
  int _advertInterval = 120; // minutes/2
  bool _floodAdvertEnable = true;
  int _floodAdvertInterval = 12; // hours
  int _privAdvertInterval = 60; // minutes

  final List<int> _bandwidthOptions = [
    7800,
    10400,
    15600,
    20800,
    31250,
    41700,
    62500,
    125000,
    250000,
    500000,
  ];
  final List<int> _spreadingFactorOptions = [5, 6, 7, 8, 9, 10, 11, 12];
  final List<int> _codingRateOptions = [5, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _commandService = RepeaterCommandService(connector);
    _setupMessageListener();
    _loadSettings();
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _commandService?.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _guestPasswordController.dispose();
    _intThreshController.dispose();
    _agcResetIntervalController.dispose();
    _floodMaxController.dispose();
    _freqController.dispose();
    _txPowerController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _setupMessageListener() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);

    // Listen for incoming text messages from the repeater
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;

      // Check if it's a text message response
      if (frame[0] == respCodeContactMsgRecv ||
          frame[0] == respCodeContactMsgRecvV3) {
        _handleTextMessageResponse(frame);
      }
    });
  }

  void _handleTextMessageResponse(Uint8List frame) {
    final parsed = parseContactMessageText(frame);
    if (parsed == null) return;
    if (!_matchesRepeaterPrefix(parsed.senderPrefix)) return;

    // Notify command service of response (for retry handling)
    _commandService?.handleResponse(widget.repeater, parsed.text);
  }

  Contact _resolveRepeater(MeshCoreConnector connector) {
    return connector.contacts.firstWhere(
      (c) => c.publicKeyHex == widget.repeater.publicKeyHex,
      orElse: () => widget.repeater,
    );
  }

  bool _matchesRepeaterPrefix(Uint8List prefix) {
    final target = widget.repeater.publicKey;
    if (target.length < 6 || prefix.length < 6) return false;
    for (int i = 0; i < 6; i++) {
      if (prefix[i] != target[i]) return false;
    }
    return true;
  }

  void _updateUIFromFetchedSettings(Map<String, String> fetchedSettings) {
    if (fetchedSettings.isEmpty) return;

    final appLog = Provider.of<AppDebugLogService>(context, listen: false);
    appLog.info(
      'Updating UI with keys: ${fetchedSettings.keys.toList()}',
      tag: 'RadioSettings',
    );

    setState(() {
      // Update name
      if (fetchedSettings.containsKey('name')) {
        _nameController.text = fetchedSettings['name']!;
        _setBaselineValue('name', _normalizedText(_nameController));
      }

      // Update radio settings - parse "908.205017,62.5,10,7" format
      // Format: freq_mhz,bandwidth_khz,spreading_factor,coding_rate
      if (fetchedSettings.containsKey('radio')) {
        final appLog = Provider.of<AppDebugLogService>(context, listen: false);
        final radioStr = fetchedSettings['radio']!;
        appLog.info('Raw radio string: "$radioStr"', tag: 'RadioSettings');
        final parts = radioStr.split(',');
        appLog.info(
          'Split into ${parts.length} parts: $parts',
          tag: 'RadioSettings',
        );

        if (parts.isNotEmpty) {
          final freqText = parts[0].replaceAll(RegExp(r'[^0-9.]'), '').trim();
          appLog.info('Frequency text: "$freqText"', tag: 'RadioSettings');
          if (freqText.isNotEmpty) {
            _freqController.text = freqText;
          }
        }
        if (parts.length > 1) {
          final bwText = parts[1].replaceAll(RegExp(r'[^0-9.]'), '').trim();
          appLog.info('Bandwidth text: "$bwText"', tag: 'RadioSettings');
          final bw = double.tryParse(bwText);
          if (bw != null) {
            _bandwidth = (bw * 1000).toInt();
            appLog.info('Bandwidth Hz: $_bandwidth', tag: 'RadioSettings');
            if (_bandwidth != null && !_bandwidthOptions.contains(_bandwidth)) {
              _bandwidthOptions.add(_bandwidth!);
              _bandwidthOptions.sort();
            }
          }
        }
        if (parts.length > 2) {
          final sfText = parts[2].replaceAll(RegExp(r'[^0-9]'), '').trim();
          appLog.info('SF text: "$sfText"', tag: 'RadioSettings');
          _spreadingFactor = int.tryParse(sfText) ?? _spreadingFactor;
        }
        if (parts.length > 3) {
          final crText = parts[3].replaceAll(RegExp(r'[^0-9]'), '').trim();
          appLog.info('CR text: "$crText"', tag: 'RadioSettings');
          _codingRate = int.tryParse(crText) ?? _codingRate;
        }
        appLog.info(
          'Final values: freq=${_freqController.text}, bw=$_bandwidth, sf=$_spreadingFactor, cr=$_codingRate',
          tag: 'RadioSettings',
        );
        _setBaselineValue('radio', _radioSignature());
      }

      if (fetchedSettings.containsKey('tx')) {
        final txValue = fetchedSettings['tx']!;
        // Extract just the power value - format is typically "10" or "10 dBm"
        final powerStr = txValue.replaceAll(RegExp(r'[^0-9-]'), '');
        final powerInt = int.tryParse(powerStr);
        if (powerInt != null && powerInt >= 1 && powerInt <= 30) {
          _txPowerController.text = powerInt.toString();
          _setBaselineValue('tx', _normalizedText(_txPowerController));
        }
      }

      if (fetchedSettings.containsKey('lat')) {
        appLog.info(
          'Setting lat to: "${fetchedSettings['lat']}"',
          tag: 'RadioSettings',
        );
        _latController.text = fetchedSettings['lat']!;
        _setBaselineValue('lat', _normalizedText(_latController));
      }
      if (fetchedSettings.containsKey('lon')) {
        appLog.info(
          'Setting lon to: "${fetchedSettings['lon']}"',
          tag: 'RadioSettings',
        );
        _lonController.text = fetchedSettings['lon']!;
        _setBaselineValue('lon', _normalizedText(_lonController));
      }

      if (fetchedSettings.containsKey('repeat')) {
        _repeatEnabled = _normalizeOnOff(fetchedSettings['repeat']!);
        _setBaselineValue('repeat', _repeatEnabled);
      }
      if (fetchedSettings.containsKey('allow.read.only')) {
        _allowReadOnly = _normalizeOnOff(fetchedSettings['allow.read.only']!);
        _setBaselineValue('allow.read.only', _allowReadOnly);
      }
      if (fetchedSettings.containsKey('privacy')) {
        _privacyMode = _normalizeOnOff(fetchedSettings['privacy']!);
        _setBaselineValue('privacy', _privacyMode);
      }

      if (fetchedSettings.containsKey('advert.interval')) {
        _advertInterval = _parseIntWithFallback(
          fetchedSettings['advert.interval']!,
          _advertInterval,
        );
        _advertEnable = _advertInterval > 0;
        _setBaselineValue('advert.interval', _advertInterval);
      }
      if (fetchedSettings.containsKey('flood.advert.interval')) {
        _floodAdvertInterval = _parseIntWithFallback(
          fetchedSettings['flood.advert.interval']!,
          _floodAdvertInterval,
        );
        _floodAdvertEnable = _floodAdvertInterval > 0;
        _setBaselineValue('flood.advert.interval', _floodAdvertInterval);
      }
      if (fetchedSettings.containsKey('priv.advert.interval')) {
        _privAdvertInterval = _parseIntWithFallback(
          fetchedSettings['priv.advert.interval']!,
          _privAdvertInterval,
        );
        _setBaselineValue('priv.advert.interval', _privAdvertInterval);
      }

      if (fetchedSettings.containsKey('int.thresh')) {
        final threshold = _parseIntWithFallback(
          fetchedSettings['int.thresh']!,
          14,
        );
        _intThreshController.text = threshold.toString();
        _setBaselineValue('int.thresh', _normalizedText(_intThreshController));
      }
      if (fetchedSettings.containsKey('agc.reset.interval')) {
        final seconds = _parseIntWithFallback(
          fetchedSettings['agc.reset.interval']!,
          0,
        );
        _agcResetIntervalController.text = seconds.toString();
        _setBaselineValue(
          'agc.reset.interval',
          _normalizedText(_agcResetIntervalController),
        );
      }
      if (fetchedSettings.containsKey('flood.max')) {
        final maxHops = _parseIntWithFallback(fetchedSettings['flood.max']!, 4);
        _floodMaxController.text = maxHops.toString();
        _setBaselineValue('flood.max', _normalizedText(_floodMaxController));
      }
      if (fetchedSettings.containsKey('multi.acks')) {
        final value = fetchedSettings['multi.acks']!.trim().toLowerCase();
        _multiAcksEnabled = value == '1' || value == 'on' || value == 'true';
        _setBaselineValue('multi.acks', _multiAcksEnabled);
      }

      _hasChanges = _modifiedSettings.isNotEmpty;
    });
  }

  bool _normalizeOnOff(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'on' ||
        normalized == 'true' ||
        normalized == '1' ||
        normalized == 'enabled';
  }

  int _parseIntWithFallback(String value, int fallback) {
    final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));
    return parsed ?? fallback;
  }

  int _parseRequiredNonNegativeIntForSave(String value, String label) {
    final trimmed = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      throw FormatException('$label must be a non-negative whole number.');
    }
    return int.parse(trimmed);
  }

  int _parseRequiredIntInRangeForSave(
    String value,
    String label, {
    required int min,
    required int max,
  }) {
    final trimmed = value.trim();
    if (!RegExp(r'^-?\d+$').hasMatch(trimmed)) {
      throw FormatException('$label must be a whole number.');
    }
    final parsed = int.parse(trimmed);
    if (parsed < min || parsed > max) {
      throw FormatException('$label must be between $min and $max.');
    }
    return parsed;
  }

  String _normalizedText(TextEditingController controller) {
    return controller.text.trim();
  }

  String _radioSignature() {
    return [
      _normalizedText(_freqController),
      _bandwidth?.toString() ?? '',
      _spreadingFactor?.toString() ?? '',
      _codingRate?.toString() ?? '',
    ].join('|');
  }

  void _setBaselineValue(String key, Object? value) {
    _baselineValues[key] = value;
    _modifiedSettings.remove(key);
  }

  void _syncModifiedSetting(String key, Object? value) {
    if (_baselineValues.containsKey(key) && _baselineValues[key] == value) {
      _modifiedSettings.remove(key);
    } else {
      _modifiedSettings.add(key);
    }

    final hasChanges = _modifiedSettings.isNotEmpty;
    if (_hasChanges != hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _commitSavedChanges(Set<String> savedKeys) {
    if (savedKeys.contains('name')) {
      _setBaselineValue('name', _normalizedText(_nameController));
    }
    if (savedKeys.contains('password')) {
      _setBaselineValue('password', _normalizedText(_passwordController));
    }
    if (savedKeys.contains('guest.password')) {
      _setBaselineValue(
        'guest.password',
        _normalizedText(_guestPasswordController),
      );
    }
    if (savedKeys.contains('radio')) {
      _setBaselineValue('radio', _radioSignature());
    }
    if (savedKeys.contains('tx')) {
      _setBaselineValue('tx', _normalizedText(_txPowerController));
    }
    if (savedKeys.contains('lat')) {
      _setBaselineValue('lat', _normalizedText(_latController));
    }
    if (savedKeys.contains('lon')) {
      _setBaselineValue('lon', _normalizedText(_lonController));
    }
    if (savedKeys.contains('repeat')) {
      _setBaselineValue('repeat', _repeatEnabled);
    }
    if (savedKeys.contains('allow.read.only')) {
      _setBaselineValue('allow.read.only', _allowReadOnly);
    }
    if (savedKeys.contains('privacy')) {
      _setBaselineValue('privacy', _privacyMode);
    }
    if (savedKeys.contains('advert.interval')) {
      _setBaselineValue('advert.interval', _advertInterval);
    }
    if (savedKeys.contains('flood.advert.interval')) {
      _setBaselineValue('flood.advert.interval', _floodAdvertInterval);
    }
    if (savedKeys.contains('priv.advert.interval')) {
      _setBaselineValue('priv.advert.interval', _privAdvertInterval);
    }
    if (savedKeys.contains('int.thresh')) {
      _setBaselineValue('int.thresh', _normalizedText(_intThreshController));
    }
    if (savedKeys.contains('agc.reset.interval')) {
      _setBaselineValue(
        'agc.reset.interval',
        _normalizedText(_agcResetIntervalController),
      );
    }
    if (savedKeys.contains('flood.max')) {
      _setBaselineValue('flood.max', _normalizedText(_floodMaxController));
    }
    if (savedKeys.contains('multi.acks')) {
      _setBaselineValue('multi.acks', _multiAcksEnabled);
    }
  }

  String _formatBandwidthLabel(int bandwidthHz) {
    final bandwidthKHz = bandwidthHz / 1000;
    var text = bandwidthKHz.toStringAsFixed(2);
    text = text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$text kHz';
  }

  void _applySettingResponse(
    String command,
    String response,
    Map<String, String> fetchedSettings,
  ) {
    final appLog = Provider.of<AppDebugLogService>(context, listen: false);
    appLog.info(
      'Command: "$command", Raw response: "$response"',
      tag: 'RadioSettings',
    );
    final value = _extractCliValue(response);
    appLog.info('Extracted value: "$value"', tag: 'RadioSettings');
    if (value == null) return;

    final normalized = command.trim().toLowerCase();
    if (!normalized.startsWith('get ')) return;
    final key = normalized.substring(4);

    // Validate response content matches expected format for the command
    // This prevents mismatched responses over LoRa where order isn't guaranteed
    if (!_validateResponseForCommand(key, value)) {
      appLog.warn(
        'Response "$value" does not match expected format for "$key", ignoring',
        tag: 'RadioSettings',
      );
      return;
    }

    switch (key) {
      case 'name':
      case 'radio':
      case 'tx':
      case 'lat':
      case 'lon':
      case 'repeat':
      case 'allow.read.only':
      case 'privacy':
      case 'advert.interval':
      case 'flood.advert.interval':
      case 'priv.advert.interval':
      case 'int.thresh':
      case 'agc.reset.interval':
      case 'flood.max':
      case 'multi.acks':
        appLog.info('Storing key="$key" value="$value"', tag: 'RadioSettings');
        fetchedSettings[key] = value;
        break;
    }
  }

  /// Validates that a response value matches the expected format for a given command.
  /// Returns true if the response appears valid for the command type.
  bool _validateResponseForCommand(String key, String value) {
    switch (key) {
      case 'radio':
        // Radio format: "freq,bw,sf,cr" e.g., "908.205017,62.5,10,7"
        // Must have at least 3 commas and start with a frequency-like number
        final parts = value.split(',');
        if (parts.length < 4) return false;
        final freq = double.tryParse(
          parts[0].replaceAll(RegExp(r'[^0-9.]'), ''),
        );
        // Frequency should be in reasonable LoRa range (300-2500 MHz)
        return freq != null && freq >= 300 && freq <= 2500;

      case 'tx':
        // TX power: single integer 1-30
        final power = int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));
        // Must NOT contain commas (distinguishes from radio format)
        if (value.contains(',')) return false;
        return power != null && power >= 1 && power <= 30;

      case 'lat':
        // Latitude: decimal number between -90 and 90
        if (value.contains(',')) return false; // Not radio format
        final lat = double.tryParse(value.replaceAll(RegExp(r'[^0-9.\-]'), ''));
        return lat != null && lat >= -90 && lat <= 90;

      case 'lon':
        // Longitude: decimal number between -180 and 180
        if (value.contains(',')) return false; // Not radio format
        final lon = double.tryParse(value.replaceAll(RegExp(r'[^0-9.\-]'), ''));
        return lon != null && lon >= -180 && lon <= 180;

      case 'repeat':
      case 'allow.read.only':
      case 'privacy':
        // Boolean values: on/off/true/false/1/0/enabled/disabled
        final lower = value.toLowerCase().trim();
        return [
          'on',
          'off',
          'true',
          'false',
          '1',
          '0',
          'enabled',
          'disabled',
        ].contains(lower);

      case 'advert.interval':
      case 'flood.advert.interval':
      case 'priv.advert.interval':
      case 'int.thresh':
      case 'agc.reset.interval':
      case 'flood.max':
        // Interval/threshold: non-negative integer (0 means disabled)
        if (value.contains(',')) return false;
        final interval = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
        return interval != null && interval >= 0;

      case 'multi.acks':
        final lower = value.toLowerCase().trim();
        return ['on', 'off', 'true', 'false', '1', '0'].contains(lower);

      case 'name':
        // Name: any non-empty string, but should NOT look like radio settings
        if (value.isEmpty) return false;
        // If it has 3+ commas and looks like numbers, probably radio data
        final commaCount = ','.allMatches(value).length;
        if (commaCount >= 3 && RegExp(r'^[\d.,\s]+$').hasMatch(value)) {
          return false;
        }
        return true;

      default:
        // Unknown keys - accept any value
        return true;
    }
  }

  String? _extractCliValue(String response) {
    final lines = response.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('>')) {
        final value = trimmed.substring(1).trim();
        if (value.isNotEmpty) return value;
      }
      final colonIndex = trimmed.indexOf(':');
      if (colonIndex > 0) {
        final value = trimmed.substring(colonIndex + 1).trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  Future<void> _refreshSection({
    required String label,
    required List<String> commands,
    required ValueSetter<bool> setRefreshing,
  }) async {
    if (_commandService == null) return;
    final l10n = context.l10n;
    final fetchedSettings = <String, String>{};

    setState(() {
      setRefreshing(true);
    });

    var successCount = 0;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);
    for (final command in commands) {
      try {
        final response = await _commandService!.sendCommand(
          repeater,
          command,
          retries: 1,
        );
        _applySettingResponse(command, response, fetchedSettings);
        successCount += 1;
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('Error fetching $command: $e');
      }
    }

    if (mounted) {
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.repeater_refreshed(label)),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.repeater_errorRefreshing(label)),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (fetchedSettings.isNotEmpty) {
        _updateUIFromFetchedSettings(fetchedSettings);
      }
      setState(() {
        setRefreshing(false);
      });
    }
  }

  Future<void> _refreshBasicSettings() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_basicSettings,
      commands: const ['get name'],
      setRefreshing: (value) => _refreshingBasic = value,
    );
  }

  Future<void> _refreshRadioSettings() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_radioSettings,
      commands: const ['get radio'],
      setRefreshing: (value) => _refreshingRadio = value,
    );
  }

  Future<void> _refreshTxPower() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_txPower,
      commands: const ['get tx'],
      setRefreshing: (value) => _refreshingTxPower = value,
    );
  }

  Future<void> _refreshLocationSettings() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_locationSettings,
      commands: const ['get lat', 'get lon'],
      setRefreshing: (value) => _refreshingLocation = value,
    );
  }

  Future<void> _refreshRepeat() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_packetForwarding,
      commands: const ['get repeat'],
      setRefreshing: (value) => _refreshingRepeat = value,
    );
  }

  Future<void> _refreshAllowReadOnly() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_guestAccess,
      commands: const ['get allow.read.only'],
      setRefreshing: (value) => _refreshingAllowReadOnly = value,
    );
  }

  Future<void> _refreshAdvertisementSettings() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_advertisementSettings,
      commands: const [
        'get advert.interval',
        'get flood.advert.interval',
        // 'get priv.advert.interval', // Hidden until privacy mode is implemented
      ],
      setRefreshing: (value) => _refreshingAdvertisement = value,
    );
  }

  Future<void> _refreshAdvancedSettings() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_advancedSettings,
      commands: const [
        'get int.thresh',
        'get agc.reset.interval',
        'get flood.max',
        'get multi.acks',
      ],
      setRefreshing: (value) => _refreshingAdvanced = value,
    );
  }

  Future<void> _refreshInterferenceThreshold() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_interferenceThreshold,
      commands: const ['get int.thresh'],
      setRefreshing: (value) => _refreshingIntThresh = value,
    );
  }

  Future<void> _refreshAgcResetInterval() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_agcResetInterval,
      commands: const ['get agc.reset.interval'],
      setRefreshing: (value) => _refreshingAgcResetInterval = value,
    );
  }

  Future<void> _refreshFloodMax() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_floodMaxHops,
      commands: const ['get flood.max'],
      setRefreshing: (value) => _refreshingFloodMax = value,
    );
  }

  Future<void> _refreshMultiAcks() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_multiAcks,
      commands: const ['get multi.acks'],
      setRefreshing: (value) => _refreshingMultiAcks = value,
    );
  }

  Future<void> _loadSettings() async {
    // Just populate with current repeater data on initial load
    // User must click sync button to fetch from device
    setState(() {
      _nameController.text = widget.repeater.name;

      if (widget.repeater.hasLocation) {
        _latController.text = widget.repeater.latitude?.toString() ?? '';
        _lonController.text = widget.repeater.longitude?.toString() ?? '';
      }
      _setBaselineValue('name', _normalizedText(_nameController));
      _setBaselineValue('password', _normalizedText(_passwordController));
      _setBaselineValue(
        'guest.password',
        _normalizedText(_guestPasswordController),
      );
      _setBaselineValue('radio', _radioSignature());
      _setBaselineValue('tx', _normalizedText(_txPowerController));
      _setBaselineValue('lat', _normalizedText(_latController));
      _setBaselineValue('lon', _normalizedText(_lonController));
      _setBaselineValue('repeat', _repeatEnabled);
      _setBaselineValue('allow.read.only', _allowReadOnly);
      _setBaselineValue('privacy', _privacyMode);
      _setBaselineValue('advert.interval', _advertInterval);
      _setBaselineValue('flood.advert.interval', _floodAdvertInterval);
      _setBaselineValue('priv.advert.interval', _privAdvertInterval);
      _setBaselineValue('int.thresh', _normalizedText(_intThreshController));
      _setBaselineValue(
        'agc.reset.interval',
        _normalizedText(_agcResetIntervalController),
      );
      _setBaselineValue('flood.max', _normalizedText(_floodMaxController));
      _setBaselineValue('multi.acks', _multiAcksEnabled);
      _hasChanges = false;
    });
  }

  Future<void> _saveSettings() async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);
    final l10n = context.l10n;

    setState(() {
      _isLoading = true;
    });

    try {
      final selection = await connector.preparePathForContactSend(repeater);
      final commands = <String>[];
      final savedKeys = <String>{};

      // Build set commands for each setting
      if (_modifiedSettings.contains('name') &&
          _nameController.text.isNotEmpty) {
        commands.add('set name ${_nameController.text}');
        savedKeys.add('name');
      }

      if (_modifiedSettings.contains('password') &&
          _passwordController.text.isNotEmpty) {
        commands.add('password ${_passwordController.text}');
        savedKeys.add('password');
      }

      if (_modifiedSettings.contains('guest.password') &&
          _guestPasswordController.text.isNotEmpty) {
        commands.add('set guest.password ${_guestPasswordController.text}');
        savedKeys.add('guest.password');
      }

      // Radio parameters
      if (_modifiedSettings.contains('radio') &&
          _freqController.text.isNotEmpty &&
          _bandwidth != null &&
          _spreadingFactor != null &&
          _codingRate != null) {
        final freqMHz = double.tryParse(_freqController.text);
        if (freqMHz != null) {
          final bwKHz = _bandwidth! / 1000;
          commands.add(
            'set radio ${freqMHz.toStringAsFixed(1)} $bwKHz $_spreadingFactor $_codingRate',
          );
          savedKeys.add('radio');
        }
      }
      if (_modifiedSettings.contains('tx')) {
        final txPower = _parseRequiredIntInRangeForSave(
          _txPowerController.text,
          l10n.repeater_txPower,
          min: 1,
          max: 30,
        );
        commands.add('set tx $txPower');
        savedKeys.add('tx');
      }

      // Location
      if (_modifiedSettings.contains('lat') && _latController.text.isNotEmpty) {
        commands.add('set lat ${_latController.text}');
        savedKeys.add('lat');
      }
      if (_modifiedSettings.contains('lon') && _lonController.text.isNotEmpty) {
        commands.add('set lon ${_lonController.text}');
        savedKeys.add('lon');
      }

      // Feature toggles
      if (_modifiedSettings.contains('repeat')) {
        commands.add('set repeat ${_repeatEnabled ? "on" : "off"}');
        savedKeys.add('repeat');
      }
      if (_modifiedSettings.contains('allow.read.only')) {
        commands.add('set allow.read.only ${_allowReadOnly ? "on" : "off"}');
        savedKeys.add('allow.read.only');
      }
      if (_modifiedSettings.contains('privacy')) {
        commands.add('set privacy ${_privacyMode ? "on" : "off"}');
        savedKeys.add('privacy');
      }

      // Advertisement intervals
      if (_modifiedSettings.contains('advert.interval')) {
        commands.add('set advert.interval $_advertInterval');
        savedKeys.add('advert.interval');
      }
      if (_modifiedSettings.contains('flood.advert.interval')) {
        commands.add('set flood.advert.interval $_floodAdvertInterval');
        savedKeys.add('flood.advert.interval');
      }
      if (_privacyMode && _modifiedSettings.contains('priv.advert.interval')) {
        commands.add('set priv.advert.interval $_privAdvertInterval');
        savedKeys.add('priv.advert.interval');
      }

      // Advanced settings
      if (_modifiedSettings.contains('int.thresh')) {
        final intThresh = _parseRequiredNonNegativeIntForSave(
          _intThreshController.text,
          l10n.repeater_interferenceThreshold,
        );
        commands.add('set int.thresh $intThresh');
        savedKeys.add('int.thresh');
      }
      if (_modifiedSettings.contains('agc.reset.interval')) {
        final agcResetSeconds = _parseRequiredNonNegativeIntForSave(
          _agcResetIntervalController.text,
          l10n.repeater_agcResetInterval,
        );
        commands.add('set agc.reset.interval $agcResetSeconds');
        savedKeys.add('agc.reset.interval');
      }
      if (_modifiedSettings.contains('flood.max')) {
        final floodMax = _parseRequiredNonNegativeIntForSave(
          _floodMaxController.text,
          l10n.repeater_floodMaxHops,
        );
        commands.add('set flood.max $floodMax');
        savedKeys.add('flood.max');
      }
      if (_modifiedSettings.contains('multi.acks')) {
        commands.add('set multi.acks ${_multiAcksEnabled ? 1 : 0}');
        savedKeys.add('multi.acks');
      }

      if (commands.isEmpty) {
        throw const FormatException(
          'No valid modified fields are ready to save.',
        );
      }

      // Send all commands
      for (final command in commands) {
        final timestampSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        connector.trackRepeaterAck(
          contact: repeater,
          selection: selection,
          text: command,
          timestampSeconds: timestampSeconds,
        );
        final frame = buildSendCliCommandFrame(
          repeater.publicKey,
          command,
          timestampSeconds: timestampSeconds,
        );
        await connector.sendFrame(frame);
        await Future.delayed(
          const Duration(milliseconds: 200),
        ); // Delay between commands
      }

      setState(() {
        _commitSavedChanges(savedKeys);
        _isLoading = false;
        _hasChanges = _modifiedSettings.isNotEmpty;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.repeater_settingsSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.repeater_errorSavingSettings(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String tooltip,
    required bool isRefreshing,
    required VoidCallback onRefresh,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).textTheme.headlineSmall?.color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: isRefreshing ? null : onRefresh,
          tooltip: tooltip,
        ),
      ],
    );
  }

  Widget _buildInlineRefreshButton({
    required bool isRefreshing,
    required VoidCallback onRefresh,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: IconButton(
        icon: isRefreshing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh, size: 20),
        onPressed: isRefreshing ? null : onRefresh,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
      ),
    );
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
            Text(l10n.repeater_settingsTitle),
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
              if (mounted) {
                setState(() {});
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
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveSettings,
              icon: const Icon(Icons.save),
              label: Text(l10n.common_save),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading && _nameController.text.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBasicSettingsCard(),
                  const SizedBox(height: 16),
                  _buildRadioSettingsCard(),
                  const SizedBox(height: 16),
                  _buildLocationSettingsCard(),
                  const SizedBox(height: 16),
                  _buildFeatureTogglesCard(),
                  const SizedBox(height: 16),
                  _buildAdvertisementSettingsCard(),
                  const SizedBox(height: 16),
                  _buildAdvancedSettingsCard(),
                  const SizedBox(height: 32),
                  _buildDangerZoneCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildBasicSettingsCard() {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.settings,
              title: l10n.repeater_basicSettings,
              tooltip: l10n.repeater_refreshBasicSettings,
              isRefreshing: _refreshingBasic,
              onRefresh: _refreshBasicSettings,
            ),
            const Divider(),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.repeater_repeaterName,
                helperText: l10n.repeater_repeaterNameHelper,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _syncModifiedSetting(
                'name',
                _normalizedText(_nameController),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: l10n.repeater_adminPassword,
                helperText: l10n.repeater_adminPasswordHelper,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (_) => _syncModifiedSetting(
                'password',
                _normalizedText(_passwordController),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _guestPasswordController,
              decoration: InputDecoration(
                labelText: l10n.repeater_guestPassword,
                helperText: l10n.repeater_guestPasswordHelper,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (_) => _syncModifiedSetting(
                'guest.password',
                _normalizedText(_guestPasswordController),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioSettingsCard() {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.radio,
              title: l10n.repeater_radioSettings,
              tooltip: l10n.repeater_refreshRadioSettings,
              isRefreshing: _refreshingRadio,
              onRefresh: _refreshRadioSettings,
            ),
            const Divider(),
            TextField(
              controller: _freqController,
              decoration: InputDecoration(
                labelText: l10n.repeater_frequencyMhz,
                helperText: l10n.repeater_frequencyHelper,
                border: const OutlineInputBorder(),
                suffixText: 'MHz',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) =>
                  _syncModifiedSetting('radio', _radioSignature()),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _txPowerController,
                    decoration: InputDecoration(
                      labelText: l10n.repeater_txPower,
                      helperText: l10n.repeater_txPowerHelper,
                      border: const OutlineInputBorder(),
                      suffixText: 'dBm',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _syncModifiedSetting(
                      'tx',
                      _normalizedText(_txPowerController),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildInlineRefreshButton(
                  isRefreshing: _refreshingTxPower,
                  onRefresh: _refreshTxPower,
                  tooltip: l10n.repeater_refreshTxPower,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _bandwidth,
              decoration: InputDecoration(
                labelText: l10n.repeater_bandwidth,
                border: const OutlineInputBorder(),
              ),
              items: _bandwidthOptions.map((bw) {
                return DropdownMenuItem(
                  value: bw,
                  child: Text(_formatBandwidthLabel(bw)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _bandwidth = value;
                  });
                  _syncModifiedSetting('radio', _radioSignature());
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _spreadingFactor,
              decoration: InputDecoration(
                labelText: l10n.repeater_spreadingFactor,
                border: const OutlineInputBorder(),
              ),
              items: _spreadingFactorOptions.map((sf) {
                return DropdownMenuItem(value: sf, child: Text('SF$sf'));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _spreadingFactor = value;
                  });
                  _syncModifiedSetting('radio', _radioSignature());
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _codingRate,
              decoration: InputDecoration(
                labelText: l10n.repeater_codingRate,
                border: const OutlineInputBorder(),
              ),
              items: _codingRateOptions.map((cr) {
                return DropdownMenuItem(value: cr, child: Text('4/$cr'));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _codingRate = value;
                  });
                  _syncModifiedSetting('radio', _radioSignature());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSettingsCard() {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.location_on,
              title: l10n.repeater_locationSettings,
              tooltip: l10n.repeater_refreshLocationSettings,
              isRefreshing: _refreshingLocation,
              onRefresh: _refreshLocationSettings,
            ),
            const Divider(),
            TextField(
              controller: _latController,
              decoration: InputDecoration(
                labelText: l10n.repeater_latitude,
                helperText: l10n.repeater_latitudeHelper,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              onChanged: (_) =>
                  _syncModifiedSetting('lat', _normalizedText(_latController)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lonController,
              decoration: InputDecoration(
                labelText: l10n.repeater_longitude,
                helperText: l10n.repeater_longitudeHelper,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              onChanged: (_) =>
                  _syncModifiedSetting('lon', _normalizedText(_lonController)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTogglesCard() {
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
                  Icons.toggle_on,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.repeater_features,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildFeatureToggleRow(
              title: l10n.repeater_packetForwarding,
              subtitle: l10n.repeater_packetForwardingSubtitle,
              value: _repeatEnabled,
              isRefreshing: _refreshingRepeat,
              onChanged: (value) {
                setState(() {
                  _repeatEnabled = value;
                });
                _syncModifiedSetting('repeat', _repeatEnabled);
              },
              onRefresh: _refreshRepeat,
              refreshTooltip: l10n.repeater_refreshPacketForwarding,
            ),
            _buildFeatureToggleRow(
              title: l10n.repeater_guestAccess,
              subtitle: l10n.repeater_guestAccessSubtitle,
              value: _allowReadOnly,
              isRefreshing: _refreshingAllowReadOnly,
              onChanged: (value) {
                setState(() {
                  _allowReadOnly = value;
                });
                _syncModifiedSetting('allow.read.only', _allowReadOnly);
              },
              onRefresh: _refreshAllowReadOnly,
              refreshTooltip: l10n.repeater_refreshGuestAccess,
            ),
            // Privacy mode - hidden until fully implemented
            // _buildFeatureToggleRow(
            //   title: l10n.repeater_privacyMode,
            //   subtitle: l10n.repeater_privacyModeSubtitle,
            //   value: _privacyMode,
            //   isRefreshing: _refreshingPrivacy,
            //   onChanged: (value) {
            //     setState(() {
            //       _privacyMode = value;
            //     });
            //     _markChanged();
            //   },
            //   onRefresh: _refreshPrivacy,
            //   refreshTooltip: l10n.repeater_refreshPrivacyMode,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required bool isRefreshing,
    required ValueChanged<bool> onChanged,
    required VoidCallback onRefresh,
    required String refreshTooltip,
  }) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            title: Text(title),
            subtitle: Text(subtitle),
            value: value,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        IconButton(
          icon: isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 20),
          onPressed: isRefreshing ? null : onRefresh,
          tooltip: refreshTooltip,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildAdvertisementSettingsCard() {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.broadcast_on_personal,
              title: l10n.repeater_advertisementSettings,
              tooltip: l10n.repeater_refreshAdvertisementSettings,
              isRefreshing: _refreshingAdvertisement,
              onRefresh: _refreshAdvertisementSettings,
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.repeater_localAdvertInterval),
              subtitle: Text(
                l10n.repeater_localAdvertIntervalMinutes(_advertInterval),
              ),
              trailing: Switch(
                value: _advertEnable,
                onChanged: (value) {
                  setState(() {
                    _advertInterval = value ? 60 : 0;
                    _advertEnable = value;
                  });
                  _syncModifiedSetting('advert.interval', _advertInterval);
                },
              ),
            ),
            Slider(
              value: _advertInterval == 0
                  ? 60.toDouble()
                  : _advertInterval.toDouble(),
              min: 60,
              max: 240,
              divisions: 18,
              label: l10n.repeater_localAdvertIntervalMinutes(_advertInterval),
              onChanged: _advertEnable
                  ? (value) {
                      setState(() {
                        _advertInterval = value.toInt();
                      });
                      _syncModifiedSetting('advert.interval', _advertInterval);
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.repeater_floodAdvertInterval),
              subtitle: Text(
                l10n.repeater_floodAdvertIntervalHours(_floodAdvertInterval),
              ),
              trailing: Switch(
                value: _floodAdvertEnable,
                onChanged: (value) {
                  setState(() {
                    _floodAdvertInterval = value ? 3 : 0;
                    _floodAdvertEnable = value;
                  });
                  _syncModifiedSetting(
                    'flood.advert.interval',
                    _floodAdvertInterval,
                  );
                },
              ),
            ),
            Slider(
              value: _floodAdvertInterval == 0
                  ? 3.toDouble()
                  : _floodAdvertInterval.toDouble(),
              min: 3,
              max: 168,
              divisions: 165,
              label: l10n.repeater_floodAdvertIntervalHours(
                _floodAdvertInterval,
              ),
              onChanged: _floodAdvertEnable
                  ? (value) {
                      setState(() {
                        _floodAdvertInterval = value.toInt();
                      });
                      _syncModifiedSetting(
                        'flood.advert.interval',
                        _floodAdvertInterval,
                      );
                    }
                  : null,
            ),
            // Encrypted advertisement interval - hidden until privacy mode is implemented
            // if (_privacyMode) ...[
            //   const SizedBox(height: 16),
            //   ListTile(
            //     title: Text(l10n.repeater_encryptedAdvertInterval),
            //     subtitle: Text(l10n.repeater_localAdvertIntervalMinutes(_privAdvertInterval)),
            //     trailing: Text(l10n.repeater_localAdvertIntervalMinutes(_privAdvertInterval)),
            //   ),
            //   Slider(
            //     value: _privAdvertInterval.toDouble(),
            //     min: 30,
            //     max: 240,
            //     divisions: 21,
            //     label: l10n.repeater_localAdvertIntervalMinutes(_privAdvertInterval),
            //     onChanged: (value) {
            //       setState(() {
            //         _privAdvertInterval = value.toInt();
            //       });
            //       _markChanged();
            //     },
            //   ),
            // ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsCard() {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              icon: Icons.tune,
              title: l10n.repeater_advancedSettings,
              tooltip: l10n.repeater_refreshAdvancedSettings,
              isRefreshing: _refreshingAdvanced,
              onRefresh: _refreshAdvancedSettings,
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _intThreshController,
                    decoration: InputDecoration(
                      labelText: l10n.repeater_interferenceThreshold,
                      helperText: l10n.repeater_interferenceThresholdHelper,
                      border: const OutlineInputBorder(),
                      suffixText: 'dB',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _syncModifiedSetting(
                      'int.thresh',
                      _normalizedText(_intThreshController),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildInlineRefreshButton(
                  isRefreshing: _refreshingIntThresh,
                  onRefresh: _refreshInterferenceThreshold,
                  tooltip: l10n.repeater_refreshInterferenceThreshold,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _agcResetIntervalController,
                    decoration: InputDecoration(
                      labelText: l10n.repeater_agcResetInterval,
                      helperText: l10n.repeater_agcResetIntervalHelper,
                      border: const OutlineInputBorder(),
                      suffixText: 's',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _syncModifiedSetting(
                      'agc.reset.interval',
                      _normalizedText(_agcResetIntervalController),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildInlineRefreshButton(
                  isRefreshing: _refreshingAgcResetInterval,
                  onRefresh: _refreshAgcResetInterval,
                  tooltip: l10n.repeater_refreshAgcResetInterval,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _floodMaxController,
                    decoration: InputDecoration(
                      labelText: l10n.repeater_floodMaxHops,
                      helperText: l10n.repeater_floodMaxHopsHelper,
                      border: const OutlineInputBorder(),
                      suffixText: l10n.repeater_hopsShort,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _syncModifiedSetting(
                      'flood.max',
                      _normalizedText(_floodMaxController),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildInlineRefreshButton(
                  isRefreshing: _refreshingFloodMax,
                  onRefresh: _refreshFloodMax,
                  tooltip: l10n.repeater_refreshFloodMaxHops,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: Text(l10n.repeater_multiAcks),
                    subtitle: Text(l10n.repeater_multiAcksHelper),
                    value: _multiAcksEnabled,
                    onChanged: (value) {
                      setState(() {
                        _multiAcksEnabled = value;
                      });
                      _syncModifiedSetting('multi.acks', _multiAcksEnabled);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                IconButton(
                  icon: _refreshingMultiAcks
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 20),
                  onPressed: _refreshingMultiAcks ? null : _refreshMultiAcks,
                  tooltip: l10n.repeater_refreshMultiAcks,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Text(
                  l10n.repeater_dangerZone,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.refresh, color: colorScheme.onErrorContainer),
              title: Text(
                l10n.repeater_rebootRepeater,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
              subtitle: Text(
                l10n.repeater_rebootRepeaterSubtitle,
                style: TextStyle(
                  color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
                ),
              ),
              onTap: () => _confirmAction(
                l10n.repeater_rebootRepeater,
                l10n.repeater_rebootRepeaterConfirm,
                () => _sendDangerCommand('reboot'),
              ),
            ),
            // Regenerate identity key - hidden until fully implemented
            // ListTile(
            //   leading: Icon(Icons.vpn_key, color: colorScheme.onErrorContainer),
            //   title: Text('Regenerate Identity Key', style: TextStyle(color: colorScheme.onErrorContainer)),
            //   subtitle: Text(
            //     'Generate new public/private key pair',
            //     style: TextStyle(color: colorScheme.onErrorContainer.withValues(alpha: 0.8)),
            //   ),
            //   onTap: () => _confirmAction(
            //     'Regenerate Identity',
            //     'This will generate a new identity for the repeater. Continue?',
            //     () => _sendDangerCommand('regen key'),
            //   ),
            // ),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: colorScheme.onErrorContainer,
              ),
              title: Text(
                l10n.repeater_eraseFileSystem,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
              subtitle: Text(
                l10n.repeater_eraseFileSystemSubtitle,
                style: TextStyle(
                  color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
                ),
              ),
              onTap: () => _confirmAction(
                l10n.repeater_eraseFileSystem,
                l10n.repeater_eraseFileSystemConfirm,
                () => _sendDangerCommand('erase'),
                isDestructive: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendDangerCommand(String command) async {
    final l10n = context.l10n;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);

    if (command == 'erase') {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.repeater_eraseSerialOnly)));
      }
      return;
    }

    try {
      final selection = await connector.preparePathForContactSend(repeater);
      final timestampSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      connector.trackRepeaterAck(
        contact: repeater,
        selection: selection,
        text: command,
        timestampSeconds: timestampSeconds,
      );
      final frame = buildSendCliCommandFrame(
        repeater.publicKey,
        command,
        timestampSeconds: timestampSeconds,
      );
      await connector.sendFrame(frame);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.repeater_commandSent(command))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.repeater_errorSendingCommand(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmAction(
    String title,
    String message,
    VoidCallback onConfirm, {
    bool isDestructive = false,
  }) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(l10n.repeater_confirm),
          ),
        ],
      ),
    );
  }
}
