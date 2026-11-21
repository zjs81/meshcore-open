import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/background_service.dart';

void main() {
  test('the foreground service does not stop when the app goes to the '
      'background', () {
    // flutter_foreground_task's stopWithTask option stops the service on the
    // first activity pause, not on task removal. Swipe-away is handled by
    // android:stopWithTask in the manifest instead.
    final options = BackgroundService.taskOptions;
    expect(options.stopWithTask, isNull);
    expect(options.toJson().containsKey('stopWithTask'), isFalse);
    expect(options.allowAutoRestart, isFalse);
  });
}
