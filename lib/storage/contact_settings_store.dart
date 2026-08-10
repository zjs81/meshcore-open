import '../utils/app_logger.dart';
import 'prefs_manager.dart';

class ContactSettingsStore {
  static const String _keyPrefix = 'contact_smaz_';
  static const String _cyr2latKeyPrefix = 'contact_cyr2lat_';
  static const String _imagesKeyPrefix = 'contact_images_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';
  String get keyForCyr2Lat => '$_cyr2latKeyPrefix$publicKeyHex';
  String get keyForImages => '$_imagesKeyPrefix$publicKeyHex';

  Future<bool> loadSmazEnabled(String contactKeyHex) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load contact settings.',
      );
      return false;
    }
    final prefs = PrefsManager.instance;
    final key = '$keyFor$contactKeyHex';
    final oldKey = '$_keyPrefix$contactKeyHex';
    bool? enabled = prefs.getBool(key);
    if (enabled == null) {
      // Attempt migration from legacy unscoped key on first load
      enabled = prefs.getBool(oldKey);
      prefs.remove(oldKey);
      if (enabled != null) {
        appLogger.info(
          'Migrating contact settings from legacy key $oldKey to scoped key $key',
        );
        await prefs.setBool(key, enabled);
      }
    }
    return prefs.getBool(key) ?? false;
  }

  Future<void> saveSmazEnabled(String contactKeyHex, bool enabled) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save contact settings.',
      );
      return;
    }
    final prefs = PrefsManager.instance;
    final key = '$keyFor$contactKeyHex';
    await prefs.setBool(key, enabled);
  }

  Future<bool> loadCyr2LatEnabled(String contactKeyHex) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load contact Cyr2Lat settings.',
      );
      return false;
    }
    final prefs = PrefsManager.instance;
    final key = '$keyForCyr2Lat$contactKeyHex';
    return prefs.getBool(key) ?? false;
  }

  Future<void> saveCyr2LatEnabled(String contactKeyHex, bool enabled) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save contact Cyr2Lat settings.',
      );
      return;
    }
    final prefs = PrefsManager.instance;
    final key = '$keyForCyr2Lat$contactKeyHex';
    await prefs.setBool(key, enabled);
  }

  Future<bool> loadImagesEnabled(String contactKeyHex) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load contact image settings.',
      );
      return false;
    }
    return PrefsManager.instance.getBool('$keyForImages$contactKeyHex') ??
        false;
  }

  Future<void> saveImagesEnabled(String contactKeyHex, bool enabled) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save contact image settings.',
      );
      return;
    }
    await PrefsManager.instance.setBool('$keyForImages$contactKeyHex', enabled);
  }

  Future<String?> loadCyr2LatProfileId(String contactKeyHex) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load contact settings.',
      );
      return null;
    }
    final prefs = PrefsManager.instance;
    final key = '${keyForCyr2Lat}profile_$contactKeyHex';
    return prefs.getString(key);
  }

  Future<void> saveCyr2LatProfileId(
    String contactKeyHex,
    String? profileId,
  ) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save contact settings.',
      );
      return;
    }
    final prefs = PrefsManager.instance;
    final key = '${keyForCyr2Lat}profile_$contactKeyHex';
    if (profileId == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, profileId);
    }
  }
}
