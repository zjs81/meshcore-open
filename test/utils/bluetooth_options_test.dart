import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/utils/bluetooth_options.dart';

void main() {
  test('restore state helper returns a bool', () {
    expect(shouldRestoreBluetoothState(), isA<bool>());
  });

  test('platform options helper returns a bool', () {
    expect(supportsBluetoothPlatformOptions(), isA<bool>());
  });
}
