import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/models/mesh_event.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/image_chunk_transport.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [code][snr][reserved x2][channel][path_len][data_type LE x2][len][payload]
Uint8List _channelDataFrame({
  required int snrRaw,
  required int channelIndex,
  required int dataType,
  required List<int> payload,
}) {
  return Uint8List.fromList([
    respCodeChannelDataRecv,
    snrRaw & 0xFF,
    0,
    0,
    channelIndex,
    2,
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
        dataType: 0xB652,
        payload: [1, 2, 3],
      ),
    );
    await _waitFor(() => events.whereType<ChannelDataEvent>().isNotEmpty);

    final event = events.whereType<ChannelDataEvent>().single;
    expect(event.channelIndex, 0);
    expect(event.channelName, connector.channels.first.name);
    expect(event.dataType, 0xB652);
    expect(event.payload, [1, 2, 3]);
    expect(event.snrDb, -7.5);
    expect(event.outgoing, isFalse);
  });

  test('a truncated channel data frame emits nothing', () async {
    await connect();
    final frame = _channelDataFrame(
      snrRaw: 0,
      channelIndex: 0,
      dataType: 0xB652,
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
      dataType: 0xB652,
      payload: Uint8List.fromList([4, 5]),
    );
    expect(sent, isTrue);
    await _waitFor(() => events.whereType<ChannelDataEvent>().isNotEmpty);
    final event = events.whereType<ChannelDataEvent>().single;
    expect(event.outgoing, isTrue);
    expect(event.payload, [4, 5]);
  });

  test('sendChannelData refuses while disconnected or out of range', () async {
    expect(
      await connector.sendChannelData(
        channelIndex: 0,
        dataType: 0xB652,
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
        dataType: 0xB652,
        payload: Uint8List(kMaxChannelDataPayload + 1),
      ),
      isFalse,
    );
  });
}
