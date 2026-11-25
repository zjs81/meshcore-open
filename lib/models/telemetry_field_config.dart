import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../storage/prefs_manager.dart';

/// User-defined label and unit for one telemetry field of one node.
@immutable
class TelemetryFieldOverride {
  final String label;
  final String unit;

  const TelemetryFieldOverride({this.label = '', this.unit = ''});

  bool get isEmpty => label.isEmpty && unit.isEmpty;
}

/// User-defined labels and units for the telemetry fields of a single node,
/// persisted as JSON in shared preferences under `telemetry_field_config_<key>`.
///
/// Entries are keyed by `TelemetryFieldConfig.keyFor(channel, field)`, so the
/// same sensor type on different LPP channels can be labelled separately.
class TelemetryFieldConfig {
  TelemetryFieldConfig._(this.publicKeyHex, this.overrides);

  factory TelemetryFieldConfig.load(String publicKeyHex) {
    final raw = PrefsManager.instance.getString(storageKeyFor(publicKeyHex));
    if (raw == null || raw.isEmpty) {
      return TelemetryFieldConfig._(publicKeyHex, {});
    }
    final overrides = <String, TelemetryFieldOverride>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return TelemetryFieldConfig._(publicKeyHex, {});
      for (final entry in decoded.entries) {
        if (entry.key is! String || entry.value is! Map) continue;
        final label = entry.value['label'];
        final unit = entry.value['unit'];
        final override = TelemetryFieldOverride(
          label: label is String ? label : '',
          unit: unit is String ? unit : '',
        );
        if (!override.isEmpty) overrides[entry.key as String] = override;
      }
    } catch (e) {
      return TelemetryFieldConfig._(publicKeyHex, {});
    }
    return TelemetryFieldConfig._(publicKeyHex, overrides);
  }

  final String publicKeyHex;
  final Map<String, TelemetryFieldOverride> overrides;

  static String storageKeyFor(String publicKeyHex) =>
      'telemetry_field_config_$publicKeyHex';

  static String keyFor(int channel, String field) => '$channel:$field';

  TelemetryFieldOverride? overrideFor(int channel, String field) =>
      overrides[keyFor(channel, field)];

  /// Merges [updates] into the stored overrides, dropping entries whose label
  /// and unit are both empty, and persists the result.
  Future<void> save(Map<String, TelemetryFieldOverride> updates) async {
    for (final entry in updates.entries) {
      if (entry.value.isEmpty) {
        overrides.remove(entry.key);
      } else {
        overrides[entry.key] = entry.value;
      }
    }
    final prefs = PrefsManager.instance;
    if (overrides.isEmpty) {
      await prefs.remove(storageKeyFor(publicKeyHex));
      return;
    }
    final encoded = <String, Map<String, String>>{};
    for (final entry in overrides.entries) {
      encoded[entry.key] = {
        if (entry.value.label.isNotEmpty) 'label': entry.value.label,
        if (entry.value.unit.isNotEmpty) 'unit': entry.value.unit,
      };
    }
    await prefs.setString(storageKeyFor(publicKeyHex), jsonEncode(encoded));
  }
}
