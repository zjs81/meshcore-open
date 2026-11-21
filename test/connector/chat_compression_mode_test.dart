import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/models/chat_compression_mode.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/channel_settings_store.dart';
import 'package:meshcore_open/storage/contact_settings_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _contactKey =
    '1111111111111111111111111111111111111111111111111111111111111111';

Future<void> _waitFor(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 8));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

ContactSettingsStore _contactStore() =>
    ContactSettingsStore()..setPublicKeyHex = ReviewRadio.selfPublicKeyHex;

ChannelSettingsStore _channelStore() =>
    ChannelSettingsStore()..setPublicKeyHex = ReviewRadio.selfPublicKeyHex;

Future<(bool, bool)> _savedContactFlags() async => (
  await _contactStore().loadSmazEnabled(_contactKey),
  await _contactStore().loadCyr2LatEnabled(_contactKey),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeshCoreConnector connector;

  // The connector's frame streams can only be listened to once per process,
  // so the tests share one connected review radio.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    connector = MeshCoreConnector();
    final retryService = MessageRetryService();
    connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
    );
    connector.reviewRadioFactoryForTest = () => ReviewRadio(
      scheduledMessageInterval: const Duration(hours: 1),
      ackDelay: const Duration(hours: 1),
      replyDelay: const Duration(hours: 1),
    );
    await connector.connectReview();
    await _waitFor(() => connector.channelMapConfirmed);
    addTearDown(() async {
      await connector.disconnect();
      connector.dispose();
      retryService.dispose();
    });
  });

  test('contact modes are mutually exclusive and saved', () async {
    expect(
      connector.contactCompressionMode(_contactKey),
      ChatCompressionMode.off,
    );

    await connector.setContactCompressionMode(
      _contactKey,
      ChatCompressionMode.smaz,
    );
    expect(connector.isContactSmazEnabled(_contactKey), isTrue);
    expect(connector.isContactCyr2LatEnabled(_contactKey), isFalse);
    expect(await _savedContactFlags(), (true, false));

    await connector.setContactCompressionMode(
      _contactKey,
      ChatCompressionMode.cyr2lat,
    );
    expect(
      connector.contactCompressionMode(_contactKey),
      ChatCompressionMode.cyr2lat,
    );
    expect(connector.isContactSmazEnabled(_contactKey), isFalse);
    expect(await _savedContactFlags(), (false, true));

    await connector.setContactCompressionMode(
      _contactKey,
      ChatCompressionMode.off,
    );
    expect(
      connector.contactCompressionMode(_contactKey),
      ChatCompressionMode.off,
    );
    expect(await _savedContactFlags(), (false, false));
  });

  test('overlapping contact choices end on the last one, never both', () async {
    final writes = [
      connector.setContactCompressionMode(
        _contactKey,
        ChatCompressionMode.smaz,
      ),
      connector.setContactCompressionMode(
        _contactKey,
        ChatCompressionMode.cyr2lat,
      ),
      connector.setContactCompressionMode(
        _contactKey,
        ChatCompressionMode.smaz,
      ),
    ];
    await Future.wait(writes);
    expect(
      connector.contactCompressionMode(_contactKey),
      ChatCompressionMode.smaz,
    );
    expect(connector.isContactCyr2LatEnabled(_contactKey), isFalse);
    expect(await _savedContactFlags(), (true, false));
  });

  test(
    'channel modes are mutually exclusive and saved by channel ID',
    () async {
      final channelId = connector.channelIdForSlot(1)!;

      await connector.setChannelCompressionMode(1, ChatCompressionMode.cyr2lat);
      expect(connector.channelCompressionMode(1), ChatCompressionMode.cyr2lat);
      expect(await _channelStore().loadCyr2LatEnabled(channelId), isTrue);
      expect(await _channelStore().loadSmazEnabled(channelId), isFalse);

      await connector.setChannelCompressionMode(1, ChatCompressionMode.smaz);
      expect(connector.channelCompressionMode(1), ChatCompressionMode.smaz);
      expect(connector.isChannelCyr2LatEnabled(1), isFalse);
      expect(await _channelStore().loadCyr2LatEnabled(channelId), isFalse);
      expect(await _channelStore().loadSmazEnabled(channelId), isTrue);

      // Other channels are untouched.
      expect(connector.channelCompressionMode(0), ChatCompressionMode.off);
    },
  );

  test('a channel slot without a storage ID is refused', () async {
    const emptySlot = 30;
    expect(connector.channelIdForSlot(emptySlot), isNull);
    await expectLater(
      connector.setChannelCompressionMode(emptySlot, ChatCompressionMode.smaz),
      throwsStateError,
    );
    expect(
      connector.channelCompressionMode(emptySlot),
      ChatCompressionMode.off,
    );

    // A refused write does not block later ones.
    await connector.setChannelCompressionMode(1, ChatCompressionMode.smaz);
    expect(connector.channelCompressionMode(1), ChatCompressionMode.smaz);
  });
}
