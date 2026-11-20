import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/review_mode/review_script.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/storage/region_store.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

Uint8List _psk(int slot) =>
    Channel.parsePskHex(ReviewScript.channels[slot].pskHex);

/// `[0x88][snr*4][rssi][header][codes?][path_len][payload]` carrying an
/// encrypted GRP_TXT payload for the channel with [psk].
Uint8List _logRxGroupText(
  Uint8List psk,
  String text,
  int timestampSecs, {
  int routeType = 1,
  List<int> transportCodes = const [],
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
  final payload = Uint8List.fromList([
    channelHash,
    mac[0],
    mac[1],
    ...encrypted,
  ]);
  return Uint8List.fromList([
    pushCodeLogRxData,
    40, // snr
    0xA0, // rssi
    (0x05 << 2) | routeType,
    if (routeType == 0) ...transportCodes,
    0x00, // no path
    ...payload,
  ]);
}

// NotificationService is a process-wide singleton whose reply stream can be
// listened to once, so every test shares one connector and reconnects it.
late MeshCoreConnector _connector;

Future<ReviewRadio> _connect() async {
  final radio = ReviewRadio(
    scheduledMessageInterval: const Duration(hours: 1),
    ackDelay: const Duration(milliseconds: 50),
    replyDelay: const Duration(hours: 1),
    firmwareVerCode: 14,
  );
  _connector.reviewRadioFactoryForTest = () => radio;
  await _connector.connectReview();
  addTearDown(_connector.disconnect);
  await _waitFor(() => _connector.channelMapConfirmed);
  return radio;
}

List<String> _texts(int slot) => _connector
    .getChannelMessages(_connector.channels.firstWhere((c) => c.index == slot))
    .map((m) => m.text)
    .toList();

String? _regionOf(int slot, String text) {
  final messages = _connector
      .getChannelMessages(
        _connector.channels.firstWhere((c) => c.index == slot),
      )
      .where((m) => m.text == text)
      .toList();
  return messages.isEmpty ? null : messages.last.region;
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  test('legacy flood with no transport codes is labelled unscoped', () async {
    final radio = await _connect();
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    radio.emitForTest(_logRxGroupText(_psk(2), 'Pat: no scope', ts));
    await _waitFor(() => _texts(2).contains('no scope'));
    expect(_regionOf(2, 'no scope'), kUnscopedRegion);
  });

  test('transport flood with a zero code is labelled unscoped', () async {
    final radio = await _connect();
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    radio.emitForTest(
      _logRxGroupText(
        _psk(2),
        'Pat: null region',
        ts,
        routeType: 0,
        transportCodes: const [0x00, 0x00, 0x11, 0x22],
      ),
    );
    await _waitFor(() => _texts(2).contains('null region'));
    expect(_regionOf(2, 'null region'), kUnscopedRegion);
  });

  test('transport flood matching a saved region keeps its label', () async {
    RegionStore().addRegion('eu');
    final radio = await _connect();
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final psk = _psk(2);
    final plain = Uint8List.fromList([
      ...Uint8List(4)..buffer.asByteData().setUint32(0, ts, Endian.little),
      0,
      ...utf8.encode('Pat: scoped'),
      0,
    ]);
    final padded = Uint8List(((plain.length + 15) ~/ 16) * 16)
      ..setRange(0, plain.length, plain);
    final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(psk));
    final encrypted = Uint8List(padded.length);
    for (var i = 0; i < padded.length; i += 16) {
      cipher.processBlock(padded, i, encrypted, i);
    }
    final key32 = Uint8List(32)..setRange(0, 16, psk);
    final mac = crypto.Hmac(crypto.sha256, key32).convert(encrypted).bytes;
    final channelHash = crypto.sha256.convert(psk).bytes[0];
    final payload = Uint8List.fromList([
      channelHash,
      mac[0],
      mac[1],
      ...encrypted,
    ]);
    final code = floodTransportCode(
      scopeKey: floodScopeKeyForRegion('eu'),
      payloadType: 0x05,
      payload: payload,
    );
    radio.emitForTest(
      _logRxGroupText(
        psk,
        'Pat: scoped',
        ts,
        routeType: 0,
        transportCodes: [code[0], code[1], 0x11, 0x22],
      ),
    );
    await _waitFor(() => _texts(2).contains('scoped'));
    expect(_regionOf(2, 'scoped'), 'eu');
  });
}
