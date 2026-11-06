import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_filter.dart';
import 'prefs_manager.dart';

/// Global (not per-radio) persistence for the message filter: settings, user
/// rules and the classifier's training examples. Values are JSON strings in
/// SharedPreferences. Loads are synchronous; saves are async.
///
/// Malformed stored data is tolerated: bad records are skipped and missing or
/// unreadable values fall back to defaults.
class MessageFilterStore {
  static const String settingsKey = 'message_filter_settings';
  static const String rulesKey = 'message_filter_rules';
  static const String spamExamplesKey = 'message_filter_spam_examples';
  static const String hamExamplesKey = 'message_filter_ham_examples';
  static const String recentCleanKey = 'message_filter_recent_clean';

  SharedPreferences? get _prefs {
    try {
      return PrefsManager.instance;
    } on StateError {
      return null;
    }
  }

  Object? _decode(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (e) {
      debugPrint('MessageFilterStore: failed to decode $key: $e');
      return null;
    }
  }

  List<T> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final decoded = _decode(key);
    if (decoded is! List) return <T>[];
    final result = <T>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      try {
        result.add(fromJson(Map<String, dynamic>.from(item)));
      } catch (e) {
        debugPrint('MessageFilterStore: skipping bad record in $key: $e');
      }
    }
    return result;
  }

  Future<void> _encode(String key, Object value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(key, jsonEncode(value));
  }

  MessageFilterSettings loadSettings() {
    final decoded = _decode(settingsKey);
    if (decoded is! Map) return MessageFilterSettings.defaults;
    try {
      return MessageFilterSettings.fromJson(Map<String, dynamic>.from(decoded));
    } catch (e) {
      debugPrint('MessageFilterStore: bad settings: $e');
      return MessageFilterSettings.defaults;
    }
  }

  Future<void> saveSettings(MessageFilterSettings settings) =>
      _encode(settingsKey, settings.toJson());

  List<FilterRule> loadRules() => _decodeList(
    rulesKey,
    FilterRule.fromJson,
  ).where((rule) => rule.id.isNotEmpty && rule.pattern.isNotEmpty).toList();

  Future<void> saveRules(List<FilterRule> rules) =>
      _encode(rulesKey, rules.map((r) => r.toJson()).toList());

  List<FilterExample> loadSpamExamples() =>
      _decodeList(spamExamplesKey, FilterExample.fromJson);

  Future<void> saveSpamExamples(List<FilterExample> examples) =>
      _encode(spamExamplesKey, examples.map((e) => e.toJson()).toList());

  List<FilterExample> loadHamExamples() =>
      _decodeList(hamExamplesKey, FilterExample.fromJson);

  Future<void> saveHamExamples(List<FilterExample> examples) =>
      _encode(hamExamplesKey, examples.map((e) => e.toJson()).toList());

  List<FilterExample> loadRecentClean() =>
      _decodeList(recentCleanKey, FilterExample.fromJson);

  Future<void> saveRecentClean(List<FilterExample> examples) =>
      _encode(recentCleanKey, examples.map((e) => e.toJson()).toList());
}
