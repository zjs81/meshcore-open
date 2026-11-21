import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/contact_added_at_store.dart';
import 'package:meshcore_open/storage/last_radio_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/utils/contact_qr.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

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

// [cmd][pub_key x32][type][flags][path_len][path x64][name x32][last_advert x4]
const _lastAdvertOffset = 1 + 32 + 1 + 1 + 1 + 64 + 32;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  test(
    'a card add records a local added time once, never on the radio',
    () async {
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
      await _waitFor(() => connector.hasLoadedContacts);

      final key = Uint8List.fromList(List.generate(32, (i) => 0xA0 + (i % 16)));
      final keyHex = pubKeyToHex(key);
      final card = ScannedContact(publicKey: key, name: 'Card', type: 1);

      final before = DateTime.now();
      await connector.addContactFromCard(card);
      final addedAt = connector.contactAddedAt(keyHex);
      expect(addedAt, isNotNull);
      expect(addedAt!.isBefore(before), isFalse);

      // The radio still gets advert time 0 (its replay guard).
      final addFrame = radio.sent.lastWhere(
        (f) => f.first == cmdAddUpdateContact,
      );
      expect(
        ByteData.sublistView(
          addFrame,
        ).getUint32(_lastAdvertOffset, Endian.little),
        0,
      );

      // Re-adding keeps the first time.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await connector.addContactFromCard(card);
      expect(connector.contactAddedAt(keyHex), addedAt);

      // Persisted per radio.
      final store = ContactAddedAtStore()
        ..setPublicKeyHex = connector.selfPublicKeyHex;
      expect(
        store.load()[keyHex]?.millisecondsSinceEpoch,
        addedAt.millisecondsSinceEpoch,
      );
      final otherRadio = ContactAddedAtStore()
        ..setPublicKeyHex = 'ffffffffff00';
      expect(otherRadio.load(), isEmpty);

      // Removing the contact forgets it, so a later add starts fresh.
      await connector.removeContact(
        Contact(
          publicKey: key,
          name: 'Card',
          type: 1,
          pathLength: -1,
          path: Uint8List(0),
          lastSeen: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
      expect(connector.contactAddedAt(keyHex), isNull);

      // So does the firmware deleting it to make room.
      await connector.addContactFromCard(card);
      expect(connector.contactAddedAt(keyHex), isNotNull);
      connector.handleFrameForTest([pushCodeContactDeleted, ...key]);
      expect(connector.contactAddedAt(keyHex), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(store.load(), isNot(contains(keyHex)));

      await connector.disconnect(manual: true);
    },
  );

  test('a saved radio restores its added times after a restart', () async {
    const radioHex =
        'a0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebf';
    final contactHex = 'c1' * 32;
    final addedAt = DateTime.fromMillisecondsSinceEpoch(1790000000000);
    await (ContactAddedAtStore()..setPublicKeyHex = radioHex).save({
      contactHex: addedAt,
    });
    await LastRadioStore().save(
      LastRadio(
        publicKeyHex: radioHex,
        name: 'Base',
        transport: LastRadio.transportBle,
        bleRemoteId: 'AA:BB:CC:DD:EE:FF',
        savedAt: addedAt,
      ),
    );

    final connector = MeshCoreConnector();
    addTearDown(connector.dispose);
    await connector.restoreLastRadio();

    expect(connector.contactAddedAt(contactHex), addedAt);
  });
}
