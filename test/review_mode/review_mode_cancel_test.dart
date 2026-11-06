import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'stale_key_${ReviewRadio.storagePrefix}': 'stale',
      'unrelated_key': 'keep',
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  test('disconnect during connectReview cancels quietly', () async {
    final connector = MeshCoreConnector();
    addTearDown(connector.dispose);
    final retryService = MessageRetryService();
    addTearDown(retryService.dispose);
    connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
    );
    ReviewRadio? created;
    connector.reviewRadioFactoryForTest = () => created = ReviewRadio(
      scheduledMessageInterval: const Duration(milliseconds: 50),
    );

    final connecting = connector.connectReview();
    await Future<void>.delayed(Duration.zero);
    await connector.disconnect(manual: true);
    await connecting;

    expect(connector.isConnected, isFalse);
    expect(connector.isReviewMode, isFalse);
    expect(
      PrefsManager.instance.getKeys().where(
        (k) => k.contains(ReviewRadio.storagePrefix),
      ),
      isEmpty,
    );
    // Whether or not the radio was created, nothing keeps it running.
    created?.sendTestMessage();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(connector.isConnected, isFalse);
  });
}
