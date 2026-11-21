/// Stand-in for `flutter_onnxruntime` in builds made without ONNX Runtime.
///
/// Mirrors only the API MeshCore Open uses. [OnnxRuntime] cannot be
/// constructed, which is how the app detects this build.
library;

UnsupportedError _unsupported() =>
    UnsupportedError('This build was made without ONNX Runtime.');

class OnnxRuntime {
  OnnxRuntime() {
    throw _unsupported();
  }

  Future<OrtSession> createSession(String modelPath) => throw _unsupported();
}

abstract class OrtSession {
  List<String> get inputNames;

  List<String> get outputNames;

  Future<Map<String, OrtValue>> run(Map<String, OrtValue> inputs);

  Future<void> close();
}

abstract class OrtValue {
  List<int> get shape;

  static Future<OrtValue> fromList(dynamic data, List<int> shape) =>
      throw _unsupported();

  Future<List<dynamic>> asFlattenedList();

  Future<void> dispose();
}
