import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/services/received_image_store.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/channel_order_store.dart';
import 'package:meshcore_open/storage/channel_region_store.dart';
import 'package:meshcore_open/storage/channel_settings_store.dart';
import 'package:meshcore_open/storage/channel_storage_migration.dart';
import 'package:meshcore_open/storage/channel_store.dart';
import 'package:meshcore_open/storage/legacy_key_migration.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _deviceA = 'aaaaaaaaaa0123456789';
const _deviceB = 'bbbbbbbbbb0123456789';
const _scopeA = 'aaaaaaaaaa';

final _pskOne = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));
final _pskTwo = Uint8List.fromList(List<int>.generate(16, (i) => 100 + i));
final _idOne = Channel.storageIdForPsk(_pskOne)!;
final _idTwo = Channel.storageIdForPsk(_pskTwo)!;

Future<void> _init([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  PrefsManager.reset();
  await PrefsManager.initialize();
  ChannelMessageStore().forgetArchive();
}

ChannelMessage _ch(String text, int i) => ChannelMessage(
  senderKey: null,
  senderName: 'Bob',
  text: text,
  timestamp: DateTime.fromMillisecondsSinceEpoch(1000 * i),
  isOutgoing: false,
  status: ChannelMessageStatus.sent,
  channelIndex: 0,
  messageId: '$text-$i',
);

String _storedMessages(List<String> texts) => jsonEncode([
  for (var i = 0; i < texts.length; i++)
    {
      'senderName': 'Bob',
      'text': texts[i],
      'timestamp': 1000 * (i + 1),
      'isOutgoing': false,
      'status': ChannelMessageStatus.sent.index,
      'messageId': '${texts[i]}-$i',
      'plainText': true,
    },
]);

String _cachedChannels(Map<int, Uint8List> slots) => jsonEncode([
  for (final entry in slots.entries)
    {
      'index': entry.key,
      'name': 'ch${entry.key}',
      'psk': base64Encode(entry.value),
      'unreadCount': 0,
    },
]);

void main() {
  tearDown(scopesWithoutLegacyMigration.clear);

  group('channel ID', () {
    test('is stable, 16 hex chars, and absent for an empty slot', () {
      expect(_idOne, hasLength(16));
      expect(_idOne, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(Channel.storageIdForPsk(Uint8List.fromList(_pskOne)), _idOne);
      expect(_idOne, isNot(_idTwo));
      expect(Channel.storageIdForPsk(Uint8List(16)), isNull);
      expect(Channel.empty(3).storageId, isNull);
      expect(Channel(index: 5, name: 'x', psk: _pskOne).storageId, _idOne);
    });
  });

  group('ID-keyed stores', () {
    test('messages save, load and clear by channel ID', () async {
      await _init();
      final store = ChannelMessageStore()..setPublicKeyHex = _deviceA;
      await store.saveChannelMessages(_idOne, [_ch('one', 1)]);
      await store.saveChannelMessages(_idTwo, [_ch('two', 1)]);

      expect((await store.loadChannelMessages(_idOne)).single.text, 'one');
      expect((await store.loadChannelMessages(_idTwo)).single.text, 'two');
      expect(
        PrefsManager.instance.containsKey(
          'channel_messages_${_scopeA}_$_idOne',
        ),
        isTrue,
      );

      await store.clearChannelMessages(_idOne);
      expect(await store.loadChannelMessages(_idOne), isEmpty);
      expect(await store.loadChannelMessages(_idTwo), hasLength(1));
    });

    test('the same channel ID is isolated per radio scope', () async {
      await _init();
      final a = ChannelMessageStore()..setPublicKeyHex = _deviceA;
      final b = ChannelMessageStore()..setPublicKeyHex = _deviceB;
      await a.saveChannelMessages(_idOne, [_ch('a', 1)]);

      expect(await b.loadChannelMessages(_idOne), isEmpty);
      final settingsB = ChannelSettingsStore()..setPublicKeyHex = _deviceB;
      final settingsA = ChannelSettingsStore()..setPublicKeyHex = _deviceA;
      await settingsA.saveSmazEnabled(_idOne, true);
      expect(await settingsA.loadSmazEnabled(_idOne), isTrue);
      expect(await settingsB.loadSmazEnabled(_idOne), isFalse);
    });

    test('the archive follows the channel ID', () async {
      await _init();
      final store = ChannelMessageStore()..setPublicKeyHex = _deviceA;
      store.setArchived(_idOne, [_ch('old', 1), _ch('older', 2)]);
      expect(store.archivedCount(_idOne), 2);
      expect(store.archivedCount(_idTwo), isNull);

      await store.saveChannelMessages(_idOne, [_ch('new', 3)]);
      expect((await store.loadChannelMessages(_idOne)).map((m) => m.text), [
        'old',
        'older',
        'new',
      ]);
      store.forgetArchive(_idOne);
      expect(store.archivedCount(_idOne), isNull);
    });

    test('settings, region and order are keyed by channel ID', () async {
      await _init();
      final settings = ChannelSettingsStore()..setPublicKeyHex = _deviceA;
      await settings.saveCyr2LatEnabled(_idOne, true);
      await settings.saveUrlImagesEnabled(_idOne, true);
      await settings.saveCyr2LatProfileId(_idOne, 'sr');
      expect(await settings.loadCyr2LatEnabled(_idOne), isTrue);
      expect(await settings.loadUrlImagesEnabled(_idOne), isTrue);
      expect(await settings.loadCyr2LatProfileId(_idOne), 'sr');
      expect(await settings.loadCyr2LatEnabled(_idTwo), isFalse);
      await settings.clearChannel(_idOne);
      expect(await settings.loadCyr2LatEnabled(_idOne), isFalse);
      expect(await settings.loadCyr2LatProfileId(_idOne), isNull);

      final region = ChannelRegionStore()..setPublicKeyHex = _deviceA;
      await region.saveRegion(_idOne, 'EU');
      expect(await region.loadRegion(_idOne), 'EU');
      expect(await region.loadRegion(_idTwo), '');
      await ChannelRegionStore.clearRegionEverywhere('EU');
      expect(await region.loadRegion(_idOne), '');

      final order = ChannelOrderStore()..setPublicKeyHex = _deviceA;
      await order.saveChannelOrder([_idTwo, _idOne]);
      expect(await order.loadChannelOrder(), [_idTwo, _idOne]);
    });
  });

  group('migration', () {
    Map<String, Object> legacyValues() => {
      'channels$_scopeA': _cachedChannels({0: _pskOne, 2: _pskTwo}),
      'channel_messages_${_scopeA}0': _storedMessages(['hello']),
      'channel_messages_2': _storedMessages(['unscoped']),
      'channel_messages_${_scopeA}5': _storedMessages(['orphan']),
      'channel_smaz_${_scopeA}0': true,
      'channel_cyr2lat_${_scopeA}2': true,
      'channel_url_images_${_scopeA}2': true,
      'channel_cyr2lat_${_scopeA}profile_2': 'sr',
      'channel_region_${_scopeA}0': 'EU',
      'channel_order_$_scopeA': jsonEncode([2, 5, 0]),
    };

    test('moves messages, settings, region and order to channel IDs', () async {
      await _init(legacyValues());
      final mapping = await ChannelStorageMigration.migrate(_scopeA);
      expect(mapping, {0: _idOne, 2: _idTwo});

      final messages = ChannelMessageStore()..setPublicKeyHex = _deviceA;
      expect((await messages.loadChannelMessages(_idOne)).single.text, 'hello');
      // The unscoped legacy key migrates too.
      expect(
        (await messages.loadChannelMessages(_idTwo)).single.text,
        'unscoped',
      );

      final settings = ChannelSettingsStore()..setPublicKeyHex = _deviceA;
      expect(await settings.loadSmazEnabled(_idOne), isTrue);
      expect(await settings.loadSmazEnabled(_idTwo), isFalse);
      expect(await settings.loadCyr2LatEnabled(_idTwo), isTrue);
      expect(await settings.loadUrlImagesEnabled(_idTwo), isTrue);
      expect(await settings.loadCyr2LatProfileId(_idTwo), 'sr');

      final region = ChannelRegionStore()..setPublicKeyHex = _deviceA;
      expect(await region.loadRegion(_idOne), 'EU');

      final order = ChannelOrderStore()..setPublicKeyHex = _deviceA;
      expect(await order.loadChannelOrder(), [_idTwo, _idOne]);

      final prefs = PrefsManager.instance;
      expect(prefs.containsKey('channel_messages_${_scopeA}0'), isFalse);
      expect(prefs.containsKey('channel_messages_2'), isFalse);
      expect(prefs.containsKey('channel_smaz_${_scopeA}0'), isFalse);
      expect(prefs.containsKey('channel_region_${_scopeA}0'), isFalse);
      // A slot with no cached PSK is left alone.
      expect(prefs.containsKey('channel_messages_${_scopeA}5'), isTrue);
      // The slot map is seeded for the first post-migration diff.
      expect(
        await (ChannelStore()..setPublicKeyHex = _scopeA).loadSlotChannelIds(),
        {0: _idOne, 2: _idTwo},
      );
    });

    test('runs once per radio', () async {
      await _init(legacyValues());
      await ChannelStorageMigration.migrate(_scopeA);
      await PrefsManager.instance.setString(
        'channel_messages_${_scopeA}0',
        _storedMessages(['late']),
      );
      expect(await ChannelStorageMigration.migrate(_scopeA), isEmpty);
      final messages = ChannelMessageStore()..setPublicKeyHex = _deviceA;
      expect((await messages.loadChannelMessages(_idOne)).single.text, 'hello');
      expect(
        PrefsManager.instance.containsKey('channel_messages_${_scopeA}0'),
        isTrue,
      );
    });

    test('a rerun after an interrupted migration loses and duplicates '
        'nothing', () async {
      // Killed after the new keys were written but before the old ones
      // were removed and the done flag set.
      await _init({
        'channels$_scopeA': _cachedChannels({0: _pskOne, 2: _pskTwo}),
        'channel_messages_${_scopeA}0': _storedMessages(['hello']),
        'channel_messages_${_scopeA}_$_idOne': _storedMessages(['hello']),
        'channel_order_$_scopeA': jsonEncode([_idTwo, _idOne]),
      });
      await ChannelStorageMigration.migrate(_scopeA);

      final messages = ChannelMessageStore()..setPublicKeyHex = _deviceA;
      expect((await messages.loadChannelMessages(_idOne)).map((m) => m.text), [
        'hello',
      ]);
      final order = ChannelOrderStore()..setPublicKeyHex = _deviceA;
      expect(await order.loadChannelOrder(), [_idTwo, _idOne]);
      expect(
        PrefsManager.instance.containsKey('channel_messages_${_scopeA}0'),
        isFalse,
      );
    });

    test('images are stamped before the migration is marked done', () async {
      await _init(legacyValues());
      await expectLater(
        ChannelStorageMigration.migrate(
          _scopeA,
          beforeDone: (_) async => throw StateError('killed'),
        ),
        throwsStateError,
      );
      // Not marked done, so the next launch stamps again.
      Map<int, String>? stamped;
      await ChannelStorageMigration.migrate(
        _scopeA,
        beforeDone: (slotIds) async => stamped = slotIds,
      );
      expect(stamped, {0: _idOne, 2: _idTwo});
      // Data moved by the first run is still there.
      final messages = ChannelMessageStore()..setPublicKeyHex = _deviceA;
      expect((await messages.loadChannelMessages(_idOne)).single.text, 'hello');
    });

    test('skips a scope that must not adopt legacy data', () async {
      await _init(legacyValues());
      scopesWithoutLegacyMigration.add(_scopeA);
      expect(await ChannelStorageMigration.migrate(_scopeA), isEmpty);
      final prefs = PrefsManager.instance;
      expect(prefs.containsKey('channel_messages_${_scopeA}0'), isTrue);
      expect(prefs.containsKey('channel_storage_v2_$_scopeA'), isFalse);
      expect(prefs.containsKey('channel_messages_2'), isTrue);
    });

    test('two slots with the same PSK merge into one history', () async {
      await _init({
        'channels$_scopeA': _cachedChannels({1: _pskOne, 4: _pskOne}),
        'channel_messages_${_scopeA}1': _storedMessages(['first']),
        'channel_messages_${_scopeA}4': _storedMessages(['second', 'third']),
      });
      expect(await ChannelStorageMigration.migrate(_scopeA), {
        1: _idOne,
        4: _idOne,
      });
      final messages = ChannelMessageStore()..setPublicKeyHex = _deviceA;
      expect(
        (await messages.loadChannelMessages(_idOne)).map((m) => m.text),
        unorderedEquals(['first', 'second', 'third']),
      );
    });
  });

  group('received images', () {
    final png = Uint8List.fromList(List<int>.filled(32, 7));

    Future<ReceivedImageEntry> outgoing(
      ReceivedImageStore store, {
      required int slot,
      String? channelId,
      int imgId = 1,
    }) => store.registerOutgoing(
      channelIndex: slot,
      channelId: channelId,
      senderPrefix: 0x1234,
      imgId: imgId,
      previewPng: png,
      rate: AeicRatePoint.ft32,
      chunkCount: 1,
    );

    test('an entry round-trips its channel ID', () async {
      final store = ReceivedImageStore(decoder: null);
      final entry = await outgoing(store, slot: 2, channelId: _idOne);
      final json = entry.toJson();
      expect(json['channelId'], _idOne);
      expect(ReceivedImageEntry.fromJson(json).channelId, _idOne);
      expect(ReceivedImageEntry.fromJson({'streamId': 'x'}).channelId, isNull);
    });

    test('legacy entries get the ID their slot held', () async {
      final blobs = InMemoryReceivedImageBlobStore();
      final first = ReceivedImageStore(blobs: blobs, decoder: null);
      final onSlot2 = await outgoing(first, slot: 2, imgId: 1);
      final onSlot6 = await outgoing(first, slot: 6, imgId: 2);
      final stamped = await outgoing(first, slot: 2, imgId: 3, channelId: 'x');

      final store = ReceivedImageStore(blobs: blobs, decoder: null);
      await store.load();
      await store.stampLegacyChannelIds({2: _idOne, 3: _idTwo});

      expect(store.entryFor(onSlot2.streamId)!.channelId, _idOne);
      expect(store.entryFor(onSlot6.streamId)!.channelId, isNull);
      expect(store.entryFor(stamped.streamId)!.channelId, 'x');
      // Persisted, so the next launch keeps the stamp.
      final reloaded = ReceivedImageStore(blobs: blobs, decoder: null);
      await reloaded.load();
      expect(reloaded.entryFor(onSlot2.streamId)!.channelId, _idOne);
    });

    test('delete by channel ID leaves a reused slot alone', () async {
      final store = ReceivedImageStore(decoder: null);
      final old = await outgoing(store, slot: 1, channelId: _idOne, imgId: 1);
      final reused = await outgoing(
        store,
        slot: 1,
        channelId: _idTwo,
        imgId: 2,
      );

      expect(store.entriesForChannel(_idTwo).map((e) => e.streamId), [
        reused.streamId,
      ]);
      final removed = await store.deleteImagesForChannelId(_idOne);
      expect(removed, [old.streamId]);
      expect(store.entryFor(old.streamId), isNull);
      expect(store.entryFor(reused.streamId), isNotNull);
    });
  });
}
