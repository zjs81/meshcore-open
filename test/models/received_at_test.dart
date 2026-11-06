import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/reaction_helper.dart';
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

ChannelMessage _ch(
  String text, {
  required DateTime timestamp,
  DateTime? receivedAt,
}) => ChannelMessage(
  senderKey: null,
  senderName: 'Bob',
  text: text,
  timestamp: timestamp,
  receivedAt: receivedAt,
  isOutgoing: false,
  status: ChannelMessageStatus.sent,
  channelIndex: 0,
);

const _channelId = '0123456789abcdef';

void main() {
  final base = DateTime(2026, 10, 1, 12);

  group('receivedAt model', () {
    test('defaults to the sender timestamp and survives copyWith', () {
      final dm = Message(
        senderKey: Uint8List.fromList([1, 2, 3]),
        text: 'hi',
        timestamp: base,
        isOutgoing: false,
      );
      expect(dm.receivedAt, base);

      final later = base.add(const Duration(minutes: 3));
      final ch = _ch('hi', timestamp: base, receivedAt: later);
      expect(ch.copyWith(repeatCount: 2).receivedAt, later);
      final dm2 = Message(
        senderKey: Uint8List.fromList([1]),
        text: 'x',
        timestamp: base,
        receivedAt: later,
        isOutgoing: false,
      );
      expect(dm2.copyWith(retryCount: 1).receivedAt, later);
    });

    test('flags timestamps well ahead of arrival only', () {
      expect(
        _ch(
          'a',
          timestamp: base.add(const Duration(hours: 1)),
          receivedAt: base,
        ).hasFutureTimestamp,
        isTrue,
      );
      expect(
        _ch(
          'b',
          timestamp: base.add(const Duration(minutes: 2)),
          receivedAt: base,
        ).hasFutureTimestamp,
        isFalse,
      );
      expect(
        _ch(
          'c',
          timestamp: base.subtract(const Duration(days: 1)),
          receivedAt: base,
        ).hasFutureTimestamp,
        isFalse,
      );
    });

    test('identity (messageId, reaction hash) ignores receivedAt', () {
      final a = _ch('hello there', timestamp: base, receivedAt: base);
      final b = _ch(
        'hello there',
        timestamp: base,
        receivedAt: base.add(const Duration(hours: 5)),
      );
      expect(a.messageId, b.messageId);

      final secs = base.millisecondsSinceEpoch ~/ 1000;
      final hash = ReactionHelper.computeReactionHash(
        secs,
        'Bob',
        'hello there',
      );
      final info = ReactionHelper.parseReaction(
        ReactionHelper.encodeReaction(hash, '00'),
      )!;
      final messages = [b];
      final matched = ReactionHelper.applyReaction<ChannelMessage>(
        messages: messages,
        reactionInfo: info,
        getTimestampSecs: (m) => m.timestamp.millisecondsSinceEpoch ~/ 1000,
        getSenderName: (m) => m.senderName,
        getMessageText: (m) => m.text,
        getReactions: (m) => m.reactions,
        shouldSkip: (_) => false,
        updateMessage: (int i, Map<String, List<String?>> reactions) {},
      );
      expect(matched, isTrue);
    });
  });

  group('receivedAt persistence', () {
    test('channel store round-trips receivedAt', () async {
      await _init();
      final store = ChannelMessageStore()..setPublicKeyHex = _device;
      final received = base.add(const Duration(seconds: 42));
      await store.saveChannelMessages(_channelId, [
        _ch('one', timestamp: base, receivedAt: received),
      ]);
      final loaded = await store.loadChannelMessages(_channelId);
      expect(loaded.single.receivedAt, received);
      expect(loaded.single.timestamp, base);
    });

    test('DM store round-trips receivedAt', () async {
      await _init();
      final store = MessageStore()..setPublicKeyHex = _device;
      final received = base.add(const Duration(seconds: 7));
      await store.saveMessages(_contact, [
        Message(
          senderKey: Uint8List.fromList([1, 2, 3]),
          text: 'hi',
          timestamp: base,
          receivedAt: received,
          isOutgoing: false,
          status: MessageStatus.delivered,
          messageId: 'id1',
        ),
      ]);
      final loaded = await store.loadMessages(_contact);
      expect(loaded.single.receivedAt, received);
    });

    test('legacy records fall back to the timestamp, capped at now', () async {
      final past = DateTime.now().subtract(const Duration(days: 2));
      final future = DateTime.now().add(const Duration(days: 1));
      Map<String, Object?> record(String text, DateTime ts) => {
        'senderName': 'Bob',
        'text': text,
        'timestamp': ts.millisecondsSinceEpoch,
        'isOutgoing': false,
        'status': ChannelMessageStatus.sent.index,
        'messageId': 'legacy-$text',
        'plainText': true,
      };
      await _init({
        'channel_messages_${_device.substring(0, 10)}_$_channelId': jsonEncode([
          record('old', past),
          record('ahead', future),
        ]),
      });
      final store = ChannelMessageStore()..setPublicKeyHex = _device;
      final before = DateTime.now();
      final loaded = await store.loadChannelMessages(_channelId);
      expect(loaded, hasLength(2));
      expect(
        loaded[0].receivedAt.millisecondsSinceEpoch,
        past.millisecondsSinceEpoch,
      );
      // A stored future-dated message no longer sorts below later arrivals.
      expect(loaded[1].receivedAt.isAfter(future), isFalse);
      expect(
        loaded[1].receivedAt.isBefore(
          before.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(loaded[1].hasFutureTimestamp, isTrue);
    });
  });

  test(
    'ordering by receivedAt keeps a future-dated message in arrival order',
    () {
      final early = _ch(
        'clock ahead',
        timestamp: base.add(const Duration(days: 1)),
        receivedAt: base,
      );
      final late = _ch(
        'normal',
        timestamp: base.add(const Duration(minutes: 10)),
        receivedAt: base.add(const Duration(minutes: 10)),
      );
      final byTimestamp = [late, early]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      expect(byTimestamp.last.text, 'clock ahead');

      final byArrival = [late, early]
        ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
      expect(byArrival.map((m) => m.text), ['clock ahead', 'normal']);
    },
  );
}
