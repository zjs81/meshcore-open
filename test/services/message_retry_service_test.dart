import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/message_retry_service.dart';

void main() {
  group('MessageRetryService.resolveAttemptForSend', () {
    test('forces flood-routed sends to use attempt 3', () {
      final attempt = MessageRetryService.resolveAttemptForSend(
        retryCount: 0,
        pathLength: -1,
      );

      expect(attempt, 3);
    });

    test('clamps directed sends to the retry count range', () {
      final attempt = MessageRetryService.resolveAttemptForSend(
        retryCount: 5,
        pathLength: 2,
      );

      expect(attempt, 3);
    });
  });
}
