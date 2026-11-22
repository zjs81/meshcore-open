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

  setUp(() {
    service.resetForTest();
    debugDefaultTargetPlatformOverride = null;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FlutterLocalNotificationsPlatform.instance = _NoopNotificationsPlatform();
    debugDefaultTargetPlatformOverride = null;
    service.resetForTest();
  });

  group('NotificationService.hasNotificationPermission', () {
    test('queries Android areNotificationsEnabled and updates cache', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();

      bool? androidEnabled = true;
      var checkCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'initialize') return true;
            if (call.method == 'areNotificationsEnabled') {
              checkCalls++;
              return androidEnabled;
            }
            return null;
          });

      expect(await service.hasNotificationPermission(), isTrue);
      expect(service.canNotifyCacheForTest, isTrue);
      expect(checkCalls, 1);

      // Subsequent ensureCanNotify uses the cached grant without re-querying.
      expect(await service.ensureCanNotifyForTest(), isTrue);
      expect(checkCalls, 1);

      // Revoking OS permission invalidates the cached true on the next live check.
      androidEnabled = false;
      expect(await service.hasNotificationPermission(), isFalse);
      expect(service.canNotifyCacheForTest, isNull);
      expect(checkCalls, 2);

      // _ensureCanNotify now re-queries and returns false instead of stale true.
      expect(await service.ensureCanNotifyForTest(), isFalse);
      expect(checkCalls, 3);

      // Null response from channel is treated as false.
      androidEnabled = null;
      expect(await service.hasNotificationPermission(), isFalse);
      expect(service.canNotifyCacheForTest, isNull);
    });

    test(
      'queries iOS checkPermissions and invalidates cache when revoked',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        IOSFlutterLocalNotificationsPlugin.registerWith();

        Map<String, Object?>? permissionsResponse = {
          'isEnabled': true,
          'isAlertEnabled': true,
          'isBadgeEnabled': true,
          'isSoundEnabled': true,
          'isProvisionalEnabled': false,
          'isCriticalEnabled': false,
          'isProvidesAppNotificationSettingsEnabled': false,
          'isCarPlayEnabled': false,
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'initialize') return true;
              if (call.method == 'checkPermissions') return permissionsResponse;
              return null;
            });

        expect(await service.hasNotificationPermission(), isTrue);
        expect(service.canNotifyCacheForTest, isTrue);
        expect(await service.ensureCanNotifyForTest(), isTrue);

        // Provisional permission also counts as granted.
        permissionsResponse = {
          'isEnabled': false,
          'isAlertEnabled': false,
          'isBadgeEnabled': false,
          'isSoundEnabled': false,
          'isProvisionalEnabled': true,
        };
        expect(await service.hasNotificationPermission(), isTrue);
        expect(service.canNotifyCacheForTest, isTrue);

        // Denied in iOS Settings clears the cached grant.
        permissionsResponse = {
          'isEnabled': false,
          'isAlertEnabled': false,
          'isBadgeEnabled': false,
          'isSoundEnabled': false,
          'isProvisionalEnabled': false,
        };
        expect(await service.hasNotificationPermission(), isFalse);
        expect(service.canNotifyCacheForTest, isNull);
        expect(await service.ensureCanNotifyForTest(), isFalse);

        permissionsResponse = null;
        expect(await service.hasNotificationPermission(), isFalse);
      },
    );

    test('queries macOS checkPermissions and updates cache', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      MacOSFlutterLocalNotificationsPlugin.registerWith();

      Map<String, Object?>? permissionsResponse = {
        'isEnabled': true,
        'isAlertEnabled': true,
        'isBadgeEnabled': true,
        'isSoundEnabled': true,
      };

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'initialize') return true;
            if (call.method == 'checkPermissions') return permissionsResponse;
            return null;
          });

      expect(await service.hasNotificationPermission(), isTrue);
      expect(service.canNotifyCacheForTest, isTrue);

      permissionsResponse = {
        'isEnabled': false,
        'isAlertEnabled': false,
        'isBadgeEnabled': false,
        'isSoundEnabled': false,
      };
      expect(await service.hasNotificationPermission(), isFalse);
      expect(service.canNotifyCacheForTest, isNull);
    });

    test(
      'returns true on desktop platforms without an OS permission gate',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        FlutterLocalNotificationsPlatform.instance =
            _NoopNotificationsPlatform();

        expect(await service.hasNotificationPermission(), isTrue);
        expect(service.canNotifyCacheForTest, isTrue);
      },
    );

    test('requestPermissions updates and clears canNotify cache', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();

      var grantResult = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'initialize') return true;
            if (call.method == 'requestNotificationsPermission') {
              return grantResult;
            }
            if (call.method == 'areNotificationsEnabled') {
              return grantResult;
            }
            return null;
          });

      expect(await service.requestPermissions(), isTrue);
      expect(service.canNotifyCacheForTest, isTrue);

      grantResult = false;
      expect(await service.requestPermissions(), isFalse);
      expect(service.canNotifyCacheForTest, isNull);
      expect(await service.ensureCanNotifyForTest(), isFalse);
    });
  });
}
