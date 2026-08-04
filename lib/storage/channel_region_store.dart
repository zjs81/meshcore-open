import '../utils/app_logger.dart';
import 'prefs_manager.dart';

class ChannelRegionStore {
  static const String _keyPrefix = 'channel_region_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length >= 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  Future<String> loadRegion(int channelIndex) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load channel settings.',
      );
      return '';
    }
    final prefs = PrefsManager.instance;
    final key = '$keyFor$channelIndex';
    String? region = prefs.getString(key);
    return region ?? '';
  }

  Future<String> saveRegion(int channelIndex, String region) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save channel settings.',
      );
      return '';
    }

    final prefs = PrefsManager.instance;
    final key = '$keyFor$channelIndex';
    await prefs.setString(key, region);
    return region;
  }
}
