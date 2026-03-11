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
    final raw = prefs.getString(keyFor);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
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
