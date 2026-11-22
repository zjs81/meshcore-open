import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  test('a saved on or off overrides the global clock-sync default', () async {
    SharedPreferences.setMockInitialValues({
      'repeater_auto_clock_sync_after_login': jsonEncode({
        'on-node': true,
        'off-node': false,
      }),
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
    final storage = StorageService();

    expect(
      await storage.repeaterClockSyncAfterLogin(
        'on-node',
        globalDefault: false,
      ),
      isTrue,
    );
    expect(
      await storage.repeaterClockSyncAfterLogin(
        'off-node',
        globalDefault: true,
      ),
      isFalse,
    );
    expect(
      await storage.repeaterClockSyncAfterLogin(
        'new-node',
        globalDefault: true,
      ),
      isTrue,
    );
    expect(
      await storage.repeaterClockSyncAfterLogin(
        'new-node',
        globalDefault: false,
      ),
      isFalse,
    );
  });

  test('choosing default removes the per-repeater override', () async {
    final storage = StorageService();
    await storage.setRepeaterClockSyncOverride(
      'node',
      RepeaterClockSyncOverride.on,
    );
    expect(
      await storage.getRepeaterClockSyncOverride('node'),
      RepeaterClockSyncOverride.on,
    );

    await storage.setRepeaterClockSyncOverride(
      'node',
      RepeaterClockSyncOverride.followDefault,
    );
    expect(
      await storage.getRepeaterClockSyncOverride('node'),
      RepeaterClockSyncOverride.followDefault,
    );
    expect(
      PrefsManager.instance.containsKey('repeater_auto_clock_sync_after_login'),
      isFalse,
    );
  });
}
