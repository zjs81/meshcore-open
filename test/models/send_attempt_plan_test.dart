import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/models/send_attempt_plan.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

void main() {
  group('SendAttemptPlan', () {
    const rotating = SendAttemptPlan(
      directRetries: 4,
      floodRetries: 1,
      rotateRoutes: true,
    );
    const fixed = SendAttemptPlan(
      directRetries: 4,
      floodRetries: 2,
      rotateRoutes: false,
    );

    test('rotation spends direct attempts then flood attempts', () {
      expect(rotating.attemptLimit(floodPath: false), 5);
      expect(rotating.attemptLimit(floodPath: true), 5);
      expect(rotating.floodFromAttempt, 4);
    });

    test('a fixed path uses only that path kind', () {
      expect(fixed.attemptLimit(floodPath: false), 4);
      expect(fixed.attemptLimit(floodPath: true), 2);
      expect(fixed.floodFromAttempt, isNull);
    });

    test('both limits at zero still send once and do not switch to flood', () {
      const plan = SendAttemptPlan(
        directRetries: 0,
        floodRetries: 0,
        rotateRoutes: true,
      );
      expect(plan.attemptLimit(floodPath: false), 1);
      expect(plan.floodFromAttempt, isNull);
    });

    test('direct zero with rotation floods from the first attempt', () {
      const plan = SendAttemptPlan(
        directRetries: 0,
        floodRetries: 3,
        rotateRoutes: true,
      );
      expect(plan.attemptLimit(floodPath: false), 3);
      expect(plan.floodFromAttempt, 0);
    });

    test('flood zero with rotation never switches to flood', () {
      const plan = SendAttemptPlan(
        directRetries: 6,
        floodRetries: 0,
        rotateRoutes: true,
      );
      expect(plan.attemptLimit(floodPath: true), 6);
      expect(plan.floodFromAttempt, isNull);
    });
  });

  group('AppSettings retry migration', () {
    test('a saved single retry limit becomes direct plus one flood', () {
      final settings = AppSettings.fromJson({'max_message_retries': 5});
      expect(settings.directRetries, 4);
      expect(settings.floodRetries, 1);
      expect(settings.toJson().containsKey('max_message_retries'), isFalse);
    });

    test('the old maximum of 10 keeps nine direct attempts and one flood', () {
      final settings = AppSettings.fromJson({'max_message_retries': 10});
      expect(settings.directRetries, 9);
      expect(settings.floodRetries, 1);
    });

    test('new keys win over a leftover single limit and are clamped', () {
      final settings = AppSettings.fromJson({
        'max_message_retries': 5,
        'max_direct_retries': 40,
        'max_flood_retries': -2,
        'login_attempts': 0,
      });
      expect(settings.directRetries, SendAttemptPlan.maxDirectRetries);
      expect(settings.floodRetries, SendAttemptPlan.minFloodRetries);
      expect(settings.loginAttempts, SendAttemptPlan.minLoginAttempts);
    });

    test('round trip keeps the split limits', () {
      final saved = AppSettings(
        directRetries: 12,
        floodRetries: 7,
        loginAttempts: 3,
        clearPathOnMaxRetry: true,
        autoRouteRotationEnabled: false,
        channelMinHopsEnabled: true,
      ).toJson();
      final restored = AppSettings.fromJson(saved);
      expect(restored.directRetries, 12);
      expect(restored.floodRetries, 7);
      expect(restored.loginAttempts, 3);
      expect(restored.clearPathOnMaxRetry, isTrue);
      expect(restored.autoRouteRotationEnabled, isFalse);
      expect(restored.channelMinHopsEnabled, isTrue);
    });
  });

  test('reset routing settings restores the moved controls', () async {
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
    final service = AppSettingsService();
    await service.loadSettings();
    await service.updateSettings(
      service.settings.copyWith(
        clearPathOnMaxRetry: true,
        autoRouteRotationEnabled: false,
        directRetries: 15,
        floodRetries: 10,
        loginAttempts: 9,
        channelMinHopsEnabled: true,
        channelMinHops: 6,
        channelMinHopsRetries: 4,
        channelMinHopsCountRepeaters: true,
        maxRouteWeight: 9,
      ),
    );

    await service.resetRoutingSettingsToDefault();
    final settings = service.settings;
    expect(settings.clearPathOnMaxRetry, isFalse);
    expect(settings.autoRouteRotationEnabled, isTrue);
    expect(settings.directRetries, SendAttemptPlan.defaultDirectRetries);
    expect(settings.floodRetries, SendAttemptPlan.defaultFloodRetries);
    expect(settings.loginAttempts, 9);
    expect(settings.channelMinHopsEnabled, isFalse);
    expect(settings.channelMinHops, 2);
    expect(settings.channelMinHopsRetries, 1);
    expect(settings.channelMinHopsCountRepeaters, isFalse);
    expect(settings.maxRouteWeight, AppSettings.defaultMaxRouteWeight);

    final reloaded = AppSettingsService();
    await reloaded.loadSettings();
    expect(
      reloaded.settings.directRetries,
      SendAttemptPlan.defaultDirectRetries,
    );
    expect(reloaded.settings.floodRetries, SendAttemptPlan.defaultFloodRetries);
    expect(reloaded.settings.loginAttempts, 9);
  });

  test('reset repeater and room settings restores that section', () async {
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
    final service = AppSettingsService();
    await service.loadSettings();
    await service.updateSettings(
      service.settings.copyWith(
        clockSyncAfterLogin: true,
        loginPasswordAutofocus: true,
        autoFetchRepeaterSettings: true,
        loginAttempts: 8,
        directRetries: 12,
      ),
    );

    await service.resetRepeaterRoomSettingsToDefault();
    final settings = service.settings;
    expect(settings.clockSyncAfterLogin, isFalse);
    expect(settings.loginPasswordAutofocus, isFalse);
    expect(settings.autoFetchRepeaterSettings, isFalse);
    expect(settings.loginAttempts, SendAttemptPlan.defaultLoginAttempts);
    expect(settings.directRetries, 12);
  });
}
