import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/contact_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

/// Review radio that records every frame the app sends.
class _RecordingReviewRadio extends ReviewRadio {
  final List<Uint8List> sent = [];

  _RecordingReviewRadio()
    : super(scheduledMessageInterval: const Duration(hours: 1));

  @override
  void handle(Uint8List frame) {
    sent.add(frame);
    super.handle(frame);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  test('removed contact stays gone from the radio, list and store', () async {
    final connector = MeshCoreConnector();
    addTearDown(connector.dispose);
    final retryService = MessageRetryService();
    addTearDown(retryService.dispose);
    connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
    );
    final radio = _RecordingReviewRadio();
    connector.reviewRadioFactoryForTest = () => radio;

    await connector.connectReview();
    await _waitFor(
      () => connector.hasLoadedContacts && connector.contacts.length >= 6,
    );
    final contact = connector.contacts.firstWhere((c) => c.name == 'Maya');

    await connector.removeContact(contact);

    bool listed() =>
        connector.contacts.any((c) => c.publicKeyHex == contact.publicKeyHex);
    expect(listed(), isFalse);
    expect(
      connector.discoveredContacts
          .firstWhere((c) => c.publicKeyHex == contact.publicKeyHex)
          .isActive,
      isFalse,
    );

    // A full resync from the radio must not bring it back.
    await connector.getContacts();
    await _waitFor(() => connector.hasLoadedContacts);
    expect(connector.contacts, isNotEmpty);
    expect(listed(), isFalse);

    final store = ContactStore()..setPublicKeyHex = connector.selfPublicKeyHex;
    final saved = await store.loadContacts();
    expect(saved.any((c) => c.publicKeyHex == contact.publicKeyHex), isFalse);

    // An open chat/repeater screen still syncs the path before each send, and
    // the favourite toggle writes flags. On firmware CMD_ADD_UPDATE_CONTACT
    // adds unknown keys, so neither may be sent for the removed contact.
    radio.sent.clear();
    await connector.setContactPath(contact, Uint8List.fromList([0x42]), 1);
    await connector.preparePathForContactSend(contact);
    await connector.setContactFlags(contact, isFavorite: true);
    expect(radio.sent.where((f) => f.first == cmdAddUpdateContact), isEmpty);

    await connector.disconnect(manual: true);
  });

  test('auto-add config reports which contact types come back', () {
    final connector = MeshCoreConnector();
    addTearDown(connector.dispose);
    connector.handleFrameForTest([respCodeAutoAddConfig, autoAddRepeaterFlag]);

    expect(connector.autoAddsContactType(advTypeRepeater), isTrue);
    expect(connector.autoAddsContactType(advTypeChat), isFalse);
    expect(connector.autoAddsContactType(advTypeRoom), isFalse);
  });
}
