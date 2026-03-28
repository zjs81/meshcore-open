/// No-op stub for web builds where dart:io is unavailable.
///
/// The real implementation lives in linux_ble_pairing_service.dart and is
/// selected via conditional import in meshcore_connector.dart.
class LinuxBlePairingService {
  LinuxBlePairingService();

  Future<bool> isBluetoothctlAvailable() async => false;

  Future<void> disconnectDevice(
    String remoteId, {
    void Function(String message)? onLog,
  }) async {}

  Future<bool> isPairedAndTrusted(String remoteId) async => false;

  Future<bool> trustDevice(
    String remoteId, {
    void Function(String message)? onLog,
  }) async => false;

  Future<bool> pairAndTrust({
    required String remoteId,
    Duration timeout = const Duration(seconds: 45),
    void Function(String message)? onLog,
    Future<String?> Function()? onRequestPin,
  }) async => false;
}
