import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/utils/scan_update_throttle.dart';

void main() {
  test(
    'publishes immediately and coalesces scan updates to the interval',
    () async {
      var notifications = 0;
      final throttle = ScanUpdateThrottle(
        interval: const Duration(milliseconds: 40),
        onNotify: () => notifications++,
      );
      addTearDown(throttle.dispose);

      throttle.schedule();
      expect(notifications, 1);

      throttle.schedule();
      throttle.schedule();
      expect(notifications, 1);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(notifications, 2);

      throttle.schedule();
      expect(notifications, 2);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(notifications, 3);
    },
  );

  test(
    'reset cancels pending updates and allows an immediate next update',
    () async {
      var notifications = 0;
      final throttle = ScanUpdateThrottle(
        interval: const Duration(milliseconds: 40),
        onNotify: () => notifications++,
      );
      addTearDown(throttle.dispose);

      throttle.schedule();
      throttle.schedule();
      throttle.reset();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(notifications, 1);

      throttle.schedule();
      expect(notifications, 2);
    },
  );

  test('dispose cancels a pending notification', () async {
    var notifications = 0;
    final throttle = ScanUpdateThrottle(
      interval: const Duration(milliseconds: 40),
      onNotify: () => notifications++,
    );

    throttle.schedule();
    throttle.schedule();
    throttle.dispose();

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(notifications, 1);
  });
}
