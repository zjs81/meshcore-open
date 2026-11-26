import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/background_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the foreground service does not stop when the app goes to the '
      'background', () {
    // flutter_foreground_task's stopWithTask option stops the service on the
    // first activity pause, not on task removal. The manifest flag decides
    // what happens on swipe-away instead.
    final options = BackgroundService.taskOptions;
    expect(options.stopWithTask, isNull);
    expect(options.toJson().containsKey('stopWithTask'), isFalse);
    expect(options.allowAutoRestart, isFalse);
    // The task handler has no periodic work, so no repeat events are sent.
    expect(options.eventAction.type, ForegroundTaskEventType.nothing);
  });

  test('the foreground service keeps running when the app is swiped away', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final service = RegExp(
      r'<service\b[^>]*flutter_foreground_task\.service\.ForegroundService[^>]*>',
    ).firstMatch(manifest)?.group(0);
    expect(service, isNotNull);
    expect(service, contains('android:stopWithTask="false"'));
    expect(
      service,
      contains('android:foregroundServiceType="connectedDevice"'),
    );
  });

  group('MeshCoreTaskHandler.onStart', () {
    const channel = MethodChannel('flutter_foreground_task/methods');
    late List<String> calls;

    setUp(() {
      calls = [];
      FlutterForegroundTask.skipServiceResponseCheck = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (call.method == 'isRunningService') return true;
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      FlutterForegroundTask.skipServiceResponseCheck = false;
    });

    test('stops a service that Android restarted on its own', () async {
      await MeshCoreTaskHandler().onStart(DateTime.now(), TaskStarter.system);
      expect(calls, contains('stopService'));
    });

    test('keeps a service the app started', () async {
      await MeshCoreTaskHandler().onStart(
        DateTime.now(),
        TaskStarter.developer,
      );
      expect(calls, isEmpty);
    });
  });
}
