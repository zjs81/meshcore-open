import 'dart:typed_data';

import '../models/image_codec_support.dart';

/// Web stand-in. There is no isolate and no native runtime on web, so the
/// session cannot exist; `ImageCodecService` gates on `kIsWeb` long before it
/// would reach here.
class ImageCodecSession {
  ImageCodecSession._();

  static Future<ImageCodecSession> spawn(ImageCodecBundle bundle) async {
    throw UnsupportedError('The image codec is not supported on web.');
  }

  String get backendName => 'unsupported';

  bool get supportsBitstreamCodec => false;

  bool get hasEntropyGraph => false;

  bool get hasTables => false;

  Future<void> release({bool decoder = false, bool entropy = false}) async {}

  Future<Uint8List> decodeLatent(
    Float32List yHat, {
    void Function(double progress)? onProgress,
  }) async {
    throw UnsupportedError('The image codec is not supported on web.');
  }

  Future<Uint8List> encode(
    Uint8List rgbBytes,
    AeicRatePoint ratePoint,
    int resolution, {
    void Function(double progress)? onProgress,
  }) async {
    throw UnsupportedError('The image codec is not supported on web.');
  }

  Future<Uint8List> decode(
    Uint8List bitstream,
    AeicRatePoint ratePoint,
    int resolution, {
    void Function(double progress)? onProgress,
  }) async {
    throw UnsupportedError('The image codec is not supported on web.');
  }

  void cancel() {}

  Future<void> dispose() async {}
}
