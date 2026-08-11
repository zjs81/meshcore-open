import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/image_codec_service.dart';

/// Covers the one piece of the decode path that can be executed without a model
/// file, a device or ONNX Runtime: turning the backend's packed RGB output into
/// PNG bytes a widget can render.
///
/// It needs the engine's image codecs, hence the binding.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCodecService.rgbToPng', () {
    test('encodes a PNG with the right magic bytes and dimensions', () async {
      const side = 8;
      final rgb = Uint8List(side * side * 3);
      for (var i = 0; i < rgb.length; i++) {
        rgb[i] = i & 0xFF;
      }

      final png = await ImageCodecService.rgbToPng(rgb, side);

      expect(png.sublist(0, 8), [
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      // IHDR width/height, big-endian at offsets 16 and 20.
      final header = ByteData.sublistView(png);
      expect(header.getUint32(16), side);
      expect(header.getUint32(20), side);
    });

    test('rejects a buffer that is not RGB at the stated size', () async {
      await expectLater(
        ImageCodecService.rgbToPng(Uint8List(10), 8),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
