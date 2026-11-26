import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/notification_service.dart';

class _NoopNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final service = NotificationService();
  Map<String, Object?>? launchDetails;

  Map<String, Object?> launchedBy({required int type}) => {
    'notificationLaunchedApp': true,
    'notificationResponse': {
      'notificationId': 7,
      'actionId': type == 0 ? null : 'mark_read',
      'input': null,
      'notificationResponseType': type,
      'payload': 'message:ab12cd',
    },
  };

  setUp(() async {
    service.resetForTest();
    service.pendingTap.value = null;
    launchDetails = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'initialize') return true;
          if (call.method == 'getNotificationAppLaunchDetails') {
            return launchDetails ?? {'notificationLaunchedApp': false};
          }
          return null;
        });
    await service.initialize();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FlutterLocalNotificationsPlatform.instance = _NoopNotificationsPlatform();
    debugDefaultTargetPlatformOverride = null;
    service.pendingTap.value = null;
    service.resetForTest();
  });

  test('a notification tap that started the activity opens the '
      'conversation', () async {
    launchDetails = launchedBy(type: 0);
    await service.routeLaunchTap();
    expect(service.pendingTap.value, 'message:ab12cd');
  });

  test('a launch that was not from a notification opens nothing', () async {
    await service.routeLaunchTap();
    expect(service.pendingTap.value, isNull);
  });

  test('an action button response opens nothing', () async {
    launchDetails = launchedBy(type: 1);
    await service.routeLaunchTap();
    expect(service.pendingTap.value, isNull);
  });
}
