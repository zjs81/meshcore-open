import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';

void main() {
  group('shouldAutoSyncTimeOnConnect', () {
    test('allows automatic time sync when firmware is unknown', () {
      expect(shouldAutoSyncTimeOnConnect(null), isTrue);
    });

    test('allows automatic time sync on older firmware', () {
      expect(shouldAutoSyncTimeOnConnect(9), isTrue);
    });

    test('skips automatic time sync on firmware 10 and newer', () {
      expect(shouldAutoSyncTimeOnConnect(10), isFalse);
      expect(shouldAutoSyncTimeOnConnect(11), isFalse);
    });
  });
}
