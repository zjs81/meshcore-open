import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import 'history_store_stub.dart'
    if (dart.library.io) 'history_store_io.dart'
    as platform;
import 'prefs_manager.dart';

/// Histories use an indexed native store; preferences remain the web backend.
abstract class HistoryStore {
  static HistoryStore _instance = PreferencesHistoryStore();
  static HistoryStore get instance => _instance;

  static bool isHistoryKey(String key) =>
      key.startsWith('messages_') ||
      key.startsWith('channel_messages_') ||
      key.startsWith('path_history_');

  static bool isSequenceKey(String key) =>
      key.startsWith('messages_') || key.startsWith('channel_messages_');

  /// Set while a run had to keep histories in preferences because the
  /// database could not be opened; the next launch that opens it merges them.
  static const String fallbackRunKey = 'history_fallback_run';

  /// Never throws: a database that cannot be opened must not keep the app
  /// from starting, so this run keeps histories in preferences instead.
  static Future<void> initialize() async {
    try {
      _instance = await platform.createHistoryStore();
    } catch (error) {
      // The app logger is not set up this early.
      debugPrint('History database unavailable: $error');
      _instance = PreferencesHistoryStore();
      await PrefsManager.instance.setBool(fallbackRunKey, true);
    }
  }

  static void use(HistoryStore store) => _instance = store;
  static void reset() => _instance = PreferencesHistoryStore();

  Future<String?> getString(String key);
  Future<bool> setString(String key, String value);
  Future<bool> remove(String key);
  Future<Set<String>> getKeys();
  Future<int> entryCount(String key);
  Future<List<String>> readEntries(String key, {int offset = 0, int? limit});

  /// Replaces the visible tail, preserving the first [preservedCount] entries.
  /// Returns the number of preserved entries remaining after the storage cap.
  Future<int> replaceTail(
    String key,
    int preservedCount,
    List<String> entries, {
    int maxEntries = 1000,
  });

  Future<void> close() async {}
}

class PreferencesHistoryStore extends HistoryStore {
  SharedPreferences? _preferences;
  SharedPreferences get _prefs => _preferences ??= PrefsManager.instance;
  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<bool> remove(String key) async {
    final prefs = _prefs;
    return !prefs.containsKey(key) || await prefs.remove(key);
  }

  @override
  Future<Set<String>> getKeys() async =>
      _prefs.getKeys().where(HistoryStore.isHistoryKey).toSet();

  /// Encoded entries of recently used histories, so paging and saves do not
  /// re-parse the blob or re-encode the preserved prefix each time. An entry
  /// is used only while the stored string is the one it was split from.
  static const int _maxDecoded = 8;
  final Map<String, (String, List<String>)> _decoded = {};

  Future<List<String>> _entries(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return const [];
    final cached = _decoded[key];
    if (cached != null && cached.$1 == raw) return cached.$2;
    final decoded = jsonDecode(raw);
    if (decoded is! List) throw const FormatException('Expected message array');
    return _remember(key, raw, decoded.map(jsonEncode).toList());
  }

  List<String> _remember(String key, String raw, List<String> entries) {
    _decoded.remove(key);
    _decoded[key] = (raw, entries);
    if (_decoded.length > _maxDecoded) _decoded.remove(_decoded.keys.first);
    return entries;
  }

  @override
  Future<List<String>> readEntries(
    String key, {
    int offset = 0,
    int? limit,
  }) async {
    RangeError.checkNotNegative(offset, 'offset');
    if (limit != null) RangeError.checkNotNegative(limit, 'limit');
    final selected = (await _entries(key)).skip(offset);
    return (limit == null ? selected : selected.take(limit)).toList();
  }

  @override
  Future<int> entryCount(String key) async => (await _entries(key)).length;

  @override
  Future<int> replaceTail(
    String key,
    int preservedCount,
    List<String> entries, {
    int maxEntries = 1000,
  }) async {
    RangeError.checkNotNegative(preservedCount, 'preservedCount');
    RangeError.checkNotNegative(maxEntries, 'maxEntries');
    List<String> previous;
    try {
      previous = (await _entries(key)).take(preservedCount).toList();
    } on FormatException catch (error) {
      // Preferences hold one value per key, so the save replaces it.
      appLogger.warn('Replacing unreadable history $key: $error');
      previous = [];
    }
    final combined = [...previous, ...entries];
    final overflow = (combined.length - maxEntries).clamp(0, combined.length);
    final kept = combined.sublist(overflow);
    final raw = '[${kept.join(',')}]';
    if (!await setString(key, raw)) {
      throw StateError('Could not save message history');
    }
    _remember(key, raw, kept);
    return (previous.length - overflow).clamp(0, previous.length);
  }
}
