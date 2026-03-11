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
    final raw = prefs.getString(keyFor);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((value) => value is int ? value : int.tryParse('$value'))
            .whereType<int>()
            .toList();
      }
    } catch (_) {
      // fall through to legacy parse
    }
    return raw
        .split(',')
        .map((value) => int.tryParse(value))
        .whereType<int>()
        .toList();
  }
}
