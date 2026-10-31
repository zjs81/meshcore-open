import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/radio_settings.dart';
import '../services/app_debug_log_service.dart';

/// Convert device coding-rate value (1-4 on some firmware, 5-8 on others)
/// to the UI enum range (always 5-8).
int _toUiCodingRate(int deviceCr) {
  return deviceCr <= 4 ? deviceCr + 4 : deviceCr;
}

const Set<int> _defaultRepeatFreqsKHz = {433000, 869495, 918000};

/// Whether the firmware accepts [freqKHz] for off-grid client repeat, using
/// the ranges from CMD_GET_ALLOWED_REPEAT_FREQ when known.
bool _isAllowedRepeatFreqKHz(MeshCoreConnector connector, int freqKHz) {
  final ranges = connector.allowedRepeatFreqRanges;
  if (ranges == null || ranges.isEmpty) {
    return _defaultRepeatFreqsKHz.contains(freqKHz);
  }
  return ranges.any((r) => freqKHz >= r.lowKHz && freqKHz <= r.highKHz);
}

/// Lowest TX power companion firmware accepts (CMD_SET_RADIO_TX_POWER).
const int _minTxPowerDbm = -9;

/// Radio parameter editor (preset, frequency, bandwidth, SF, CR, TX power,
/// path-hash size and off-grid client repeat). Stays open when the radio
/// rejects or fails to apply the settings so the user's edits are not lost.
class RadioSettingsDialog extends StatefulWidget {
  final MeshCoreConnector connector;

  const RadioSettingsDialog({super.key, required this.connector});

  @override
  State<RadioSettingsDialog> createState() => _RadioSettingsDialogState();
}

class _RadioSettingsDialogState extends State<RadioSettingsDialog> {
  final _frequencyController = TextEditingController();
  LoRaBandwidth _bandwidth = LoRaBandwidth.bw125;
  LoRaSpreadingFactor _spreadingFactor = LoRaSpreadingFactor.sf7;
  LoRaCodingRate _codingRate = LoRaCodingRate.cr4_5;
  final _txPowerController = TextEditingController(text: '20');
  bool _clientRepeat = false;
  int _pathHashByteWidth = 1;
  int? _selectedPresetIndex;
  _RadioSettingsSnapshot? _lastNonRepeatSnapshot;
  String? _frequencyError;
  String? _txPowerError;

  bool get _supportsPathHashMode => widget.connector.supportsPathHashMode;

  AppDebugLogService get _appLog =>
      Provider.of<AppDebugLogService>(context, listen: false);

  @override
  void initState() {
    super.initState();

    // Populate with current settings if available
    if (widget.connector.currentFreqHz != null) {
      _frequencyController.text = (widget.connector.currentFreqHz! / 1000.0)
          .toStringAsFixed(3);
    } else {
      _frequencyController.text = '915.0';
    }

    if (widget.connector.currentBwHz != null) {
      // Find matching bandwidth enum
      final bwValue = widget.connector.currentBwHz!;
      for (var bw in LoRaBandwidth.values) {
        if (bw.hz == bwValue) {
          _bandwidth = bw;
          break;
        }
      }
    }

    if (widget.connector.currentSf != null) {
      // Find matching spreading factor enum
      final sfValue = widget.connector.currentSf!;
      for (var sf in LoRaSpreadingFactor.values) {
        if (sf.value == sfValue) {
          _spreadingFactor = sf;
          break;
        }
      }
    }

    if (widget.connector.currentCr != null) {
      // Find matching coding rate enum
      final crValue = _toUiCodingRate(widget.connector.currentCr!);
      for (var cr in LoRaCodingRate.values) {
        if (cr.value == crValue) {
          _codingRate = cr;
          break;
        }
      }
    }

    if (widget.connector.currentTxPower != null) {
      _txPowerController.text = widget.connector.currentTxPower.toString();
    }

    _pathHashByteWidth = widget.connector.pathHashByteWidth;
    _clientRepeat = widget.connector.clientRepeat ?? false;
    _selectedPresetIndex = _findMatchingPresetIndex();
    if (_clientRepeat) {
      _lastNonRepeatSnapshot =
          _sessionRememberedNonRepeatSnapshot() ??
          _inferNonRepeatSnapshotForRepeatEnabled();
      _selectedPresetIndex = _findMatchingPresetIndexForSnapshot(
        _lastNonRepeatSnapshot!,
      );
    } else {
      _lastNonRepeatSnapshot = _nonRepeatSnapshotForCurrentSelection();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _logRadioSettingsState('Dialog initialized');
    });
  }

  @override
  void dispose() {
    _frequencyController.dispose();
    _txPowerController.dispose();
    super.dispose();
  }

  void _applyPreset(int index) {
    setState(() {
      _applyPresetState(index);
    });
    _logRadioSettingsState(
      'Applied preset ${RadioSettings.presets[index].$1} (#$index)',
    );
  }

  int? _findMatchingPresetIndex() {
    return _findMatchingPresetIndexForSnapshot(_currentSnapshot());
  }

  int? _findMatchingPresetIndexForSnapshot(_RadioSettingsSnapshot snapshot) {
    for (final i in _visiblePresetIndexes()) {
      final preset = RadioSettings.presets[i].$2;
      if (preset.frequencyHz == snapshot.frequencyHz &&
          preset.bandwidth == snapshot.bandwidth &&
          preset.spreadingFactor == snapshot.spreadingFactor &&
          preset.codingRate == snapshot.codingRate) {
        return i;
      }
    }
    return null;
  }

  Iterable<int> _visiblePresetIndexes() sync* {
    for (var i = 0; i < RadioSettings.presets.length; i++) {
      if (_isOffGridPresetIndex(i)) {
        continue;
      }
      yield i;
    }
  }

  _RadioSettingsSnapshot _currentSnapshot() {
    final frequencyMHz = double.tryParse(_frequencyController.text) ?? 915.0;
    final txPowerDbm = int.tryParse(_txPowerController.text) ?? 20;
    return _RadioSettingsSnapshot(
      frequencyMHz: frequencyMHz,
      bandwidth: _bandwidth,
      spreadingFactor: _spreadingFactor,
      codingRate: _codingRate,
      txPowerDbm: txPowerDbm,
    );
  }

  bool _isOffGridPresetIndex(int? index) {
    if (index == null) return false;
    return RadioSettings.presets[index].$1.startsWith('Off-Grid ');
  }

  double _offGridFrequencyForBaseFrequency(double baseFrequencyMHz) {
    final baseKHz = (baseFrequencyMHz * 1000).round();
    final ranges = widget.connector.allowedRepeatFreqRanges;
    final candidates = ranges == null || ranges.isEmpty
        ? _defaultRepeatFreqsKHz
        : {for (final r in ranges) baseKHz.clamp(r.lowKHz, r.highKHz)};
    final closestKHz = candidates.reduce(
      (a, b) => (a - baseKHz).abs() <= (b - baseKHz).abs() ? a : b,
    );
    return closestKHz / 1000.0;
  }

  double _normalFrequencyForBand(double frequencyMHz) {
    if (frequencyMHz < 500) return 433.650;
    if (frequencyMHz < 900) return 869.432;
    return 915.8;
  }

  _RadioSettingsSnapshot _fallbackNonRepeatSnapshot(
    double currentFrequencyMHz,
  ) {
    return _RadioSettingsSnapshot(
      frequencyMHz: _normalFrequencyForBand(currentFrequencyMHz),
      bandwidth: _bandwidth,
      spreadingFactor: _spreadingFactor,
      codingRate: _codingRate,
      txPowerDbm: int.tryParse(_txPowerController.text) ?? 20,
    );
  }

  _RadioSettingsSnapshot _nonRepeatSnapshotForCurrentSelection() {
    final current = _currentSnapshot();
    if (!_isOffGridPresetIndex(_selectedPresetIndex)) {
      return current;
    }
    return _fallbackNonRepeatSnapshot(current.frequencyMHz);
  }

  _RadioSettingsSnapshot? _sessionRememberedNonRepeatSnapshot() {
    final snapshot = widget.connector.rememberedNonRepeatRadioState;
    if (snapshot == null) return null;
    return _RadioSettingsSnapshot.fromMeshCoreSnapshot(snapshot);
  }

  _RadioSettingsSnapshot _inferNonRepeatSnapshotForRepeatEnabled() {
    final current = _currentSnapshot();
    for (final i in _visiblePresetIndexes()) {
      final preset = RadioSettings.presets[i].$2;
      final offGridFreqHz =
          (_offGridFrequencyForBaseFrequency(preset.frequencyMHz) * 1000)
              .round();
      if (offGridFreqHz == current.frequencyHz &&
          preset.bandwidth == current.bandwidth &&
          preset.spreadingFactor == current.spreadingFactor &&
          preset.codingRate == current.codingRate) {
        return _RadioSettingsSnapshot(
          frequencyMHz: preset.frequencyMHz,
          bandwidth: preset.bandwidth,
          spreadingFactor: preset.spreadingFactor,
          codingRate: preset.codingRate,
          txPowerDbm: current.txPowerDbm,
        );
      }
    }
    return _fallbackNonRepeatSnapshot(current.frequencyMHz);
  }

  void _applySnapshot(_RadioSettingsSnapshot snapshot) {
    _frequencyController.text = snapshot.frequencyMHz.toStringAsFixed(3);
    _bandwidth = snapshot.bandwidth;
    _spreadingFactor = snapshot.spreadingFactor;
    _codingRate = snapshot.codingRate;
    _txPowerController.text = snapshot.txPowerDbm.toString();
  }

  void _applyPresetState(int index) {
    final preset = RadioSettings.presets[index].$2;
    final baseSnapshot = _RadioSettingsSnapshot(
      frequencyMHz: preset.frequencyMHz,
      bandwidth: preset.bandwidth,
      spreadingFactor: preset.spreadingFactor,
      codingRate: preset.codingRate,
      txPowerDbm: preset.txPowerDbm,
    );
    final frequencyMHz = _clientRepeat
        ? _offGridFrequencyForBaseFrequency(baseSnapshot.frequencyMHz)
        : baseSnapshot.frequencyMHz;
    _frequencyController.text = frequencyMHz.toString();
    _bandwidth = preset.bandwidth;
    _spreadingFactor = preset.spreadingFactor;
    _codingRate = preset.codingRate;
    _txPowerController.text = preset.txPowerDbm.toString();
    _selectedPresetIndex = index;
    _lastNonRepeatSnapshot = baseSnapshot;
    // Programmatic writes skip TextField.onChanged, so clear any stale
    // frequency/TX errors here or Save stays disabled.
    _validateFields();
  }

  void _syncPresetSelection() {
    final previousPresetIndex = _selectedPresetIndex;
    final previousLastNonRepeat = _lastNonRepeatSnapshot;
    if (_clientRepeat) {
      final baseSnapshot =
          previousLastNonRepeat ?? _inferNonRepeatSnapshotForRepeatEnabled();
      if (_bandwidth != baseSnapshot.bandwidth ||
          _spreadingFactor != baseSnapshot.spreadingFactor ||
          _codingRate != baseSnapshot.codingRate ||
          (int.tryParse(_txPowerController.text) ?? 20) !=
              baseSnapshot.txPowerDbm) {
        _lastNonRepeatSnapshot = _RadioSettingsSnapshot(
          frequencyMHz: baseSnapshot.frequencyMHz,
          bandwidth: _bandwidth,
          spreadingFactor: _spreadingFactor,
          codingRate: _codingRate,
          txPowerDbm: int.tryParse(_txPowerController.text) ?? 20,
        );
      }
      _selectedPresetIndex = _findMatchingPresetIndexForSnapshot(
        _lastNonRepeatSnapshot ?? baseSnapshot,
      );
      if (previousPresetIndex != _selectedPresetIndex ||
          previousLastNonRepeat != _lastNonRepeatSnapshot) {
        _logRadioSettingsState(
          'Preset match updated while repeat enabled: ${_presetLabel(previousPresetIndex)} -> ${_presetLabel(_selectedPresetIndex)}',
        );
      }
      return;
    }
    _lastNonRepeatSnapshot = _nonRepeatSnapshotForCurrentSelection();
    _selectedPresetIndex = _findMatchingPresetIndexForSnapshot(
      _lastNonRepeatSnapshot!,
    );
    if (previousPresetIndex != _selectedPresetIndex ||
        previousLastNonRepeat != _lastNonRepeatSnapshot) {
      _logRadioSettingsState(
        'Preset sync updated state from ${_presetLabel(previousPresetIndex)} to ${_presetLabel(_selectedPresetIndex)}',
      );
    }
  }

  void _handleManualSettingsChanged(String source) {
    _logRadioSettingsState('Manual settings edit: $source');
    setState(() {
      _validateFields();
      _syncPresetSelection();
    });
  }

  void _validateFields() {
    final l10n = context.l10n;
    final freqMHz = double.tryParse(_frequencyController.text);
    _frequencyError = (freqMHz == null || freqMHz < 150 || freqMHz > 2500)
        ? l10n.settings_frequencyInvalid
        : null;

    final maxTxPower = widget.connector.maxTxPower ?? 22;
    final txPower = int.tryParse(_txPowerController.text);
    _txPowerError =
        (txPower == null || txPower < _minTxPowerDbm || txPower > maxTxPower)
        ? l10n.settings_txPowerInvalidRange(_minTxPowerDbm, maxTxPower)
        : null;
  }

  void _handleClientRepeatChanged(bool enabled) {
    _logRadioSettingsState(
      'Off-grid repeat toggle requested: $_clientRepeat -> $enabled',
    );
    setState(() {
      final currentSnapshot = _currentSnapshot();
      if (enabled) {
        if (!_clientRepeat) {
          _syncPresetSelection();
        }
        final baseSnapshot = _lastNonRepeatSnapshot ?? currentSnapshot;
        _clientRepeat = true;
        _frequencyController.text = _offGridFrequencyForBaseFrequency(
          baseSnapshot.frequencyMHz,
        ).toStringAsFixed(3);
        _validateFields();
        return;
      }

      _clientRepeat = false;
      _applySnapshot(
        _lastNonRepeatSnapshot ??
            _fallbackNonRepeatSnapshot(currentSnapshot.frequencyMHz),
      );
      _validateFields();
      _syncPresetSelection();
    });
    _logRadioSettingsState('Off-grid repeat toggle applied');
  }

  Future<void> _saveSettings() async {
    final l10n = context.l10n;
    final freqMHz = double.tryParse(_frequencyController.text);
    final txPower = int.tryParse(_txPowerController.text);

    if (freqMHz == null || freqMHz < 150 || freqMHz > 2500) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_frequencyInvalid),
      );
      return;
    }

    final maxTxPower = widget.connector.maxTxPower ?? 22;
    if (txPower == null || txPower < _minTxPowerDbm || txPower > maxTxPower) {
      showDismissibleSnackBar(
        context,
        content: Text(
          l10n.settings_txPowerInvalidRange(_minTxPowerDbm, maxTxPower),
        ),
      );
      return;
    }

    final freqHz = (freqMHz * 1000).round();
    final bwHz = _bandwidth.hz;
    final sf = _spreadingFactor.value;
    final cr = _codingRate.value;

    // if the client repeat isnt null then we know its supported
    //otherwise we leave it out of the frame to avoid accidentally enabling
    final knownRepeat = widget.connector.clientRepeat != null;

    if (knownRepeat) {
      if (_clientRepeat && !_isAllowedRepeatFreqKHz(widget.connector, freqHz)) {
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_clientRepeatFreqWarning),
        );
        return;
      }
    }

    try {
      _logRadioSettingsState('Saving radio settings');
      final accepted = await widget.connector.setRadioParams(
        freqHz,
        bwHz,
        sf,
        cr,
        clientRepeat: knownRepeat ? _clientRepeat : null,
      );
      if (!accepted) {
        _logRadioSettingsState('Radio rejected requested settings');
        if (!mounted) return;
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_radioSettingsNotApplied),
        );
        return;
      }
      await widget.connector.sendFrame(buildSetRadioTxPowerFrame(txPower));
      // setPathHashMode updates the local width optimistically; the refreshed
      // DEVICE_INFO below overwrites it with what the radio actually stored.
      final requestedPathHashWidth =
          _supportsPathHashMode &&
              _pathHashByteWidth != widget.connector.pathHashByteWidth
          ? _pathHashByteWidth
          : null;
      if (requestedPathHashWidth != null) {
        await widget.connector.setPathHashMode(requestedPathHashWidth - 1);
      }
      final selfInfo = widget.connector.receivedFrames
          .firstWhere((f) => f.isNotEmpty && f[0] == respCodeSelfInfo)
          .timeout(const Duration(seconds: 5));
      final deviceInfo = requestedPathHashWidth == null
          ? null
          : widget.connector.receivedFrames
                .firstWhere((f) => f.isNotEmpty && f[0] == respCodeDeviceInfo)
                .timeout(const Duration(seconds: 5));
      await widget.connector.refreshDeviceInfo();
      // Without a refreshed DEVICE_INFO the path hash change is unconfirmed
      // (this also covers setPathHashMode skipping a disconnected radio).
      final pathHashApplied =
          deviceInfo == null ||
          await deviceInfo.then(
            (_) => widget.connector.pathHashByteWidth == requestedPathHashWidth,
            onError: (_) => false,
          );
      final radioApplied = await selfInfo.then(
        (_) => _deviceMatches(
          freqHz: freqHz,
          bwHz: bwHz,
          sf: sf,
          cr: cr,
          txPower: txPower,
          clientRepeat: knownRepeat ? _clientRepeat : null,
        ),
        onError: (_) => true,
      );
      if (!radioApplied) {
        _logRadioSettingsState('Radio did not apply requested settings');
        if (!mounted) return;
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_radioSettingsNotApplied),
        );
        return;
      }
      if (!pathHashApplied) {
        // Radio params and TX power were already applied; only the path
        // hash size is outstanding, so say that rather than a generic error.
        _logRadioSettingsState('Radio did not apply requested path hash size');
        if (!mounted) return;
        showDismissibleSnackBar(
          context,
          content: Text(l10n.settings_pathHashModeNotApplied),
        );
        return;
      }
      final rememberedSnapshot = _clientRepeat
          ? _lastNonRepeatSnapshot
          : _currentSnapshot();
      if (rememberedSnapshot != null) {
        widget.connector.rememberNonRepeatRadioState(
          rememberedSnapshot.toMeshCoreSnapshot(),
        );
      }

      if (!mounted) return;
      _logRadioSettingsState('Radio settings saved successfully');
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_radioSettingsUpdated),
      );
      Navigator.pop(context);
    } catch (e) {
      _appLog.warn('Radio settings save failed: $e', tag: 'RadioSettings');
      if (!mounted) return;
      // Keep the dialog open, like the rejected/not-applied paths, so the
      // user's edits survive a transient failure and can be retried.
      showDismissibleSnackBar(
        context,
        content: Text(l10n.settings_error(e.toString())),
      );
    }
  }

  bool _deviceMatches({
    required int freqHz,
    required int bwHz,
    required int sf,
    required int cr,
    required int txPower,
    required bool? clientRepeat,
  }) {
    final c = widget.connector;
    // Firmware stores freq/bw as float MHz/kHz, so allow 1 unit of rounding.
    return c.currentFreqHz != null &&
        (c.currentFreqHz! - freqHz).abs() <= 1 &&
        c.currentBwHz != null &&
        (c.currentBwHz! - bwHz).abs() <= 1 &&
        c.currentSf == sf &&
        c.currentCr != null &&
        _toUiCodingRate(c.currentCr!) == cr &&
        c.currentTxPower == txPower &&
        (clientRepeat == null || c.clientRepeat == clientRepeat);
  }

  String _presetLabel(int? index) {
    if (index == null) {
      return 'custom';
    }
    return '${RadioSettings.presets[index].$1} (#$index)';
  }

  String _formatSnapshot(_RadioSettingsSnapshot? snapshot) {
    if (snapshot == null) {
      return 'null';
    }
    return '${snapshot.frequencyMHz.toStringAsFixed(3)}MHz/'
        '${snapshot.bandwidth.label}/'
        '${snapshot.spreadingFactor.label}/'
        '${snapshot.codingRate.label}/'
        '${snapshot.txPowerDbm}dBm';
  }

  void _logRadioSettingsState(String message) {
    if (!kDebugMode) return;
    _appLog.info(
      '$message | '
      'freq=${_frequencyController.text}MHz '
      'bw=${_bandwidth.label} '
      'sf=${_spreadingFactor.label} '
      'cr=${_codingRate.label} '
      'tx=${_txPowerController.text}dBm '
      'pathHash=${_pathHashByteWidth}B '
      'repeat=$_clientRepeat '
      'preset=${_presetLabel(_selectedPresetIndex)} '
      'lastNonRepeat=${_formatSnapshot(_lastNonRepeatSnapshot)}',
      tag: 'RadioSettings',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.settings_radioSettings),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey<int?>(_selectedPresetIndex),
              initialValue: _selectedPresetIndex ?? -1,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.settings_presets,
                border: const OutlineInputBorder(),
              ),
              items: [
                if (_selectedPresetIndex == null)
                  DropdownMenuItem(
                    value: -1,
                    child: Text(l10n.settings_presetCustom),
                  ),
                for (final i in _visiblePresetIndexes())
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      RadioSettings.presets[i].$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (index) {
                if (index != null && index >= 0) {
                  _applyPreset(index);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _frequencyController,
              onChanged: (_) => _handleManualSettingsChanged('frequency'),
              decoration: InputDecoration(
                labelText: l10n.settings_frequency,
                border: const OutlineInputBorder(),
                helperText: _clientRepeat
                    ? l10n.settings_clientRepeatFrequencyNote(
                        _frequencyController.text,
                      )
                    : l10n.settings_frequencyHelper,
                errorText: _frequencyError,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LoRaBandwidth>(
              isExpanded: true,
              initialValue: _bandwidth,
              decoration: InputDecoration(
                labelText: l10n.settings_bandwidth,
                border: const OutlineInputBorder(),
              ),
              items: LoRaBandwidth.values
                  .map(
                    (bw) => DropdownMenuItem(
                      value: bw,
                      child: Text(bw.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _bandwidth = value;
                    _syncPresetSelection();
                  });
                  _logRadioSettingsState('Manual settings edit: bandwidth');
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LoRaSpreadingFactor>(
              isExpanded: true,
              initialValue: _spreadingFactor,
              decoration: InputDecoration(
                labelText: l10n.settings_spreadingFactor,
                border: const OutlineInputBorder(),
              ),
              items: LoRaSpreadingFactor.values
                  .map(
                    (sf) => DropdownMenuItem(
                      value: sf,
                      child: Text(sf.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _spreadingFactor = value;
                    _syncPresetSelection();
                  });
                  _logRadioSettingsState(
                    'Manual settings edit: spreading factor',
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LoRaCodingRate>(
              isExpanded: true,
              initialValue: _codingRate,
              decoration: InputDecoration(
                labelText: l10n.settings_codingRate,
                border: const OutlineInputBorder(),
              ),
              items: LoRaCodingRate.values
                  .map(
                    (cr) => DropdownMenuItem(
                      value: cr,
                      child: Text(cr.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _codingRate = value;
                    _syncPresetSelection();
                  });
                  _logRadioSettingsState('Manual settings edit: coding rate');
                }
              },
            ),
            const SizedBox(height: 16),
            if (_supportsPathHashMode) ...[
              // Values are path hash modes (0-2, byte width - 1), matching
              // the selectors in settings_screen and repeater_settings_screen.
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: (_pathHashByteWidth - 1).clamp(0, 2).toInt(),
                decoration: InputDecoration(
                  labelText: l10n.repeater_pathHashMode,
                  helperText: l10n.settings_pathHashModeHelper,
                  helperMaxLines: 5,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 0,
                    child: Text(
                      l10n.repeater_pathHashModeOption0,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 1,
                    child: Text(
                      l10n.repeater_pathHashModeOption1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text(
                      l10n.repeater_pathHashModeOption2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _pathHashByteWidth = value + 1);
                  _logRadioSettingsState(
                    'Manual settings edit: path hash size',
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _txPowerController,
              onChanged: (_) => _handleManualSettingsChanged('tx power'),
              decoration: InputDecoration(
                labelText: l10n.settings_txPower,
                border: const OutlineInputBorder(),
                helperText: l10n.settings_txPowerRangeHelper(
                  _minTxPowerDbm,
                  widget.connector.maxTxPower ?? 22,
                ),
                errorText: _txPowerError,
              ),
              keyboardType: TextInputType.number,
            ),
            if (widget.connector.clientRepeat != null) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(l10n.settings_clientRepeat),
                subtitle: Text(l10n.settings_clientRepeatSubtitle),
                value: _clientRepeat,
                onChanged: _handleClientRepeatChanged,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.settings_radioMatchWarning,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: (_frequencyError != null || _txPowerError != null)
              ? null
              : _saveSettings,
          child: Text(l10n.common_save),
        ),
      ],
    );
  }
}

class _RadioSettingsSnapshot {
  final double frequencyMHz;
  final LoRaBandwidth bandwidth;
  final LoRaSpreadingFactor spreadingFactor;
  final LoRaCodingRate codingRate;
  final int txPowerDbm;

  const _RadioSettingsSnapshot({
    required this.frequencyMHz,
    required this.bandwidth,
    required this.spreadingFactor,
    required this.codingRate,
    required this.txPowerDbm,
  });

  /// Frequency in integer Hz — avoids floating-point comparison issues.
  int get frequencyHz => (frequencyMHz * 1000).round();

  /// Convert from the connector's raw-int snapshot to UI-enum snapshot.
  static _RadioSettingsSnapshot? fromMeshCoreSnapshot(
    MeshCoreRadioStateSnapshot snapshot,
  ) {
    final bw = LoRaBandwidth.values
        .where((b) => b.hz == snapshot.bwHz)
        .firstOrNull;
    final sf = LoRaSpreadingFactor.values
        .where((s) => s.value == snapshot.sf)
        .firstOrNull;
    final cr = LoRaCodingRate.values
        .where((c) => c.value == _toUiCodingRate(snapshot.cr))
        .firstOrNull;
    if (bw == null || sf == null || cr == null) return null;
    return _RadioSettingsSnapshot(
      frequencyMHz: snapshot.freqHz / 1000.0,
      bandwidth: bw,
      spreadingFactor: sf,
      codingRate: cr,
      txPowerDbm: snapshot.txPowerDbm,
    );
  }

  /// Convert back to the connector's raw-int snapshot.
  MeshCoreRadioStateSnapshot toMeshCoreSnapshot() {
    return MeshCoreRadioStateSnapshot(
      freqHz: frequencyHz,
      bwHz: bandwidth.hz,
      sf: spreadingFactor.value,
      cr: codingRate.value,
      txPowerDbm: txPowerDbm,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _RadioSettingsSnapshot &&
        frequencyHz == other.frequencyHz &&
        bandwidth == other.bandwidth &&
        spreadingFactor == other.spreadingFactor &&
        codingRate == other.codingRate &&
        txPowerDbm == other.txPowerDbm;
  }

  @override
  int get hashCode => Object.hash(
    frequencyHz,
    bandwidth,
    spreadingFactor,
    codingRate,
    txPowerDbm,
  );
}
