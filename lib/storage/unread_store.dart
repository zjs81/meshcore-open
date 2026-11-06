import 'dart:async';
import 'dart:convert';

import '../utils/app_logger.dart';
import 'legacy_key_migration.dart';
import 'prefs_manager.dart';

/// Storage for unread message tracking with debounced writes to reduce I/O.
class UnreadStore {
  static const String _keyPrefix = 'contact_unread_count';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length >= 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  // Debounce timers to batch rapid writes
  Timer? _contactUnreadSaveTimer;
  static const Duration _saveDebounceDuration = Duration(milliseconds: 500);

  // Pending write data
  Map<String, int>? _pendingContactUnreadCount;

  /// Dispose timers when no longer needed
  void dispose() {
    _contactUnreadSaveTimer?.cancel();
  }

  Future<Map<String, int>> loadContactUnreadCount() async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load unread counts.');
      return {};
    }
    final prefs = PrefsManager.instance;
    String? jsonString = prefs.getString(keyFor);
    if ((jsonString == null || jsonString.isEmpty) &&
        canMigrateLegacyKeys(publicKeyHex)) {
      // Attempt migration from legacy unscoped key on first load
      final legacyJsonString = prefs.getString(_keyPrefix);
      prefs.remove(_keyPrefix);
      if (legacyJsonString != null && legacyJsonString.isNotEmpty) {
        appLogger.info(
          'Migrating channel messages from legacy key $_keyPrefix to scoped key $keyFor',
        );
        await prefs.setString(keyFor, legacyJsonString);
        jsonString = legacyJsonString;
      }
    }
    if (jsonString == null || jsonString.isEmpty) {
      jsonString = prefs.getString(keyFor);
    }
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      appLogger.warn('Stored unread counts are unreadable: $e');
      return {};
    }
    final counts = <String, int>{};
    json.forEach((key, value) {
      if (value is int) {
        counts[key] = value;
      } else if (value is num) {
        counts[key] = value.toInt();
      }
    });
    return counts;
  }

  void saveContactUnreadCount(Map<String, int> counts) {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save unread counts.');
      return;
    }
    _pendingContactUnreadCount = counts;

    _contactUnreadSaveTimer?.cancel();

    _contactUnreadSaveTimer = Timer(_saveDebounceDuration, () async {
      if (_pendingContactUnreadCount != null) {
        await _flushContactUnreadCount();
      }
    });
  }

  Future<void> _flushContactUnreadCount() async {
    if (_pendingContactUnreadCount == null) return;

    final prefs = PrefsManager.instance;
    final jsonStr = jsonEncode(_pendingContactUnreadCount);
    await prefs.setString(keyFor, jsonStr);
    _pendingContactUnreadCount = null;
  }

  /// Immediately flush pending writes (call before app termination or disposal)
  Future<void> flush() async {
    _contactUnreadSaveTimer?.cancel();
    await _flushContactUnreadCount();
  }
}
