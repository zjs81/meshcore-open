import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/channel_store.dart';
import 'package:meshcore_open/storage/contact_store.dart';
import 'package:meshcore_open/storage/last_radio_store.dart';
import 'package:meshcore_open/storage/message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/storage/unread_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _radioKey = Uint8List.fromList(List<int>.generate(32, (i) => 0xA0 + i));
final _radioHex = pubKeyToHex(_radioKey);
final _aliceKey = Uint8List.fromList(List<int>.generate(32, (i) => 0x10 + i));
final _psk = Uint8List.fromList(List<int>.generate(16, (i) => 0x40 + i));

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

/// Saves a radio's data the way a real session would.
Future<void> _seedRadio() async {
  final alice = Contact(
    publicKey: _aliceKey,
    name: 'Alice',
    type: advTypeChat,
    pathLength: 1,
    path: Uint8List.fromList([0x22]),
    lastSeen: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
  final self = Contact(
    publicKey: _radioKey,
    name: 'Me',
    type: advTypeChat,
    pathLength: 0,
    path: Uint8List(0),
    lastSeen: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
  await (ContactStore()..setPublicKeyHex = _radioHex).saveContacts([
    alice,
    self,
  ]);

  final channel = Channel(index: 0, name: 'Base Camp', psk: _psk);
  final channelId = channel.storageId!;
  final channelStore = ChannelStore()..setPublicKeyHex = _radioHex;
  await channelStore.saveChannels([channel]);
  await channelStore.saveSlotChannelIds({0: channelId});
  await (ChannelMessageStore()..setPublicKeyHex = _radioHex)
      .saveChannelMessages(channelId, [
        ChannelMessage(
          senderName: 'Bob',
          text: 'camp is up',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1700000001000),
          isOutgoing: false,
          status: ChannelMessageStatus.sent,
          channelIndex: 0,
        ),
      ]);

  await (MessageStore()..setPublicKeyHex = _radioHex)
      .saveMessages(alice.publicKeyHex, [
        Message(
          senderKey: _aliceKey,
          text: 'hi there',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1700000002000),
          isOutgoing: false,
          status: MessageStatus.delivered,
        ),
        Message(
          senderKey: _aliceKey,
          text: 'did not go out',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1700000003000),
          isOutgoing: true,
          status: MessageStatus.failed,
        ),
      ]);

  final unread = UnreadStore()..setPublicKeyHex = _radioHex;
  unread.saveContactUnreadCount({alice.publicKeyHex: 2});
  await unread.flush();

  await LastRadioStore().save(
    LastRadio(
      publicKeyHex: _radioHex,
      name: 'Base',
      transport: LastRadio.transportBle,
      bleRemoteId: 'AA:BB:CC:DD:EE:FF',
      savedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    ),
  );
}

// initialize() listens to the notification service's single-subscription
// reply stream, so these connectors run without it.
MeshCoreConnector _newConnector() {
  final connector = MeshCoreConnector();
  addTearDown(connector.dispose);
  return connector;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    ChannelMessageStore().forgetArchive();
    MessageStore().forgetArchive();
    await _seedRadio();
    ChannelMessageStore().forgetArchive();
    MessageStore().forgetArchive();
  });

  test('restoreLastRadio shows the saved radio while disconnected', () async {
    final connector = _newConnector();
    expect(connector.hasRadioData, isFalse);

    await connector.restoreLastRadio();

    expect(connector.isConnected, isFalse);
    expect(connector.hasRadioData, isTrue);
    expect(connector.storageKeyHex, _radioHex);
    expect(connector.lastRadioName, 'Base');
    expect(connector.lastRadio?.canReconnectBle, isTrue);

    // The radio's own entry is filtered out of the contact list.
    expect(connector.contacts.map((c) => c.name), ['Alice']);
    final alice = connector.contacts.single;
    expect(
      connector.getMessages(alice).map((m) => m.text),
      containsAll(['hi there', 'did not go out']),
    );
    expect(connector.getUnreadCountForContact(alice), 2);

    expect(connector.channels.map((c) => c.name), ['Base Camp']);
    expect(
      connector
          .getChannelMessages(connector.channels.single)
          .map((m) => m.text),
      ['camp is up'],
    );
  });

  test('resend while offline keeps the message', () async {
    final connector = _newConnector();
    await connector.restoreLastRadio();
    final alice = connector.contacts.single;
    final failed = connector
        .getMessages(alice)
        .firstWhere((m) => m.text == 'did not go out');

    await connector.resendMessage(alice, failed);

    expect(
      connector.getMessages(alice).where((m) => m.text == 'did not go out'),
      hasLength(1),
    );
    final stored = await (MessageStore()..setPublicKeyHex = _radioHex)
        .loadMessages(alice.publicKeyHex);
    expect(stored.map((m) => m.text), contains('did not go out'));
  });

  test('sendFrame throws RadioNotConnectedException offline', () async {
    final connector = _newConnector();
    await expectLater(
      connector.sendFrame(Uint8List.fromList([1])),
      throwsA(isA<RadioNotConnectedException>()),
    );
  });

  test('a review session neither replaces the remembered radio nor keeps its '
      'channels, and the saved radio is back afterwards', () async {
    final connector = _newConnector();
    connector.reviewRadioFactoryForTest = () => ReviewRadio(
      scheduledMessageInterval: const Duration(hours: 1),
      ackDelay: const Duration(milliseconds: 100),
      replyDelay: const Duration(milliseconds: 200),
    );
    await connector.restoreLastRadio();
    expect(connector.channels.map((c) => c.name), ['Base Camp']);

    await connector.connectReview();
    expect(connector.isReviewMode, isTrue);
    await _waitFor(() => connector.channels.length >= 3);

    // A different radio answered: the saved radio's channels are gone.
    expect(connector.channels.map((c) => c.name), isNot(contains('Base Camp')));
    expect(connector.contacts.map((c) => c.name), isNot(contains('Alice')));
    expect(connector.storageKeyHex, isNot(_radioHex));
    expect(LastRadioStore().load()?.publicKeyHex, _radioHex);

    await connector.disconnect();
    await _waitFor(
      () =>
          connector.channels.any((c) => c.name == 'Base Camp') &&
          connector.contacts.any((c) => c.name == 'Alice'),
    );
    expect(connector.isConnected, isFalse);
    expect(connector.storageKeyHex, _radioHex);
    expect(connector.lastRadio?.publicKeyHex, _radioHex);
    expect(LastRadioStore().load()?.publicKeyHex, _radioHex);
    final alice = connector.contacts.firstWhere((c) => c.name == 'Alice');
    expect(
      connector.getMessages(alice).map((m) => m.text),
      contains('hi there'),
    );
    expect(connector.getUnreadCountForContact(alice), 2);
    // Review data never lands under the real radio's keys.
    final channels = await (ChannelStore()..setPublicKeyHex = _radioHex)
        .loadChannels();
    expect(channels.map((c) => c.name), ['Base Camp']);
  });

  test('without a remembered radio nothing is loaded', () async {
    await LastRadioStore().clear();
    final connector = _newConnector();
    await connector.restoreLastRadio();
    expect(connector.hasRadioData, isFalse);
    expect(connector.contacts, isEmpty);
    expect(connector.channels, isEmpty);
    expect(connector.lastRadio, isNull);
  });

  test('stored last_radio is JSON with the full key', () {
    final raw = PrefsManager.instance.getString(LastRadioStore.prefsKey)!;
    expect((jsonDecode(raw) as Map)['publicKeyHex'], _radioHex);
  });
}
