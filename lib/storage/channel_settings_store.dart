import '../utils/app_logger.dart';
import 'prefs_manager.dart';

class ChannelSettingsStore {
  static const String _keyPrefix = 'channel_smaz_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  Future<bool> loadSmazEnabled(int channelIndex) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load channel settings.',
      );
      return false;
    }
    final prefs = PrefsManager.instance;
    final key = '$keyFor$channelIndex';
    final oldKey = '$_keyPrefix$channelIndex';
    bool? enabled = prefs.getBool(oldKey);
    if (enabled == null) {
      // Attempt migration from legacy unscoped key on first load
      enabled = prefs.getBool(oldKey);
      prefs.remove(oldKey);
      if (enabled != null) {
        appLogger.info(
          'Migrating channel settings from legacy key $oldKey to scoped key $key',
        );
        await prefs.setBool(key, enabled);
      }
    }
    return enabled ?? false;
  }

  Future<void> saveSmazEnabled(int channelIndex, bool enabled) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save channel settings.',
      );
      return;
    }
    final prefs = PrefsManager.instance;
    final key = '$keyFor$channelIndex';
    await prefs.setBool(key, enabled);
  }
}
