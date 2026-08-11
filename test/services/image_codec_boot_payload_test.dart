import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/services/image_codec_session_io.dart';

/// Connection tests for the codec worker's boot payload.
///
/// Two bugs in this feature had the same shape and both survived a green suite:
/// `imageCodecRansCoderBuilder` was declared, documented and consumed but never
/// assigned; and `entropyDecodeGraphPath` was resolved on the main isolate but
/// never put in the list handed to the worker, so every decode threw
/// [ImageCodecBundleIncomplete] while `canDecode` cheerfully reported true.
///
/// Neither was a broken component. Both were missing *connections*, and unit
/// tests that exercise each side in isolation cannot see them. These tests
/// assert the payload itself: what spawn() sends is exactly what the worker
/// needs to rebuild a bundle that can decode.
void main() {
  ImageCodecBundle fiveAssetBundle() => const ImageCodecBundle(
    decoderGraphPath: '/models/aeic_decoder_qdq_conv_pct.onnx',
    entropyGraphPath: '/models/aeic_entropy_side_fp32_op17.onnx',
    entropyDecodeGraphPath: '/models/aeic_entropy_decode_fp32_op17.onnx',
    tablesPath: '/models/aeic_cdf_ft32.bin',
    ratePoint: AeicRatePoint.ft32,
  );

  group('codec worker boot payload', () {
    test('a five-asset bundle survives the round trip and can still decode', () {
      final sent = fiveAssetBundle();
      expect(sent.supportsDecode, isTrue, reason: 'precondition');

      final rebuilt = debugBundleFromBootPayload(debugBootPayloadFor(sent));

      expect(rebuilt.decoderGraphPath, sent.decoderGraphPath);
      expect(rebuilt.entropyGraphPath, sent.entropyGraphPath);
      expect(rebuilt.tablesPath, sent.tablesPath);
      expect(rebuilt.ratePoint, sent.ratePoint);
      // The one that was missing. Without it the worker builds a bundle whose
      // supportsDecode is false and every decode throws, on a correct install.
      expect(rebuilt.entropyDecodeGraphPath, sent.entropyDecodeGraphPath);
      expect(rebuilt.supportsDecode, isTrue);
    });

    test('no field is silently reindexed by the positional layout', () {
      // The payload is a positional List. Inserting a slot anywhere but the end
      // shifts every field after it, and the casts are permissive enough that
      // tablesPath could arrive as the rate point without throwing. Pin each
      // slot to its meaning so a future insert fails here rather than in the
      // field, where it would read as a mysterious wrong-model error.
      final payload = debugBootPayloadFor(fiveAssetBundle());
      expect(payload[1], '/models/aeic_decoder_qdq_conv_pct.onnx');
      expect(payload[2], '/models/aeic_entropy_side_fp32_op17.onnx');
      expect(payload[3], '/models/aeic_cdf_ft32.bin');
      expect(payload[4], AeicRatePoint.ft32.wireValue);
      expect(payload[6], '/models/aeic_entropy_decode_fp32_op17.onnx');
    });

    test(
      'a send-only bundle rebuilds as send-only rather than half-decoding',
      () {
        const sendOnly = ImageCodecBundle(
          decoderGraphPath: '/models/decoder.onnx',
          entropyGraphPath: '/models/entropy.onnx',
          tablesPath: '/models/tables.bin',
          ratePoint: AeicRatePoint.ft32,
        );
        final rebuilt = debugBundleFromBootPayload(
          debugBootPayloadFor(sendOnly),
        );
        expect(rebuilt.entropyDecodeGraphPath, isNull);
        expect(rebuilt.supportsDecode, isFalse);
      },
    );

    test('a short payload does not crash the worker', () {
      // An older sender, or a truncated message, must degrade to "cannot
      // decode" rather than throwing a RangeError inside the isolate where the
      // failure would surface as an opaque spawn error.
      final short = debugBootPayloadFor(fiveAssetBundle()).sublist(0, 6);
      final rebuilt = debugBundleFromBootPayload(short);
      expect(rebuilt.entropyDecodeGraphPath, isNull);
      expect(rebuilt.supportsDecode, isFalse);
    });
  });
}
