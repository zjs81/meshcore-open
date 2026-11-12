import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/connector/pending_command_replies.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/review_mode/review_frames.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/review_mode/review_script.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestRadio extends ReviewRadio {
  _TestRadio()
    : super(
        scheduledMessageInterval: const Duration(hours: 1),
        ackDelay: const Duration(milliseconds: 50),
        replyDelay: const Duration(hours: 1),
      );
}

/// Answers the first channel text send with ERR, like a firmware reply that
/// arrives after the app gave up or was misattributed.
class _FlakySendRadio extends ReviewRadio {
  _FlakySendRadio()
    : super(
        scheduledMessageInterval: const Duration(hours: 1),
        ackDelay: const Duration(milliseconds: 50),
        replyDelay: const Duration(hours: 1),
      );

  bool _failNextChannelSend = true;

  @override
  void handle(Uint8List frame) {
    if (_failNextChannelSend &&
        frame.isNotEmpty &&
        frame[0] == cmdSendChannelTxtMsg) {
      _failNextChannelSend = false;
      emitForTest(ReviewFrames.err());
      return;
    }
    super.handle(frame);
  }
}

late MeshCoreConnector _connector;

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<void> _connect() async {
  final radio = _TestRadio();
  _connector.reviewRadioFactoryForTest = () => radio;
  await _connector.connectReview();
  addTearDown(_connector.disconnect);
  await _waitFor(() => _connector.channelMapConfirmed);
}

Channel _channelAt(int slot) =>
    _connector.channels.firstWhere((c) => c.index == slot);

List<ChannelMessage> _messages(int slot) =>
    _connector.getChannelMessages(_channelAt(slot));

ChannelMessage? _find(int slot, String text) {
  for (final m in _messages(slot)) {
    if (m.text == text) return m;
  }
  return null;
}

int _nowSecs() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

Uint8List _logRxGroupText(
  Uint8List psk,
  String text,
  int timestampSecs,
  int snrQuarterDb,
  int rssiDbm, {
  List<int> path = const [],
  int hashWidth = 1,
}) {
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
  final pathLenRaw = path.isEmpty
      ? 0x00
      : (((hashWidth - 1) << 6) | (path.length ~/ hashWidth));
  return Uint8List.fromList([
    pushCodeLogRxData,
    snrQuarterDb,
    rssiDbm,
    0x15, // flood route, GRP_TXT payload
    pathLenRaw,
    ...path,
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

  test('sync message then raw packet merge into one copy', () async {
    await _connect();
    final ts = _nowSecs();
    const text = 'Cross merge A';
    final psk = Channel.parsePskHex(ReviewScript.channels[2].pskHex);

    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Alice',
        message: text,
        timestampSecs: ts,
        snrQuarterDb: 20,
      ),
    );
    await _waitFor(() => _find(2, text) != null);

    _connector.handleFrameForTest(
      _logRxGroupText(psk, 'Alice: $text', ts, 40, -70),
    );
    await _waitFor(() => _find(2, text)!.repeatCount == 1);

    final merged = _find(2, text)!;
    expect(_messages(2).where((m) => m.text == text).length, 1);
    expect(merged.rssiDbm, -70);
  });

  test('raw packet then sync message merge into one copy', () async {
    await _connect();
    final ts = _nowSecs();
    const text = 'Cross merge B';
    final psk = Channel.parsePskHex(ReviewScript.channels[2].pskHex);

    _connector.handleFrameForTest(
      _logRxGroupText(psk, 'Bob: $text', ts, 40, -66),
    );
    await _waitFor(() => _find(2, text) != null);

    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Bob',
        message: text,
        timestampSecs: ts,
        snrQuarterDb: 20,
      ),
    );
    await _waitFor(() => _find(2, text)!.repeatCount == 1);

    expect(_messages(2).where((m) => m.text == text).length, 1);
  });

  test('sent message merges with its raw echo', () async {
    await _connect();
    const text = 'Raw echo probe';
    final channel = _channelAt(2);
    await _connector.sendChannelMessage(channel, text);

    final outgoing = _messages(2).last;
    final ts = outgoing.timestamp.millisecondsSinceEpoch ~/ 1000;
    final self = _connector.selfName!;
    final psk = Channel.parsePskHex(ReviewScript.channels[2].pskHex);

    _connector.handleFrameForTest(
      _logRxGroupText(
        psk,
        '$self: $text',
        ts,
        48,
        -60,
        path: const [0xAA, 0xBB],
        hashWidth: 2,
      ),
    );
    await _waitFor(() => _find(2, text)!.repeatCount == 1);

    final echoed = _find(2, text)!;
    expect(echoed.isOutgoing, isTrue);
    expect(echoed.snrDb, 12.0);
    expect(echoed.rssiDbm, -60);
  });

  test('sent message merges with sync echo then raw echo', () async {
    await _connect();
    const text = 'Both echoes A';
    final channel = _channelAt(2);
    await _connector.sendChannelMessage(channel, text);

    final outgoing = _messages(2).last;
    final ts = outgoing.timestamp.millisecondsSinceEpoch ~/ 1000;
    final self = _connector.selfName!;
    final psk = Channel.parsePskHex(ReviewScript.channels[2].pskHex);

    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: self,
        message: text,
        timestampSecs: ts,
        path: Uint8List.fromList([0xAB]),
        snrQuarterDb: 16,
      ),
    );
    await _waitFor(() => _find(2, text)!.repeatCount == 1);

    _connector.handleFrameForTest(
      _logRxGroupText(psk, '$self: $text', ts, 48, -60, path: const [0xAB]),
    );
    await _waitFor(() => _find(2, text)!.repeatCount == 2);

    final echoed = _find(2, text)!;
    expect(echoed.isOutgoing, isTrue);
    expect(_messages(2).where((m) => m.text == text).length, 1);
    expect(echoed.rssiDbm, -60);
  });

  test('sent message merges with raw echo then sync echo', () async {
    await _connect();
    const text = 'Both echoes B';
    final channel = _channelAt(2);
    await _connector.sendChannelMessage(channel, text);

    final outgoing = _messages(2).last;
    final ts = outgoing.timestamp.millisecondsSinceEpoch ~/ 1000;
    final self = _connector.selfName!;
    final psk = Channel.parsePskHex(ReviewScript.channels[2].pskHex);

    _connector.handleFrameForTest(
      _logRxGroupText(psk, '$self: $text', ts, 48, -60, path: const [0xAB]),
    );
    await _waitFor(() => _find(2, text)!.repeatCount == 1);

    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: self,
        message: text,
        timestampSecs: ts,
        path: Uint8List.fromList([0xAB]),
        snrQuarterDb: 16,
      ),
    );
    await _waitFor(() => _find(2, text)!.repeatCount == 2);

    final echoed = _find(2, text)!;
    expect(echoed.isOutgoing, isTrue);
    expect(_messages(2).where((m) => m.text == text).length, 1);
    expect(echoed.rssiDbm, -60);
  });

  test('failed message is promoted to sent when its echo is heard', () async {
    final radio = _FlakySendRadio();
    _connector.reviewRadioFactoryForTest = () => radio;
    await _connector.connectReview();
    addTearDown(_connector.disconnect);
    await _waitFor(() => _connector.channelMapConfirmed);

    const text = 'Failed then echoed';
    final channel = _channelAt(2);
    await expectLater(
      _connector.sendChannelMessage(channel, text),
      throwsA(isA<FirmwareCommandException>()),
    );

    final failed = _find(2, text)!;
    expect(failed.status, ChannelMessageStatus.failed);

    final ts = failed.timestamp.millisecondsSinceEpoch ~/ 1000;
    final self = _connector.selfName!;
    final psk = Channel.parsePskHex(ReviewScript.channels[2].pskHex);
    _connector.handleFrameForTest(
      _logRxGroupText(
        psk,
        '$self: $text',
        ts,
        48,
        -60,
        path: const [0xAA, 0xBB],
        hashWidth: 2,
      ),
    );
    await _waitFor(() => _find(2, text)!.status == ChannelMessageStatus.sent);

    final echoed = _find(2, text)!;
    expect(echoed.repeatCount, 1);
    expect(echoed.isOutgoing, isTrue);
  });
}
