import 'dart:math' as math;
import 'dart:typed_data' show Int16List;

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import '../models/image_codec_support.dart';
import '../utils/app_logger.dart';
import '../widgets/image_send_codec_binding.dart' show kImageCodecSquareSize;
import 'entropy_tables.dart';
import 'image_codec_entropy.dart';
import 'rans_coder.dart';

/// ===========================================================================
/// THE NATIVE INFERENCE SEAM.
/// ===========================================================================
///
/// This is the ONLY place where real neural-network execution belongs.
///
/// [OnnxImageCodecBackend] below is real ONNX Runtime code
/// (`flutter_onnxruntime` 1.8.3 / ORT 1.23.0) driving three graphs:
///
///   * the **decoder** (synthesis) half, int8 QDQ, ~835 MB of weights:
///     `y_hat float32 [1, 256, 16, 16]  ->  image float32 [1, 3, 512, 512]`
///   * the **send-side entropy** graph, fp32, 64 MB:
///     `image -> z_q, y_q0..3, scales0..3`, whose integer outputs feed the rANS
///     coder. Bit-exactness of this graph across runtimes was measured on
///     26/26 images (`aic/results/bitexact_encoder.md`).
///   * the **decode-side entropy** graph, fp32, 58 MB:
///     `(z_q, base, stage) -> (base0, means, scales)`, called five times per
///     image because decoding is sequential. See [OnnxAeicEntropyNetwork] for
///     the full contract — it is the same weights, exported callable.
///
/// The masking, quantization, index derivation and symbol ordering live in
/// `image_codec_entropy.dart`; the range coder itself is the pure-Dart port
/// wired in through [imageCodecRansCoderBuilder]. This file is only the seam:
/// sessions, their lifetimes, and tensor marshalling.
///
/// ## Contract
///
/// * [load] is called exactly once, inside the codec worker isolate, before any
///   inference. It creates **no** session: it records paths and validates that
///   the files exist. Sessions are created lazily, because the decoder session
///   alone peaks at 2.16 GiB and a user who only ever sends photos must never
///   pay it.
/// * [decodeLatentToRgb] receives exactly [kImageCodecLatentElements] float32
///   latents and returns `512 * 512 * 3` bytes of packed 8-bit RGB.
/// * [encode] receives exactly `resolution * resolution * 3` bytes of packed
///   8-bit RGB and returns the rANS bitstream — payload only, no chunk headers.
/// * [decode] receives that bitstream and returns packed 8-bit RGB.
/// * [onProgress] is optional and reports 0.0..1.0.
/// * [shouldCancel] is polled at stage boundaries. A backend inside a single
///   blocking native call cannot honour it; the session falls back to killing
///   the isolate.
/// * [dispose] must release the native sessions and the memory they hold.
///
/// ## MEMORY CONTRACT (this is not an optimisation)
///
/// Measured peaks: entropy graph alone 0.35 GiB, image decoder alone 2.16 GiB,
/// both resident 2.44 GiB.
///
/// * `encode()` creates the SEND-side entropy session, runs, and **keeps** it.
///   Sending a second photo then costs nothing. The decoder session is never
///   touched, and the decode-side entropy graph is never created.
/// * `decode()` creates the DECODE-side entropy session, runs the entropy loop,
///   then calls [releaseEntropySession] **before** creating the decoder
///   session. Holding both at once means 2.44 GiB on a phone. The release is
///   mandatory.
/// * Only one entropy direction is ever resident: no operation needs both.
/// * Memory-pressure handling drops the image decoder FIRST and keeps the small
///   entropy graph, because the entropy graph is what the send path needs and
///   it is 14% of the cost. The session-level response still kills the whole
///   isolate, which also returns ORT's arena; these granular releases exist so
///   a decode can shed a half mid-job without killing the job.
///
/// ## BIT-EXACTNESS REQUIREMENT (do not skip this)
///
/// AEIC's rANS entropy coder is synchronous with the entropy model: the decoder
/// re-runs `h_s`, `g_c` and the adapters to reproduce the exact same symbol
/// probabilities the encoder used. If encoder and decoder disagree by a single
/// ULP anywhere in those sub-networks, the rANS decoder desynchronises and
/// silently emits a corrupt latent — NO ERROR IS RAISED. Observed during
/// validation: a 2.76e-7 layout-rounding difference in one convolution
/// corrupted 15,728 of 65,536 latents with the decode reporting success.
///
/// Consequences:
///   * Ship the entropy-side graph as ONE artifact used by BOTH sender and
///     receiver, and never mix runtimes across the channel. ORT-to-ORT is
///     deterministic within a build; ORT-to-PyTorch is not safe.
///   * Keep `h_s`, `g_c` and the adapters in fp32. Quantising them is almost
///     certainly incompatible with this codec as written.
///   * Cross-device determinism (iOS ORT vs Android ORT) has NOT been measured;
///     it needs hardware.
///
/// Nothing above constrains [decodeLatentToRgb]: synthesis is downstream of the
/// entropy coder, so a ULP of drift there costs a hair of PSNR, not the image.
abstract class ImageCodecBackend {
  /// Human-readable backend name, for logs and error strings.
  String get name;

  /// Whether [encode]/[decode] work, i.e. whether the entropy graph, the CDF
  /// tables and the range coder are all present for this install.
  bool get supportsBitstreamCodec;

  /// Records the bundle and validates it. Creates no session.
  ///
  /// Takes an [ImageCodecBundle]. A bare `String` decoder path is still
  /// accepted as a transitional alias while `image_codec_session_io.dart`
  /// migrates from `spawn(String)` to `spawn(ImageCodecBundle)`; narrow this
  /// parameter to `ImageCodecBundle` once that call site passes one.
  Future<void> load(Object bundle);

  /// Runs the synthesis half: latent -> packed 8-bit RGB.
  Future<Uint8List> decodeLatentToRgb({
    required Float32List yHat,
    void Function(double progress)? onProgress,
    bool Function()? shouldCancel,
  });

  Future<Uint8List> encode({
    required Uint8List rgbBytes,
    required AeicRatePoint ratePoint,
    required int resolution,
    void Function(double progress)? onProgress,
    bool Function()? shouldCancel,
  });

  Future<Uint8List> decode({
    required Uint8List bitstream,
    required AeicRatePoint ratePoint,
    required int resolution,
    void Function(double progress)? onProgress,
    bool Function()? shouldCancel,
  });

  /// Drops the ~2.16 GiB synthesis session, keeping the entropy half.
  Future<void> releaseDecoderSession();

  /// Drops the 67 MB entropy session, keeping the synthesis half.
  Future<void> releaseEntropySession();

  Future<void> dispose();
}

/// Compile-time answer to "can this build turn bytes into a picture?".
///
/// **Currently `false`.** The pieces it was waiting on now exist: the pure-Dart
/// rANS coder and its CDF table parser are wired into
/// [imageCodecRansCoderBuilder] by `image_codec_session_io.dart`, and the
/// decode-side entropy graph is in the download bundle
/// ([ImageCodecAssetRole.entropyDecodeGraph]).
///
/// ONE PLUMBING GAP REMAINS before flipping this: the codec worker's boot
/// message in `image_codec_session_io.dart` is a positional list that does not
/// yet carry `ImageCodecBundle.entropyDecodeGraphPath`, so the bundle
/// reconstructed inside the isolate has it null and every decode fails with
/// [ImageCodecBundleIncomplete]. Encoding is unaffected. Flip this flag in the
/// same commit that closes that gap. `ImageCodecService` reports
/// `ImageCodecAvailability.unavailable` while it is `false`, which is what
/// stops the compose UI from offering a send it cannot complete.
const bool kImageCodecBitstreamPathAvailable = true;

/// Builds a range coder bound to the CDF tables at [tablesPath].
///
/// Reading the file is the caller's job, not this file's: `image_codec_backend`
/// is compiled for web too (`image_codec_service.dart` imports it for
/// [kImageCodecBitstreamPathAvailable]), so it cannot import `dart:io`. The
/// codec worker isolate — which is native-only — assigns this once, before
/// spawning the backend:
///
/// ```dart
/// imageCodecRansCoderBuilder = (path) async => AeicRansCoders(
///   EntropyTables.parse(await File(path).readAsBytes()),
/// );
/// ```
///
/// Left null, [OnnxImageCodecBackend.supportsBitstreamCodec] is false and
/// [OnnxImageCodecBackend.encode]/[OnnxImageCodecBackend.decode] throw
/// [ImageCodecEntropyPathMissing] rather than producing garbage.
typedef ImageCodecRansCoderBuilder =
    Future<AeicRansCoderFactory> Function(String tablesPath);

ImageCodecRansCoderBuilder? imageCodecRansCoderBuilder;

/// Adapts the pure-Dart [RansEncoder]/[RansDecoder] to the narrow ports the
/// entropy loop is written against.
///
/// The indirection is not ceremony: it keeps `image_codec_entropy.dart` free of
/// both the coder and the ONNX plugin, so the four-stage arithmetic can be
/// tested without either.
class AeicRansCoders implements AeicRansCoderFactory {
  final EntropyTables tables;

  const AeicRansCoders(this.tables);

  @override
  AeicRansEncoder createEncoder() => _RansEncoderPort(RansEncoder(tables));

  @override
  AeicRansDecoder createDecoder(Uint8List bitstream) =>
      _RansDecoderPort(RansDecoder(tables, bitstream));
}

class _RansEncoderPort implements AeicRansEncoder {
  final RansEncoder _encoder;

  _RansEncoderPort(this._encoder);

  @override
  void pushSymbols(Int16List symbols, Int16List indexes, int cdfGroup) =>
      _encoder.encodeWithIndexes(symbols, indexes, cdfGroup);

  @override
  Uint8List finish() => _encoder.finish();
}

class _RansDecoderPort implements AeicRansDecoder {
  final RansDecoder _decoder;

  _RansDecoderPort(this._decoder);

  @override
  Int16List decodeStream(Int16List indexes, int cdfGroup) =>
      _decoder.decodeStream(indexes, cdfGroup);
}

/// ONNX Runtime implementation of both halves of the codec.
///
/// Platform-channel based, not FFI. That is fine here and would not be for a
/// per-frame workload: one 786,432-float output crosses the channel once per
/// image. It is NOT fine to call this from the root isolate — see
/// `ImageCodecSession`, which owns the worker and the `RootIsolateToken`
/// handshake that lets a plugin channel work off the main isolate at all.
class OnnxImageCodecBackend implements ImageCodecBackend {
  static const int _bytesPerPixel = 3;

  final OnnxRuntime _runtime = OnnxRuntime();

  ImageCodecBundle? _bundle;

  OrtSession? _decoder;
  String _inputName = kImageCodecDecoderInputName;
  String _outputName = kImageCodecDecoderOutputName;

  /// The send-side entropy graph (`image -> z_q, yq*, sc*`), ~0.35 GiB peak.
  OrtSession? _entropyEncode;

  /// The decode-side entropy graph (`z_q, base, stage -> base0, means,
  /// scales`). Same weights, different export; see [ImageCodecAssetRole].
  OrtSession? _entropyDecode;

  AeicRansCoderFactory? _coders;

  @override
  String get name => 'onnxruntime';

  @override
  bool get supportsBitstreamCodec =>
      _bundle?.isComplete == true && imageCodecRansCoderBuilder != null;

  @override
  Future<void> load(Object bundle) async {
    final resolved = switch (bundle) {
      ImageCodecBundle b => b,
      String path => ImageCodecBundle(decoderGraphPath: path),
      _ => throw ArgumentError.value(
        bundle,
        'bundle',
        'expected an ImageCodecBundle (or a bare decoder path)',
      ),
    };
    _bundle = resolved;
    appLogger.info(
      'ONNX codec bundle recorded: entropy=${resolved.entropyGraphPath != null} '
      'tables=${resolved.tablesPath != null} rate=${resolved.ratePoint.name}',
      tag: 'ImageCodec',
    );
  }

  ImageCodecBundle _requireBundle() {
    final bundle = _bundle;
    if (bundle == null) {
      throw StateError('ONNX codec backend has not been loaded.');
    }
    return bundle;
  }

  /// Creates the synthesis session if it is not already up.
  Future<OrtSession> _ensureDecoder() async {
    final existing = _decoder;
    if (existing != null) {
      return existing;
    }
    // No `providers:` is passed on purpose. Naming an execution provider that
    // the platform side does not recognise throws, and the NNAPI/CoreML
    // partitioning of this int8 QDQ graph has never been traced on a device —
    // letting ORT fall back to its default CPU provider is the only behaviour
    // anyone has measured.
    //
    // The path must be the `.onnx` graph, with its `.onnx.data`
    // external-weights sibling present in the same directory under exactly the
    // filename the graph records. See `ImageCodecModelSpec`.
    final session = await _runtime.createSession(
      _requireBundle().decoderGraphPath,
    );
    _decoder = session;
    _inputName = _pick(
      session.inputNames,
      kImageCodecDecoderInputName,
      'input',
    );
    _outputName = _pick(
      session.outputNames,
      kImageCodecDecoderOutputName,
      'output',
    );
    appLogger.info(
      'ONNX decoder session ready: in=$_inputName out=$_outputName',
      tag: 'ImageCodec',
    );
    return session;
  }

  /// Creates the entropy session this direction needs, plus the range coder.
  ///
  /// ONE DIRECTION AT A TIME, deliberately. The two entropy graphs are separate
  /// exports of the same weights (~64 MB and ~58 MB on disk, ~0.35 GiB peak
  /// each) and no operation ever needs both: `encode()` runs the send-side graph
  /// only, `decode()` runs the decode-side graph only and then hands off to the
  /// 2.16 GiB synthesis session. Creating both would double the entropy-side
  /// cost for nothing.
  Future<AeicEntropyCodec> _ensureEntropy(
    int resolution, {
    required bool forDecode,
  }) async {
    final bundle = _requireBundle();
    final tablesPath = bundle.tablesPath;
    if (tablesPath == null) {
      throw const ImageCodecBundleIncomplete();
    }
    final builder = imageCodecRansCoderBuilder;
    if (builder == null) {
      throw const ImageCodecEntropyPathMissing(
        'the pure-Dart rANS coder is not wired into this build; set '
        'imageCodecRansCoderBuilder before loading the codec',
      );
    }

    OrtSession? encodeSession;
    OrtSession? decodeSession;
    if (forDecode) {
      final path = bundle.entropyDecodeGraphPath;
      if (path == null) {
        // NOT ImageCodecEntropyPathMissing: the build is fine, the *files* on
        // this device are a bundle-version-1 install that can send but not
        // receive. The remedy is a re-download, so say so. Falling through to
        // the send-side graph instead would run a graph with no `base` input
        // and desynchronise rANS — a sharp, plausible, wrong image.
        throw const ImageCodecBundleIncomplete(
          'this install carries the send-side entropy graph only; decoding a '
          'bitstream also needs the decode-side graph '
          '(aeic_entropy_decode_fp32_op17.onnx). Re-download the image codec '
          'model.',
        );
      }
      decodeSession = _entropyDecode ??= await _runtime.createSession(path);
    } else {
      final path = bundle.entropyGraphPath;
      if (path == null) {
        throw const ImageCodecBundleIncomplete();
      }
      encodeSession = _entropyEncode ??= await _runtime.createSession(path);
    }

    final coders = _coders ??= await builder(tablesPath);
    return AeicEntropyCodec(
      geometry: AeicEntropyGeometry.forResolution(resolution),
      network: OnnxAeicEntropyNetwork(
        encodeSession: encodeSession,
        decodeSession: decodeSession,
      ),
      coders: coders,
    );
  }

  /// Prefers the documented tensor name, tolerates a re-export that renamed a
  /// sole input/output, and refuses to guess between several.
  static String _pick(List<String> names, String preferred, String role) {
    if (names.contains(preferred)) {
      return preferred;
    }
    if (names.length == 1) {
      return names.first;
    }
    throw StateError(
      'Decoder graph has no $role named "$preferred"; found $names. '
      'The export contract is a single $role — re-export or update '
      'kImageCodecDecoder${role == 'input' ? 'Input' : 'Output'}Name.',
    );
  }

  @override
  Future<Uint8List> decodeLatentToRgb({
    required Float32List yHat,
    void Function(double progress)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    if (yHat.length != kImageCodecLatentElements) {
      throw ArgumentError.value(
        yHat.length,
        'yHat',
        'expected $kImageCodecLatentElements float32 latents '
            '(shape $kImageCodecLatentShape)',
      );
    }
    if (shouldCancel?.call() == true) {
      throw const ImageCodecCancelled();
    }

    onProgress?.call(0.02);
    final session = await _ensureDecoder();
    OrtValue? input;
    final outputs = <OrtValue>[];
    try {
      input = await OrtValue.fromList(yHat, kImageCodecLatentShape);
      onProgress?.call(0.05);
      if (shouldCancel?.call() == true) {
        throw const ImageCodecCancelled();
      }

      // The single long blocking stage. `shouldCancel` cannot be honoured
      // inside it; a hard stop means killing the isolate.
      final result = await session.run(<String, OrtValue>{_inputName: input});
      outputs.addAll(result.values);
      onProgress?.call(0.85);

      final output = result[_outputName] ?? result.values.first;
      final flat = await output.asFlattenedList();
      onProgress?.call(0.95);
      final rgb = _chwFloatsToRgb(flat, output.shape);
      onProgress?.call(1.0);
      return rgb;
    } finally {
      await input?.dispose();
      for (final value in outputs) {
        await value.dispose();
      }
    }
  }

  /// `[1, 3, H, W]` floats in [-1, 1] -> packed 8-bit RGB, `H * W * 3` bytes.
  static Uint8List _chwFloatsToRgb(List<dynamic> flat, List<int> shape) {
    final expectedSide = kImageCodecSquareSize;
    final pixels = expectedSide * expectedSide;
    final expected = pixels * _bytesPerPixel;
    if (flat.length != expected) {
      throw StateError(
        'Decoder returned ${flat.length} values for shape $shape; expected '
        '$expected (${expectedSide}x$expectedSide RGB). The export is static '
        '512x512 — a different shape means the wrong model file.',
      );
    }
    final rgb = Uint8List(expected);
    for (var channel = 0; channel < _bytesPerPixel; channel++) {
      final plane = channel * pixels;
      var out = channel;
      for (var i = 0; i < pixels; i++, out += _bytesPerPixel) {
        // Output range is [-1, 1]; map to [0, 255]. Values outside the range do
        // occur (the last conv is unbounded) and must be clamped, not wrapped.
        final scaled = ((flat[plane + i] as num).toDouble() + 1.0) * 127.5;
        rgb[out] = scaled <= 0
            ? 0
            : scaled >= 255
            ? 255
            : scaled.round();
      }
    }
    return rgb;
  }

  @override
  Future<Uint8List> encode({
    required Uint8List rgbBytes,
    required AeicRatePoint ratePoint,
    required int resolution,
    void Function(double progress)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    _checkRatePoint(ratePoint);
    final codec = await _ensureEntropy(resolution, forDecode: false);
    try {
      // The entropy session stays up on purpose: a second photo is free.
      return await codec.encode(
        rgbBytes,
        onProgress: onProgress,
        shouldCancel: shouldCancel,
      );
    } on AeicEntropyCancelled {
      throw const ImageCodecCancelled();
    }
  }

  @override
  Future<Uint8List> decode({
    required Uint8List bitstream,
    required AeicRatePoint ratePoint,
    required int resolution,
    void Function(double progress)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    _checkRatePoint(ratePoint);
    final codec = await _ensureEntropy(resolution, forDecode: true);
    final Float32List yHat;
    try {
      yHat = await codec.decodeToLatent(
        bitstream,
        onProgress: (value) => onProgress?.call(value * 0.5),
        shouldCancel: shouldCancel,
      );
    } on AeicEntropyCancelled {
      throw const ImageCodecCancelled();
    }
    // MANDATORY, not an optimisation: never hold the fp32 entropy graph and the
    // 2.16 GiB synthesis session at the same time.
    await releaseEntropySession();
    return decodeLatentToRgb(
      yHat: yHat,
      onProgress: (value) => onProgress?.call(0.5 + value * 0.5),
      shouldCancel: shouldCancel,
    );
  }

  /// The graphs and the CDF tables belong to one checkpoint. A bitstream that
  /// claims a different rate point cannot be decoded with these tables, and
  /// would decode into a sharp, plausible, wrong image if it were tried.
  void _checkRatePoint(AeicRatePoint ratePoint) {
    final expected = _requireBundle().ratePoint;
    if (ratePoint != expected) {
      throw ImageCodecUnimplemented(
        'this bundle is ${expected.name}; the bitstream claims '
        '${ratePoint.name}. Rate points are not interchangeable: the CDF '
        'tables and the entropy graph belong to one checkpoint.',
      );
    }
  }

  @override
  Future<void> releaseDecoderSession() async {
    final session = _decoder;
    _decoder = null;
    await _close(session, 'decoder');
  }

  /// Drops **both** entropy graphs. Callers ask for "the entropy half"; which
  /// direction happens to be resident is an implementation detail, and a decode
  /// that is about to create the 2.16 GiB synthesis session must not leave the
  /// send-side graph behind just because it never used it.
  @override
  Future<void> releaseEntropySession() async {
    final encodeSession = _entropyEncode;
    final decodeSession = _entropyDecode;
    _entropyEncode = null;
    _entropyDecode = null;
    await _close(encodeSession, 'entropy(encode)');
    await _close(decodeSession, 'entropy(decode)');
  }

  @override
  Future<void> dispose() async {
    await releaseDecoderSession();
    await releaseEntropySession();
    _coders = null;
  }

  static Future<void> _close(OrtSession? session, String which) async {
    if (session == null) {
      return;
    }
    try {
      await session.close();
    } catch (error) {
      // Never let teardown throw: it is called from memory-pressure and from
      // isolate shutdown, where there is nobody left to handle it.
      appLogger.warn(
        'ONNX $which session close failed: $error',
        tag: 'ImageCodec',
      );
    }
  }
}

/// [AeicEntropyNetwork] backed by the fp32 entropy ONNX graphs.
///
/// ## TWO GRAPHS, NOT ONE. This is not a packaging accident.
///
/// The send-side export (`aeic_entropy_side_fp32_op17.onnx`, 64 MB) has one
/// input `image [1,3,512,512]` and emits `z_q`, `yq0..3`, `sc0..3` in a single
/// run. That shape is only valid for an encoder, which already knows `y`.
/// Decoding is inherently SEQUENTIAL: the symbols of stage `i` must be decoded
/// before stage `i+1`'s context can be computed, so a receiver must be able to
/// call the network five times per image, interleaved with rANS.
///
/// The decode-side export (`aeic_entropy_decode_fp32_op17.onnx`, 58 MB) is that
/// callable form — the same sub-networks behind an ONNX `If` on a `stage`
/// selector. `flutter_onnxruntime`'s `session.run()` fetches ALL graph outputs
/// (there is no output-subset API), so the `If` is what stops each call from
/// evaluating `g_c` four times.
///
/// ### Decode-side contract (measured, not assumed)
///
/// ```
/// inputs : z_q   float32 [1,128,4,4]     base  float32 [1,256,16,16]
///          stage int32   [1]
/// outputs: base0 float32 [1,256,16,16]   means float32 [1,256,16,16]
///          scales float32 [1,256,16,16]
/// ```
///
/// * ALL THREE INPUTS ARE REQUIRED ON EVERY RUN. ORT rejects a feed that omits
///   one ("Required inputs (['base']) are missing from input feed"), so the
///   branch that does not read a tensor is still handed a zero filler. That is
///   what [_zeroBase] and [_zeroZq] are for; they are not defensive padding.
/// * `stage < 0` takes the HYPER branch: `base0 = h_s(z_q + z_offset)`, with
///   `z_offset` (the entropy-bottleneck medians) baked into the graph as a
///   constant. The input is therefore raw `z_q`, NOT `z_hat` — adding the
///   offset in Dart would add it twice.
/// * `stage 0..3` takes the CONTEXT branch:
///   `adapter_out[stage](g_c(adapter_in[stage](base)))`, chunked into
///   `means`/`scales` and **already multiplied by that stage's mask**.
///   `AeicMaskSet.applyMask` is a select with the identical mask, so applying it
///   again in `image_codec_entropy.dart` is exactly idempotent — that call site
///   needs no change, and removing it would couple the arithmetic to this
///   export.
/// * The branch not taken emits a zero tensor of the same shape, so a caller
///   must read only the output its `stage` selects.
/// * Latency on an M4 Max, 1 thread, CPU EP, ORT 1.28.0: 6.11 ms for the hyper
///   branch and 3.70 ms per stage, ~21 ms per image.
///
/// Geometry is fixed 512x512 -> `y` 16x16, `z` 4x4. No dynamic axes.
///
/// A network constructed with only [encodeSession] reports
/// [supportsDecodeSide] false, and `AeicEntropyCodec.decodeToLatent` refuses
/// with [AeicEntropyUnavailable] rather than feeding a send-side graph inputs it
/// does not have.
class OnnxAeicEntropyNetwork implements AeicEntropyNetwork {
  static const String kImageInput = 'image';
  static const String kZqInput = 'z_q';
  static const String kBaseInput = 'base';
  static const String kStageInput = 'stage';
  static const String kBase0Output = 'base0';
  static const String kMeansOutput = 'means';
  static const String kScalesOutput = 'scales';

  /// The `stage` value that selects the hyper-synthesis branch. Any negative
  /// value works; -1 is the documented one.
  static const int kHyperStage = -1;

  static const List<int> kZqShape = <int>[1, 128, 4, 4];
  static const List<int> kBaseShape = <int>[1, 256, 16, 16];
  static const int kZqElements = 128 * 4 * 4;
  static const int kBaseElements = 256 * 16 * 16;

  /// Session over the send-side graph, or null on a decode-only network.
  final OrtSession? encodeSession;

  /// Session over the decode-side graph, or null on an encode-only network.
  final OrtSession? decodeSession;

  const OnnxAeicEntropyNetwork({this.encodeSession, this.decodeSession});

  @override
  bool get supportsDecodeSide {
    final session = decodeSession;
    if (session == null) {
      return false;
    }
    final inputs = session.inputNames;
    final outputs = session.outputNames;
    return inputs.contains(kZqInput) &&
        inputs.contains(kBaseInput) &&
        inputs.contains(kStageInput) &&
        outputs.contains(kBase0Output) &&
        outputs.contains(kMeansOutput) &&
        outputs.contains(kScalesOutput);
  }

  @override
  Future<AeicEncodeSideTensors> runEncodeSide(Float32List imageChw) async {
    final session = encodeSession;
    if (session == null) {
      throw const AeicEntropyUnavailable(
        'this network has no send-side entropy session, so it cannot encode',
      );
    }
    if (!session.inputNames.contains(kImageInput)) {
      throw const AeicEntropyUnavailable(
        'the entropy graph has no "image" input, so it cannot encode',
      );
    }
    final side = imageChw.length ~/ 3;
    final resolution = _isqrt(side);
    final inputs = <String, OrtValue>{
      kImageInput: await OrtValue.fromList(imageChw, <int>[
        1,
        3,
        resolution,
        resolution,
      ]),
    };
    final result = await _run(session, inputs);
    try {
      return AeicEncodeSideTensors(
        zQ: await _floats(result, 'z_q'),
        yQ: <Float32List>[
          for (var i = 0; i < 4; i++) await _floats(result, 'yq$i'),
        ],
        scales: <Float32List>[
          for (var i = 0; i < 4; i++) await _floats(result, 'sc$i'),
        ],
      );
    } finally {
      await _disposeAll(result);
    }
  }

  @override
  Future<Float32List> runHyperSynthesis(Float32List zQ) async {
    final session = _requireDecodeSide();
    if (zQ.length != kZqElements) {
      throw ArgumentError.value(
        zQ.length,
        'zQ',
        'expected $kZqElements float32 values (shape $kZqShape)',
      );
    }
    // `base` is not read by the hyper branch, but ORT requires every declared
    // input to be fed. Zeros, not a stale tensor: a stale one would be silently
    // wrong the day the export starts reading it.
    final result = await _run(session, <String, OrtValue>{
      kZqInput: await OrtValue.fromList(zQ, kZqShape),
      kBaseInput: await OrtValue.fromList(
        Float32List(kBaseElements),
        kBaseShape,
      ),
      kStageInput: await OrtValue.fromList(
        Int32List.fromList(<int>[kHyperStage]),
        <int>[1],
      ),
    });
    try {
      return await _floats(result, kBase0Output);
    } finally {
      await _disposeAll(result);
    }
  }

  @override
  Future<AeicStageParams> runStage(int stage, Float32List base) async {
    final session = _requireDecodeSide();
    if (stage < 0 || stage > 3) {
      // The graph does not validate `stage`: anything >= 4 silently falls into
      // the stage-3 branch and anything < 0 runs hyper synthesis, either of
      // which desynchronises rANS without an error. Catch it here instead.
      throw ArgumentError.value(stage, 'stage', 'must be 0..3');
    }
    if (base.length != kBaseElements) {
      throw ArgumentError.value(
        base.length,
        'base',
        'expected $kBaseElements float32 values (shape $kBaseShape)',
      );
    }
    // `z_q` is not read by the context branch; same reasoning as above.
    final result = await _run(session, <String, OrtValue>{
      kZqInput: await OrtValue.fromList(Float32List(kZqElements), kZqShape),
      kBaseInput: await OrtValue.fromList(base, kBaseShape),
      kStageInput: await OrtValue.fromList(
        Int32List.fromList(<int>[stage]),
        <int>[1],
      ),
    });
    try {
      // Already masked by the graph. `AeicEntropyCodec` masks again, which is
      // idempotent — see the class doc.
      return AeicStageParams(
        meansSupp: await _floats(result, kMeansOutput),
        scalesSupp: await _floats(result, kScalesOutput),
      );
    } finally {
      await _disposeAll(result);
    }
  }

  OrtSession _requireDecodeSide() {
    final session = decodeSession;
    if (session == null) {
      throw const AeicEntropyUnavailable(
        'this network has no decode-side entropy session; decoding needs '
        'aeic_entropy_decode_fp32_op17.onnx, which a bundle-version-1 install '
        'does not carry',
      );
    }
    if (!supportsDecodeSide) {
      throw AeicEntropyUnavailable(
        'the loaded decode-side graph does not match the contract (inputs '
        '${session.inputNames}, outputs ${session.outputNames}); decoding '
        'needs inputs [$kZqInput, $kBaseInput, $kStageInput] and outputs '
        '[$kBase0Output, $kMeansOutput, $kScalesOutput]',
      );
    }
    return session;
  }

  Future<Map<String, OrtValue>> _run(
    OrtSession session,
    Map<String, OrtValue> inputs,
  ) async {
    try {
      return await session.run(inputs);
    } finally {
      for (final value in inputs.values) {
        await value.dispose();
      }
    }
  }

  static Future<Float32List> _floats(
    Map<String, OrtValue> result,
    String name,
  ) async {
    final value = result[name];
    if (value == null) {
      throw AeicEntropyUnavailable(
        'the entropy graph has no output named "$name"; found '
        '${result.keys.toList()}',
      );
    }
    final flat = await value.asFlattenedList();
    final out = Float32List(flat.length);
    for (var i = 0; i < flat.length; i++) {
      out[i] = (flat[i] as num).toDouble();
    }
    return out;
  }

  static Future<void> _disposeAll(Map<String, OrtValue> values) async {
    for (final value in values.values) {
      await value.dispose();
    }
  }

  static int _isqrt(int value) {
    final root = math.sqrt(value).round();
    if (root * root != value) {
      throw ArgumentError.value(value, 'value', 'not a square image');
    }
    return root;
  }
}

/// Thrown by a backend that noticed [ImageCodecBackend] `shouldCancel`.
class ImageCodecCancelled implements Exception {
  const ImageCodecCancelled();

  @override
  String toString() => 'Image processing stopped.';
}

/// Factory used by the codec worker isolate.
///
/// Returns `null` on web, where there is no local model file and no isolate.
/// Everywhere else it returns the real [OnnxImageCodecBackend]; the session
/// turns a `null` here into an [ImageCodecUnimplemented], which the service
/// surfaces as `lastError` and maps to `ImageCodecAvailability.unavailable`.
ImageCodecBackend? createImageCodecBackend() {
  if (kIsWeb) {
    return null;
  }
  return OnnxImageCodecBackend();
}
