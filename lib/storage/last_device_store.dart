import 'prefs_manager.dart';

class LastDeviceStore {
  static const _prefKeyLastDeviceId = 'bg_last_device_id';
  static const _prefKeyLastDeviceName = 'bg_last_device_name';

  Future<void> persistLastDevice(
    String deviceId,
    String deviceDisplayName,
  ) async {
    final prefs = PrefsManager.instance;
    await prefs.setString(_prefKeyLastDeviceId, deviceId);
    await prefs.setString(_prefKeyLastDeviceName, deviceDisplayName);
  }

  String? getPersistedDeviceId() {
    final prefs = PrefsManager.instance;
    final deviceId = prefs.getString(_prefKeyLastDeviceId);
    return deviceId;
  }

  String? getPersistedDeviceName() {
    final prefs = PrefsManager.instance;
    final displayName = prefs.getString(_prefKeyLastDeviceName);
    return displayName;
  }

  Future<void> clearPersistedDevice() async {
    final prefs = PrefsManager.instance;
    await prefs.remove(_prefKeyLastDeviceId);
    await prefs.remove(_prefKeyLastDeviceName);
  }
}
