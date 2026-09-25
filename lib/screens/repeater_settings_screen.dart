import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/utf8_length_limiter.dart';
import '../services/repeater_command_service.dart';
import '../services/storage_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/routing_sheet.dart';
import '../utils/keys.dart';
import '../helpers/snack_bar_builder.dart';

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

enum _SettingField {
  name,
  radio,
  txPower,
  rxGain,
  lat,
  lon,
  repeat,
  allowReadOnly,
  multiAcks,
  loopDetect,
  dutyCycle,
  ownerInfo,
  floodMax,
  advertInterval,
  floodAdvertInterval,
  pathHashMode,
  prvKey,
  txDelay,
  directTxDelay,
  intThresh,
  agcResetInterval,
}

enum _SaveOutcome { ok, rebootNeeded, error }

// Firmware reply taxonomy for `set ...` / `password ...` commands
// (see MeshCore CommonCLI.cpp): success replies always start with "OK"
// (any case) or "password now:"; reboot-required successes contain the word
// "reboot" (e.g. "OK - reboot to apply", "OK, reboot to apply! New pubkey:...");
// some replies are parenthesized like "(OK - stats reset)". Anything else
// (Error/ERR/ERROR/unknown/can't/...) is a failure.
_SaveOutcome _classifySaveResponse(String response) {
  var s = response.trim();
  if (s.isEmpty) return _SaveOutcome.error;
  if (s.startsWith('(')) s = s.substring(1);
  final lower = s.toLowerCase();
  if (lower.startsWith('ok') || lower.startsWith('password now')) {
    return lower.contains('reboot')
        ? _SaveOutcome.rebootNeeded
        : _SaveOutcome.ok;
  }
  return _SaveOutcome.error;
}

String _shortCommandLabel(String command) {
  final firstSpace = command.indexOf(' ');
  if (firstSpace == -1) return command;
  if (command.startsWith('set ')) {
    final rest = command.substring(4);
    final nextSpace = rest.indexOf(' ');
    return nextSpace == -1 ? rest : rest.substring(0, nextSpace);
  }
  return command.substring(0, firstSpace);
}

class _RepeaterSettingsScreenState extends State<RepeaterSettingsScreen> {
  final StorageService _storage = StorageService();

  bool _isLoading = false;
  bool _hasChanges = false;
  final Set<_SettingField> _dirtyFields = {};
  bool _refreshingBasic = false;
  bool _refreshingRadio = false;
  bool _refreshingTxPower = false;
  bool _refreshingRxGain = false;
  bool _refreshingRepeat = false;
  bool _refreshingAllowReadOnly = false;
  bool _refreshingMultiAcks = false;
  bool _refreshingOwnerInfo = false;
  bool _refreshingLat = false;
  bool _refreshingLon = false;
  bool _refreshingLoopDetect = false;
  bool _refreshingDutyCycle = false;
  bool _refreshingAdvertInterval = false;
  bool _refreshingFloodAdvertInterval = false;
  bool _refreshingFloodMax = false;
  bool _refreshingPathHashMode = false;
  bool _refreshingTxDelay = false;
  bool _refreshingDirectTxDelay = false;
  bool _refreshingIntThresh = false;
  bool _refreshingAgcResetInterval = false;
  bool _runningAction = false;
  bool _loadingAll = false;
  int _unansweredSections = 0;
  double _loadAllProgress = 0;
  final Set<String> _loadedKeys = {};
  bool _searchingForKeyPair = false;
  bool _stopSearchingForKeyPair = false;
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;

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
  bool _latInvalid = false;
  bool _lonInvalid = false;

  // Feature toggles
  bool _repeatEnabled = true;
  bool _allowReadOnly = true;
  bool _multiAcks = false;
  bool _rxGainBoosted = false;
  bool _autoClockSyncAfterLogin = false;

  // Advertisement settings
  bool _advertEnable = true;
  int _advertInterval = 120; // minutes/2
  bool _floodAdvertEnable = true;
  int _floodAdvertInterval = 12; // hours
  int _floodMax = 64; // 0-64 hops

  // Network health
  String _loopDetect = 'off'; // off|minimal|moderate|strict
  int _dutyCycle = 50; // 1-100

  // Operator info
  final TextEditingController _ownerInfoController = TextEditingController();

  // Advanced
  int _pathHashMode = 0; // 0-2
  final TextEditingController _prvKeyController = TextEditingController();
  final TextEditingController _pubKeyController = TextEditingController();
  final TextEditingController _prvKeyPrefixController = TextEditingController();
  final KeyPairSearcher _keyPairSearcher = KeyPairSearcher();
  final int _searchChunkTime = 30; // time in ms to search before yielding
  final TextEditingController _txDelayController = TextEditingController();
  final TextEditingController _directTxDelayController =
      TextEditingController();
  final TextEditingController _intThreshController = TextEditingController();
  int _agcResetInterval = 0; // seconds, multiple of 4, 0 disabled

  static const List<String> _loopDetectOptions = [
    'off',
    'minimal',
    'moderate',
    'strict',
  ];

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
  static const int _minRepeaterTxPower = -9;
  static const int _maxRepeaterTxPower = 30;
  // CommonCLI.h: password[16], node_name[32], owner_info[120].
  static const int _maxPasswordBytes = 15;
  static const int _maxNameBytes = 31;
  static const int _maxOwnerInfoBytes = 119;
  static const int _maxAgcResetInterval = 255 * 4;

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
    _ownerInfoController.dispose();
    _txDelayController.dispose();
    _directTxDelayController.dispose();
    _intThreshController.dispose();
    _prvKeyController.dispose();
    _pubKeyController.dispose();
    _prvKeyPrefixController.dispose();
    _stopSearchingForKeyPair = true;
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

  /// Apply a single `get <key>` response value to the relevant UI state.
  /// Caller is responsible for invoking this inside setState.
  /// Unparseable values are ignored (current state is preserved).
  void _applyGetValue(String key, String value) {
    switch (key) {
      case 'name':
        _nameController.text = value;
        break;
      case 'radio':
        _applyRadioValue(value);
        break;
      case 'tx':
        final dbm = int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), ''));
        if (dbm != null && dbm >= -128 && dbm <= 127) {
          _txPowerController.text = dbm.toString();
        }
        break;
      case 'lat':
        _latController.text = value;
        break;
      case 'lon':
        _lonController.text = value;
        break;
      case 'repeat':
        _repeatEnabled = _parseOnOff(value);
        break;
      case 'allow.read.only':
        _allowReadOnly = _parseOnOff(value);
        break;
      case 'advert.interval':
        final v = int.tryParse(value.trim());
        if (v != null && v >= 0) {
          _advertInterval = v;
          _advertEnable = v > 0;
        }
        break;
      case 'flood.advert.interval':
        final v = int.tryParse(value.trim());
        if (v != null && v >= 0) {
          _floodAdvertInterval = v;
          _floodAdvertEnable = v > 0;
        }
        break;
      case 'radio.rxgain':
        _rxGainBoosted = _parseOnOff(value);
        break;
      case 'multi.acks':
        // Firmware reply is "0" or "1".
        _multiAcks = _parseOnOff(value);
        break;
      case 'loop.detect':
        final lower = value.trim().toLowerCase();
        if (_loopDetectOptions.contains(lower)) _loopDetect = lower;
        break;
      case 'dutycycle':
        // Reply is "<int>.<int>%" e.g. "50.0%"; first number is the percent.
        final pct = double.tryParse(
          value.replaceAll('%', '').split('.').first.trim(),
        );
        if (pct != null) _dutyCycle = pct.toInt().clamp(1, 100);
        break;
      case 'owner.info':
        // Firmware translates internal newlines back to '|' on the wire.
        _ownerInfoController.text = value.replaceAll('|', '\n');
        break;
      case 'flood.max':
        final v = int.tryParse(value.trim());
        if (v != null && v >= 0 && v <= 64) _floodMax = v;
        break;
      case 'path.hash.mode':
        final v = int.tryParse(value.trim());
        if (v != null && v >= 0 && v <= 2) _pathHashMode = v;
        break;
      case 'txdelay':
        if (double.tryParse(value.trim()) != null) {
          _txDelayController.text = value.trim();
        }
        break;
      case 'direct.txdelay':
        if (double.tryParse(value.trim()) != null) {
          _directTxDelayController.text = value.trim();
        }
        break;
      case 'int.thresh':
        if (int.tryParse(value.trim()) != null) {
          _intThreshController.text = value.trim();
        }
        break;
      case 'agc.reset.interval':
        final v = int.tryParse(value.trim());
        if (v != null && v >= 0) {
          _agcResetInterval = v.clamp(0, _maxAgcResetInterval);
        }
        break;
    }
  }

  /// Parse the firmware "freq,bw,sf,cr" radio reply (e.g. "908.205017,62.5,10,7").
  void _applyRadioValue(String radioStr) {
    final parts = radioStr.split(',');
    if (parts.isEmpty) return;
    final freqText = parts[0].trim();
    if (freqText.isNotEmpty && double.tryParse(freqText) != null) {
      _freqController.text = freqText;
    }
    if (parts.length > 1) {
      final bw = double.tryParse(parts[1].trim());
      if (bw != null) {
        _bandwidth = (bw * 1000).toInt();
        if (!_bandwidthOptions.contains(_bandwidth)) {
          _bandwidthOptions.add(_bandwidth!);
          _bandwidthOptions.sort();
        }
      }
    }
    if (parts.length > 2) {
      final sf = int.tryParse(parts[2].trim());
      if (sf != null && _spreadingFactorOptions.contains(sf)) {
        _spreadingFactor = sf;
      }
    }
    if (parts.length > 3) {
      final cr = int.tryParse(parts[3].trim());
      // Some firmware reports CR as 1-4 instead of 5-8.
      final uiCr = cr != null && cr <= 4 ? cr + 4 : cr;
      if (uiCr != null && _codingRateOptions.contains(uiCr)) {
        _codingRate = uiCr;
      }
    }
  }

  bool _parseOnOff(String value) {
    final lower = value.trim().toLowerCase();
    return lower == 'on' ||
        lower == 'true' ||
        lower == '1' ||
        lower == 'enabled';
  }

  String _formatBandwidthLabel(int bandwidthHz) {
    final bandwidthKHz = bandwidthHz / 1000;
    var text = bandwidthKHz.toStringAsFixed(2);
    text = text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$text kHz';
  }

  /// Decode a `get <key>` response and apply it to local state.
  /// Returns true if a value was applied.
  ///
  /// Response/command pairing is guaranteed by the prefix-matching layer in
  /// RepeaterCommandService (firmware echoes the `XX|` token from MyMesh.cpp),
  /// so no shape-based validation is needed here — `tryParse` handles any
  /// malformed value by leaving state untouched.
  bool _handleGetResponse(String command, String response) {
    final normalized = command.trim().toLowerCase();
    if (!normalized.startsWith('get ')) return false;
    final key = normalized.substring(4).trim();
    final value = _extractGetValue(response);
    if (value == null) return false;
    setState(() {
      _applyGetValue(key, value);
      _loadedKeys.add(key);
    });
    return true;
  }

  bool _loaded(String key) => _loadedKeys.contains(key);

  /// Firmware GET replies are always `> <value>` (CommonCLI.cpp `sprintf(reply, "> %s", ...)`).
  /// Returns the first such value, trimmed; null if none found.
  String? _extractGetValue(String response) {
    for (final line in response.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('>')) {
        final value = trimmed.substring(1).trim();
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

    setState(() => setRefreshing(true));

    var successCount = 0;
    var answered = false;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);
    for (final command in commands) {
      try {
        final response = await _commandService!.sendCommand(
          repeater,
          command,
          retries: 1,
        );
        if (!mounted) return;
        answered = true;
        if (_handleGetResponse(command, response)) successCount += 1;
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('Error fetching $command: $e');
      }
      if (!mounted) return;
    }

    if (_loadingAll) {
      // A reply we can't use usually means older firmware without that
      // setting; only a section that never answered counts as a failure.
      if (!answered) _unansweredSections += 1;
      setState(() => setRefreshing(false));
    } else {
      showDismissibleSnackBar(
        context,
        content: Text(
          successCount > 0
              ? l10n.repeater_refreshed(label)
              : l10n.repeater_errorRefreshing(label),
        ),
        backgroundColor: successCount > 0
            ? null
            : Theme.of(context).colorScheme.error,
      );
      setState(() => setRefreshing(false));
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

  Future<void> _refreshRxGain() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_rxGain,
      commands: const ['get radio.rxgain'],
      setRefreshing: (value) => _refreshingRxGain = value,
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

  Future<void> _refreshOwnerInfo() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_ownerInfo,
      commands: const ['get owner.info'],
      setRefreshing: (value) => _refreshingOwnerInfo = value,
    );
  }

  Future<void> _refreshLat() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_latitude,
      commands: const ['get lat'],
      setRefreshing: (value) => _refreshingLat = value,
    );
  }

  Future<void> _refreshLon() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_longitude,
      commands: const ['get lon'],
      setRefreshing: (value) => _refreshingLon = value,
    );
  }

  Future<void> _refreshLoopDetect() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_loopDetect,
      commands: const ['get loop.detect'],
      setRefreshing: (value) => _refreshingLoopDetect = value,
    );
  }

  Future<void> _refreshDutyCycle() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_dutyCycle,
      commands: const ['get dutycycle'],
      setRefreshing: (value) => _refreshingDutyCycle = value,
    );
  }

  Future<void> _refreshAdvertInterval() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_localAdvertInterval,
      commands: const ['get advert.interval'],
      setRefreshing: (value) => _refreshingAdvertInterval = value,
    );
  }

  Future<void> _refreshFloodAdvertInterval() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_floodAdvertInterval,
      commands: const ['get flood.advert.interval'],
      setRefreshing: (value) => _refreshingFloodAdvertInterval = value,
    );
  }

  Future<void> _refreshFloodMax() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_floodMax,
      commands: const ['get flood.max'],
      setRefreshing: (value) => _refreshingFloodMax = value,
    );
  }

  Future<void> _refreshPathHashMode() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_pathHashMode,
      commands: const ['get path.hash.mode'],
      setRefreshing: (value) => _refreshingPathHashMode = value,
    );
  }

  Future<void> _refreshTxDelay() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_txDelay,
      commands: const ['get txdelay'],
      setRefreshing: (value) => _refreshingTxDelay = value,
    );
  }

  Future<void> _refreshDirectTxDelay() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_directTxDelay,
      commands: const ['get direct.txdelay'],
      setRefreshing: (value) => _refreshingDirectTxDelay = value,
    );
  }

  Future<void> _refreshIntThresh() async {
    final l10n = context.l10n;
    await _refreshSection(
      label: l10n.repeater_intThresh,
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

  /// Send a one-shot CLI action (advert / clock sync / etc.) and surface the
  /// firmware's reply via snackbar. Not part of the dirty-field save flow.
  Future<void> _runAction(String command, String label) async {
    if (_commandService == null) return;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);
    final l10n = context.l10n;
    setState(() => _runningAction = true);
    try {
      final response = await _commandService!.sendCommand(
        repeater,
        command,
        retries: 1,
      );
      if (!mounted) return;
      final outcome = _classifySaveResponse(response);
      showDismissibleSnackBar(
        context,
        content: Text(
          outcome == _SaveOutcome.error
              ? l10n.repeater_actionFailed(label, response.trim())
              : l10n.repeater_actionSucceeded(label),
        ),
        backgroundColor: outcome == _SaveOutcome.error
            ? Theme.of(context).colorScheme.error
            : null,
      );
    } catch (e) {
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(l10n.repeater_actionFailed(label, e.toString())),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _runningAction = false);
    }
  }

  Future<void> _refreshAll() async {
    if (_loadingAll) return;
    final sections = <Future<void> Function()>[
      _refreshBasicSettings,
      _refreshRadioSettings,
      _refreshTxPower,
      _refreshRxGain,
      _refreshLat,
      _refreshLon,
      _refreshRepeat,
      _refreshAllowReadOnly,
      _refreshMultiAcks,
      _refreshLoopDetect,
      _refreshDutyCycle,
      _refreshAdvertInterval,
      _refreshFloodAdvertInterval,
      _refreshFloodMax,
      _refreshOwnerInfo,
      _refreshPathHashMode,
      _refreshTxDelay,
      _refreshDirectTxDelay,
      _refreshIntThresh,
      _refreshAgcResetInterval,
    ];
    _unansweredSections = 0;
    setState(() {
      _loadingAll = true;
      _loadAllProgress = 0;
    });
    for (var i = 0; i < sections.length; i++) {
      if (!mounted) return;
      await sections[i]();
      if (!mounted) return;
      setState(() => _loadAllProgress = (i + 1) / sections.length);
    }
    setState(() => _loadingAll = false);
    if (_unansweredSections > 0) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.repeater_settingsLoadIncomplete),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _nameController.text = widget.repeater.name;

      if (widget.repeater.hasLocation) {
        _latController.text = widget.repeater.latitude?.toString() ?? '';
        _lonController.text = widget.repeater.longitude?.toString() ?? '';
      }
    });

    final autoClockSync = await _storage
        .getRepeaterAutoClockSyncAfterLoginEnabled(
          widget.repeater.publicKeyHex,
        );
    if (!mounted) return;
    setState(() {
      _autoClockSyncAfterLogin = autoClockSync;
    });
  }

  Future<void> _saveSettings() async {
    if (_commandService == null) return;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);

    setState(() {
      _isLoading = true;
    });

    try {
      final l10n = context.l10n;
      // Each pending command remembers the dirty-field it came from (null for
      // password commands, which always re-send when text is present). On
      // failure we keep that field in `_dirtyFields` so the Save button stays
      // available and the user can retry.
      final pending = <({_SettingField? field, String command})>[];
      final failures = <String>[];
      final retainDirty = <_SettingField>{};
      void reject(_SettingField field, String message) {
        failures.add(message);
        retainDirty.add(field);
      }

      if (_dirtyFields.contains(_SettingField.name) &&
          _nameController.text.isNotEmpty) {
        pending.add((
          field: _SettingField.name,
          command: 'set name ${_nameController.text}',
        ));
      }

      // Passwords are write-only; send whenever a value was typed.
      if (_passwordController.text.isNotEmpty) {
        pending.add((
          field: null,
          command: 'password ${_passwordController.text}',
        ));
      }
      if (_guestPasswordController.text.isNotEmpty) {
        pending.add((
          field: null,
          command: 'set guest.password ${_guestPasswordController.text}',
        ));
      }

      // Radio parameters are bundled in a single command.
      if (_dirtyFields.contains(_SettingField.radio) &&
          _freqController.text.isNotEmpty &&
          _bandwidth != null &&
          _spreadingFactor != null &&
          _codingRate != null) {
        final freqText = _normalizeDecimal(_freqController.text);
        final freq = double.tryParse(freqText);
        final bwKHz = _bandwidth! / 1000;
        if (freq == null || freq < 150 || freq > 2500) {
          reject(_SettingField.radio, l10n.repeater_frequencyInvalid);
        } else if (bwKHz < 7.8 || bwKHz > 500) {
          reject(_SettingField.radio, '${l10n.repeater_bandwidth}: $bwKHz');
        } else if (_spreadingFactor! < 5 || _spreadingFactor! > 12) {
          reject(
            _SettingField.radio,
            '${l10n.repeater_spreadingFactor}: $_spreadingFactor',
          );
        } else if (_codingRate! < 5 || _codingRate! > 8) {
          reject(
            _SettingField.radio,
            '${l10n.repeater_codingRate}: $_codingRate',
          );
        } else {
          pending.add((
            field: _SettingField.radio,
            command:
                'set radio $freqText,$bwKHz,$_spreadingFactor,$_codingRate',
          ));
        }
      }

      if (_dirtyFields.contains(_SettingField.txPower) &&
          _txPowerController.text.isNotEmpty) {
        final dbm = int.tryParse(_txPowerController.text.trim());
        if (dbm == null ||
            dbm < _minRepeaterTxPower ||
            dbm > _maxRepeaterTxPower) {
          reject(
            _SettingField.txPower,
            '${l10n.repeater_txPower}: ${_txPowerController.text.trim()} '
            '($_minRepeaterTxPower-$_maxRepeaterTxPower dBm)',
          );
        } else {
          pending.add((field: _SettingField.txPower, command: 'set tx $dbm'));
        }
      }

      if (_dirtyFields.contains(_SettingField.lat) &&
          _latController.text.isNotEmpty) {
        if (_isValidCoordinate(_latController.text, 90)) {
          pending.add((
            field: _SettingField.lat,
            command: 'set lat ${_normalizeDecimal(_latController.text)}',
          ));
        } else {
          reject(
            _SettingField.lat,
            '${l10n.repeater_latitude}: ${_latController.text.trim()}',
          );
        }
      }
      if (_dirtyFields.contains(_SettingField.lon) &&
          _lonController.text.isNotEmpty) {
        if (_isValidCoordinate(_lonController.text, 180)) {
          pending.add((
            field: _SettingField.lon,
            command: 'set lon ${_normalizeDecimal(_lonController.text)}',
          ));
        } else {
          reject(
            _SettingField.lon,
            '${l10n.repeater_longitude}: ${_lonController.text.trim()}',
          );
        }
      }

      if (_dirtyFields.contains(_SettingField.repeat)) {
        pending.add((
          field: _SettingField.repeat,
          command: 'set repeat ${_repeatEnabled ? "on" : "off"}',
        ));
      }
      if (_dirtyFields.contains(_SettingField.allowReadOnly)) {
        pending.add((
          field: _SettingField.allowReadOnly,
          command: 'set allow.read.only ${_allowReadOnly ? "on" : "off"}',
        ));
      }

      if (_dirtyFields.contains(_SettingField.advertInterval)) {
        pending.add((
          field: _SettingField.advertInterval,
          command: 'set advert.interval $_advertInterval',
        ));
      }
      if (_dirtyFields.contains(_SettingField.floodAdvertInterval)) {
        pending.add((
          field: _SettingField.floodAdvertInterval,
          command: 'set flood.advert.interval $_floodAdvertInterval',
        ));
      }
      if (_dirtyFields.contains(_SettingField.floodMax)) {
        pending.add((
          field: _SettingField.floodMax,
          command: 'set flood.max $_floodMax',
        ));
      }

      if (_dirtyFields.contains(_SettingField.rxGain)) {
        pending.add((
          field: _SettingField.rxGain,
          command: 'set radio.rxgain ${_rxGainBoosted ? "on" : "off"}',
        ));
      }
      if (_dirtyFields.contains(_SettingField.multiAcks)) {
        pending.add((
          field: _SettingField.multiAcks,
          command: 'set multi.acks ${_multiAcks ? 1 : 0}',
        ));
      }
      if (_dirtyFields.contains(_SettingField.loopDetect)) {
        pending.add((
          field: _SettingField.loopDetect,
          command: 'set loop.detect $_loopDetect',
        ));
      }
      if (_dirtyFields.contains(_SettingField.dutyCycle)) {
        pending.add((
          field: _SettingField.dutyCycle,
          command: 'set dutycycle $_dutyCycle',
        ));
      }
      if (_dirtyFields.contains(_SettingField.ownerInfo)) {
        // Firmware splits on '|', treating it as newline.
        final encoded = _ownerInfoController.text.replaceAll('\n', '|');
        pending.add((
          field: _SettingField.ownerInfo,
          command: 'set owner.info $encoded',
        ));
      }
      if (_dirtyFields.contains(_SettingField.pathHashMode)) {
        pending.add((
          field: _SettingField.pathHashMode,
          command: 'set path.hash.mode $_pathHashMode',
        ));
      }
      if (_dirtyFields.contains(_SettingField.prvKey)) {
        final v = _prvKeyController.text.trim();
        if (v != "") {
          pending.add((field: _SettingField.prvKey, command: 'set prv.key $v'));
        }
      }
      if (_dirtyFields.contains(_SettingField.txDelay) &&
          _txDelayController.text.isNotEmpty) {
        final v = double.tryParse(_normalizeDecimal(_txDelayController.text));
        if (v != null) {
          pending.add((
            field: _SettingField.txDelay,
            command: 'set txdelay $v',
          ));
        } else {
          reject(
            _SettingField.txDelay,
            '${l10n.repeater_txDelay}: ${_txDelayController.text.trim()}',
          );
        }
      }
      if (_dirtyFields.contains(_SettingField.directTxDelay) &&
          _directTxDelayController.text.isNotEmpty) {
        final v = double.tryParse(
          _normalizeDecimal(_directTxDelayController.text),
        );
        if (v != null) {
          pending.add((
            field: _SettingField.directTxDelay,
            command: 'set direct.txdelay $v',
          ));
        } else {
          reject(
            _SettingField.directTxDelay,
            '${l10n.repeater_directTxDelay}: '
            '${_directTxDelayController.text.trim()}',
          );
        }
      }
      if (_dirtyFields.contains(_SettingField.intThresh) &&
          _intThreshController.text.isNotEmpty) {
        final v = int.tryParse(_intThreshController.text.trim());
        if (v != null && v >= 0 && v <= 255) {
          pending.add((
            field: _SettingField.intThresh,
            command: 'set int.thresh $v',
          ));
        } else {
          reject(
            _SettingField.intThresh,
            '${l10n.repeater_intThresh}: ${_intThreshController.text.trim()}',
          );
        }
      }
      if (_dirtyFields.contains(_SettingField.agcResetInterval)) {
        pending.add((
          field: _SettingField.agcResetInterval,
          command: 'set agc.reset.interval $_agcResetInterval',
        ));
      }

      var passwordsFailed = false;
      var rebootNeeded = false;
      for (final entry in pending) {
        var failed = false;
        try {
          final response = await _commandService!.sendCommand(
            repeater,
            entry.command,
            retries: 1,
          );
          final outcome = _classifySaveResponse(response);
          if (outcome == _SaveOutcome.error) {
            failures.add(
              '${_shortCommandLabel(entry.command)}: ${response.trim()}',
            );
            failed = true;
          } else if (outcome == _SaveOutcome.rebootNeeded) {
            rebootNeeded = true;
          }
        } catch (e) {
          failures.add('${_shortCommandLabel(entry.command)}: ${e.toString()}');
          failed = true;
        }
        if (failed) {
          if (entry.field != null) {
            retainDirty.add(entry.field!);
          } else {
            passwordsFailed = true;
          }
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (!mounted) return;

      // Only clear password fields if every password command succeeded —
      // otherwise the user keeps their typed value to retry.
      if (!passwordsFailed) {
        _passwordController.clear();
        _guestPasswordController.clear();
      }
      setState(() {
        _isLoading = false;
        _dirtyFields
          ..clear()
          ..addAll(retainDirty);
        _hasChanges = _dirtyFields.isNotEmpty || passwordsFailed;
      });

      if (mounted) {
        if (failures.isEmpty && rebootNeeded) {
          showDismissibleSnackBar(
            context,
            content: Text(l10n.repeater_settingsSavedRebootNeeded),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          );
        } else if (failures.isEmpty) {
          showDismissibleSnackBar(
            context,
            content: Text(l10n.repeater_settingsSaved),
          );
        } else {
          showDismissibleSnackBar(
            context,
            content: Text(
              l10n.repeater_settingsPartialFailure(failures.join('; ')),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showDismissibleSnackBar(
          context,
          content: Text(
            context.l10n.repeater_errorSavingSettings(e.toString()),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  void _markChanged(_SettingField field) {
    _dirtyFields.add(field);
    _flagHasChanges();
  }

  static String _normalizeDecimal(String text) =>
      text.trim().replaceAll(',', '.');

  static bool _isValidCoordinate(String text, double max) {
    if (text.trim().isEmpty) return true;
    final value = double.tryParse(_normalizeDecimal(text));
    return value != null && value >= -max && value <= max;
  }

  void _flagHasChanges() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _startSearchingForKeyPair() async {
    if (_searchingForKeyPair) return;
    setState(() {
      _searchingForKeyPair = true;
      _stopSearchingForKeyPair = false;
    });
    _searchForKeyPair();
  }

  void _searchForKeyPair() async {
    if (_stopSearchingForKeyPair) {
      if (mounted) setState(() => _searchingForKeyPair = false);
      return;
    }
    final String prefix = _prvKeyPrefixController.text.trim();
    MCKeyPair? keys = await _keyPairSearcher.findMatchingKeyPair(
      prefix,
      _searchChunkTime,
    );
    if (keys == null) {
      // Ran out of time; schedule another attempt.
      Timer.run(_searchForKeyPair);
    } else {
      setState(() => _searchingForKeyPair = false);
      _prvKeyController.text = pubKeyToHex(keys.private);
      _pubKeyController.text = pubKeyToHex(keys.public);
      _markChanged(_SettingField.prvKey);
    }
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
        title: Text(l10n.repeater_settingsTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isFloodMode ? Icons.waves : Icons.route),
            tooltip: l10n.repeater_routingMode,
            onPressed: () =>
                ContactRoutingSheet.show(context, contact: repeater),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.repeater_refreshAll,
            onPressed: _loadingAll || _isLoading ? null : _refreshAll,
          ),
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isLoading || _loadingAll ? null : _saveSettings,
              icon: const Icon(Icons.save),
              label: Text(l10n.common_save),
            ),
        ],
        bottom: _loadingAll
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: _loadAllProgress),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: _isLoading && _nameController.text.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  if (_loadedKeys.isEmpty && !_loadingAll)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: MeshCard(
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.l10n.repeater_settingsNotLoaded,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : _refreshAll,
                              child: Text(context.l10n.repeater_refreshAll),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _buildBasicSettingsCard(),
                  _buildRadioSettingsCard(),
                  _buildLocationSettingsCard(),
                  _buildFeatureTogglesCard(),
                  _buildNetworkHealthCard(),
                  _buildAdvertisementSettingsCard(),
                  _buildOwnerInfoCard(),
                  _buildActionsCard(),
                  _buildAdvancedCard(),
                  _buildKeysCard(),
                  const SizedBox(height: 16),
                  _buildDangerZoneCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildBasicSettingsCard() {
    final l10n = context.l10n;
    final refreshButton = _refreshingBasic
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _refreshBasicSettings,
            tooltip: l10n.repeater_refreshBasicSettings,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.repeater_basicSettings, trailing: refreshButton),
        MeshCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                enabled: _loaded('name'),
                decoration: InputDecoration(
                  labelText: l10n.repeater_repeaterName,
                  helperText: l10n.repeater_repeaterNameHelper,
                ),
                inputFormatters: const [
                  Utf8LengthLimitingTextInputFormatter(_maxNameBytes),
                ],
                onChanged: (_) => _markChanged(_SettingField.name),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.repeater_adminPassword,
                  helperText: l10n.repeater_adminPasswordHelper,
                ),
                obscureText: true,
                inputFormatters: const [
                  Utf8LengthLimitingTextInputFormatter(_maxPasswordBytes),
                ],
                onChanged: (_) => _flagHasChanges(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _guestPasswordController,
                decoration: InputDecoration(
                  labelText: l10n.repeater_guestPassword,
                  helperText: l10n.repeater_guestPasswordHelper,
                ),
                obscureText: true,
                inputFormatters: const [
                  Utf8LengthLimitingTextInputFormatter(_maxPasswordBytes),
                ],
                onChanged: (_) => _flagHasChanges(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadioSettingsCard() {
    final l10n = context.l10n;
    final refreshButton = _refreshingRadio
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _refreshRadioSettings,
            tooltip: l10n.repeater_refreshRadioSettings,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.repeater_radioSettings, trailing: refreshButton),
        MeshCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _freqController,
                enabled: _loaded('radio'),
                decoration: InputDecoration(
                  labelText: l10n.repeater_frequencyMhz,
                  helperText: l10n.repeater_frequencyRangeHelper,
                  suffixText: 'MHz',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _markChanged(_SettingField.radio),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _txPowerController,
                      enabled: _loaded('tx'),
                      decoration: InputDecoration(
                        labelText: l10n.repeater_txPower,
                        helperText: l10n.repeater_txPowerRangeHelper,
                        suffixText: 'dBm',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      onChanged: (_) => _markChanged(_SettingField.txPower),
                    ),
                  ),
                  _buildInlineRefreshButton(
                    isRefreshing: _refreshingTxPower,
                    onRefresh: _refreshTxPower,
                    tooltip: l10n.repeater_refreshTxPower,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _bandwidth,
                decoration: InputDecoration(labelText: l10n.repeater_bandwidth),
                items: _bandwidthOptions.map((bw) {
                  return DropdownMenuItem(
                    value: bw,
                    child: Text(_formatBandwidthLabel(bw)),
                  );
                }).toList(),
                onChanged: !_loaded('radio')
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _bandwidth = value;
                          });
                          _markChanged(_SettingField.radio);
                        }
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _spreadingFactor,
                decoration: InputDecoration(
                  labelText: l10n.repeater_spreadingFactor,
                ),
                items: _spreadingFactorOptions.map((sf) {
                  return DropdownMenuItem(value: sf, child: Text('SF$sf'));
                }).toList(),
                onChanged: !_loaded('radio')
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _spreadingFactor = value;
                          });
                          _markChanged(_SettingField.radio);
                        }
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _codingRate,
                decoration: InputDecoration(
                  labelText: l10n.repeater_codingRate,
                ),
                items: _codingRateOptions.map((cr) {
                  return DropdownMenuItem(value: cr, child: Text('4/$cr'));
                }).toList(),
                onChanged: !_loaded('radio')
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _codingRate = value;
                          });
                          _markChanged(_SettingField.radio);
                        }
                      },
              ),
              const SizedBox(height: 4),
              _buildFeatureToggleRow(
                title: l10n.repeater_rxGain,
                subtitle: l10n.repeater_rxGainHelper,
                value: _rxGainBoosted,
                loaded: _loaded('radio.rxgain'),
                isRefreshing: _refreshingRxGain,
                onChanged: (v) {
                  setState(() => _rxGainBoosted = v);
                  _markChanged(_SettingField.rxGain);
                },
                onRefresh: _refreshRxGain,
                refreshTooltip: l10n.repeater_refreshRxGain,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSettingsCard() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.repeater_locationSettings),
        MeshCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      enabled: _loaded('lat'),
                      decoration: InputDecoration(
                        labelText: l10n.repeater_latitude,
                        helperText: l10n.repeater_latitudeHelper,
                        errorText: _latInvalid
                            ? l10n.settings_locationInvalid
                            : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      onChanged: (value) {
                        _markChanged(_SettingField.lat);
                        final invalid = !_isValidCoordinate(value, 90);
                        if (invalid != _latInvalid) {
                          setState(() => _latInvalid = invalid);
                        }
                      },
                    ),
                  ),
                  _buildInlineRefreshButton(
                    isRefreshing: _refreshingLat,
                    onRefresh: _refreshLat,
                    tooltip: l10n.repeater_latitude,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lonController,
                      enabled: _loaded('lon'),
                      decoration: InputDecoration(
                        labelText: l10n.repeater_longitude,
                        helperText: l10n.repeater_longitudeHelper,
                        errorText: _lonInvalid
                            ? l10n.settings_locationInvalid
                            : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      onChanged: (value) {
                        _markChanged(_SettingField.lon);
                        final invalid = !_isValidCoordinate(value, 180);
                        if (invalid != _lonInvalid) {
                          setState(() => _lonInvalid = invalid);
                        }
                      },
                    ),
                  ),
                  _buildInlineRefreshButton(
                    isRefreshing: _refreshingLon,
                    onRefresh: _refreshLon,
                    tooltip: l10n.repeater_longitude,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureTogglesCard() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.repeater_features),
        MeshCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeatureToggleRow(
                title: l10n.repeater_packetForwarding,
                subtitle: l10n.repeater_packetForwardingSubtitle,
                value: _repeatEnabled,
                loaded: _loaded('repeat'),
                isRefreshing: _refreshingRepeat,
                onChanged: (value) {
                  setState(() {
                    _repeatEnabled = value;
                  });
                  _markChanged(_SettingField.repeat);
                },
                onRefresh: _refreshRepeat,
                refreshTooltip: l10n.repeater_refreshPacketForwarding,
              ),
              _buildFeatureToggleRow(
                title: l10n.repeater_guestAccess,
                subtitle: l10n.repeater_guestAccessSubtitle,
                value: _allowReadOnly,
                loaded: _loaded('allow.read.only'),
                isRefreshing: _refreshingAllowReadOnly,
                onChanged: (value) {
                  setState(() {
                    _allowReadOnly = value;
                  });
                  _markChanged(_SettingField.allowReadOnly);
                },
                onRefresh: _refreshAllowReadOnly,
                refreshTooltip: l10n.repeater_refreshGuestAccess,
              ),
              _buildFeatureToggleRow(
                title: l10n.repeater_multiAcks,
                subtitle: l10n.repeater_multiAcksSubtitle,
                value: _multiAcks,
                loaded: _loaded('multi.acks'),
                isRefreshing: _refreshingMultiAcks,
                onChanged: (v) {
                  setState(() => _multiAcks = v);
                  _markChanged(_SettingField.multiAcks);
                },
                onRefresh: _refreshMultiAcks,
                refreshTooltip: l10n.repeater_refreshMultiAcks,
              ),
              SwitchListTile(
                title: Text(l10n.repeater_clockSyncAfterLogin),
                subtitle: Text(l10n.repeater_clockSyncAfterLoginSubtitle),
                value: _autoClockSyncAfterLogin,
                onChanged: (value) async {
                  setState(() {
                    _autoClockSyncAfterLogin = value;
                  });
                  await _storage.setRepeaterAutoClockSyncAfterLoginEnabled(
                    widget.repeater.publicKeyHex,
                    value,
                  );
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required bool loaded,
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
            value: loaded && value,
            onChanged: loaded ? onChanged : null,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.repeater_advertisementSettings),
        MeshCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(l10n.repeater_localAdvertInterval),
                      subtitle: Text(
                        _loaded('advert.interval')
                            ? l10n.repeater_localAdvertIntervalMinutes(
                                _advertInterval,
                              )
                            : '—',
                      ),
                      trailing: Switch(
                        value: _loaded('advert.interval') && _advertEnable,
                        onChanged: !_loaded('advert.interval')
                            ? null
                            : (value) {
                                setState(() {
                                  _advertInterval = value ? 60 : 0;
                                  _advertEnable = value;
                                });
                                _markChanged(_SettingField.advertInterval);
                              },
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    icon: _refreshingAdvertInterval
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    onPressed: _refreshingAdvertInterval
                        ? null
                        : _refreshAdvertInterval,
                    tooltip: l10n.repeater_localAdvertInterval,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Slider(
                value: _advertInterval.clamp(60, 240).toDouble(),
                min: 60,
                max: 240,
                divisions: 18,
                label: l10n.repeater_localAdvertIntervalMinutes(
                  _advertInterval,
                ),
                onChanged: _advertEnable && _loaded('advert.interval')
                    ? (value) {
                        setState(() {
                          _advertInterval = value.toInt();
                        });
                        _markChanged(_SettingField.advertInterval);
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(l10n.repeater_floodAdvertInterval),
                      subtitle: Text(
                        _loaded('flood.advert.interval')
                            ? l10n.repeater_floodAdvertIntervalHours(
                                _floodAdvertInterval,
                              )
                            : '—',
                      ),
                      trailing: Switch(
                        value:
                            _loaded('flood.advert.interval') &&
                            _floodAdvertEnable,
                        onChanged: !_loaded('flood.advert.interval')
                            ? null
                            : (value) {
                                setState(() {
                                  _floodAdvertInterval = value ? 3 : 0;
                                  _floodAdvertEnable = value;
                                });
                                _markChanged(_SettingField.floodAdvertInterval);
                              },
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    icon: _refreshingFloodAdvertInterval
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    onPressed: _refreshingFloodAdvertInterval
                        ? null
                        : _refreshFloodAdvertInterval,
                    tooltip: l10n.repeater_floodAdvertInterval,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Slider(
                value: _floodAdvertInterval.clamp(3, 168).toDouble(),
                min: 3,
                max: 168,
                divisions: 165,
                label: l10n.repeater_floodAdvertIntervalHours(
                  _floodAdvertInterval,
                ),
                onChanged:
                    _floodAdvertEnable && _loaded('flood.advert.interval')
                    ? (value) {
                        setState(() {
                          _floodAdvertInterval = value.toInt();
                        });
                        _markChanged(_SettingField.floodAdvertInterval);
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(l10n.repeater_floodMax),
                      subtitle: Text(l10n.repeater_floodMaxHelper),
                      trailing: Text(
                        _loaded('flood.max') ? '$_floodMax' : '—',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    icon: _refreshingFloodMax
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    onPressed: _refreshingFloodMax ? null : _refreshFloodMax,
                    tooltip: l10n.repeater_floodMax,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Slider(
                value: _floodMax.toDouble(),
                min: 0,
                max: 64,
                divisions: 64,
                label: '$_floodMax',
                onChanged: !_loaded('flood.max')
                    ? null
                    : (v) {
                        setState(() => _floodMax = v.toInt());
                        _markChanged(_SettingField.floodMax);
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkHealthCard() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.repeater_networkHealth),
        MeshCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _loaded('loop.detect') ? _loopDetect : null,
                      decoration: InputDecoration(
                        labelText: l10n.repeater_loopDetect,
                        helperText: l10n.repeater_loopDetectHelper,
                        helperMaxLines: 3,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'off',
                          child: Text(l10n.repeater_loopDetectOff),
                        ),
                        DropdownMenuItem(
                          value: 'minimal',
                          child: Text(l10n.repeater_loopDetectMinimal),
                        ),
                        DropdownMenuItem(
                          value: 'moderate',
                          child: Text(l10n.repeater_loopDetectModerate),
                        ),
                        DropdownMenuItem(
                          value: 'strict',
                          child: Text(l10n.repeater_loopDetectStrict),
                        ),
                      ],
                      onChanged: !_loaded('loop.detect')
                          ? null
                          : (v) {
                              if (v != null) {
                                setState(() => _loopDetect = v);
                                _markChanged(_SettingField.loopDetect);
                              }
                            },
                    ),
                  ),
                  _buildInlineRefreshButton(
                    isRefreshing: _refreshingLoopDetect,
                    onRefresh: _refreshLoopDetect,
                    tooltip: l10n.repeater_loopDetect,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(l10n.repeater_dutyCycle),
                      subtitle: Text(l10n.repeater_dutyCycleHelper),
                      trailing: Text(
                        _loaded('dutycycle')
                            ? l10n.repeater_dutyCyclePercent(_dutyCycle)
                            : '—',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    icon: _refreshingDutyCycle
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    onPressed: _refreshingDutyCycle ? null : _refreshDutyCycle,
                    tooltip: l10n.repeater_dutyCycle,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Slider(
                value: _dutyCycle.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                label: l10n.repeater_dutyCyclePercent(_dutyCycle),
                onChanged: !_loaded('dutycycle')
                    ? null
                    : (v) {
                        setState(() => _dutyCycle = v.toInt());
                        _markChanged(_SettingField.dutyCycle);
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerInfoCard() {
    final l10n = context.l10n;
    final refreshButton = _refreshingOwnerInfo
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _refreshOwnerInfo,
            tooltip: l10n.repeater_refreshOwnerInfo,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.repeater_ownerInfo, trailing: refreshButton),
        MeshCard(
          child: TextField(
            controller: _ownerInfoController,
            enabled: _loaded('owner.info'),
            decoration: InputDecoration(
              labelText: l10n.repeater_ownerInfo,
              helperText: l10n.repeater_ownerInfoHelper,
              helperMaxLines: 3,
            ),
            maxLines: 4,
            minLines: 2,
            inputFormatters: const [
              Utf8LengthLimitingTextInputFormatter(_maxOwnerInfoBytes),
            ],
            onChanged: (_) => _markChanged(_SettingField.ownerInfo),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.repeater_actionsTitle),
        MeshCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.podcasts),
                title: Text(l10n.repeater_sendAdvert),
                subtitle: Text(l10n.repeater_sendAdvertSubtitle),
                enabled: !_runningAction,
                onTap: _runningAction
                    ? null
                    : () => _runAction('advert', l10n.repeater_sendAdvert),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.cell_tower),
                title: Text(l10n.repeater_sendAdvertZeroHop),
                subtitle: Text(l10n.repeater_sendAdvertZeroHopSubtitle),
                enabled: !_runningAction,
                onTap: _runningAction
                    ? null
                    : () => _runAction(
                        'advert.zerohop',
                        l10n.repeater_sendAdvertZeroHop,
                      ),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(l10n.repeater_clockSync),
                subtitle: Text(l10n.repeater_clockSyncSubtitle),
                enabled: !_runningAction,
                onTap: _runningAction
                    ? null
                    : () => _runAction('clock sync', l10n.repeater_clockSync),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedCard() {
    final l10n = context.l10n;
    return MeshCard(
      child: ExpansionTile(
        leading: const Icon(Icons.tune),
        title: Text(
          l10n.repeater_advancedSettings,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.repeater_advancedSettingsSubtitle),
        childrenPadding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _loaded('path.hash.mode')
                      ? _pathHashMode
                      : null,
                  decoration: InputDecoration(
                    labelText: l10n.repeater_pathHashMode,
                    helperText: l10n.repeater_pathHashModeHelper,
                    helperMaxLines: 5,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(l10n.repeater_pathHashModeOption0),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text(l10n.repeater_pathHashModeOption1),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(l10n.repeater_pathHashModeOption2),
                    ),
                  ],
                  onChanged: !_loaded('path.hash.mode')
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() => _pathHashMode = v);
                            _markChanged(_SettingField.pathHashMode);
                          }
                        },
                ),
              ),
              _buildInlineRefreshButton(
                isRefreshing: _refreshingPathHashMode,
                onRefresh: _refreshPathHashMode,
                tooltip: l10n.repeater_pathHashMode,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _txDelayController,
                  enabled: _loaded('txdelay'),
                  decoration: InputDecoration(
                    labelText: l10n.repeater_txDelay,
                    helperText: l10n.repeater_txDelayHelper,
                    helperMaxLines: 3,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _markChanged(_SettingField.txDelay),
                ),
              ),
              _buildInlineRefreshButton(
                isRefreshing: _refreshingTxDelay,
                onRefresh: _refreshTxDelay,
                tooltip: l10n.repeater_txDelay,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _directTxDelayController,
                  enabled: _loaded('direct.txdelay'),
                  decoration: InputDecoration(
                    labelText: l10n.repeater_directTxDelay,
                    helperText: l10n.repeater_directTxDelayHelper,
                    helperMaxLines: 3,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _markChanged(_SettingField.directTxDelay),
                ),
              ),
              _buildInlineRefreshButton(
                isRefreshing: _refreshingDirectTxDelay,
                onRefresh: _refreshDirectTxDelay,
                tooltip: l10n.repeater_directTxDelay,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _intThreshController,
                  enabled: _loaded('int.thresh'),
                  decoration: InputDecoration(
                    labelText: l10n.repeater_intThresh,
                    helperText: l10n.repeater_intThreshHelper,
                    helperMaxLines: 3,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _markChanged(_SettingField.intThresh),
                ),
              ),
              _buildInlineRefreshButton(
                isRefreshing: _refreshingIntThresh,
                onRefresh: _refreshIntThresh,
                tooltip: l10n.repeater_intThresh,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(l10n.repeater_agcResetInterval),
                  subtitle: Text(l10n.repeater_agcResetIntervalHelper),
                  trailing: Text(
                    _loaded('agc.reset.interval')
                        ? '${_agcResetInterval}s'
                        : '—',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              IconButton(
                icon: _refreshingAgcResetInterval
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 20),
                onPressed: _refreshingAgcResetInterval
                    ? null
                    : _refreshAgcResetInterval,
                tooltip: l10n.repeater_agcResetInterval,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Slider(
            value: _agcResetInterval.clamp(0, _maxAgcResetInterval).toDouble(),
            min: 0,
            max: _maxAgcResetInterval.toDouble(),
            divisions: _maxAgcResetInterval ~/ 4,
            label: '${_agcResetInterval}s',
            onChanged: !_loaded('agc.reset.interval')
                ? null
                : (v) {
                    setState(() {
                      // Clamp to multiple of 4 to match firmware semantics.
                      _agcResetInterval = (v.toInt() ~/ 4) * 4;
                    });
                    _markChanged(_SettingField.agcResetInterval);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildKeysCard() {
    final l10n = context.l10n;
    return MeshCard(
      child: ExpansionTile(
        leading: const Icon(Icons.vpn_key),
        title: Text(
          l10n.repeater_keySettings,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.repeater_keySettingsSubtitle),
        childrenPadding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _prvKeyController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp("[0-9a-fA-F]")),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.repeater_prvKey,
                    helperText: l10n.repeater_prvKeyHelper,
                    helperMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    _pubKeyController.text = "";
                    if (_prvKeyController.text.isNotEmpty) {
                      _markChanged(_SettingField.prvKey);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _searchingForKeyPair
                    ? IconButton(
                        icon: const Icon(Icons.cancel, size: 24),
                        onPressed: (() => _stopSearchingForKeyPair = true),
                        tooltip: l10n.repeater_stopGeneratingPrvKey,
                        visualDensity: VisualDensity.compact,
                      )
                    : IconButton(
                        icon: const Icon(Icons.casino_rounded, size: 24),
                        onPressed: () {
                          _startSearchingForKeyPair();
                        },
                        tooltip: l10n.repeater_generatePrvKey,
                        visualDensity: VisualDensity.compact,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: _pubKeyController,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.color?.withValues(alpha: 0.6),
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.repeater_pubKey,
                    helperText: l10n.repeater_pubKeyHelper,
                    helperMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: _searchingForKeyPair
                      ? CircularProgressIndicator(strokeWidth: 2)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _prvKeyPrefixController,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp("[0-9a-fA-F]")),
                  ],
                  onChanged: (_) => setState(() => {}), // updates helper text
                  decoration: InputDecoration(
                    labelText: l10n.repeater_pubKeyPrefix,
                    helperText: l10n.repeater_pubKeyPrefixHelper(
                      pow(16, _prvKeyPrefixController.text.length).toInt(),
                    ),
                    helperMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    final l10n = context.l10n;
    return MeshCard(
      color: MeshPalette.alertBg,
      borderColor: MeshPalette.alertLine,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: MeshPalette.alert),
              const SizedBox(width: 8),
              Text(
                l10n.repeater_dangerZone,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MeshPalette.alert,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: MeshPalette.alertLine),
          ListTile(
            leading: const Icon(Icons.refresh, color: MeshPalette.alert),
            title: Text(
              l10n.repeater_rebootRepeater,
              style: const TextStyle(color: MeshPalette.alert),
            ),
            subtitle: Text(
              l10n.repeater_rebootRepeaterSubtitle,
              style: const TextStyle(color: MeshPalette.warnDim),
            ),
            onTap: () => _confirmAction(
              l10n.repeater_rebootRepeater,
              l10n.repeater_rebootRepeaterConfirm,
              () => _sendDangerCommand('reboot'),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          // Regenerate identity key - hidden until fully implemented
          ListTile(
            leading: const Icon(Icons.delete_forever, color: MeshPalette.alert),
            title: Text(
              l10n.repeater_eraseFileSystem,
              style: const TextStyle(color: MeshPalette.alert),
            ),
            subtitle: Text(
              l10n.repeater_eraseFileSystemSubtitle,
              style: const TextStyle(color: MeshPalette.warnDim),
            ),
            onTap: () => _confirmAction(
              l10n.repeater_eraseFileSystem,
              l10n.repeater_eraseFileSystemConfirm,
              () => _sendDangerCommand('erase'),
              isDestructive: true,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Future<void> _sendDangerCommand(String command) async {
    final l10n = context.l10n;
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final repeater = _resolveRepeater(connector);

    if (command == 'erase') {
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(l10n.repeater_eraseSerialOnly),
        );
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
        showDismissibleSnackBar(
          context,
          content: Text(l10n.repeater_commandSent(command)),
        );
      }
    } catch (e) {
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(l10n.repeater_errorSendingCommand(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
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
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(l10n.repeater_confirm),
          ),
        ],
      ),
    );
  }
}
