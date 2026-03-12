import 'platform_info.dart';

bool supportsBluetoothPlatformOptions() {
  return PlatformInfo.isAndroid || PlatformInfo.isIOS || PlatformInfo.isMacOS;
}

bool shouldRestoreBluetoothState() {
  // iOS restoration currently revives stale BLE sessions before the adapter is
  // fully powered on, which breaks normal scan/connect flow after app restart.
  // Keep restoration disabled until the restore path is explicitly handled.
  return false;
}
