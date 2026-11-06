import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/smaz.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _device = 'abcdef012345';
const _contact = 'c1';

Future<void> _init([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  PrefsManager.reset();
  await PrefsManager.initialize();
  MessageStore().forgetArchive();
  ChannelMessageStore().forgetArchive();
}

Message _dm(int i, {String? text}) => Message(
  senderKey: Uint8List.fromList([1, 2, 3]),
  text: text ?? 'm$i',
  timestamp: DateTime.fromMillisecondsSinceEpoch(1000 * i),
  isOutgoing: false,
  status: MessageStatus.delivered,
  messageId: 'id$i',
);

ChannelMessage _ch(int i) => ChannelMessage(
  senderKey: null,
  senderName: 'Bob',
  text: 'c$i',
  timestamp: DateTime.fromMillisecondsSinceEpoch(1000 * i),
  isOutgoing: false,
  status: ChannelMessageStatus.sent,
  channelIndex: 0,
  messageId: 'cid$i',
);

MessageStore _messageStore() => MessageStore()..setPublicKeyHex = _device;

const _channelId = '0123456789abcdef';

void main() {
  group('MessageStore window persistence', () {
    test('saving the window keeps archived history ahead of it', () async {
      await _init();
      final store = _messageStore();
      final all = [for (var i = 0; i < 10; i++) _dm(i)];
      await store.saveMessages(_contact, all);

      final loaded = await store.loadMessages(_contact);
      final window = loaded.sublist(6);
      store.setArchived(_contact, loaded.sublist(0, 6));
      await store.saveMessages(_contact, [...window, _dm(10)]);

      final reloaded = await store.loadMessages(_contact);
      expect(reloaded.map((m) => m.text), [
        for (var i = 0; i <= 10; i++) 'm$i',
      ]);
    });

    test('trimmed messages are archived, deletes stay deleted', () async {
      await _init();
      final store = _messageStore();
      store.setArchived(_contact, const []);
      final window = [for (var i = 0; i < 4; i++) _dm(i)];
      await store.saveMessages(_contact, window);

      // Trim the oldest two out of the window, delete one still in it.
      store.archive(_contact, window.sublist(0, 2));
      final remaining = [window[3], _dm(4)];
      await store.saveMessages(_contact, remaining);

      final reloaded = await store.loadMessages(_contact);
      expect(reloaded.map((m) => m.text), ['m0', 'm1', 'm3', 'm4']);
      expect(store.archivedCount(_contact), 2);

      store.unarchiveNewest(_contact, 1);
      expect(store.archivedCount(_contact), 1);
    });

    test('an unreconciled save merges with what is stored', () async {
      await _init();
      final store = _messageStore();
      await store.saveMessages(_contact, [for (var i = 0; i < 5; i++) _dm(i)]);

      // A fresh session saves a new message before the history was loaded.
      store.forgetArchive();
      await store.saveMessages(_contact, [_dm(5)]);

      final reloaded = await store.loadMessages(_contact);
      expect(reloaded.map((m) => m.text), [for (var i = 0; i <= 5; i++) 'm$i']);
    });

    test('clearMessages wipes archived history too', () async {
      await _init();
      final store = _messageStore();
      store.setArchived(_contact, [_dm(0), _dm(1)]);
      await store.saveMessages(_contact, [_dm(2)]);

      await store.clearMessages(_contact);
      await store.saveMessages(_contact, [_dm(3)]);

      final reloaded = await store.loadMessages(_contact);
      expect(reloaded.map((m) => m.text), ['m3']);
    });

    test('storage is capped by dropping the oldest archived entries', () async {
      await _init();
      final store = _messageStore();
      const cap = MessageStore.maxStoredMessages;
      store.setArchived(_contact, [for (var i = 0; i < cap; i++) _dm(i)]);
      await store.saveMessages(_contact, [_dm(cap), _dm(cap + 1)]);

      final reloaded = await store.loadMessages(_contact);
      expect(reloaded.length, cap);
      expect(reloaded.first.text, 'm2');
      expect(reloaded.last.text, 'm${cap + 1}');
      expect(store.archivedCount(_contact), cap - 2);
    });
  });

  group('MessageStore decoding', () {
    test('plain text that looks like Smaz survives a reload', () async {
      await _init();
      final store = _messageStore();
      await store.saveMessages(_contact, [
        _dm(0, text: 's:test'),
        _dm(1, text: 's:abcd'),
      ]);
      final reloaded = await store.loadMessages(_contact);
      expect(reloaded.map((m) => m.text), ['s:test', 's:abcd']);
    });

    test('legacy records still decode real Smaz payloads', () async {
      const plain = 'hello there how are you doing';
      final encoded = Smaz.encodeIfSmaller(plain);
      expect(encoded, startsWith('s:'));
      await _init({
        'messages_${_device.substring(0, 10)}$_contact': jsonEncode([
          {
            'senderKey': base64Encode([1, 2, 3]),
            'text': encoded,
            'timestamp': 1000,
          },
          {
            'senderKey': base64Encode([1, 2, 3]),
            'text': 's:test',
            'timestamp': 2000,
          },
        ]),
      });
      final reloaded = await _messageStore().loadMessages(_contact);
      expect(reloaded.map((m) => m.text), [plain, 's:test']);
    });

    test('a corrupt reaction status does not drop the message', () async {
      await _init({
        'messages_${_device.substring(0, 10)}$_contact': jsonEncode([
          {
            'senderKey': base64Encode([1, 2, 3]),
            'text': 'hi',
            'timestamp': 1000,
            'reactionStatuses': {'👍': 99, '❤': 'x', '😀': 1},
          },
        ]),
      });
      final reloaded = await _messageStore().loadMessages(_contact);
      expect(reloaded.single.text, 'hi');
      expect(reloaded.single.reactionStatuses, {'😀': MessageStatus.values[1]});
    });
  });

  group('ChannelMessageStore window persistence', () {
    test('saving the window keeps archived history ahead of it', () async {
      await _init();
      final store = ChannelMessageStore()..setPublicKeyHex = _device;
      final all = [for (var i = 0; i < 8; i++) _ch(i)];
      await store.saveChannelMessages(_channelId, all);

      final loaded = await store.loadChannelMessages(_channelId);
      store.setArchived(_channelId, loaded.sublist(0, 5));
      await store.saveChannelMessages(_channelId, [
        ...loaded.sublist(5),
        _ch(8),
      ]);

      final reloaded = await store.loadChannelMessages(_channelId);
      expect(reloaded.map((m) => m.text), [for (var i = 0; i <= 8; i++) 'c$i']);
    });

    test('clearing through another instance resets the archive', () async {
      await _init();
      final store = ChannelMessageStore()..setPublicKeyHex = _device;
      store.setArchived(_channelId, [_ch(0), _ch(1)]);
      await store.saveChannelMessages(_channelId, [_ch(2)]);

      await (ChannelMessageStore()..setPublicKeyHex = _device)
          .clearChannelMessages(_channelId);
      await store.saveChannelMessages(_channelId, [_ch(3)]);

      final reloaded = await store.loadChannelMessages(_channelId);
      expect(reloaded.map((m) => m.text), ['c3']);
    });
  });

  group('Smaz.tryDecodePrefixed', () {
    test('rejects plain text that is not a canonical compressed payload', () {
      expect(Smaz.tryDecodePrefixed('s:test'), isNull);
      expect(Smaz.tryDecodePrefixed('s:done'), isNull);
      expect(Smaz.tryDecodePrefixed('s:hello'), isNull);
    });

    test('decodes what encodeIfSmaller produced', () {
      for (final plain in [
        'hello there how are you doing',
        'ok see you at the meeting',
      ]) {
        expect(Smaz.tryDecodePrefixed(Smaz.encodeIfSmaller(plain)), plain);
      }
    });
  });
}
