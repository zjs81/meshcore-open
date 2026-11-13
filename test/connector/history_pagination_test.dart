import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/channel_store.dart';
import 'package:meshcore_open/storage/contact_store.dart';
import 'package:meshcore_open/storage/history_store.dart';
import 'package:meshcore_open/storage/last_radio_store.dart';
import 'package:meshcore_open/storage/message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _radioA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _radioB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
final _contactKey = Uint8List.fromList(List.generate(32, (i) => i + 1));
final _contactHex = pubKeyToHex(_contactKey);
final _channel = Channel(
  index: 0,
  name: 'Test',
  psk: Uint8List.fromList(List.filled(16, 1)),
);

String _dmKey(String radio) => 'messages_${radio.substring(0, 10)}$_contactHex';
String _channelKey(String radio) =>
    'channel_messages_${radio.substring(0, 10)}_${_channel.storageId}';

Map<String, Object?> _dm(int i, {String prefix = 'dm'}) => {
  'senderKey': base64Encode(_contactKey),
  'text': '$prefix-$i',
  'timestamp': 1000 * (i + 1),
  'isOutgoing': false,
  'status': 2,
  'messageId': '$prefix-$i',
  'plainText': true,
};
Map<String, Object?> _ch(int i, {String prefix = 'ch'}) => {
  'senderName': 'Bob',
  'text': '$prefix-$i',
  'timestamp': 1000 * (i + 1),
  'isOutgoing': false,
  'status': 1,
  'channelIndex': 0,
  'messageId': '$prefix-$i',
  'plainText': true,
};

class _TrackingHistory extends HistoryStore {
  final data = <String, String>{};
  final reads = <({String key, int offset, int? limit})>[];
  final fullReads = <String>[];
  String? delayedKey;
  Completer<void>? gate;
  Completer<void>? started;
  String? failedKey;

  @override
  Future<String?> getString(String key) async {
    fullReads.add(key);
    return data[key];
  }

  @override
  Future<bool> setString(String key, String value) async {
    data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    data.remove(key);
    return true;
  }

  @override
  Future<Set<String>> getKeys() async => data.keys.toSet();

  List<String> _entries(String key) =>
      ((jsonDecode(data[key] ?? '[]')) as List).map(jsonEncode).toList();

  @override
  Future<int> entryCount(String key) async => _entries(key).length;

  @override
  Future<List<String>> readEntries(
    String key, {
    int offset = 0,
    int? limit,
  }) async {
    if (key == failedKey) throw StateError('History storage unavailable');
    reads.add((key: key, offset: offset, limit: limit));
    final selected = _entries(key).skip(offset);
    final snapshot = (limit == null ? selected : selected.take(limit)).toList();
    if (key == delayedKey && gate != null) {
      final wait = gate!;
      gate = null;
      started?.complete();
      await wait.future;
    }
    return snapshot;
  }

  @override
  Future<int> replaceTail(
    String key,
    int preservedCount,
    List<String> entries, {
    int maxEntries = 1000,
  }) async {
    final prefix = _entries(key).take(preservedCount).toList();
    final combined = [...prefix, ...entries];
    final overflow = (combined.length - maxEntries).clamp(0, combined.length);
    data[key] = '[${combined.skip(overflow).join(',')}]';
    return (prefix.length - overflow).clamp(0, prefix.length);
  }

  Completer<void> delayNextRead(String key) {
    delayedKey = key;
    gate = Completer<void>();
    started = Completer<void>();
    return gate!;
  }
}

Future<void> _seedRadio(String radio) async {
  final contact = Contact(
    publicKey: _contactKey,
    name: 'Alice',
    type: advTypeChat,
    pathLength: 0,
    path: Uint8List(0),
    lastSeen: DateTime.fromMillisecondsSinceEpoch(1000),
  );
  await (ContactStore()..setPublicKeyHex = radio).saveContacts([contact]);
  final channels = ChannelStore()..setPublicKeyHex = radio;
  await channels.saveChannels([_channel]);
  await channels.saveSlotChannelIds({0: _channel.storageId!});
  await PrefsManager.instance.setBool(
    'channel_storage_v2_${radio.substring(0, 10)}',
    true,
  );
  await LastRadioStore().save(
    LastRadio(
      publicKeyHex: radio,
      name: 'Saved',
      transport: LastRadio.transportBle,
      bleRemoteId: 'AA:BB:CC:DD:EE:FF',
      savedAt: DateTime.fromMillisecondsSinceEpoch(1000),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _TrackingHistory history;
  late MeshCoreConnector connector;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    await _seedRadio(_radioA);
    history = _TrackingHistory();
    history.data[_dmKey(_radioA)] = jsonEncode([
      for (var i = 0; i < 620; i++) _dm(i),
    ]);
    history.data[_channelKey(_radioA)] = jsonEncode([
      for (var i = 0; i < 620; i++) _ch(i),
    ]);
    HistoryStore.use(history);
    MessageStore().forgetArchive();
    ChannelMessageStore().forgetArchive();
    connector = MeshCoreConnector();
    addTearDown(connector.dispose);
  });

  test(
    'initial loads and older pages read only the requested stored rows',
    () async {
      await connector.restoreLastRadio();
      final contact = connector.contacts.single;
      final channel = connector.channels.single;
      expect(connector.getMessages(contact).map((m) => m.text), [
        for (var i = 420; i < 620; i++) 'dm-$i',
      ]);
      expect(connector.getChannelMessages(channel).map((m) => m.text), [
        for (var i = 420; i < 620; i++) 'ch-$i',
      ]);
      expect(
        history.reads,
        containsAll([
          (key: _dmKey(_radioA), offset: 420, limit: 200),
          (key: _channelKey(_radioA), offset: 420, limit: 200),
        ]),
      );
      expect(
        history.fullReads.where(
          (key) => key == _dmKey(_radioA) || key == _channelKey(_radioA),
        ),
        isEmpty,
      );
      history.reads.clear();
      final dms = await connector.loadOlderMessages(_contactHex);
      final channels = await connector.loadOlderChannelMessages(0);
      expect(dms.map((m) => m.text), [for (var i = 370; i < 420; i++) 'dm-$i']);
      expect(channels.map((m) => m.text), [
        for (var i = 370; i < 420; i++) 'ch-$i',
      ]);
      expect(history.reads, [
        (key: _dmKey(_radioA), offset: 370, limit: 50),
        (key: _channelKey(_radioA), offset: 370, limit: 50),
      ]);
      final next = await connector.loadOlderMessages(_contactHex);
      expect(next.map((m) => m.text), [
        for (var i = 320; i < 370; i++) 'dm-$i',
      ]);
      expect(
        connector.getMessages(contact).map((m) => m.messageId).toSet(),
        hasLength(300),
      );
      final search = await connector.allMessagesForSearch(_contactHex);
      expect(search.map((m) => m.text), [
        for (var i = 0; i < 620; i++) 'dm-$i',
      ]);
    },
  );

  test(
    'older pages start before the window when the archive is unreconciled',
    () async {
      await connector.restoreLastRadio();
      MessageStore().forgetArchive();
      ChannelMessageStore().forgetArchive();
      final dms = await connector.loadOlderMessages(_contactHex);
      final channels = await connector.loadOlderChannelMessages(0);
      expect(dms.map((m) => m.text), [for (var i = 370; i < 420; i++) 'dm-$i']);
      expect(channels.map((m) => m.text), [
        for (var i = 370; i < 420; i++) 'ch-$i',
      ]);
      expect(
        connector.getMessages(connector.contacts.single).map((m) => m.text),
        [for (var i = 370; i < 620; i++) 'dm-$i'],
      );
    },
  );

  test(
    'malformed rows consume physical offsets and do not hide older pages',
    () async {
      history.data[_dmKey(_radioA)] = jsonEncode([
        for (var i = 0; i < 620; i++)
          if (i >= 400 && i < 600) {'text': 1} else _dm(i),
      ]);
      await connector.restoreLastRadio();
      expect(connector.getMessages(connector.contacts.single), hasLength(200));
      final older = await connector.loadOlderMessages(_contactHex);
      expect(older.map((m) => m.text), [
        for (var i = 170; i < 220; i++) 'dm-$i',
      ]);
      final stored = await connector.allMessagesForSearch(_contactHex);
      expect(stored.map((m) => m.text), [
        for (var i = 0; i < 620; i++)
          if (i < 400 || i >= 600) 'dm-$i',
      ]);
      expect(history.reads.last, (
        key: _dmKey(_radioA),
        offset: 0,
        limit: 170,
      ), reason: 'Search reads the remaining prefix before the loaded window');
    },
  );

  test(
    'a storage read failure keeps the loaded window and archive cursor',
    () async {
      await connector.restoreLastRadio();
      final before = List.of(connector.getMessages(connector.contacts.single));
      final store = MessageStore()..setPublicKeyHex = _radioA;
      expect(store.archivedCount(_contactHex), 420);
      history.failedKey = _dmKey(_radioA);

      await expectLater(
        connector.loadOlderMessages(_contactHex),
        throwsStateError,
      );
      expect(connector.getMessages(connector.contacts.single), before);
      expect(store.archivedCount(_contactHex), 420);
      history.failedKey = null;
      expect(await connector.loadOlderMessages(_contactHex), hasLength(50));
    },
  );

  test(
    'overlapping requests share a page rather than prepending it twice',
    () async {
      await connector.restoreLastRadio();
      history.reads.clear();
      final gate = history.delayNextRead(_dmKey(_radioA));
      final first = connector.loadOlderMessages(_contactHex);
      await history.started!.future;
      final second = connector.loadOlderMessages(_contactHex);
      gate.complete();
      await Future.wait([first, second]);
      expect(
        history.reads.where((r) => r.key == _dmKey(_radioA)),
        hasLength(1),
      );
      expect(connector.getMessages(connector.contacts.single), hasLength(250));
    },
  );

  test(
    'a delayed old-radio page cannot enter a newly restored radio',
    () async {
      await connector.restoreLastRadio();
      final gate = history.delayNextRead(_dmKey(_radioA));
      final oldPage = connector.loadOlderMessages(_contactHex);
      await history.started!.future;
      await _seedRadio(_radioB);
      history.data[_dmKey(_radioB)] = jsonEncode([
        for (var i = 0; i < 10; i++) _dm(i, prefix: 'new'),
      ]);
      history.data[_channelKey(_radioB)] = '[]';
      await connector.restoreLastRadio();
      gate.complete();
      expect(await oldPage, isEmpty);
      expect(connector.storageKeyHex, _radioB);
      expect(
        connector.getMessages(connector.contacts.single).map((m) => m.text),
        [for (var i = 0; i < 10; i++) 'new-$i'],
      );
    },
  );

  test(
    'channel edits during an asynchronous reload survive the stale read',
    () async {
      await connector.restoreLastRadio();
      final channel = connector.channels.single;
      final gate = history.delayNextRead(_channelKey(_radioA));
      final reload = connector.loadAllChannelMessages();
      await history.started!.future;
      final current = connector.getChannelMessages(channel);
      final removed = current.first;
      current.add(
        ChannelMessage(
          senderName: 'Live',
          text: 'arrived during read',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1000000),
          isOutgoing: false,
          status: ChannelMessageStatus.sent,
          channelIndex: 0,
          messageId: 'live',
        ),
      );
      await connector.deleteChannelMessage(removed);
      gate.complete();
      await reload;
      final messages = connector.getChannelMessages(channel);
      expect(messages.any((m) => m.messageId == 'live'), isTrue);
      expect(messages.any((m) => m.messageId == removed.messageId), isFalse);
    },
  );
}
