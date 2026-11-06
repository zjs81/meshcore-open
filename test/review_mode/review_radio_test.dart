import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/review_mode/review_script.dart';
import 'package:meshcore_open/services/message_retry_service.dart';

const _tick = Duration(milliseconds: 60);

class _Harness {
  final ReviewRadio radio;
  final List<Uint8List> frames = [];
  late final StreamSubscription<Uint8List> _sub;

  _Harness(this.radio) {
    _sub = radio.frames.listen(frames.add);
  }

  Future<void> settle([Duration d = _tick]) => Future<void>.delayed(d);

  Future<List<Uint8List>> request(Uint8List frame) async {
    frames.clear();
    radio.handle(frame);
    await settle();
    return List<Uint8List>.of(frames);
  }

  Future<void> close() async {
    await _sub.cancel();
    radio.dispose();
  }
}

ReviewRadio _fastRadio() => ReviewRadio(
  scheduledMessageInterval: const Duration(milliseconds: 40),
  ackDelay: const Duration(milliseconds: 100),
  replyDelay: const Duration(milliseconds: 200),
);

void main() {
  test('public key constants are consistent', () {
    expect(ReviewRadio.selfPublicKeyHex.length, 64);
    expect(ReviewRadio.selfPublicKeyHex.startsWith('ee5e'), isTrue);
    expect(
      ReviewRadio.selfPublicKeyHex,
      ReviewRadio.selfPublicKeyHex.toLowerCase(),
    );
    expect(
      ReviewRadio.storagePrefix,
      ReviewRadio.selfPublicKeyHex.substring(0, 10),
    );
  });

  test('responses are never synchronous', () async {
    final h = _Harness(ReviewRadio());
    h.radio.handle(buildAppStartFrame());
    expect(h.frames, isEmpty);
    await h.settle();
    expect(h.frames, hasLength(1));
    await h.close();
  });

  test('handshake replies with SELF_INFO and DEVICE_INFO', () async {
    final h = _Harness(ReviewRadio());

    final self = (await h.request(buildAppStartFrame())).single;
    expect(self[0], respCodeSelfInfo);
    final reader = BufferReader(self)..skipBytes(4);
    expect(
      pubKeyToHex(reader.readBytes(pubKeySize)),
      ReviewRadio.selfPublicKeyHex,
    );
    expect(reader.readInt32LE(), ReviewScript.selfLatitudeE6);
    expect(reader.readInt32LE(), ReviewScript.selfLongitudeE6);
    reader.skipBytes(4);
    expect(reader.readUInt32LE(), 910525000);
    expect(reader.readUInt32LE(), 62500);
    expect(reader.readByte(), 7);
    expect(reader.readByte(), 5);
    expect(reader.readCString(), 'Review Radio');

    final info = (await h.request(buildDeviceQueryFrame())).single;
    expect(info[0], respCodeDeviceInfo);
    expect(info.length, 82);
    expect(info[1], ReviewScript.firmwareVerCode);
    expect(info[2] * 2, ReviewScript.maxContacts);
    expect(info[3], ReviewScript.maxChannels);
    expect(
      String.fromCharCodes(info.sublist(20, 40)),
      startsWith('MeshCore Open Review'),
    );
    expect(String.fromCharCodes(info.sublist(60, 66)), 'review');
    expect(info[81], 0);
    await h.close();
  });

  test('contact list parses with the app Contact parser', () async {
    final h = _Harness(ReviewRadio());
    final out = await h.request(buildGetContactsFrame());

    expect(out.first[0], respCodeContactsStart);
    expect(readUint32LE(out.first, 1), ReviewScript.contacts.length);
    expect(out.last[0], respCodeEndOfContacts);
    final contacts = out.sublist(1, out.length - 1);
    expect(contacts, hasLength(6));
    for (final f in contacts) {
      expect(f.length, contactFrameSize);
    }
    final parsed = contacts.map((f) => Contact.fromFrame(f)!).toList();
    expect(parsed.map((c) => c.name), ReviewScript.contacts.map((c) => c.name));
    expect(parsed.where((c) => c.type == advTypeChat), hasLength(4));
    expect(parsed.where((c) => c.type == advTypeRepeater), hasLength(1));
    expect(parsed.where((c) => c.type == advTypeRoom), hasLength(1));
    expect(parsed[1].pathLength, 2);
    expect(parsed[0].latitude, closeTo(45.5231, 1e-6));
    expect(parsed.map((c) => c.publicKeyHex).toSet(), hasLength(6));

    // Incremental sync with a current 'since' returns nothing new.
    final since = readUint32LE(out.last, 1);
    final incremental = await h.request(buildGetContactsFrame(since: since));
    expect(incremental, hasLength(2));
    await h.close();
  });

  test('get contact by key returns the contact or ERR', () async {
    final h = _Harness(ReviewRadio());
    final key = hexToPubKey(ReviewScript.contacts[2].publicKeyHex);
    final found = (await h.request(buildGetContactByKeyFrame(key))).single;
    expect(Contact.fromFrame(found)!.name, 'Sam');

    final missing = (await h.request(
      buildGetContactByKeyFrame(Uint8List(pubKeySize)..fillRange(0, 32, 9)),
    )).single;
    expect(missing[0], respCodeErr);
    await h.close();
  });

  test('channel info for configured and empty slots', () async {
    final h = _Harness(ReviewRadio());
    final pub = Channel.fromFrame(
      (await h.request(buildGetChannelFrame(0))).single,
    )!;
    expect(pub.name, 'Public');
    expect(pub.isPublicChannel, isTrue);
    final hiking = Channel.fromFrame(
      (await h.request(buildGetChannelFrame(1))).single,
    )!;
    expect(hiking.name, 'Hiking Group');
    expect(hiking.isPublicChannel, isFalse);
    final local = Channel.fromFrame(
      (await h.request(buildGetChannelFrame(2))).single,
    )!;
    expect(local.name, 'Local Net');
    final empty = Channel.fromFrame(
      (await h.request(buildGetChannelFrame(5))).single,
    )!;
    expect(empty.isEmpty, isTrue);

    await h.request(
      buildSetChannelFrame(
        4,
        'New One',
        Uint8List.fromList(List.filled(16, 7)),
      ),
    );
    final added = Channel.fromFrame(
      (await h.request(buildGetChannelFrame(4))).single,
    )!;
    expect(added.name, 'New One');
    await h.close();
  });

  test('seed history drains through SYNC_NEXT_MESSAGE', () async {
    final h = _Harness(ReviewRadio());
    final direct = <ParsedContactText>[];
    final channel = <ChannelMessage>[];
    for (var i = 0; i < 20; i++) {
      final f = (await h.request(buildSyncNextMessageFrame())).single;
      if (f[0] == respCodeNoMoreMessages) break;
      if (f[0] == respCodeContactMsgRecvV3) {
        direct.add(parseContactMessageText(f)!);
      } else {
        expect(f[0], respCodeChannelMsgRecvV3);
        channel.add(ChannelMessage.fromFrame(f)!);
      }
    }
    expect(direct, hasLength(3));
    expect(channel, hasLength(4));
    expect(direct.first.text, contains('ridge'));
    expect(
      direct.first.senderPrefix,
      hexToPubKey(ReviewScript.contacts[0].publicKeyHex).sublist(0, 6),
    );
    expect(channel.map((m) => m.channelIndex).toSet(), {0, 1, 2});
    expect(
      channel.any(
        (m) => m.senderName == 'Jordan' && m.text.contains('trailhead'),
      ),
      isTrue,
    );

    final again = (await h.request(buildSyncNextMessageFrame())).single;
    expect(again[0], respCodeNoMoreMessages);
    await h.close();
  });

  test('direct send yields SENT, SEND_CONFIRMED and a queued reply', () async {
    final h = _Harness(_fastRadio());
    final contact = ReviewScript.contacts[0];
    final key = hexToPubKey(contact.publicKeyHex);
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final sent = await h.request(
      buildSendTextMsgFrame(key, 'Hello Maya', timestampSeconds: ts),
    );
    expect(sent.single[0], respCodeSent);
    final reader = BufferReader(sent.single)..skipBytes(2);
    final ackHash = reader.readUInt32LE();
    expect(reader.readUInt32LE(), greaterThan(0));
    expect(
      ackHash,
      MessageRetryService.computeExpectedAckHash(
        ts,
        0,
        'Hello Maya',
        hexToPubKey(ReviewRadio.selfPublicKeyHex),
      ),
    );

    h.frames.clear();
    await h.settle(const Duration(milliseconds: 150));
    expect(h.frames.first[0], pushCodeSendConfirmed);
    final confirmed = BufferReader(h.frames.first)..skipBytes(1);
    expect(confirmed.readUInt32LE(), ackHash);

    await h.settle(const Duration(milliseconds: 300));
    expect(h.frames.last[0], pushCodeMsgWaiting);

    // Drain the seed history; the reply is the last queued message.
    Uint8List? last;
    for (var i = 0; i < 20; i++) {
      final f = (await h.request(buildSyncNextMessageFrame())).single;
      if (f[0] == respCodeNoMoreMessages) break;
      last = f;
    }
    final reply = parseContactMessageText(last!)!;
    expect(reply.senderPrefix, key.sublist(0, 6));
    expect(ReviewScript.directReplies, contains(reply.text));
    await h.close();
  });

  test('room login succeeds and repeater login fails promptly', () async {
    final h = _Harness(_fastRadio());
    final room = ReviewScript.contacts.firstWhere((c) => c.type == advTypeRoom);
    final roomKey = hexToPubKey(room.publicKeyHex);
    final sent = await h.request(buildSendLoginFrame(roomKey, 'any'));
    expect(sent.single[0], respCodeSent);
    h.frames.clear();
    await h.settle(const Duration(milliseconds: 150));
    final success = h.frames.single;
    expect(success[0], pushCodeLoginSuccess);
    expect(success.length, greaterThanOrEqualTo(12));
    expect(success.sublist(2, 8), roomKey.sublist(0, 6));
    expect(readUint32LE(success, 8), greaterThan(0));

    final repeater = ReviewScript.contacts.firstWhere(
      (c) => c.type == advTypeRepeater,
    );
    final repeaterKey = hexToPubKey(repeater.publicKeyHex);
    expect(
      (await h.request(buildSendLoginFrame(repeaterKey, 'any'))).single[0],
      respCodeSent,
    );
    h.frames.clear();
    await h.settle(const Duration(milliseconds: 150));
    expect(h.frames.single[0], pushCodeLoginFail);
    expect(h.frames.single.sublist(2, 8), repeaterKey.sublist(0, 6));
    await h.close();
  });

  test('unknown recipient prefix is answered with ERR', () async {
    final h = _Harness(ReviewRadio());
    final out = await h.request(
      buildSendTextMsgFrame(Uint8List(pubKeySize)..fillRange(0, 32, 3), 'hi'),
    );
    expect(out.single[0], respCodeErr);
    await h.close();
  });

  test('channel send yields OK then a channel reply', () async {
    final h = _Harness(_fastRadio());
    final ok = await h.request(
      buildSendChannelTextMsgFrame(1, 'Review Radio: hi all'),
    );
    expect(ok.single[0], respCodeOk);

    h.frames.clear();
    await h.settle(const Duration(milliseconds: 300));
    expect(h.frames.single[0], pushCodeMsgWaiting);

    ChannelMessage? reply;
    for (var i = 0; i < 20; i++) {
      final f = (await h.request(buildSyncNextMessageFrame())).single;
      if (f[0] == respCodeNoMoreMessages) break;
      if (f[0] == respCodeChannelMsgRecvV3) reply = ChannelMessage.fromFrame(f);
    }
    expect(reply, isNotNull);
    expect(reply!.channelIndex, 1);
    expect(ReviewScript.channelMembers[1], contains(reply.senderName));
    expect(ReviewScript.channelReplies, contains(reply.text));
    await h.close();
  });

  test('status commands get plausible replies', () async {
    final h = _Harness(ReviewRadio());
    expect(
      (await h.request(buildGetBattAndStorageFrame())).single[0],
      respCodeBattAndStorage,
    );
    final time = (await h.request(buildGetDeviceTimeFrame())).single;
    expect(time[0], respCodeCurrTime);
    expect(
      readUint32LE(time, 1),
      closeTo(DateTime.now().millisecondsSinceEpoch ~/ 1000, 5),
    );
    expect(
      (await h.request(buildGetCustomVarsFrame())).single[0],
      respCodeCustomVars,
    );
    expect(
      (await h.request(buildGetAutoAddFlagsFrame())).single[0],
      respCodeAutoAddConfig,
    );
    final freq = (await h.request(buildGetAllowedRepeatFreqFrame())).single;
    expect(parseAllowedRepeatFreqFrame(freq), isNotEmpty);
    expect(
      (await h.request(buildGetStatsFrame(statsTypeRadio))).single.length,
      14,
    );
    expect(
      (await h.request(buildSetFloodScopeFrame('#west'))).single[0],
      respCodeOk,
    );
    expect((await h.request(buildSendSelfAdvertFrame())).single[0], respCodeOk);
    expect(
      (await h.request(
        buildSendLoginFrame(Uint8List(pubKeySize), 'pw'),
      )).single[0],
      respCodeErr,
    );
    await h.close();
  });

  test(
    'sendTestMessage queues alternating direct and channel messages',
    () async {
      final h = _Harness(ReviewRadio());
      // Drain seed history first.
      for (var i = 0; i < 20; i++) {
        final f = (await h.request(buildSyncNextMessageFrame())).single;
        if (f[0] == respCodeNoMoreMessages) break;
      }

      h.frames.clear();
      h.radio.sendTestMessage();
      h.radio.sendTestMessage();
      await h.settle();
      expect(h.frames.map((f) => f[0]), [
        pushCodeMsgWaiting,
        pushCodeMsgWaiting,
      ]);

      final first = (await h.request(buildSyncNextMessageFrame())).single;
      final second = (await h.request(buildSyncNextMessageFrame())).single;
      expect(first[0], respCodeContactMsgRecvV3);
      expect(second[0], respCodeChannelMsgRecvV3);
      expect(parseContactMessageText(first), isNotNull);
      expect(ChannelMessage.fromFrame(second), isNotNull);
      expect(
        (await h.request(buildSyncNextMessageFrame())).single[0],
        respCodeNoMoreMessages,
      );
      await h.close();
    },
  );

  test('scheduled timer emits MSG_WAITING after start', () async {
    final h = _Harness(_fastRadio());
    await h.settle(const Duration(milliseconds: 150));
    expect(h.frames, isEmpty);
    h.radio.start();
    await h.settle(const Duration(milliseconds: 150));
    expect(h.frames.where((f) => f[0] == pushCodeMsgWaiting), isNotEmpty);
    await h.close();
  });

  test('dispose cancels timers, closes the stream and is idempotent', () async {
    final radio = _fastRadio();
    final frames = <Uint8List>[];
    var done = false;
    radio.frames.listen(frames.add, onDone: () => done = true);
    radio.start();
    radio.handle(buildSendChannelTextMsgFrame(0, 'x: y'));
    radio.handle(
      buildSendTextMsgFrame(
        hexToPubKey(ReviewScript.contacts[0].publicKeyHex),
        'bye',
      ),
    );
    radio.dispose();
    radio.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(frames, isEmpty);
    expect(done, isTrue);
    radio.handle(buildAppStartFrame());
    radio.sendTestMessage();
    await Future<void>.delayed(_tick);
    expect(frames, isEmpty);
  });
}
