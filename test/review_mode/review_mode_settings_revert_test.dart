import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/review_mode/review_mode_storage.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/contact_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Separate file: NotificationService is a singleton whose reply stream can
// only be listened to by one connector per isolate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'unrelated_key': 'keep'});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  test('channel mutes made in review mode are undone on exit', () async {
    final settings = AppSettingsService();
    await settings.loadSettings();
    await settings.setChannelNotificationMode(
      'Hiking Group',
      ChannelNotificationMode.muted,
    );
    final connector = MeshCoreConnector();
    addTearDown(connector.dispose);
    final retryService = MessageRetryService();
    addTearDown(retryService.dispose);
    connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
      appSettingsService: settings,
    );
    connector.reviewRadioFactoryForTest = () =>
        ReviewRadio(scheduledMessageInterval: const Duration(hours: 1));

    await connector.connectReview();
    // Mutes are keyed by channel name, so these would leak into real radios.
    await settings.setChannelNotificationMode(
      'Public',
      ChannelNotificationMode.muted,
    );
    await settings.setChannelNotificationMode(
      'Hiking Group',
      ChannelNotificationMode.all,
    );
    // Other app preferences are the user's to change, even while reviewing.
    await PrefsManager.instance.setString('unrelated_key', 'changed');

    await connector.disconnect(manual: true);

    expect(
      settings.getChannelNotificationMode('Public'),
      ChannelNotificationMode.all,
    );
    expect(
      settings.getChannelNotificationMode('Hiking Group'),
      ChannelNotificationMode.muted,
    );
    expect(PrefsManager.instance.getString('unrelated_key'), 'changed');

    // A fresh launch has nothing left to undo.
    final relaunched = AppSettingsService();
    await relaunched.loadSettings();
    await endReviewModeSession(relaunched);
    expect(
      relaunched.getChannelNotificationMode('Public'),
      ChannelNotificationMode.all,
    );
    expect(
      relaunched.getChannelNotificationMode('Hiking Group'),
      ChannelNotificationMode.muted,
    );
  });

  test(
    'a session interrupted by the app being killed is undone at startup',
    () async {
      final settings = AppSettingsService();
      await settings.loadSettings();
      await settings.setChannelNotificationMode(
        'Hiking Group',
        ChannelNotificationMode.muted,
      );

      await beginReviewModeSession(settings);
      await settings.setChannelNotificationMode(
        'Public',
        ChannelNotificationMode.muted,
      );
      await settings.setChannelNotificationMode(
        'Hiking Group',
        ChannelNotificationMode.all,
      );
      await PrefsManager.instance.setString(
        'contacts${ReviewRadio.storagePrefix}',
        '[]',
      );
      // The app is killed here: no disconnect, no cleanup.

      final relaunched = AppSettingsService();
      await relaunched.loadSettings();
      expect(
        relaunched.getChannelNotificationMode('Public'),
        ChannelNotificationMode.muted,
      );
      await endReviewModeSession(relaunched);

      expect(
        relaunched.getChannelNotificationMode('Public'),
        ChannelNotificationMode.all,
      );
      expect(
        relaunched.getChannelNotificationMode('Hiking Group'),
        ChannelNotificationMode.muted,
      );
      expect(
        PrefsManager.instance.getKeys().where(
          (k) => k.contains(ReviewRadio.storagePrefix),
        ),
        isEmpty,
      );
    },
  );

  test('every channel notification mode is restored on exit', () async {
    final settings = AppSettingsService();
    await settings.loadSettings();
    await settings.setChannelNotificationMode(
      'Hiking Group',
      ChannelNotificationMode.mentionsOnly,
    );
    await settings.setChannelNotificationMode(
      'Noisy',
      ChannelNotificationMode.muted,
    );

    await beginReviewModeSession(settings);
    await settings.setChannelNotificationMode(
      'Hiking Group',
      ChannelNotificationMode.all,
    );
    await settings.setChannelNotificationMode(
      'Noisy',
      ChannelNotificationMode.mentionsOnly,
    );
    await settings.setChannelNotificationMode(
      'Public',
      ChannelNotificationMode.mentionsOnly,
    );
    await endReviewModeSession(settings);

    expect(
      settings.getChannelNotificationMode('Hiking Group'),
      ChannelNotificationMode.mentionsOnly,
    );
    expect(
      settings.getChannelNotificationMode('Noisy'),
      ChannelNotificationMode.muted,
    );
    expect(
      settings.getChannelNotificationMode('Public'),
      ChannelNotificationMode.all,
    );
  });

  test('setting a channel back to all drops its stored mode', () async {
    final settings = AppSettingsService();
    await settings.loadSettings();
    await settings.setChannelNotificationMode(
      'Public',
      ChannelNotificationMode.muted,
    );
    await settings.setChannelNotificationMode(
      'Public',
      ChannelNotificationMode.all,
    );
    expect(settings.settings.channelNotificationModes, isEmpty);
  });

  test('the review scope never adopts legacy unscoped data', () async {
    await PrefsManager.instance.setString('contacts', '[]');
    await beginReviewModeSession(null);

    final store = ContactStore()
      ..setPublicKeyHex = ReviewRadio.selfPublicKeyHex;
    await store.loadContacts();
    expect(PrefsManager.instance.getString('contacts'), '[]');

    final realRadio = ContactStore()..setPublicKeyHex = 'ab' * 32;
    await realRadio.loadContacts();
    expect(PrefsManager.instance.containsKey('contacts'), isFalse);
    expect(PrefsManager.instance.getString(realRadio.keyFor), '[]');
  });
}
