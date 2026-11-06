import '../utils/app_logger.dart';
import 'prefs_manager.dart';

class ChannelSettingsStore {
  static const String _keyPrefix = 'channel_smaz_';
  static const String _cyr2latKeyPrefix = 'channel_cyr2lat_';
  static const String _urlImagesKeyPrefix = 'channel_url_images_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';
  String get keyForCyr2Lat => '$_cyr2latKeyPrefix$publicKeyHex';
  String get keyForUrlImages => '$_urlImagesKeyPrefix$publicKeyHex';

  String _smazKey(String channelId) => '${keyFor}_$channelId';
  String _cyr2LatKey(String channelId) => '${keyForCyr2Lat}_$channelId';
  String _cyr2LatProfileKey(String channelId) =>
      '${keyForCyr2Lat}_profile_$channelId';
  String _urlImagesKey(String channelId) => '${keyForUrlImages}_$channelId';

  Future<bool> loadSmazEnabled(String channelId) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load channel settings.',
      );
      return false;
    }
    return PrefsManager.instance.getBool(_smazKey(channelId)) ?? false;
  }

  Future<void> saveSmazEnabled(String channelId, bool enabled) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save channel settings.',
      );
      return;
    }
    await PrefsManager.instance.setBool(_smazKey(channelId), enabled);
  }

  Future<bool> loadCyr2LatEnabled(String channelId) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load channel Cyr2Lat settings.',
      );
      return false;
    }
    return PrefsManager.instance.getBool(_cyr2LatKey(channelId)) ?? false;
  }

  Future<void> saveCyr2LatEnabled(String channelId, bool enabled) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save channel Cyr2Lat settings.',
      );
      return;
    }
    await PrefsManager.instance.setBool(_cyr2LatKey(channelId), enabled);
  }

  Future<bool?> loadUrlImagesEnabled(String channelId) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load channel URL image settings.',
      );
      return null;
    }
    return PrefsManager.instance.getBool(_urlImagesKey(channelId));
  }

  Future<void> saveUrlImagesEnabled(String channelId, bool enabled) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save channel URL image settings.',
      );
      return;
    }
    await PrefsManager.instance.setBool(_urlImagesKey(channelId), enabled);
  }

  Future<String?> loadCyr2LatProfileId(String channelId) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load channel settings.',
      );
      return null;
    }
    return PrefsManager.instance.getString(_cyr2LatProfileKey(channelId));
  }

  Future<void> saveCyr2LatProfileId(String channelId, String? profileId) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save channel settings.',
      );
      return;
    }
    final prefs = PrefsManager.instance;
    final key = _cyr2LatProfileKey(channelId);
    if (profileId == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, profileId);
    }
  }

  /// Removes every setting stored for [channelId].
  Future<void> clearChannel(String channelId) async {
    if (publicKeyHex.isEmpty) return;
    final prefs = PrefsManager.instance;
    await prefs.remove(_smazKey(channelId));
    await prefs.remove(_cyr2LatKey(channelId));
    await prefs.remove(_cyr2LatProfileKey(channelId));
    await prefs.remove(_urlImagesKey(channelId));
  }
}
