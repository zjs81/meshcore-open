import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/review_mode/review_frames.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/review_mode/review_script.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _scope = ReviewRadio.storagePrefix;
const _queuedHikingText = 'Planning to leave the trailhead at 8 on Saturday.';

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Uint8List _psk(int slot) =>
    Channel.parsePskHex(ReviewScript.channels[slot].pskHex);

String _id(Uint8List psk) => Channel.storageIdForPsk(psk)!;

String _messagesKey(String channelId) =>
    'channel_messages_${_scope}_$channelId';

List<String> _storedTexts(String channelId) {
  final raw = PrefsManager.instance.getString(_messagesKey(channelId));
  if (raw == null) return [];
  return [
    for (final entry in jsonDecode(raw) as List<dynamic>)
      (entry as Map<String, dynamic>)['text'] as String,
  ];
}

// SharedPreferences updates its in-memory cache synchronously.
void _seedMessages(String channelId, List<String> texts) =>
    PrefsManager.instance.setString(
      _messagesKey(channelId),
      jsonEncode([
        for (var i = 0; i < texts.length; i++)
          {
            'senderName': 'Ghost',
            'text': texts[i],
            'timestamp': 1000 * (i + 1),
            'isOutgoing': false,
            'status': ChannelMessageStatus.sent.index,
            'messageId': 'seed-$channelId-$i',
            'plainText': true,
          },
      ]),
    );

void _seedSlotMap(Map<int, String> slotIds) => PrefsManager.instance.setString(
  'channel_slot_ids_$_scope',
  jsonEncode({for (final e in slotIds.entries) '${e.key}': e.value}),
);

/// Review radio that records every frame the app sends and can swallow some.
class _TestRadio extends ReviewRadio {
  _TestRadio({this.swallow, this.afterHandle})
    : super(
        scheduledMessageInterval: const Duration(hours: 1),
        ackDelay: const Duration(milliseconds: 50),
        replyDelay: const Duration(hours: 1),
      );

  final bool Function(Uint8List frame)? swallow;
  final void Function(_TestRadio radio, Uint8List frame)? afterHandle;
  final List<Uint8List> sent = [];

  @override
  void handle(Uint8List frame) {
    sent.add(Uint8List.fromList(frame));
    if (swallow?.call(frame) ?? false) return;
    super.handle(frame);
    afterHandle?.call(this, frame);
  }

  void deliver(Uint8List frame) => super.handle(frame);

  List<int> codes() => [for (final f in sent) f.isEmpty ? -1 : f[0]];
}

late MeshCoreConnector _connector;

/// Connects a fresh review radio. [seed] runs after review mode has cleared
/// its storage and before SELF_INFO, standing in for a previous session.
Future<void> _connect(_TestRadio radio, {void Function()? seed}) async {
  _connector.reviewRadioFactoryForTest = () {
    // beginReviewModeSession wipes the review scope before this runs.
    seed?.call();
    return radio;
  };
  await _connector.connectReview();
  addTearDown(_connector.disconnect);
  await _waitFor(() => _connector.channelMapConfirmed);
}

Channel _channelAt(int slot) =>
    _connector.channels.firstWhere((c) => c.index == slot);

List<String> _texts(int slot) =>
    _connector.getChannelMessages(_channelAt(slot)).map((m) => m.text).toList();

Uint8List _logRxGroupText(Uint8List psk, String text, int timestampSecs) {
  final plain = BytesBuilder()
    ..add(
      Uint8List(4)
        ..buffer.asByteData().setUint32(0, timestampSecs, Endian.little),
    )
    ..addByte(0)
    ..add(utf8.encode(text))
    ..addByte(0);
  final padded = Uint8List(((plain.length + 15) ~/ 16) * 16)
    ..setRange(0, plain.length, plain.toBytes());
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(psk));
  final encrypted = Uint8List(padded.length);
  for (var i = 0; i < padded.length; i += 16) {
    cipher.processBlock(padded, i, encrypted, i);
  }
  final key32 = Uint8List(32)..setRange(0, 16, psk);
  final mac = crypto.Hmac(crypto.sha256, key32).convert(encrypted).bytes;
  final channelHash = crypto.sha256.convert(psk).bytes[0];
  return Uint8List.fromList([
    pushCodeLogRxData,
    40, // snr
    0xA0, // rssi
    0x15, // flood route, GRP_TXT payload
    0x00, // no path
    channelHash,
    mac[0],
    mac[1],
    ...encrypted,
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    _connector = MeshCoreConnector();
    final retryService = MessageRetryService();
    _connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
    );
    addTearDown(() {
      _connector.dispose();
      retryService.dispose();
    });
  });

  tearDown(() => _connector.channelSyncTimeoutMs = 2000);

  final hikingId = _id(_psk(1));
  final ghostPsk = Uint8List.fromList(List<int>.generate(16, (i) => 200 - i));
  final ghostId = _id(ghostPsk);

  test('a slot reused by another channel while away starts clean', () async {
    await _connect(
      _TestRadio(),
      seed: () {
        // Last session slot 1 held the ghost channel.
        _seedSlotMap({0: _id(_psk(0)), 1: ghostId, 2: _id(_psk(2))});
        _seedMessages(ghostId, ['ghost message']);
      },
    );
    await _waitFor(() => _texts(1).contains(_queuedHikingText));

    expect(_channelAt(1).name, 'Hiking Group');
    expect(_texts(1), isNot(contains('ghost message')));
    await _connector.flushPendingWrites();
    // The old channel's history is kept under its own ID.
    expect(_storedTexts(ghostId), ['ghost message']);
    expect(_storedTexts(hikingId), contains(_queuedHikingText));
    expect(_connector.channelIdForSlot(1), hikingId);
    expect(
      jsonDecode(PrefsManager.instance.getString('channel_slot_ids_$_scope')!),
      containsPair('1', hikingId),
    );
  });

  test('a PSK edit in place starts clean, and re-adding the old PSK in '
      'another slot brings its history back', () async {
    await _connect(_TestRadio());
    await _waitFor(() => _texts(1).contains(_queuedHikingText));
    await _connector.setChannelSmazEnabled(1, true);

    await _connector.setChannel(1, 'Hiking Group', ghostPsk);
    expect(_connector.channelIdForSlot(1), ghostId);
    expect(_texts(1), isEmpty);
    expect(_connector.isChannelSmazEnabled(1), isFalse);
    expect(_storedTexts(hikingId), contains(_queuedHikingText));

    await _connector.setChannel(6, 'Hiking Group', _psk(1));
    expect(_connector.channelIdForSlot(6), hikingId);
    expect(_texts(6), contains(_queuedHikingText));
    expect(_connector.isChannelSmazEnabled(6), isTrue);

    // Restored history belongs to slot 6 now, so deleting from it works.
    final restored = _connector
        .getChannelMessages(_channelAt(6))
        .firstWhere((m) => m.text == _queuedHikingText);
    expect(restored.channelIndex, 6);
    await _connector.deleteChannelMessage(restored);
    await _connector.flushPendingWrites();
    expect(_texts(6), isNot(contains(_queuedHikingText)));
    expect(_storedTexts(hikingId), isNot(contains(_queuedHikingText)));
  });

  test(
    'a PSK edit in place keeps the channel\'s place in the custom order',
    () async {
      await _connect(_TestRadio());
      await _connector.setChannelOrder([1, 0, 2]);
      expect(_connector.channels.first.index, 1);

      await _connector.setChannel(1, 'Hiking Group', ghostPsk);
      expect(_connector.channels.first.index, 1);
    },
  );

  test('deleting a channel clears its stored history', () async {
    await _connect(_TestRadio());
    await _waitFor(() => _texts(1).contains(_queuedHikingText));
    await _connector.flushPendingWrites();
    expect(_storedTexts(hikingId), isNotEmpty);

    await _connector.deleteChannel(1);
    expect(_storedTexts(hikingId), isEmpty);
  });

  test('deleting a channel clears its history when the refresh cannot read '
      'the slot', () async {
    _connector.channelSyncTimeoutMs = 30;
    var deleted = false;
    final radio = _TestRadio(
      swallow: (frame) {
        if (frame[0] == cmdSetChannel && frame[1] == 1) deleted = true;
        return deleted && frame[0] == cmdGetChannel && frame[1] == 1;
      },
    );
    await _connect(radio);
    await _waitFor(() => _texts(1).contains(_queuedHikingText));

    await _connector.deleteChannel(1);
    expect(_connector.channelIdForSlot(1), hikingId);
    expect(_storedTexts(hikingId), isEmpty);
  });

  test(
    'deleting one of two slots with the same PSK keeps the history',
    () async {
      final radio = _TestRadio();
      await _connect(
        radio,
        seed: () =>
            radio.handle(buildSetChannelFrame(5, 'Hiking Twin', _psk(1))),
      );
      await _waitFor(() => _texts(1).contains(_queuedHikingText));

      await _connector.deleteChannel(1);
      await _connector.flushPendingWrites();
      expect(_storedTexts(hikingId), contains(_queuedHikingText));
    },
  );

  test('a channel frame that arrives before the slot map is held, then filed '
      'by the confirmed map', () async {
    final radio = _TestRadio(
      afterHandle: (radio, frame) {
        if (frame[0] == cmdAppStart) {
          radio.emitForTest(
            ReviewFrames.channelMessage(
              channelIndex: 1,
              sender: 'Sam',
              message: 'before the map',
              timestampSecs: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
          );
        }
      },
    );
    await _connect(
      radio,
      // A stale map from last session would file it under the ghost channel.
      seed: () => _seedSlotMap({0: _id(_psk(0)), 1: ghostId, 2: _id(_psk(2))}),
    );
    await _waitFor(() => _texts(1).contains('before the map'));
    await _connector.flushPendingWrites();
    expect(_storedTexts(hikingId), contains('before the map'));
    expect(_storedTexts(ghostId), isNot(contains('before the map')));
  });

  test('MSG_WAITING before the channel sync waits for the slot map', () async {
    // DEVICE_INFO is held back so MSG_WAITING lands between SELF_INFO and the
    // start of the channel sync.
    late final _TestRadio radio;
    var deviceInfoHeld = false;
    radio = _TestRadio(
      swallow: (frame) {
        if (frame[0] != cmdDeviceQuery || deviceInfoHeld) return false;
        deviceInfoHeld = true;
        Future<void>.delayed(
          const Duration(milliseconds: 400),
          () => radio.deliver(frame),
        );
        return true;
      },
      afterHandle: (radio, frame) {
        if (frame[0] == cmdAppStart) {
          radio.emitForTest(ReviewFrames.msgWaiting());
        }
      },
    );
    await _connect(radio);
    await _waitFor(() => _texts(1).contains(_queuedHikingText));

    final codes = radio.codes();
    final firstSync = codes.indexOf(cmdSyncNextMessage);
    final lastGetChannel = codes.lastIndexOf(cmdGetChannel);
    expect(firstSync, isNonNegative);
    expect(lastGetChannel, isNonNegative);
    expect(firstSync, greaterThan(lastGetChannel));
  });

  test('a slot that never answers retries the sync, then releases the '
      'queue with the saved map', () async {
    _connector.channelSyncTimeoutMs = 30;
    final radio = _TestRadio(
      swallow: (frame) => frame[0] == cmdGetChannel && frame[1] == 1,
    );
    await _connect(
      radio,
      seed: () => _seedSlotMap({0: _id(_psk(0)), 1: hikingId, 2: _id(_psk(2))}),
    );
    await _waitFor(() => _storedTexts(hikingId).contains(_queuedHikingText));

    final firstSync = radio.codes().indexOf(cmdSyncNextMessage);
    final passes = radio.sent
        .take(firstSync)
        .where((f) => f[0] == cmdGetChannel && f[1] == 0)
        .length;
    expect(passes, 3);
    expect(_connector.channelIdForSlot(1), hikingId);
  });

  test('two slots with the same PSK share one history', () async {
    final radio = _TestRadio();
    await _connect(
      radio,
      seed: () => radio.handle(buildSetChannelFrame(5, 'Hiking Twin', _psk(1))),
    );
    await _waitFor(() => _texts(1).contains(_queuedHikingText));
    expect(_connector.channelIdForSlot(5), hikingId);
    expect(_texts(5), _texts(1));

    // Settings are stored per channel, so both slots see a change.
    await _connector.setChannelSmazEnabled(5, true);
    expect(_connector.isChannelSmazEnabled(1), isTrue);
    await _connector.setChannelRegion(1, 'test-region');
    expect(_connector.getChannelRegion(5), 'test-region');

    radio.emitForTest(
      ReviewFrames.channelMessage(
        channelIndex: 5,
        sender: 'Sam',
        message: 'from the twin slot',
        timestampSecs: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );
    await _waitFor(() => _texts(1).contains('from the twin slot'));
    expect(_texts(5), contains('from the twin slot'));
    await _connector.flushPendingWrites();
    expect(
      _storedTexts(hikingId).where((t) => t == 'from the twin slot'),
      hasLength(1),
    );
  });

  test('an RX-log message is filed by its PSK-derived channel ID', () async {
    final radio = _TestRadio();
    await _connect(radio);
    final localId = _id(_psk(2));
    radio.emitForTest(
      _logRxGroupText(
        _psk(2),
        'Ranger Pat: heard over the air',
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );
    await _waitFor(() => _texts(2).contains('heard over the air'));
    await _connector.flushPendingWrites();
    expect(_storedTexts(localId), contains('heard over the air'));
    expect(_texts(1), isNot(contains('heard over the air')));
  });

  test('a busy channel is capped at the stored-message limit in memory and '
      'in storage', () async {
    await _connect(_TestRadio());
    await _waitFor(() => _texts(1).contains(_queuedHikingText));
    const cap = ChannelMessageStore.maxStoredMessages;
    final start = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (var i = 0; i < cap + 50; i++) {
      _connector.handleFrameForTest(
        ReviewFrames.channelMessage(
          channelIndex: 1,
          sender: 'Sam',
          message: 'busy $i',
          timestampSecs: start + i,
        ),
      );
    }

    final texts = _texts(1);
    expect(texts, hasLength(cap));
    expect(texts.last, 'busy ${cap + 49}');
    // Nothing is written per frame; the batch lands on flush.
    await _connector.flushPendingWrites();
    final stored = _storedTexts(hikingId);
    expect(stored, hasLength(cap));
    expect(stored.first, 'busy 50');
    expect(stored.last, 'busy ${cap + 49}');
  });
}
