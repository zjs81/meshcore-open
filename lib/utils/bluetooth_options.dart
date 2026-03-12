import 'platform_info.dart';

bool supportsBluetoothPlatformOptions() {
  return PlatformInfo.isAndroid || PlatformInfo.isIOS || PlatformInfo.isMacOS;
}

bool shouldRestoreBluetoothState() {
  return PlatformInfo.isIOS || PlatformInfo.isMacOS;
}
