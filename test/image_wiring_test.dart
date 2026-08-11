import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/main.dart';
import 'package:meshcore_open/services/image_chunk_transport.dart';
import 'package:meshcore_open/services/received_image_store.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/widgets/image_send_codec_binding.dart';

void main() {
  test(
    'ImageStreamReassembler.selfPrefix override suppresses our own echo',
    () {
      final store = ReceivedImageStore();
      final r = ImageStreamReassembler(store: store);
      final set = buildImageChunks(
        payload: Uint8List.fromList(List<int>.generate(120, (i) => i)),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: 0xABCD,
        imgId: 7,
      );
      // Before SELF_INFO the prefix is unknown, so nothing is suppressed.
      expect(
        r.addChunk(set.blobs[0], channelIndex: 1).status,
        ImageChunkStatus.completed,
      );
      r.clear();
      // After SELF_INFO the superclass must see the overridden getter.
      r.selfPrefix = 0xABCD;
      expect(
        r.addChunk(set.blobs[0], channelIndex: 1).status,
        ImageChunkStatus.fromSelf,
      );
    },
  );

  test(
    'addChunk forwards outcomes to the store with the channel index',
    () async {
      final store = ReceivedImageStore();
      final r = ImageStreamReassembler(store: store);
      final set = buildImageChunks(
        payload: Uint8List.fromList(List<int>.generate(400, (i) => i & 0xFF)),
        metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.standard),
        senderPrefix: 0x1234,
        imgId: 3,
      );
      r.addChunk(set.blobs[0], channelIndex: 5);
      await store.settle();
      final entry = store.entries.single;
      expect(entry.channelIndex, 5);
      expect(entry.senderPrefix, 0x1234);
      expect(entry.state, ReceivedImageState.receiving);
    },
  );

  group('AppSettings image codec block', () {
    test(
      'round-trips through toJson/fromJson on the ImageCodecPreferences keys',
      () {
        final settings = AppSettings(
          imageCodecEnabled: true,
          imageCodecSelectedModelId: 'qdq_conv_pct_novae',
          imageCodecModelSourceUrl: 'https://example.invalid/model.onnx',
          imageCodecRatePoint: 4,
          imageCodecDownloadedModels: [
            ImageCodecModelRecord(
              id: 'qdq_conv_pct_novae',
              name: 'AEIC ft32 (int8)',
              sourceUrl: 'https://example.invalid/model.onnx',
              localPath: '/tmp/model.onnx',
              downloadedAt: DateTime.fromMillisecondsSinceEpoch(1000),
              fileSizeBytes: 872 * 1024 * 1024,
            ),
          ],
        );
        final json = settings.toJson();
        // The keys must be the ones ImageCodecPreferences already used, so a
        // build that wrote them through the old standalone store still reads.
        expect(json['image_codec_enabled'], isTrue);
        expect(json['image_codec_selected_model_id'], 'qdq_conv_pct_novae');
        expect(json['image_codec_rate_point'], 4);

        final restored = AppSettings.fromJson(json);
        expect(restored.imageCodecEnabled, isTrue);
        expect(restored.imageCodecSelectedModelId, 'qdq_conv_pct_novae');
        expect(
          restored.imageCodecModelSourceUrl,
          'https://example.invalid/model.onnx',
        );
        expect(restored.imageCodecRatePoint, 4);
        expect(
          restored.imageCodecDownloadedModels.single.localPath,
          '/tmp/model.onnx',
        );
      },
    );

    test('defaults are off, ft32, and empty', () {
      const prefs = ImageCodecPreferences();
      final settings = AppSettings();
      expect(settings.imageCodecEnabled, prefs.enabled);
      expect(settings.imageCodecRatePoint, prefs.ratePoint);
      expect(settings.imageCodecDownloadedModels, isEmpty);
      expect(settings.imageCodec.aeicRatePoint, AeicRatePoint.ft32);
    });

    test('the assembled view matches the five fields', () {
      final settings = AppSettings(
        imageCodecEnabled: true,
        imageCodecSelectedModelId: 'x',
        imageCodecRatePoint: 4,
      );
      expect(settings.imageCodec.enabled, isTrue);
      expect(settings.imageCodec.selectedModelId, 'x');
      expect(settings.imageCodec.ratePoint, 4);
    });
  });
}
