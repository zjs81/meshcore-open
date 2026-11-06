import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/channel_settings_store.dart';
import 'package:meshcore_open/storage/contact_settings_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  test('stores return null for chats that were never set', () async {
    final channels = ChannelSettingsStore()..setPublicKeyHex = 'aabbccddeeff';
    final contacts = ContactSettingsStore()..setPublicKeyHex = 'aabbccddeeff';
    expect(await channels.loadUrlImagesEnabled('chan'), isNull);
    expect(await contacts.loadUrlImagesEnabled('c1'), isNull);

    await channels.saveUrlImagesEnabled('chan', false);
    await contacts.saveUrlImagesEnabled('c1', false);
    expect(await channels.loadUrlImagesEnabled('chan'), isFalse);
    expect(await contacts.loadUrlImagesEnabled('c1'), isFalse);
  });

  test('effective value is the per-chat choice, else the default', () async {
    final settings = AppSettingsService();
    final connector = MeshCoreConnector();
    addTearDown(connector.dispose);
    final retryService = MessageRetryService();
    addTearDown(retryService.dispose);
    connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
      appSettingsService: settings,
    );
    var notified = 0;
    connector.addListener(() => notified++);

    expect(connector.isContactUrlImagesEnabled('c1'), isFalse);
    expect(connector.isChannelUrlImagesEnabled(0), isFalse);

    await settings.setShowLinkImagesByDefault(true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(notified, greaterThan(0));
    expect(connector.isContactUrlImagesEnabled('c1'), isTrue);
    expect(connector.isChannelUrlImagesEnabled(0), isTrue);

    await connector.setContactUrlImagesEnabled('c2', false);
    expect(connector.isContactUrlImagesEnabled('c2'), isFalse);

    await settings.setShowLinkImagesByDefault(false);
    await connector.setContactUrlImagesEnabled('c3', true);
    expect(connector.isContactUrlImagesEnabled('c1'), isFalse);
    expect(connector.isContactUrlImagesEnabled('c3'), isTrue);
  });
}
