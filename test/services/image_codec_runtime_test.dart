import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/image_codec_backend.dart';
import 'package:meshcore_open/services/image_codec_service.dart';
import 'package:meshcore_open/services/image_codec_settings_store.dart';
import 'package:meshcore_open/widgets/image_send_codec_binding.dart';

/// Runs in both build modes; each half skips in the other (`scripts/onnx.sh`).
void main() {
  ImageCodecService newService() {
    final service = ImageCodecService(
      AppSettingsService(),
      settingsStore: InMemoryImageCodecSettingsStore(
        const ImageCodecPreferences(enabled: true),
      ),
    );
    addTearDown(service.dispose);
    return service;
  }

  test('ONNX-free build reports the image codec unavailable', () {
    final service = newService();
    expect(createImageCodecBackend(), isNull);
    expect(service.availability, ImageCodecAvailability.unavailable);
    expect(service.unavailableReason, contains('without ONNX Runtime'));
    expect(service.canRunInference, isFalse);
  }, skip: imageCodecRuntimeAvailable ? 'ONNX Runtime is compiled in' : false);

  test('ONNX build has a codec backend', () {
    final service = newService();
    expect(createImageCodecBackend(), isA<OnnxImageCodecBackend>());
    expect(service.unavailableReason, isNull);
  }, skip: imageCodecRuntimeAvailable ? false : 'built without ONNX Runtime');
}
