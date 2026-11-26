import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/activity_reattach.dart';
import 'package:meshcore_open/services/notification_service.dart';
import 'package:meshcore_open/utils/platform_info.dart';

class _NoopNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const notificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final notifications = NotificationService();
  late List<MethodCall> platformCalls;
  late int launchDetailsCalls;
  late ActivityReattach reattach;

  setUp(() async {
    platformCalls = [];
    launchDetailsCalls = 0;
    reattach = ActivityReattach();
    notifications.resetForTest();
    notifications.pendingTap.value = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    PlatformInfo.debugIsAndroidOverride = true;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(notificationsChannel, (call) async {
      if (call.method == 'initialize') return true;
      if (call.method == 'getNotificationAppLaunchDetails') {
        launchDetailsCalls++;
        return {
          'notificationLaunchedApp': true,
          'notificationResponse': {
            'notificationId': 7,
            'notificationResponseType': 0,
            'payload': 'channel:2',
          },
        };
      }
      return null;
    });
    await notifications.initialize();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(notificationsChannel, null);
    FlutterLocalNotificationsPlatform.instance = _NoopNotificationsPlatform();
    debugDefaultTargetPlatformOverride = null;
    PlatformInfo.debugIsAndroidOverride = null;
    notifications.pendingTap.value = null;
    notifications.resetForTest();
  });

  List<String> methods() => platformCalls.map((c) => c.method).toList();

  Future<void> detachThenResume() async {
    await reattach.didChangeAppLifecycleState(AppLifecycleState.detached);
    await reattach.didChangeAppLifecycleState(AppLifecycleState.resumed);
  }

  test('the first resume after detached sets up the new activity', () async {
    await detachThenResume();

    final back = platformCalls.singleWhere(
      (c) => c.method == 'SystemNavigator.setFrameworkHandlesBack',
    );
    expect(back.arguments, isTrue);
    final mode = platformCalls.singleWhere(
      (c) => c.method == 'SystemChrome.setEnabledSystemUIMode',
    );
    expect(mode.arguments, 'SystemUiMode.edgeToEdge');
    expect(launchDetailsCalls, 1);
    expect(notifications.pendingTap.value, 'channel:2');
  });

  test('an ordinary pause and resume does nothing', () async {
    await reattach.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await reattach.didChangeAppLifecycleState(AppLifecycleState.paused);
    await reattach.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(platformCalls, isEmpty);
    expect(launchDetailsCalls, 0);
    expect(notifications.pendingTap.value, isNull);
  });

  test('only the first resume after detached acts', () async {
    await detachThenResume();
    platformCalls.clear();
    notifications.pendingTap.value = null;
    await reattach.didChangeAppLifecycleState(AppLifecycleState.paused);
    await reattach.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(methods(), isEmpty);
    expect(launchDetailsCalls, 1);
    expect(notifications.pendingTap.value, isNull);
  });

  test('does nothing off Android', () async {
    PlatformInfo.debugIsAndroidOverride = false;
    await detachThenResume();
    expect(platformCalls, isEmpty);
    expect(launchDetailsCalls, 0);
    expect(notifications.pendingTap.value, isNull);
  });
}
