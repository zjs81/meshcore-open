import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/review_mode/review_script.dart';
import 'package:meshcore_open/services/image_chunk_transport.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/widgets/image_send_codec_binding.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitFor(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Uint8List _psk(int slot) =>
    Channel.parsePskHex(ReviewScript.channels[slot].pskHex);

/// A raw-log frame for a repeater re-flooding [blob] as GRP_DATA on [psk]'s
/// channel, encrypted the way the firmware's createGroupDatagram does.
Uint8List _logRxGroupData(Uint8List psk, Uint8List blob, {int hops = 1}) {
  final plain = <int>[
    dataTypeAeicImage & 0xFF,
    dataTypeAeicImage >> 8,
    blob.length,
    ...blob,
  ];
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
  return Uint8List.fromList([
    pushCodeLogRxData,
    40, // snr
    0xA0, // rssi
    0x19, // flood route, GRP_DATA payload
    hops, // path length: one 1-byte hash per hop
    for (var i = 0; i < hops; i++) 0x42 + i,
    channelHash,
    mac[0],
    mac[1],
    ...encrypted,
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeshCoreConnector connector;

  // One connector for the file: the notification service it starts accepts a
  // single listener per process.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    connector = MeshCoreConnector();
    final retryService = MessageRetryService();
    connector.initialize(
      retryService: retryService,
      pathHistoryService: PathHistoryService(StorageService()),
    );
    final radio = ReviewRadio(
      scheduledMessageInterval: const Duration(hours: 1),
      ackDelay: const Duration(milliseconds: 50),
      replyDelay: const Duration(hours: 1),
    );
    connector.reviewRadioFactoryForTest = () => radio;
    await connector.connectReview();
    await _waitFor(() => connector.channelMapConfirmed);
  });

  tearDownAll(() async {
    await connector.disconnect();
    connector.dispose();
  });

  Future<ImageChunkSet> sendImage({
    required int slot,
    required int imgId,
  }) async {
    final chunkSet = buildImageChunks(
      payload: Uint8List.fromList(List<int>.generate(200, (i) => i & 0xFF)),
      metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
      senderPrefix: senderPrefixFromKey(connector.selfPublicKey)!,
      imgId: imgId,
    );
    expect(
      await connector.sendImageChunks(
        chunkSet.blobs,
        channelIndex: slot,
        interChunkDelay: Duration.zero,
      ),
      isTrue,
    );
    return chunkSet;
  }

  test('a repeater echo of our own chunk is counted for that chunk', () async {
    final chunkSet = await sendImage(slot: 0, imgId: 77);
    expect(chunkSet.blobs.length, 3, reason: '2 data chunks + parity');
    expect(connector.ownImageEchoes(0, 77), [0, 0, 0]);

    connector.handleFrameForTest(_logRxGroupData(_psk(0), chunkSet.blobs[1]));
    connector.handleFrameForTest(_logRxGroupData(_psk(0), chunkSet.blobs[1]));
    connector.handleFrameForTest(_logRxGroupData(_psk(0), chunkSet.blobs[2]));

    expect(connector.ownImageEchoes(0, 77), [0, 2, 1]);
  });

  test('chunks from someone else, or on another channel key, are not '
      'counted', () async {
    final chunkSet = await sendImage(slot: 0, imgId: 78);

    // Same image id, different sender.
    final foreign = Uint8List.fromList(chunkSet.blobs[0]);
    foreign[0] ^= 0xFF;
    connector.handleFrameForTest(_logRxGroupData(_psk(0), foreign));
    // Our chunk, but encrypted for a different channel than it was sent on.
    connector.handleFrameForTest(_logRxGroupData(_psk(1), chunkSet.blobs[0]));

    expect(connector.ownImageEchoes(0, 78), [0, 0, 0]);
  });
}
