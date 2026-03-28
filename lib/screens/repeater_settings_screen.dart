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
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;
  final Map<String, String> _fetchedSettings = {};

  // Basic settings
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _guestPasswordController =
      TextEditingController();

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

  bool _matchesRepeaterPrefix(Uint8List prefix) {
    final target = widget.repeater.publicKey;
    if (target.length < 6 || prefix.length < 6) return false;
    for (int i = 0; i < 6; i++) {
      if (prefix[i] != target[i]) return false;
    }
    return true;
  }

  void _updateUIFromFetchedSettings() {
    if (_fetchedSettings.isEmpty) return;

    final appLog = Provider.of<AppDebugLogService>(context, listen: false);
    appLog.info(
      'Updating UI with keys: ${_fetchedSettings.keys.toList()}',
      tag: 'RadioSettings',
    );

    setState(() {
      // Update name
      if (_fetchedSettings.containsKey('name')) {
        _nameController.text = _fetchedSettings['name']!;
      }

      // Update radio settings - parse "908.205017,62.5,10,7" format
      // Format: freq_mhz,bandwidth_khz,spreading_factor,coding_rate
      if (_fetchedSettings.containsKey('radio')) {
        final appLog = Provider.of<AppDebugLogService>(context, listen: false);
        final radioStr = _fetchedSettings['radio']!;
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
      }

      if (_fetchedSettings.containsKey('tx')) {
        final txValue = _fetchedSettings['tx']!;
        // Extract just the power value - format is typically "10" or "10 dBm"
        final powerStr = txValue.replaceAll(RegExp(r'[^0-9-]'), '');
        final powerInt = int.tryParse(powerStr);
        if (powerInt != null && powerInt >= 1 && powerInt <= 30) {
          _txPowerController.text = powerInt.toString();
        }
      }

      if (_fetchedSettings.containsKey('lat')) {
        appLog.info(
          'Setting lat to: "${_fetchedSettings['lat']}"',
          tag: 'RadioSettings',
        );
        _latController.text = _fetchedSettings['lat']!;
      }
      if (_fetchedSettings.containsKey('lon')) {
        appLog.info(
          'Setting lon to: "${_fetchedSettings['lon']}"',
          tag: 'RadioSettings',
        );
        _lonController.text = _fetchedSettings['lon']!;
      }

      if (_fetchedSettings.containsKey('repeat')) {
        _repeatEnabled = _normalizeOnOff(_fetchedSettings['repeat']!);
      }
      if (_fetchedSettings.containsKey('allow.read.only')) {
        _allowReadOnly = _normalizeOnOff(_fetchedSettings['allow.read.only']!);
      }
      if (_fetchedSettings.containsKey('privacy')) {
        _privacyMode = _normalizeOnOff(_fetchedSettings['privacy']!);
      }

      if (_fetchedSettings.containsKey('advert.interval')) {
        _advertInterval = _parseIntWithFallback(
          _fetchedSettings['advert.interval']!,
          _advertInterval,
        );
        _advertEnable = _advertInterval > 0;
      }
      if (_fetchedSettings.containsKey('flood.advert.interval')) {
        _floodAdvertInterval = _parseIntWithFallback(
          _fetchedSettings['flood.advert.interval']!,
          _floodAdvertInterval,
        );
        _floodAdvertEnable = _floodAdvertInterval > 0;
      }
      if (_fetchedSettings.containsKey('priv.advert.interval')) {
        _privAdvertInterval = _parseIntWithFallback(
          _fetchedSettings['priv.advert.interval']!,
          _privAdvertInterval,
        );
      }
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

  String _formatBandwidthLabel(int bandwidthHz) {
    final bandwidthKHz = bandwidthHz / 1000;
    var text = bandwidthKHz.toStringAsFixed(2);
    text = text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$text kHz';
  }

  void _applySettingResponse(String command, String response) {
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
        appLog.info('Storing key="$key" value="$value"', tag: 'RadioSettings');
        _fetchedSettings[key] = value;
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
        // Interval: non-negative integer (0 means disabled)
        if (value.contains(',')) return false;
        final interval = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
        return interval != null && interval >= 0;

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

    setState(() {
      setRefreshing(true);
      _fetchedSettings.clear();
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
        _applySettingResponse(command, response);
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

      if (_fetchedSettings.isNotEmpty) {
        _updateUIFromFetchedSettings();
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

  Future<void> _loadSettings() async {
    // Just populate with current repeater data on initial load
    // User must click sync button to fetch from device
    setState(() {
      _nameController.text = widget.repeater.name;

      if (widget.repeater.hasLocation) {
        _latController.text = widget.repeater.latitude?.toString() ?? '';
        _lonController.text = widget.repeater.longitude?.toString() ?? '';
      }
    });
  }

  Future<void> _saveSettings() async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);

    setState(() {
      _isLoading = true;
    });

    try {
      final selection = await connector.preparePathForContactSend(repeater);
      final commands = <String>[];

      // Build set commands for each setting
      if (_nameController.text.isNotEmpty) {
        commands.add('set name ${_nameController.text}');
      }

      if (_passwordController.text.isNotEmpty) {
        commands.add('password ${_passwordController.text}');
      }

      if (_guestPasswordController.text.isNotEmpty) {
        commands.add('set guest.password ${_guestPasswordController.text}');
      }

      // Radio parameters
      if (_freqController.text.isNotEmpty &&
          _bandwidth != null &&
          _spreadingFactor != null &&
          _codingRate != null) {
        final freqMHz = double.tryParse(_freqController.text);
        if (freqMHz != null) {
          final bwKHz = _bandwidth! / 1000;
          commands.add(
            'set radio ${freqMHz.toStringAsFixed(1)} $bwKHz $_spreadingFactor $_codingRate',
          );
        }
      }

      // Location
      if (_latController.text.isNotEmpty) {
        commands.add('set lat ${_latController.text}');
      }
      if (_lonController.text.isNotEmpty) {
        commands.add('set lon ${_lonController.text}');
      }

      // Feature toggles
      commands.add('set repeat ${_repeatEnabled ? "on" : "off"}');
      commands.add('set allow.read.only ${_allowReadOnly ? "on" : "off"}');
      commands.add('set privacy ${_privacyMode ? "on" : "off"}');

      // Advertisement intervals
      commands.add('set advert.interval $_advertInterval');
      commands.add('set flood.advert.interval $_floodAdvertInterval');
      if (_privacyMode) {
        commands.add('set priv.advert.interval $_privAdvertInterval');
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
        _isLoading = false;
        _hasChanges = false;
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

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
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
              onChanged: (_) => _markChanged(),
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
              onChanged: (_) => _markChanged(),
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
              onChanged: (_) => _markChanged(),
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
              onChanged: (_) => _markChanged(),
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
                    onChanged: (_) => _markChanged(),
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
                  _markChanged();
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
                  _markChanged();
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
                  _markChanged();
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
              onChanged: (_) => _markChanged(),
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
              onChanged: (_) => _markChanged(),
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
                _markChanged();
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
                _markChanged();
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
                  _markChanged();
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
                      _markChanged();
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
                  _markChanged();
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
                      _markChanged();
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
