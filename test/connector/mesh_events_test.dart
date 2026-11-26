import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/models/mesh_event.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/image_chunk_transport.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A GRP_DATA packet on [psk] as the radio logs it (push 0x88):
/// [0x88][snr*4][rssi][header][path_len][path][hash][mac x2][ciphertext].
Uint8List _logRxGroupData({
  required Uint8List psk,
  required int route,
  required List<int> path,
  required int dataType,
  required List<int> payload,
  int snrRaw = -30,
  int rssi = -101,
}) {
  final plainLen = ((3 + payload.length + 15) ~/ 16) * 16;
  final plain = Uint8List(plainLen)
    ..setAll(0, [dataType & 0xFF, dataType >> 8, payload.length, ...payload]);
  final key16 = Uint8List(16)..setRange(0, 16, psk);
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(key16));
  final encrypted = Uint8List(plainLen);
  for (var i = 0; i < plainLen; i += 16) {
    cipher.processBlock(plain, i, encrypted, i);
  }
  final key32 = Uint8List(32)..setRange(0, psk.length, psk);
  final mac = crypto.Hmac(crypto.sha256, key32).convert(encrypted).bytes;
  return Uint8List.fromList([
    0x88,
    snrRaw & 0xFF,
    rssi & 0xFF,
    (0x06 << 2) | route,
    path.length,
    ...path,
    crypto.sha256.convert(psk).bytes[0],
    mac[0],
    mac[1],
    ...encrypted,
  ]);
}

// [code][snr][reserved x2][channel][path_len][data_type LE x2][len][payload]
Uint8List _channelDataFrame({
  required int snrRaw,
  required int channelIndex,
  required int dataType,
  required List<int> payload,
  int pathLen = 2,
}) {
  return Uint8List.fromList([
    respCodeChannelDataRecv,
    snrRaw & 0xFF,
    0,
    0,
    channelIndex,
    pathLen,
    dataType & 0xFF,
    dataType >> 8,
    payload.length,
    ...payload,
  ]);
}

Future<void> _waitFor(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 8));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeshCoreConnector connector;
  late List<MeshEvent> events;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    connector = MeshCoreConnector();
    events = [];
    final subscription = connector.meshEvents.listen(events.add);
    addTearDown(subscription.cancel);
  });

  Future<void> connect() async {
    connector.reviewRadioFactoryForTest = ReviewRadio.new;
    await connector.connectReview();
    addTearDown(connector.disconnect);
    await _waitFor(() => connector.channelMapConfirmed);
    events.clear();
  }

  test('channel data of any type is emitted as a mesh event', () async {
    await connect();
    connector.handleFrameForTest(
      _channelDataFrame(
        snrRaw: -30,
        channelIndex: 0,
        dataType: 0xFF52,
        payload: [1, 2, 3],
      ),
    );
    await _waitFor(() => events.whereType<ChannelDataEvent>().isNotEmpty);

    final event = events.whereType<ChannelDataEvent>().single;
    expect(event.channelIndex, 0);
    expect(event.channelName, connector.channels.first.name);
    expect(event.dataType, 0xFF52);
    expect(event.payload, [1, 2, 3]);
    expect(event.snrDb, -7.5);
    expect(event.hops, 2);
    expect(event.outgoing, isFalse);
  });

  test('channel data takes route, path and RSSI from the RX log', () async {
    await connect();
    final psk = connector.channels.first.psk;
    connector.handleFrameForTest(
      _logRxGroupData(
        psk: psk,
        route: 0x01,
        path: [0xA1, 0x0B],
        dataType: 0xFF52,
        payload: [1, 2, 3],
      ),
    );
    // A repeater echo of the same packet must not replace the first copy.
    connector.handleFrameForTest(
      _logRxGroupData(
        psk: psk,
        route: 0x01,
        path: [0xA1, 0x0B, 0x77],
        dataType: 0xFF52,
        payload: [1, 2, 3],
        rssi: -60,
      ),
    );
    connector.handleFrameForTest(
      _channelDataFrame(
        snrRaw: -30,
        channelIndex: 0,
        dataType: 0xFF52,
        payload: [1, 2, 3],
      ),
    );
    await _waitFor(() => events.whereType<ChannelDataEvent>().isNotEmpty);
    final event = events.whereType<ChannelDataEvent>().single;
    expect(event.routeType, 'flood');
    expect(event.hops, 2);
    expect(event.path, [0xA1, 0x0B]);
    expect(event.pathHashSize, 1);
    expect(event.rssiDbm, -101);
  });

  test('zero-hop channel data is direct with an empty path', () async {
    await connect();
    connector.handleFrameForTest(
      _logRxGroupData(
        psk: connector.channels.first.psk,
        route: 0x02,
        path: [],
        dataType: 0xFF52,
        payload: [9],
      ),
    );
    connector.handleFrameForTest(
      _channelDataFrame(
        snrRaw: 40,
        channelIndex: 0,
        dataType: 0xFF52,
        payload: [9],
        pathLen: 0xFF,
      ),
    );
    await _waitFor(() => events.whereType<ChannelDataEvent>().isNotEmpty);
    final event = events.whereType<ChannelDataEvent>().single;
    expect(event.routeType, 'direct');
    expect(event.hops, isNull);
    expect(event.path, isEmpty);
    expect(event.rssiDbm, -101);
  });

  test('without the RX log the frame gives the route only', () async {
    await connect();
    connector.handleFrameForTest(
      _channelDataFrame(
        snrRaw: 0,
        channelIndex: 0,
        dataType: 0xFF52,
        payload: [4],
        pathLen: 0xFF,
      ),
    );
    await _waitFor(() => events.whereType<ChannelDataEvent>().isNotEmpty);
    final event = events.whereType<ChannelDataEvent>().single;
    expect(event.routeType, 'direct');
    expect(event.path, isNull);
    expect(event.rssiDbm, isNull);
  });

  test('a truncated channel data frame emits nothing', () async {
    await connect();
    final frame = _channelDataFrame(
      snrRaw: 0,
      channelIndex: 0,
      dataType: 0xFF52,
      payload: [1, 2, 3],
    );
    connector.handleFrameForTest(frame.sublist(0, frame.length - 1));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(events.whereType<ChannelDataEvent>(), isEmpty);
  });

  test('sendChannelData emits the acknowledged datagram as outgoing', () async {
    await connect();
    final sent = await connector.sendChannelData(
      channelIndex: 0,
      dataType: 0xFF52,
      payload: Uint8List.fromList([4, 5]),
    );
    expect(sent, isTrue);
    await _waitFor(() => events.whereType<ChannelDataEvent>().isNotEmpty);
    final event = events.whereType<ChannelDataEvent>().single;
    expect(event.outgoing, isTrue);
    expect(event.hops, isNull);
    expect(event.payload, [4, 5]);
  });

  test('sendChannelData refuses while disconnected or out of range', () async {
    expect(
      await connector.sendChannelData(
        channelIndex: 0,
        dataType: 0xFF52,
        payload: Uint8List.fromList([1]),
      ),
      isFalse,
    );
    await connect();
    expect(
      await connector.sendChannelData(
        channelIndex: 0,
        dataType: 0,
        payload: Uint8List.fromList([1]),
      ),
      isFalse,
    );
    expect(
      await connector.sendChannelData(
        channelIndex: 0,
        dataType: 0xFF52,
        payload: Uint8List(kMaxChannelDataPayload + 1),
      ),
      isFalse,
    );
  });
}
