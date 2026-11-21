import 'dart:convert';

import '../utils/app_logger.dart';
import 'prefs_manager.dart';

/// Phone time at which each contact was first added from a card, keyed by
/// contact public key hex. App-side only: the radio keeps advert time 0 for
/// these contacts, so this orders them until a real advert arrives.
class ContactAddedAtStore {
  static const String _keyPrefix = 'contact_added_at_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  Map<String, DateTime> load() {
    if (publicKeyHex.isEmpty) return {};
    final jsonString = PrefsManager.instance.getString(keyFor);
    if (jsonString == null || jsonString.isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          if (entry.value is int)
            entry.key: DateTime.fromMillisecondsSinceEpoch(entry.value as int),
      };
    } catch (e) {
      appLogger.warn('Stored contact added times are unreadable: $e');
      return {};
    }
  }

  Future<void> save(Map<String, DateTime> addedAt) async {
    if (publicKeyHex.isEmpty) return;
    await PrefsManager.instance.setString(
      keyFor,
      jsonEncode({
        for (final entry in addedAt.entries)
          entry.key: entry.value.millisecondsSinceEpoch,
      }),
    );
  }
}
