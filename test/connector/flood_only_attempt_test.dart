import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

Contact _directContact() {
  return Contact(
    publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
    name: 'Hill',
    type: 1,
    pathLength: 1,
    path: Uint8List.fromList(const [0x11]),
    lastSeen: DateTime.now(),
  );
}

void main() {
  late MeshCoreConnector connector;
  late PathHistoryService history;
  late MessageRetryService retries;
  late AppSettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    settings = AppSettingsService();
    await settings.loadSettings();
    connector = MeshCoreConnector();
    history = PathHistoryService(StorageService());
    retries = MessageRetryService();
    connector.initialize(
      retryService: retries,
      pathHistoryService: history,
      appSettingsService: settings,
    );
  });

  tearDown(() {
    connector.dispose();
    history.dispose();
    retries.dispose();
  });

  test('flood attempts do not wait for route history', () async {
    await settings.updateSettings(
      settings.settings.copyWith(
        autoRouteRotationEnabled: true,
        directRetries: 0,
        floodRetries: 1,
      ),
    );

    final flooded = await connector.preparePathForContactSend(_directContact());
    expect(flooded.useFlood, isTrue);

    await settings.updateSettings(
      settings.settings.copyWith(directRetries: 2, floodRetries: 1),
    );
    final direct = await connector.preparePathForContactSend(_directContact());
    expect(direct.useFlood, isFalse);
    expect(direct.hopCount, 1);
    expect(direct.pathBytes, [0x11]);
  });
}
