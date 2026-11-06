import 'dart:convert';
import '../models/delivery_observation.dart';
import '../models/path_history.dart';
import '../storage/legacy_key_migration.dart';
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';

class StorageService {
  static const String _pathHistoryPrefix = 'path_history_';
  static const String _pendingMessagesKey = 'pending_messages';
  static const String _repeaterPasswordsKey = 'repeater_passwords';
  static const String _repeaterAutoClockSyncAfterLoginKey =
      'repeater_auto_clock_sync_after_login';
  static const String _deliveryObservationsKey = 'delivery_observations';

  /// App-wide keys (not scoped to a radio) that hold per-repeater data. Review
  /// mode snapshots and restores them so simulated logins leave nothing behind.
  static const List<String> globalRepeaterKeys = [
    _repeaterPasswordsKey,
    _repeaterAutoClockSyncAfterLoginKey,
  ];

  String _publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      _publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String _pathHistoryKey(String contactPubKeyHex) => _publicKeyHex.isEmpty
      ? '$_pathHistoryPrefix$contactPubKeyHex'
      : '$_pathHistoryPrefix${_publicKeyHex}_$contactPubKeyHex';

  Future<Map<String, bool>> _loadRepeaterAutoClockSyncAfterLogin() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_repeaterAutoClockSyncAfterLoginKey);

    if (jsonStr == null) return {};

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value == true));
    } catch (e) {
      return {};
    }
  }

  Future<bool> getRepeaterAutoClockSyncAfterLoginEnabled(
    String repeaterPubKeyHex,
  ) async {
    final settings = await _loadRepeaterAutoClockSyncAfterLogin();
    return settings[repeaterPubKeyHex] ?? false;
  }

  Future<void> setRepeaterAutoClockSyncAfterLoginEnabled(
    String repeaterPubKeyHex,
    bool enabled,
  ) async {
    final prefs = PrefsManager.instance;
    final settings = await _loadRepeaterAutoClockSyncAfterLogin();
    settings[repeaterPubKeyHex] = enabled;
    final jsonStr = jsonEncode(settings);
    await prefs.setString(_repeaterAutoClockSyncAfterLoginKey, jsonStr);
  }

  Future<void> savePathHistory(
    String contactPubKeyHex,
    ContactPathHistory history,
  ) async {
    final prefs = PrefsManager.instance;
    final key = _pathHistoryKey(contactPubKeyHex);
    final jsonStr = jsonEncode(history.toJson());
    await prefs.setString(key, jsonStr);
  }

  Future<ContactPathHistory?> loadPathHistory(String contactPubKeyHex) async {
    final prefs = PrefsManager.instance;
    final key = _pathHistoryKey(contactPubKeyHex);
    var jsonStr = prefs.getString(key);
    final legacyKey = '$_pathHistoryPrefix$contactPubKeyHex';
    if (jsonStr == null &&
        _publicKeyHex.isNotEmpty &&
        canMigrateLegacyKeys(_publicKeyHex)) {
      // Move the pre-scoping history into the first radio that loads it so
      // learned routes survive the upgrade without leaking into other radios.
      final legacy = prefs.getString(legacyKey);
      if (legacy != null) {
        await prefs.setString(key, legacy);
        await prefs.remove(legacyKey);
        jsonStr = legacy;
      }
    } else if (jsonStr == null && _publicKeyHex.isEmpty) {
      jsonStr = prefs.getString(legacyKey);
    }

    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ContactPathHistory.fromJson(contactPubKeyHex, json);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearPathHistory(String contactPubKeyHex) async {
    final prefs = PrefsManager.instance;
    await prefs.remove(_pathHistoryKey(contactPubKeyHex));
    await prefs.remove('$_pathHistoryPrefix$contactPubKeyHex');
  }

  /// Clears the path histories of the connected radio only. Histories of other
  /// radios are left alone; with no radio scope set, everything is cleared.
  Future<void> clearAllPathHistories() async {
    final prefs = PrefsManager.instance;
    final scopedPrefix = _publicKeyHex.isEmpty
        ? _pathHistoryPrefix
        : '$_pathHistoryPrefix${_publicKeyHex}_';
    // Pre-scoping keys (no radio prefix) would otherwise be migrated into this
    // radio on the next load and bring the cleared routes back.
    final clearLegacy =
        _publicKeyHex.isNotEmpty && canMigrateLegacyKeys(_publicKeyHex);
    final pathHistoryKeys = prefs.getKeys().where((key) {
      if (key.startsWith(scopedPrefix)) return true;
      return clearLegacy &&
          key.startsWith(_pathHistoryPrefix) &&
          !key.substring(_pathHistoryPrefix.length).contains('_');
    }).toList();

    for (final key in pathHistoryKeys) {
      await prefs.remove(key);
    }
  }

  Future<Map<String, String>> loadPendingMessages() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_pendingMessagesKey);

    if (jsonStr == null) return {};

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      return {};
    }
  }

  Future<void> savePendingMessages(Map<String, String> pending) async {
    final prefs = PrefsManager.instance;
    final jsonStr = jsonEncode(pending);
    await prefs.setString(_pendingMessagesKey, jsonStr);
  }

  Future<void> clearPendingMessages() async {
    final prefs = PrefsManager.instance;
    await prefs.remove(_pendingMessagesKey);
  }

  /// Save a repeater password by public key hex
  Future<void> saveRepeaterPassword(
    String repeaterPubKeyHex,
    String password,
  ) async {
    final prefs = PrefsManager.instance;
    final passwords = await loadRepeaterPasswords();
    passwords[repeaterPubKeyHex] = password;
    final jsonStr = jsonEncode(passwords);
    await prefs.setString(_repeaterPasswordsKey, jsonStr);
  }

  /// Load all saved repeater passwords (map of pubKeyHex -> password)
  Future<Map<String, String>> loadRepeaterPasswords() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_repeaterPasswordsKey);

    if (jsonStr == null) return {};

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      return {};
    }
  }

  /// Get a specific repeater's saved password
  Future<String?> getRepeaterPassword(String repeaterPubKeyHex) async {
    final passwords = await loadRepeaterPasswords();
    return passwords[repeaterPubKeyHex];
  }

  /// Remove a saved repeater password
  Future<void> removeRepeaterPassword(String repeaterPubKeyHex) async {
    final prefs = PrefsManager.instance;
    final passwords = await loadRepeaterPasswords();
    passwords.remove(repeaterPubKeyHex);
    final jsonStr = jsonEncode(passwords);
    await prefs.setString(_repeaterPasswordsKey, jsonStr);
  }

  /// Clear all saved repeater passwords
  Future<void> clearAllRepeaterPasswords() async {
    final prefs = PrefsManager.instance;
    await prefs.remove(_repeaterPasswordsKey);
  }

  Future<void> saveDeliveryObservations(
    List<DeliveryObservation> observations,
  ) async {
    final prefs = PrefsManager.instance;
    final jsonStr = jsonEncode(observations.map((o) => o.toJson()).toList());
    await prefs.setString(_deliveryObservationsKey, jsonStr);
  }

  Future<List<DeliveryObservation>> loadDeliveryObservations() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_deliveryObservationsKey);

    if (jsonStr == null) return [];

    final List<dynamic> list;
    try {
      list = jsonDecode(jsonStr) as List<dynamic>;
    } catch (e) {
      appLogger.warn('Stored delivery observations are unreadable: $e');
      return [];
    }
    final observations = <DeliveryObservation>[];
    for (final e in list) {
      try {
        observations.add(
          DeliveryObservation.fromJson(e as Map<String, dynamic>),
        );
      } catch (err) {
        appLogger.warn('Skipping malformed delivery observation: $err');
      }
    }
    return observations;
  }

  Future<void> clearDeliveryObservations() async {
    final prefs = PrefsManager.instance;
    await prefs.remove(_deliveryObservationsKey);
  }
}
