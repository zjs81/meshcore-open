import 'dart:convert';
import '../utils/app_logger.dart';
import 'prefs_manager.dart';

/// Persists the user's channel order as a list of channel storage IDs
/// ([Channel.storageId]), so the order follows channels across slots.
class ChannelOrderStore {
  static const String _keyPrefix = 'channel_order_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  Future<void> saveChannelOrder(List<String> order) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save channel order.');
      return;
    }
    await PrefsManager.instance.setString(keyFor, jsonEncode(order));
  }

  Future<List<String>> loadChannelOrder() async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load channel order.');
      return [];
    }
    final jsonString = PrefsManager.instance.getString(keyFor);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {
      // Unreadable order: fall back to slot order.
    }
    return [];
  }
}
