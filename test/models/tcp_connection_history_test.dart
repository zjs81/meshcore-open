import 'package:flutter_test/flutter_test.dart';

import 'package:meshcore_open/models/app_settings.dart';

void main() {
  test('tcpConnectionHistory defaults to empty', () {
    expect(AppSettings().tcpConnectionHistory, isEmpty);
  });

  test('tcpConnectionHistory round-trips through JSON', () {
    final settings = AppSettings(
      tcpConnectionHistory: const ['a.com:5000', '10.0.0.1:5000'],
    );
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.tcpConnectionHistory, ['a.com:5000', '10.0.0.1:5000']);
  });

  test('legacy settings adopt the last used endpoint once', () {
    final json = AppSettings(
      tcpServerAddress: 'room.local',
      tcpServerPort: 5000,
    ).toJson()..remove('tcp_connection_history');
    final restored = AppSettings.fromJson(json);
    expect(restored.tcpConnectionHistory, ['room.local:5000']);
  });

  test('persisted empty history is not re-seeded', () {
    final json = AppSettings(
      tcpServerAddress: 'room.local',
      tcpServerPort: 5000,
    ).toJson();
    json['tcp_connection_history'] = <String>[];
    final restored = AppSettings.fromJson(json);
    expect(restored.tcpConnectionHistory, isEmpty);
  });

  test('no seed without a last used endpoint', () {
    final json = AppSettings().toJson()..remove('tcp_connection_history');
    final restored = AppSettings.fromJson(json);
    expect(restored.tcpConnectionHistory, isEmpty);
  });
}
