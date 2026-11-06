import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/repeater_setting_spec.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/utf8_length_limiter.dart';
import '../services/app_settings_service.dart';
import '../services/repeater_command_service.dart';
import '../services/storage_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/radio_disconnected_banner.dart';
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

  // Hand-built settings outside [repeaterSettingSpecs]; every other key is a
  // spec key.
  static const String _radioKey = 'radio';
  static const String _prvKeyKey = 'prv.key';

  bool _isLoading = false;
  bool _hasChanges = false;
  // Setting keys edited since they were last loaded or saved.
  final Set<String> _dirtyKeys = {};
  final Set<String> _editedDuringSave = {};
  // Setting keys with a `get` in flight.
  final Set<String> _refreshingKeys = {};
  bool _runningAction = false;
  bool _loadingAll = false;
  int _unansweredSections = 0;
  double _loadAllProgress = 0;
  final Set<String> _loadedKeys = {};
  bool _searchingForKeyPair = false;
  bool _stopSearchingForKeyPair = false;
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;

  // Spec settings: toggle (bool), slider (num) and choice (String) values,
  // and the text of number and text fields.
  final Map<String, Object> _values = {};
  final Map<String, TextEditingController> _controllers = {
    for (final spec in repeaterSettingSpecs)
      if (spec.input == RepeaterSettingInput.number ||
          spec.input == RepeaterSettingInput.text)
        spec.key: TextEditingController(),
  };

  // Passwords are write-only.
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _guestPasswordController =
      TextEditingController();

  // Radio parameters, sent together as `set radio freq,bw,sf,cr`.
  final TextEditingController _freqController = TextEditingController();
  int? _bandwidth;
  int? _spreadingFactor;
  int? _codingRate;

  bool _autoClockSyncAfterLogin = false;

  // Identity keys
  final TextEditingController _prvKeyController = TextEditingController();
  final TextEditingController _pubKeyController = TextEditingController();
  final TextEditingController _prvKeyPrefixController = TextEditingController();
  final KeyPairSearcher _keyPairSearcher = KeyPairSearcher();
  final int _searchChunkTime = 30; // time in ms to search before yielding

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
  // CommonCLI.h: password[16].
  static const int _maxPasswordBytes = 15;
  // PRV_KEY_SIZE is 64 bytes (expanded Ed25519 key), i.e. 128 hex chars;
  // firmware `set prv.key` rejects anything else.
  static const int _prvKeyHexLength = 128;
  static final RegExp _prvKeyPattern = RegExp(r'^[0-9a-fA-F]{128}$');

  TextEditingController _controller(String key) => _controllers[key]!;

  @override
  void initState() {
    super.initState();
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _commandService = RepeaterCommandService(connector);
    _setupMessageListener();
    _loadSettings();
    // Each setting is its own LoRa round trip, so fetching everything on open
    // is opt-in; otherwise the user refreshes sections on demand.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final autoFetch = context
          .read<AppSettingsService>()
          .settings
          .autoFetchRepeaterSettings;
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      if (autoFetch && connector.isConnected) _refreshAll();
    });
  }

  /// Returns true when the radio is connected; otherwise tells the user.
  bool _ensureConnected() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    if (connector.isConnected) return true;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.repeater_radioDisconnected),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
    return false;
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _commandService?.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _passwordController.dispose();
    _guestPasswordController.dispose();
    _freqController.dispose();
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

  /// Apply a single `get <key>` reply value to the relevant UI state.
  /// Caller is responsible for invoking this inside setState. Returns false
  /// (leaving state untouched) when the value doesn't parse.
  bool _applyGetValue(String key, String value) {
    if (key == _radioKey) return _applyRadioValue(value);
    final spec = repeaterSettingSpecsByKey[key];
    if (spec == null) return false;
    switch (spec.input) {
      case RepeaterSettingInput.toggle:
        _values[key] = _parseOnOff(value);
        return true;
      case RepeaterSettingInput.slider:
        // First number in the reply, e.g. "50.0%" -> 50.
        final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(value);
        final n = match == null ? null : num.tryParse(match.group(0)!);
        if (n == null) return false;
        _values[key] = spec.isInteger ? n.round() : n;
        return true;
      case RepeaterSettingInput.choice:
        final lower = value.trim().toLowerCase();
        if (!spec.choices.any((c) => c.value == lower)) return false;
        _values[key] = lower;
        return true;
      case RepeaterSettingInput.number:
        final text = value.trim();
        if (num.tryParse(text) == null) return false;
        _controller(key).text = text;
        return true;
      case RepeaterSettingInput.text:
        _controller(key).text = spec.decode?.call(value) ?? value;
        return true;
    }
  }

  /// Parse the firmware "freq,bw,sf,cr" radio reply (e.g. "908.205017,62.5,10,7").
  bool _applyRadioValue(String radioStr) {
    final parts = radioStr.split(',');
    final freqText = parts[0].trim();
    if (double.tryParse(freqText) == null) return false;
    _freqController.text = freqText;
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
    return true;
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
  /// so no shape-based validation is needed here — parsing leaves state
  /// untouched for a malformed value.
  bool _handleGetResponse(String command, String response) {
    final normalized = command.trim().toLowerCase();
    if (!normalized.startsWith('get ')) return false;
    final key = normalized.substring(4).trim();
    final parseRaw = repeaterSettingSpecsByKey[key]?.parseRawReply;
    final value = parseRaw != null
        ? parseRaw(response)
        : _extractGetValue(response);
    if (value == null) return false;
    var applied = false;
    setState(() {
      applied = _applyGetValue(key, value);
      if (applied) _loadedKeys.add(key);
    });
    return applied;
  }

  bool _loaded(String key) => _loadedKeys.contains(key);

  /// Whether the setting shows a real value: fetched from the repeater, or
  /// set by the user. Controls stay editable either way, since fetching every
  /// setting costs a LoRa round trip each.
  bool _known(String key) => _loaded(key) || _dirtyKeys.contains(key);

  /// Firmware GET replies are always `> <value>` (CommonCLI.cpp `sprintf(reply, "> %s", ...)`).
  /// Returns the first such value, trimmed (empty for an empty setting such
  /// as cleared operator info); null if none found.
  String? _extractGetValue(String response) {
    for (final line in response.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('>')) return trimmed.substring(1).trim();
    }
    return null;
  }

  Future<void> _refreshSection({
    required String label,
    required List<String> commands,
    required ValueSetter<bool> setRefreshing,
  }) async {
    if (_commandService == null) return;
    if (!_loadingAll && !_ensureConnected()) return;
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

  /// Fetch one setting with `get <key>`.
  Future<void> _refreshKey(String key, String label) => _refreshSection(
    label: label,
    commands: ['get $key'],
    setRefreshing: (value) =>
        value ? _refreshingKeys.add(key) : _refreshingKeys.remove(key),
  );

  Future<void> _refreshRadioSettings() =>
      _refreshKey(_radioKey, context.l10n.repeater_radioSettings);

  Future<void> _refreshSpec(RepeaterSettingSpec spec) =>
      _refreshKey(spec.key, spec.label(context.l10n));

  /// Send a one-shot CLI action (advert / clock sync / etc.) and surface the
  /// firmware's reply via snackbar. Not part of the dirty-field save flow.
  ///
  /// With [replyOptional] (e.g. `reboot`, which restarts without answering) a
  /// timeout means the command went out; it is reported as sent, not failed.
  Future<void> _runAction(
    String command,
    String label, {
    bool replyOptional = false,
  }) async {
    if (_commandService == null) return;
    if (!_ensureConnected()) return;
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
      if (replyOptional && e.toString().contains('Command timeout')) {
        showDismissibleSnackBar(
          context,
          content: Text(l10n.repeater_actionSentNoReply(label)),
        );
        return;
      }
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
    if (!_ensureConnected()) return;
    final sections = <Future<void> Function()>[
      _refreshRadioSettings,
      for (final spec in repeaterSettingSpecs) () => _refreshSpec(spec),
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
      _controller('name').text = widget.repeater.name;

      if (widget.repeater.hasLocation) {
        _controller('lat').text = widget.repeater.latitude?.toString() ?? '';
        _controller('lon').text = widget.repeater.longitude?.toString() ?? '';
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

  /// Validate a dirty spec setting and build its `set` command. Returns the
  /// command, or reports the problem through [reject] and returns null.
  String? _specCommand(
    RepeaterSettingSpec spec,
    void Function(String key, String message) reject,
  ) {
    final l10n = context.l10n;
    final key = spec.key;
    final label = spec.label(l10n);
    switch (spec.input) {
      case RepeaterSettingInput.toggle:
        final on = _values[key] == true;
        return 'set $key ${on ? spec.onValue : spec.offValue}';
      case RepeaterSettingInput.slider:
        final value = _values[key] as num?;
        if (value == null) return null;
        return 'set $key ${spec.isInteger ? value.toInt() : value}';
      case RepeaterSettingInput.choice:
        final value = _values[key] as String?;
        if (value == null) return null;
        return 'set $key $value';
      case RepeaterSettingInput.number:
        final text = _normalizeDecimal(_controller(key).text);
        if (text.isEmpty) {
          reject(key, l10n.repeater_valueRequired(label));
          return null;
        }
        if (!_isValidNumber(spec, text)) {
          reject(key, l10n.repeater_invalidSettingValue(label, text));
          return null;
        }
        return 'set $key $text';
      case RepeaterSettingInput.text:
        final text = _controller(key).text;
        if (spec.required && text.trim().isEmpty) {
          reject(key, l10n.repeater_valueRequired(label));
          return null;
        }
        if (spec.validate != null && !spec.validate!(text)) {
          reject(key, l10n.repeater_invalidSettingValue(label, text.trim()));
          return null;
        }
        return 'set $key ${spec.encode?.call(text) ?? text.trim()}';
    }
  }

  bool _isValidNumber(RepeaterSettingSpec spec, String normalized) {
    final value = spec.decimal
        ? double.tryParse(normalized)
        : int.tryParse(normalized);
    return value != null && spec.inRange(value);
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
      // Each pending command remembers the setting key it came from (null
      // for password commands, which always re-send when text is present). On
      // failure we keep that key in `_dirtyKeys` so the Save button stays
      // available and the user can retry.
      final pending = <({String? key, String command})>[];
      final failures = <String>[];
      final retainDirty = <String>{};
      void reject(String key, String message) {
        failures.add(message);
        retainDirty.add(key);
      }

      // Keys whose edits this save attempts. Anything edited while the
      // commands are in flight stays dirty afterwards (see _markChanged).
      final savingKeys = Set<String>.of(_dirtyKeys);
      _editedDuringSave.clear();

      for (final spec in repeaterSettingSpecs) {
        if (!_dirtyKeys.contains(spec.key)) continue;
        final command = _specCommand(spec, reject);
        if (command != null) pending.add((key: spec.key, command: command));
      }

      // Passwords are write-only; send whenever a value was typed.
      if (_passwordController.text.isNotEmpty) {
        pending.add((
          key: null,
          command: 'password ${_passwordController.text}',
        ));
      }
      if (_guestPasswordController.text.isNotEmpty) {
        pending.add((
          key: null,
          command: 'set guest.password ${_guestPasswordController.text}',
        ));
      }

      // `set radio` takes freq,bw,sf,cr together (the firmware only accepts
      // `set freq` over serial), so an unfetched radio needs all four.
      if (_dirtyKeys.contains(_radioKey)) {
        final freqText = _normalizeDecimal(_freqController.text);
        final freq = double.tryParse(freqText);
        final missing = [
          if (freqText.isEmpty) l10n.repeater_frequencyMhz,
          if (_bandwidth == null) l10n.repeater_bandwidth,
          if (_spreadingFactor == null) l10n.repeater_spreadingFactor,
          if (_codingRate == null) l10n.repeater_codingRate,
        ];
        if (missing.isNotEmpty) {
          for (final label in missing) {
            reject(_radioKey, l10n.repeater_valueRequired(label));
          }
        } else if (freq == null || freq < 150 || freq > 2500) {
          reject(_radioKey, l10n.repeater_frequencyInvalid);
        } else {
          pending.add((
            key: _radioKey,
            command:
                'set radio $freqText,${_bandwidth! / 1000},'
                '$_spreadingFactor,$_codingRate',
          ));
        }
      }

      if (_dirtyKeys.contains(_prvKeyKey)) {
        final v = _prvKeyController.text.trim();
        if (_prvKeyPattern.hasMatch(v)) {
          pending.add((key: _prvKeyKey, command: 'set prv.key $v'));
        } else if (v.isNotEmpty) {
          reject(_prvKeyKey, l10n.repeater_prvKeyLengthError(_prvKeyHexLength));
        }
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
          if (entry.key != null) {
            retainDirty.add(entry.key!);
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
        // A saved value is now the repeater's value, fetched or not.
        _loadedKeys.addAll(savingKeys.difference(retainDirty));
        // Only drop keys that were actually sent successfully; keep failed
        // ones and anything edited while the save was running.
        _dirtyKeys
          ..removeAll(savingKeys)
          ..addAll(retainDirty)
          ..addAll(_editedDuringSave);
        _editedDuringSave.clear();
        _hasChanges = _dirtyKeys.isNotEmpty || passwordsFailed;
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

  void _markChanged(String key) {
    _dirtyKeys.add(key);
    if (_isLoading) _editedDuringSave.add(key);
    _flagHasChanges();
  }

  static String _normalizeDecimal(String text) =>
      text.trim().replaceAll(',', '.');

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
    if (!mounted) return;
    if (keys == null) {
      // Ran out of time; schedule another attempt.
      Timer.run(_searchForKeyPair);
    } else {
      setState(() => _searchingForKeyPair = false);
      _prvKeyController.text = pubKeyToHex(keys.private);
      _pubKeyController.text = pubKeyToHex(keys.public);
      _markChanged(_prvKeyKey);
    }
  }

  Widget _buildRefreshButton({
    required bool isRefreshing,
    required VoidCallback onRefresh,
    required String tooltip,
  }) {
    return IconButton(
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
    );
  }

  /// Refresh button aligned with a text field's input line.
  Widget _buildInlineRefreshButton({
    required bool isRefreshing,
    required VoidCallback onRefresh,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _buildRefreshButton(
        isRefreshing: isRefreshing,
        onRefresh: onRefresh,
        tooltip: tooltip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);
    final isFloodMode = repeater.pathOverride == -1;
    final connected = connector.isConnected;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscardChanges();
      },
      child: Scaffold(
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
              onPressed: _loadingAll || _isLoading || !connected
                  ? null
                  : _refreshAll,
            ),
            if (_hasChanges)
              TextButton.icon(
                onPressed: _isLoading || _loadingAll || !connected
                    ? null
                    : _saveSettings,
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
          child: _isLoading && _controller('name').text.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    const RadioDisconnectedBanner(),
                    // Keep this slot when the hint hides: shifting the cards
                    // below would hand their state (e.g. an expanded
                    // Advanced card) to the wrong card.
                    if (_loadedKeys.isEmpty && !_loadingAll)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: MeshCard(
                          // The button sits under the message so neither is
                          // squeezed on narrow screens or large text.
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      context.l10n.repeater_settingsNotLoaded,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _isLoading || !connected
                                    ? null
                                    : _refreshAll,
                                child: Text(context.l10n.repeater_refreshAll),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    _buildSectionCard(
                      l10n.repeater_basicSettings,
                      RepeaterSettingSection.basic,
                      extra: _buildPasswordFields(),
                    ),
                    _buildRadioSettingsCard(),
                    _buildSectionCard(
                      l10n.repeater_locationSettings,
                      RepeaterSettingSection.location,
                    ),
                    _buildSectionCard(
                      l10n.repeater_features,
                      RepeaterSettingSection.features,
                      extra: [_buildClockSyncToggle()],
                    ),
                    _buildSectionCard(
                      l10n.repeater_networkHealth,
                      RepeaterSettingSection.networkHealth,
                    ),
                    _buildSectionCard(
                      l10n.repeater_advertisementSettings,
                      RepeaterSettingSection.advertisement,
                    ),
                    _buildSectionCard(
                      l10n.repeater_ownerInfo,
                      RepeaterSettingSection.ownerInfo,
                    ),
                    _buildActionsCard(),
                    _buildAdvancedCard(),
                    _buildKeysCard(),
                    const SizedBox(height: 16),
                    _buildDangerZoneCard(),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _confirmDiscardChanges() async {
    final l10n = context.l10n;
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final canSave =
            !_isLoading &&
            !_loadingAll &&
            dialogContext.read<MeshCoreConnector>().isConnected;
        return AlertDialog(
          title: Text(l10n.repeater_unsavedChangesTitle),
          content: Text(l10n.repeater_unsavedChangesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'discard'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: Text(l10n.repeater_discardChanges),
            ),
            FilledButton(
              onPressed: canSave
                  ? () => Navigator.pop(dialogContext, 'save')
                  : null,
              child: Text(l10n.common_save),
            ),
          ],
        );
      },
    );
    if (!mounted || choice == null) return;
    if (choice == 'save') {
      await _saveSettings();
      if (!mounted || _hasChanges) return;
    } else {
      // Drop the PopScope guard so the pop below can't re-trigger this dialog.
      setState(() => _hasChanges = false);
    }
    Navigator.of(context).pop();
  }

  /// The controls for every spec in [section], in list order.
  List<Widget> _buildSpecControls(RepeaterSettingSection section) => [
    for (final spec in repeaterSettingSpecs)
      if (spec.section == section) _buildSpecControl(spec),
  ];

  /// A section header and card holding [section]'s spec controls, followed by
  /// any hand-built [extra] controls.
  Widget _buildSectionCard(
    String title,
    RepeaterSettingSection section, {
    List<Widget> extra = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        MeshCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [..._buildSpecControls(section), ...extra],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecControl(RepeaterSettingSpec spec) {
    final l10n = context.l10n;
    final control = switch (spec.input) {
      RepeaterSettingInput.toggle => _buildToggleControl(spec),
      RepeaterSettingInput.slider => _buildSliderControl(spec),
      RepeaterSettingInput.choice => _buildChoiceControl(spec),
      RepeaterSettingInput.number ||
      RepeaterSettingInput.text => _buildTextControl(spec),
    };
    final note = spec.note?.call(l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: note == null
          ? control
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [control, _buildNote(note)],
            ),
    );
  }

  /// Availability caveat under a control (hardware-specific settings).
  Widget _buildNote(String text) {
    final color = Theme.of(context).colorScheme.tertiary;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRefreshButton(
    RepeaterSettingSpec spec, {
    bool inline = false,
  }) {
    final args = (
      isRefreshing: _refreshingKeys.contains(spec.key),
      onRefresh: () => _refreshSpec(spec),
      tooltip: spec.label(context.l10n),
    );
    return inline
        ? _buildInlineRefreshButton(
            isRefreshing: args.isRefreshing,
            onRefresh: args.onRefresh,
            tooltip: args.tooltip,
          )
        : _buildRefreshButton(
            isRefreshing: args.isRefreshing,
            onRefresh: args.onRefresh,
            tooltip: args.tooltip,
          );
  }

  Widget _buildToggleControl(RepeaterSettingSpec spec) {
    final l10n = context.l10n;
    final helper = spec.helper?.call(l10n);
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            title: Text(spec.label(l10n)),
            subtitle: helper == null ? null : Text(helper),
            // An unknown setting shows as off until fetched or set.
            value: _known(spec.key) && _values[spec.key] == true,
            onChanged: (value) {
              setState(() => _values[spec.key] = value);
              _markChanged(spec.key);
            },
            contentPadding: EdgeInsets.zero,
          ),
        ),
        _buildSpecRefreshButton(spec),
      ],
    );
  }

  Widget _buildSliderControl(RepeaterSettingSpec spec) {
    final l10n = context.l10n;
    final key = spec.key;
    final known = _known(key);
    final value = known ? _values[key] as num? : null;
    final special = value == null ? null : spec.specialValues[value];
    final canDisable = spec.offAt != null;
    final isOff = canDisable && value == spec.offAt;

    // The spec's range, widened to include a value the firmware reported
    // outside it so the knob matches the label. Special and "off" values
    // keep the normal range.
    var lo = spec.min!;
    var hi = spec.max!;
    if (value != null && special == null && !isOff) {
      lo = min(lo, value);
      hi = max(hi, value);
    }
    final steps = (hi - lo) / spec.step;
    final divisions = steps == steps.roundToDouble() && steps > 0
        ? steps.toInt()
        : null;

    String format(num v) => spec.valueLabel?.call(l10n, v) ?? '$v';
    final display = value == null ? '—' : special?.call(l10n) ?? format(value);
    final helper = spec.helper?.call(l10n);

    final title = ListTile(
      title: Text(spec.label(l10n)),
      // With an on/off switch the value moves under the title; otherwise
      // it sits on the right.
      subtitle: canDisable
          ? Text(helper == null ? display : '$display\n$helper')
          : helper == null
          ? null
          : Text(helper),
      trailing: canDisable
          ? Switch(
              value: value != null && !isOff,
              onChanged: (on) {
                setState(() => _values[key] = on ? spec.min! : spec.offAt!);
                _markChanged(key);
              },
            )
          : Text(display, style: const TextStyle(fontWeight: FontWeight.bold)),
      contentPadding: EdgeInsets.zero,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: title),
            _buildSpecRefreshButton(spec),
          ],
        ),
        Slider(
          value: (value ?? lo).clamp(lo, hi).toDouble(),
          min: lo.toDouble(),
          max: hi.toDouble(),
          divisions: divisions,
          label: value == null ? null : display,
          onChanged: canDisable && (value == null || isOff)
              ? null
              : (v) {
                  // Snap to the step, counting from the low end.
                  final snapped =
                      lo + ((v - lo) / spec.step).floor() * spec.step;
                  setState(
                    () => _values[key] = spec.isInteger
                        ? snapped.round()
                        : snapped,
                  );
                  _markChanged(key);
                },
        ),
      ],
    );
  }

  Widget _buildChoiceControl(RepeaterSettingSpec spec) {
    final l10n = context.l10n;
    final key = spec.key;
    final value = _known(key) ? _values[key] as String? : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            // Rebuild the field when a fetch changes the value underneath it.
            key: ValueKey('$key:$value'),
            isExpanded: true,
            initialValue: value,
            decoration: InputDecoration(
              labelText: spec.label(l10n),
              helperText: spec.helper?.call(l10n),
              helperMaxLines: 5,
            ),
            items: [
              for (final choice in spec.choices)
                DropdownMenuItem(
                  value: choice.value,
                  child: Text(
                    choice.label(l10n),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _values[key] = v);
              _markChanged(key);
            },
          ),
        ),
        _buildSpecRefreshButton(spec, inline: true),
      ],
    );
  }

  /// Number and text settings.
  Widget _buildTextControl(RepeaterSettingSpec spec) {
    final l10n = context.l10n;
    final key = spec.key;
    final controller = _controller(key);
    final isNumber = spec.input == RepeaterSettingInput.number;
    final text = controller.text;
    final invalid = isNumber
        ? text.trim().isNotEmpty &&
              !_isValidNumber(spec, _normalizeDecimal(text))
        : spec.validate != null && !spec.validate!(text);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: spec.label(l10n),
              helperText: spec.helper?.call(l10n),
              helperMaxLines: 3,
              errorText: invalid
                  ? l10n.repeater_invalidSettingValue(
                      spec.label(l10n),
                      text.trim(),
                    )
                  : null,
              errorMaxLines: 3,
            ),
            keyboardType: isNumber
                ? TextInputType.numberWithOptions(
                    decimal: spec.decimal,
                    signed: (spec.min ?? 0) < 0,
                  )
                : spec.multiline
                ? TextInputType.multiline
                : TextInputType.text,
            maxLines: spec.multiline ? 4 : 1,
            minLines: spec.multiline ? 2 : null,
            inputFormatters: [
              if (spec.maxBytes != null)
                Utf8LengthLimitingTextInputFormatter(spec.maxBytes!),
            ],
            onChanged: (_) {
              _markChanged(key);
              // Refresh the inline validation error.
              setState(() {});
            },
          ),
        ),
        _buildSpecRefreshButton(spec, inline: true),
      ],
    );
  }

  List<Widget> _buildPasswordFields() {
    final l10n = context.l10n;
    return [
      const SizedBox(height: 4),
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
    ];
  }

  Widget _buildClockSyncToggle() {
    final l10n = context.l10n;
    return SwitchListTile(
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
    );
  }

  /// Frequency, bandwidth, spreading factor and coding rate are one
  /// `set radio` command, so they are hand-built rather than specs.
  Widget _buildRadioSettingsCard() {
    final l10n = context.l10n;
    final refreshButton = _refreshingKeys.contains(_radioKey)
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

    Widget dropdown({
      required int? value,
      required String label,
      required List<int> options,
      required String Function(int) optionLabel,
      required ValueSetter<int> onSelected,
    }) {
      return DropdownButtonFormField<int>(
        // Rebuild the field when a fetch changes the value underneath it.
        key: ValueKey('$label:$value'),
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in options)
            DropdownMenuItem(
              value: option,
              child: Text(optionLabel(option), overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) {
          if (v == null) return;
          setState(() => onSelected(v));
          _markChanged(_radioKey);
        },
      );
    }

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
                decoration: InputDecoration(
                  labelText: l10n.repeater_frequencyMhz,
                  helperText: l10n.repeater_frequencyRangeHelper,
                  suffixText: 'MHz',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _markChanged(_radioKey),
              ),
              const SizedBox(height: 12),
              dropdown(
                value: _bandwidth,
                label: l10n.repeater_bandwidth,
                options: _bandwidthOptions,
                optionLabel: _formatBandwidthLabel,
                onSelected: (v) => _bandwidth = v,
              ),
              const SizedBox(height: 12),
              dropdown(
                value: _spreadingFactor,
                label: l10n.repeater_spreadingFactor,
                options: _spreadingFactorOptions,
                optionLabel: (sf) => 'SF$sf',
                onSelected: (v) => _spreadingFactor = v,
              ),
              const SizedBox(height: 12),
              dropdown(
                value: _codingRate,
                label: l10n.repeater_codingRate,
                options: _codingRateOptions,
                optionLabel: (cr) => '4/$cr',
                onSelected: (v) => _codingRate = v,
              ),
              const SizedBox(height: 12),
              ..._buildSpecControls(RepeaterSettingSection.radio),
            ],
          ),
        ),
      ],
    );
  }

  /// Wraps an [ExpansionTile]'s children in their own [PageStorage] scope.
  ///
  /// The tile saves its expanded flag (a bool) under its [PageStorageKey].
  /// A TextField's inner Scrollable has no key, so without this it shares
  /// that identifier, reads the bool back as its scroll offset and throws
  /// while building (a grey box in release builds).
  List<Widget> _ownPageStorage(String id, List<Widget> children) => [
    KeyedSubtree(
      key: PageStorageKey(id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  ];

  Widget _buildAdvancedCard() {
    final l10n = context.l10n;
    return MeshCard(
      child: ExpansionTile(
        key: const PageStorageKey('repeater_settings_advanced'),
        leading: const Icon(Icons.tune),
        title: Text(
          l10n.repeater_advancedSettings,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.repeater_advancedSettingsSubtitle),
        childrenPadding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
        children: _ownPageStorage(
          'repeater_settings_advanced_body',
          _buildSpecControls(RepeaterSettingSection.advanced),
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    final l10n = context.l10n;
    final canAct =
        !_runningAction && context.watch<MeshCoreConnector>().isConnected;
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
                enabled: canAct,
                onTap: !canAct
                    ? null
                    : () => _runAction('advert', l10n.repeater_sendAdvert),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.cell_tower),
                title: Text(l10n.repeater_sendAdvertZeroHop),
                subtitle: Text(l10n.repeater_sendAdvertZeroHopSubtitle),
                enabled: canAct,
                onTap: !canAct
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
                enabled: canAct,
                onTap: !canAct
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

  Widget _buildKeysCard() {
    final l10n = context.l10n;
    return MeshCard(
      child: ExpansionTile(
        key: const PageStorageKey('repeater_settings_keys'),
        leading: const Icon(Icons.vpn_key),
        title: Text(
          l10n.repeater_keySettings,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.repeater_keySettingsSubtitle),
        childrenPadding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
        children: _ownPageStorage('repeater_settings_keys_body', [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _prvKeyController,
                  maxLength: _prvKeyHexLength,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp("[0-9a-fA-F]")),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.repeater_prvKey,
                    helperText: l10n.repeater_prvKeyHelper,
                    helperMaxLines: 3,
                    errorText:
                        _prvKeyController.text.isNotEmpty &&
                            !_prvKeyPattern.hasMatch(_prvKeyController.text)
                        ? l10n.repeater_prvKeyLengthError(_prvKeyHexLength)
                        : null,
                    errorMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    _pubKeyController.text = "";
                    if (_prvKeyController.text.isNotEmpty) {
                      _markChanged(_prvKeyKey);
                    }
                    // Refresh the inline length error.
                    setState(() {});
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
        ]),
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    final l10n = context.l10n;
    final canAct =
        !_runningAction && context.watch<MeshCoreConnector>().isConnected;
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
            enabled: canAct,
            onTap: () => _confirmAction(
              l10n.repeater_rebootRepeater,
              l10n.repeater_rebootRepeaterConfirm,
              () => _runAction(
                'reboot',
                l10n.repeater_rebootRepeater,
                replyOptional: true,
              ),
              isDestructive: true,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          // Erase is serial-console only in firmware; shown disabled with
          // an explanation rather than behind a confirm that does nothing.
          ListTile(
            enabled: false,
            leading: const Icon(Icons.delete_forever),
            title: Text(l10n.repeater_eraseFileSystem),
            subtitle: Text(
              '${l10n.repeater_eraseFileSystemSubtitle}\n'
              '${l10n.repeater_eraseSerialOnly}',
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
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
