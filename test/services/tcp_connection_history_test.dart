import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

void main() {
  setUp(() async {
    PrefsManager.reset();
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
  });

  test(
    'addTcpConnectionHistory keeps most recent first without duplicates',
    () async {
      final service = AppSettingsService();
      await service.addTcpConnectionHistory('a:5000');
      await service.addTcpConnectionHistory('b:5000');
      await service.addTcpConnectionHistory('a:5000');
      expect(service.settings.tcpConnectionHistory, ['a:5000', 'b:5000']);
    },
  );

  test('addTcpConnectionHistory caps the list size', () async {
    final service = AppSettingsService();
    final total = AppSettingsService.maxTcpConnectionHistory + 3;
    for (var i = 0; i < total; i++) {
      await service.addTcpConnectionHistory('host$i:5000');
    }
    expect(
      service.settings.tcpConnectionHistory.length,
      AppSettingsService.maxTcpConnectionHistory,
    );
    expect(
      service.settings.tcpConnectionHistory.first,
      'host${total - 1}:5000',
    );
  });

  test('addTcpConnectionHistory ignores blank endpoints', () async {
    final service = AppSettingsService();
    await service.addTcpConnectionHistory('   ');
    expect(service.settings.tcpConnectionHistory, isEmpty);
  });

  test('removeTcpConnectionHistory deletes only that endpoint', () async {
    final service = AppSettingsService();
    await service.addTcpConnectionHistory('a:5000');
    await service.addTcpConnectionHistory('b:5000');
    await service.removeTcpConnectionHistory('a:5000');
    expect(service.settings.tcpConnectionHistory, ['b:5000']);
  });

  test('history persists across a reload', () async {
    final service = AppSettingsService();
    await service.addTcpConnectionHistory('room.local:5000');

    final reloaded = AppSettingsService();
    await reloaded.loadSettings();
    expect(reloaded.settings.tcpConnectionHistory, ['room.local:5000']);
  });
}
