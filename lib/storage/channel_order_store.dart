import 'dart:convert';
import '../utils/app_logger.dart';
import 'prefs_manager.dart';

class ChannelOrderStore {
  static const String _keyPrefix = 'channel_order_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  Future<void> saveChannelOrder(List<int> order) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save channel order.');
      return;
    }
    final prefs = PrefsManager.instance;
    await prefs.setString(keyFor, jsonEncode(order));
  }

  Future<List<int>> loadChannelOrder() async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load channel order.');
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
          'Migrating channel order from legacy key $_keyPrefix to scoped key $keyFor',
        );
        await prefs.setString(keyFor, legacyJsonString);
        jsonString = legacyJsonString;
      }
    }
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded
            .map((value) => value is int ? value : int.tryParse('$value'))
            .whereType<int>()
            .toList();
      }
    } catch (_) {
      // fall through to legacy parse
    }
    return jsonString
        .split(',')
        .map((value) => int.tryParse(value))
        .whereType<int>()
        .toList();
  }
}
