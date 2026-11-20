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

ChannelMessage? _find(int slot, String text) {
  for (final m in _connector.getChannelMessages(_channelAt(slot))) {
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
  int rssiDbm,
) {
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
    snrQuarterDb,
    rssiDbm,
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

  test(
    'a merged repeat shows the strongest signal heard, not the last one',
    () async {
      await _connect();
      final ts = _nowSecs();
      const text = 'Signal merge probe';

      _connector.handleFrameForTest(
        ReviewFrames.channelMessage(
          channelIndex: 2,
          sender: 'Alice',
          message: text,
          timestampSecs: ts,
          path: Uint8List.fromList([0xAB]),
          snrQuarterDb: 20,
        ),
      );
      await _waitFor(() => _find(2, text) != null);

      _connector.handleFrameForTest(
        ReviewFrames.channelMessage(
          channelIndex: 2,
          sender: 'Alice',
          message: text,
          timestampSecs: ts,
          path: Uint8List.fromList([0xCD, 0xEF]),
          snrQuarterDb: 60,
        ),
      );
      await _waitFor(() => _find(2, text)!.repeatCount == 1);

      final merged = _find(2, text)!;
      expect(merged.snrDb, 15.0);
      expect(
        merged
            .pathSignals[ChannelMessage.pathKey(Uint8List.fromList([0xAB]))]!
            .snrDb,
        5.0,
      );
      expect(
        merged
            .pathSignals[ChannelMessage.pathKey(
              Uint8List.fromList([0xCD, 0xEF]),
            )]!
            .snrDb,
        15.0,
      );
    },
  );

  test('a weaker later repeat keeps the strongest signal', () async {
    await _connect();
    final ts = _nowSecs();
    const text = 'Strong first probe';

    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Bob',
        message: text,
        timestampSecs: ts,
        path: Uint8List.fromList([0x12, 0x34]),
        snrQuarterDb: 72,
      ),
    );
    await _waitFor(() => _find(2, text) != null);

    _connector.handleFrameForTest(
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: 'Bob',
        message: text,
        timestampSecs: ts,
        path: Uint8List.fromList([0x56]),
        snrQuarterDb: 8,
      ),
    );
    await _waitFor(() => _find(2, text)!.repeatCount == 1);

    final merged = _find(2, text)!;
    expect(merged.snrDb, 18.0);
    expect(
      merged
          .pathSignals[ChannelMessage.pathKey(Uint8List.fromList([0x56]))]!
          .snrDb,
      2.0,
    );
  });

  test(
    'repeats on one path keep the strongest signal for that variant',
    () async {
      await _connect();
      final ts = _nowSecs();
      const text = 'Same path probe';
      final path = Uint8List.fromList([0x77]);

      for (final snrQuarterDb in [12, 44, 8]) {
        _connector.handleFrameForTest(
          ReviewFrames.channelMessage(
            channelIndex: 2,
            sender: 'Carol',
            message: text,
            timestampSecs: ts,
            path: path,
            snrQuarterDb: snrQuarterDb,
          ),
        );
      }
      await _waitFor(() => _find(2, text)?.repeatCount == 2);

      final merged = _find(2, text)!;
      expect(merged.repeatCount, 2);
      expect(merged.snrDb, 11.0);
      expect(merged.pathSignals[ChannelMessage.pathKey(path)]!.snrDb, 11.0);
    },
  );

  test('merged copies show SNR and RSSI from the same packet', () async {
    await _connect();
    final ts = _nowSecs();
    const text = 'pair probe';
    final psk = Channel.parsePskHex(ReviewScript.channels[2].pskHex);

    _connector.handleFrameForTest(
      _logRxGroupText(psk, 'Dave: $text', ts, 12, 0xA0),
    );
    await _waitFor(() => _find(2, text) != null);
    _connector.handleFrameForTest(
      _logRxGroupText(psk, 'Dave: $text', ts, 44, 0xB0),
    );
    _connector.handleFrameForTest(
      _logRxGroupText(psk, 'Dave: $text', ts, 40, 0xC0),
    );
    await _waitFor(() => _find(2, text)!.repeatCount == 2);

    final merged = _find(2, text)!;
    // The 11 dB copy wins even though the 10 dB copy arrived louder; the
    // pair is never mixed between packets.
    expect(merged.snrDb, 11.0);
    expect(merged.rssiDbm, -80);
  });

  test('a sent message shows the strongest echo heard', () async {
    await _connect();
    final channel = _channelAt(2);
    const text = 'Echo probe';
    await _connector.sendChannelMessage(channel, text);

    final outgoing = _connector.getChannelMessages(channel).last;
    expect(outgoing.isOutgoing, isTrue);
    expect(outgoing.snrDb, isNull);
    final ts = outgoing.timestamp.millisecondsSinceEpoch ~/ 1000;
    final self = _connector.selfName!;

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
      ReviewFrames.channelMessage(
        channelIndex: 2,
        sender: self,
        message: text,
        timestampSecs: ts,
        path: Uint8List.fromList([0xCD, 0xEF]),
        snrQuarterDb: 52,
      ),
    );
    await _waitFor(() => _find(2, text)!.repeatCount == 2);

    final echoed = _find(2, text)!;
    expect(echoed.isOutgoing, isTrue);
    expect(echoed.snrDb, 13.0);
  });
}
