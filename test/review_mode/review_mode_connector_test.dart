import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'stale_key_${ReviewRadio.storagePrefix}': 'stale',
      'unrelated_key': 'keep',
      // A legacy unscoped key that the contact store migrates into whichever
      // radio scope loads first. Review mode must not keep it.
      'contacts': '[]',
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  test('connectReview syncs, auto-replies, and disconnect cleans up', () async {
    final connector = MeshCoreConnector();
    addTearDown(connector.dispose);
    final retryService = MessageRetryService();
    addTearDown(retryService.dispose);
    connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
    );
    connector.reviewRadioFactoryForTest = () => ReviewRadio(
      scheduledMessageInterval: const Duration(hours: 1),
      ackDelay: const Duration(milliseconds: 100),
      replyDelay: const Duration(milliseconds: 200),
    );

    await connector.connectReview();

    expect(connector.isConnected, isTrue);
    expect(connector.isReviewMode, isTrue);
    expect(connector.activeTransport, MeshCoreTransportType.review);
    // Stale data from a previous session is wiped on connect.
    expect(
      PrefsManager.instance.containsKey(
        'stale_key_${ReviewRadio.storagePrefix}',
      ),
      isFalse,
    );
    expect(PrefsManager.instance.getString('unrelated_key'), 'keep');

    await _waitFor(
      () => connector.contacts.length >= 6 && connector.channels.length >= 3,
    );
    expect(connector.channels.map((c) => c.name), contains('Hiking Group'));

    final contact = connector.contacts.firstWhere((c) => c.name == 'Maya');
    await _waitFor(() => connector.getMessages(contact).isNotEmpty);
    final seeded = connector.getMessages(contact).length;

    await connector.sendMessage(contact, 'hello from test');
    await _waitFor(
      () => connector
          .getMessages(contact)
          .any(
            (m) =>
                m.isOutgoing &&
                m.text == 'hello from test' &&
                m.status == MessageStatus.delivered,
          ),
    );
    await _waitFor(() => connector.getMessages(contact).length >= seeded + 2);
    expect(connector.getMessages(contact).last.isOutgoing, isFalse);

    await connector.disconnect(manual: true);

    expect(connector.isReviewMode, isFalse);
    expect(connector.isConnected, isFalse);
    expect(connector.activeTransport, isNot(MeshCoreTransportType.review));
    final leftover = PrefsManager.instance.getKeys().where(
      (k) => k.contains(ReviewRadio.storagePrefix),
    );
    expect(leftover, isEmpty);
    expect(PrefsManager.instance.getString('unrelated_key'), 'keep');
    expect(PrefsManager.instance.getString('contacts'), '[]');

    // Frames after teardown must not resurrect anything.
    connector.sendReviewTestMessage();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(connector.isReviewMode, isFalse);
  });
}
