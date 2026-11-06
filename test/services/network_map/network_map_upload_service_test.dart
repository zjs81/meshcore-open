import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/network_map/network_map_records.dart';
import 'package:meshcore_open/services/network_map/network_map_upload_service.dart';
import 'dart:async';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  test('off by default and never listens without a connected radio', () async {
    final connector = MeshCoreConnector();
    final settings = AppSettingsService();
    await settings.loadSettings();
    var requests = 0;
    final service = NetworkMapUploadService(
      connector: connector,
      settings: settings,
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 202);
      }),
    );
    addTearDown(() {
      service.dispose();
      connector.dispose();
    });

    expect(service.enabled, isFalse);
    expect(service.isActive, isFalse);

    await service.setEnabled(true);
    expect(service.enabled, isTrue);
    expect(settings.settings.networkMapUploadEnabled, isTrue);
    expect(service.isActive, isFalse);
    expect(service.lastUploadAt, isNull);
    expect(service.packetsSentToday, 0);
    expect(requests, 0);
  });

  group('withdrawing consent mid-upload', () {
    NetworkMapPacketRecord packet() => NetworkMapPacketRecord(
      t: DateTime.now().millisecondsSinceEpoch ~/ 60000 * 60,
      pt: 5,
      rt: 1,
      hw: 1,
      path: 'aa',
      snr: 6.5,
      rssi: -90,
      size: 48,
      h: '0011223344556677',
      scoped: false,
    );

    Future<(NetworkMapUploadService, AppSettingsService)> setUpService(
      MockClient client,
    ) async {
      final connector = _ConnectedConnector();
      final settings = AppSettingsService();
      await settings.loadSettings();
      await settings.setNetworkMapUploadEnabled(true);
      final service = NetworkMapUploadService(
        connector: connector,
        settings: settings,
        client: client,
      );
      addTearDown(() {
        service.dispose();
        connector.dispose();
      });
      return (service, settings);
    }

    test(
      'nothing is sent when sharing is turned off before the POST',
      () async {
        var requests = 0;
        final (service, settings) = await setUpService(
          MockClient((_) async {
            requests++;
            return http.Response('{}', 202);
          }),
        );
        service.queuePacketForTest(packet());
        final upload = service.uploadNowForTest();
        await settings.setNetworkMapUploadEnabled(false);
        await upload;

        expect(requests, 0);
        expect(service.queuedPacketCount, 0);
        expect(service.lastUploadAt, isNull);
      },
    );

    test('a late response never touches the refilled queue', () async {
      final response = Completer<http.Response>();
      final posted = Completer<void>();
      final (service, settings) = await setUpService(
        MockClient((_) {
          posted.complete();
          return response.future;
        }),
      );
      service.queuePacketForTest(packet());
      final upload = service.uploadNowForTest();
      await posted.future;

      // Off and on again while the first POST is in flight, then new records.
      await settings.setNetworkMapUploadEnabled(false);
      await settings.setNetworkMapUploadEnabled(true);
      service.queuePacketForTest(packet());
      service.queuePacketForTest(packet());

      response.complete(http.Response('{}', 202));
      await upload;

      expect(service.queuedPacketCount, 2);
      expect(service.lastUploadAt, isNull);
      expect(service.packetsSentToday, 0);
    });
  });
}

class _ConnectedConnector extends MeshCoreConnector {
  @override
  bool get isConnected => true;
}
