import 'dart:convert';
import '../models/contact_group.dart';
import '../utils/app_logger.dart';
import 'prefs_manager.dart';

class ContactGroupStore {
  static const String _keyPrefix = 'contact_groups';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  Future<List<ContactGroup>> loadGroups() async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load contact groups.');
      return [];
    }
    final prefs = PrefsManager.instance;
    String? jsonString = prefs.getString(keyFor);
    if (jsonString == null || jsonString.isEmpty) {
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
      return [];
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ContactGroup.fromJson)
            .toList();
      }
    } catch (_) {
      // Return empty list on parse errors.
    }
    return [];
  }

  Future<void> saveGroups(List<ContactGroup> groups) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save contact groups.');
      return;
    }
    final prefs = PrefsManager.instance;
    final encoded = jsonEncode(groups.map((group) => group.toJson()).toList());
    await prefs.setString(keyFor, encoded);
  }
}
