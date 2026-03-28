import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/linux_ble_error_classifier.dart';

void main() {
  group('isLinuxBleConnectFailureText', () {
    test('matches flutter_blue_plus connect timeout error', () {
      expect(
        isLinuxBleConnectFailureText(
          'FlutterBluePlusException | connect | fbp-code: 1 | Timed out after 15s',
        ),
        isTrue,
      );
    });

    test('matches hard-timeout marker', () {
      expect(
        isLinuxBleConnectFailureText(
          'TimeoutException: Linux connect hard-timeout after 8s',
        ),
        isTrue,
      );
    });

    test('matches BlueZ local abort failure', () {
      expect(
        isLinuxBleConnectFailureText(
          'org.bluez.Error.Failed: le-connection-abort-by-local',
        ),
        isTrue,
      );
    });

    test('matches BlueZ in-progress failure', () {
      expect(
        isLinuxBleConnectFailureText(
          'org.bluez.Error.InProgress: Operation already in progress',
        ),
        isTrue,
      );
    });

    test('matches flutter_blue_plus null-detail connect failure', () {
      expect(
        isLinuxBleConnectFailureText(
          'FlutterBluePlusException | connect | linux-code: null | null',
        ),
        isTrue,
      );
    });

    test('matches tagged connect-stage failure marker', () {
      expect(
        isLinuxBleConnectFailureText(
          'StateError: Linux connect stage failure: Bad state: No element',
        ),
        isTrue,
      );
    });

    test('does not match connect-shaped pairing auth failure', () {
      expect(
        isLinuxBleConnectFailureText(
          'FlutterBluePlusException | connect | AuthenticationFailed',
        ),
        isFalse,
      );
    });

    test('does not match explicit pair auth failure', () {
      expect(
        isLinuxBleConnectFailureText(
          'FlutterBluePlusException | pair | AuthenticationFailed',
        ),
        isFalse,
      );
    });
  });

  group('isLikelyLinuxBlePairingTimeoutText', () {
    test('matches pair timeout text', () {
      expect(
        isLikelyLinuxBlePairingTimeoutText('Timed out waiting for pair'),
        isTrue,
      );
    });

    test('matches bond timeout text', () {
      expect(
        isLikelyLinuxBlePairingTimeoutText('Operation timed out during bond'),
        isTrue,
      );
    });

    test('does not match generic timeout text', () {
      expect(
        isLikelyLinuxBlePairingTimeoutText('Timed out after 15s'),
        isFalse,
      );
    });
  });

  group('isLinuxBlePairingFailureText', () {
    test('matches connect-shaped authentication failure', () {
      expect(
        isLinuxBlePairingFailureText(
          'FlutterBluePlusException | connect | AuthenticationFailed',
        ),
        isTrue,
      );
    });

    test('matches app pairing incomplete failure', () {
      expect(
        isLinuxBlePairingFailureText(
          'StateError: Linux BLE pairing did not complete',
        ),
        isTrue,
      );
    });

    test('does not match generic bad state error', () {
      expect(isLinuxBlePairingFailureText('Bad state: No element'), isFalse);
    });

    test('matches pair-context bad state error', () {
      expect(
        isLinuxBlePairingFailureText(
          'Pair request failed: Bad state: No element',
        ),
        isTrue,
      );
    });

    test('matches app trust repair incomplete failure', () {
      expect(
        isLinuxBlePairingFailureText(
          'StateError: Linux BLE trust repair did not complete',
        ),
        isTrue,
      );
    });

    test('matches pairing timeout text', () {
      expect(
        isLinuxBlePairingFailureText('Timed out waiting for pair'),
        isTrue,
      );
    });
  });
}
