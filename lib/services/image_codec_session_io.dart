import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import '../models/image_codec_support.dart';
import '../widgets/image_send_codec_binding.dart' show kImageCodecSquareSize;
import 'image_codec_backend.dart';
import 'entropy_tables.dart';

/// Owns a long-lived [Isolate] and the native codec session inside it.
///
/// A decode is 1385 GFLOP over 886M parameters. It must never run on the root
/// isolate: it would freeze the UI and, worse, stall the BLE notify stream that
/// `MeshCoreConnector._handleFrame()` feeds on, dropping mesh traffic while a
/// picture renders.
///
/// The isolate is spawned once per model load and reused, because loading the
/// model is the expensive part (~833 MB int8). This is the same amortisation
/// `TranslationService._ensureContext` gets for free from llamadart, which owns
/// its own worker thread. Do NOT switch this to `Isolate.run` per call.
///
/// Message protocol (all maps, all `type`-tagged):
///   worker -> host  `ready`    {port: SendPort, backend: String,
///                               bitstream: bool, entropy: bool, tables: bool}
///                   `fatal`    {error: String}          — during startup only
///                   `progress` {id: int, value: double}
///                   `result`   {id: int, bytes: Uint8List}
///                   `released` {id: int}
///                   `error`    {id: int, error: String, stack: String?}
///   host -> worker  `job`      {id, op: 'encode'|'decode'|'decodeLatent',
///                               bytes | latents, rate, size}
///                   `release`  {id, which: 'decoder'|'entropy'|'both'}
///                   `cancel`   {}
///                   `shutdown` {}
///
/// ## Two sessions, two lifetimes
///
/// The backend holds the 2.16 GiB decoder and the 67 MB entropy graph
/// independently, and [release] is how the host sheds one without killing the
/// other. It exists because `decode()` MUST drop the entropy graph before it
/// creates the decoder — holding both at once is ~2.2 GiB plus 67 MB of arena
/// on a phone — and because memory pressure wants the big half gone while the
/// small half (all that `encode()` needs) can survive.
///
/// ## Plugin channels on a background isolate
///
/// The ONNX backend is a *plugin*, reached over a platform channel, and a plain
/// spawned isolate has no binary messenger — every `invokeMethod` would throw
/// until `BackgroundIsolateBinaryMessenger.ensureInitialized` is handed a
/// [RootIsolateToken] captured on the root isolate. That token is part of the
/// boot payload below. Consequence: [spawn] must be called from the root
/// isolate. It is (via `ImageCodecService`), and if that ever changes the token
/// is null and the worker fails loudly at startup instead of on first inference.
class ImageCodecSession {
  final Isolate _isolate;
  final SendPort _toWorker;
  final ReceivePort _fromWorker;
  final ReceivePort _errors;

  /// Name of the backend that actually loaded, for logs and error strings.
  final String backendName;

  /// Whether the loaded backend can turn bytes into a picture, as opposed to
  /// only latents into a picture. True only when the bundle carried the entropy
  /// graph and the CDF tables AND the backend implements the entropy path.
  final bool supportsBitstreamCodec;

  /// Whether the bundle handed to [spawn] carried an entropy-side graph.
  final bool hasEntropyGraph;

  /// Whether the bundle handed to [spawn] carried a CDF table file.
  final bool hasTables;

  final Map<int, _PendingJob> _pending = {};
  final Map<int, Completer<void>> _pendingReleases = {};
  int _nextJobId = 1;
  bool _disposed = false;

  ImageCodecSession._({
    required Isolate isolate,
    required SendPort toWorker,
    required ReceivePort fromWorker,
    required ReceivePort errors,
    required this.backendName,
    required this.supportsBitstreamCodec,
    required this.hasEntropyGraph,
    required this.hasTables,
  }) : _isolate = isolate,
       _toWorker = toWorker,
       _fromWorker = fromWorker,
       _errors = errors;

  /// Spawns the worker and blocks until the backend has *validated* [bundle].
  ///
  /// Cheap by design: `load()` parses the CDF tables (813 KB) and checks that
  /// every path exists, and creates NO ORT session. Sessions are created lazily
  /// by the first operation that needs one, which is what lets a send pay for
  /// the 67 MB entropy graph alone instead of the 2.16 GiB decoder as well.
  ///
  /// Throws [ImageCodecUnimplemented] when no inference backend is compiled
  /// into the build, or whatever the backend threw while loading.
  static Future<ImageCodecSession> spawn(ImageCodecBundle bundle) async {
    final fromWorker = ReceivePort();
    final errors = ReceivePort();
    final handshake = Completer<Map<String, Object?>>();
    ImageCodecSession? session;

    fromWorker.listen((message) {
      if (message is! Map) return;
      final map = message.cast<String, Object?>();
      final active = session;
      if (active != null) {
        active._handleMessage(map);
      } else if (!handshake.isCompleted) {
        handshake.complete(map);
      }
    });

    errors.listen((message) {
      final description = message is List && message.isNotEmpty
          ? message.first.toString()
          : message.toString();
      final active = session;
      if (active != null) {
        active._failAll(StateError('Image codec isolate died: $description'));
      } else if (!handshake.isCompleted) {
        handshake.complete({'type': 'fatal', 'error': description});
      }
    });

    late final Isolate isolate;
    try {
      isolate = await Isolate.spawn<List<Object?>>(
        _codecWorkerMain,
        _bootPayload(
          bundle,
          fromWorker.sendPort,
          // Null when spawn() was not called from the root isolate. The worker
          // treats that as a fatal startup error rather than limping on to fail
          // at the first invokeMethod.
          RootIsolateToken.instance,
        ),
        errorsAreFatal: true,
        onError: errors.sendPort,
        debugName: 'image-codec',
      );
    } catch (_) {
      fromWorker.close();
      errors.close();
      rethrow;
    }

    Map<String, Object?> reply;
    try {
      reply = await handshake.future;
    } catch (_) {
      isolate.kill(priority: Isolate.immediate);
      fromWorker.close();
      errors.close();
      rethrow;
    }

    if (reply['type'] != 'ready') {
      isolate.kill(priority: Isolate.immediate);
      fromWorker.close();
      errors.close();
      final detail = reply['error']?.toString() ?? 'unknown startup failure';
      if (reply['unimplemented'] == true) {
        throw ImageCodecUnimplemented(detail);
      }
      throw StateError('Image codec failed to start: $detail');
    }

    return session = ImageCodecSession._(
      isolate: isolate,
      toWorker: reply['port'] as SendPort,
      fromWorker: fromWorker,
      errors: errors,
      backendName: reply['backend'] as String? ?? 'unknown',
      supportsBitstreamCodec: reply['bitstream'] == true,
      hasEntropyGraph: reply['entropy'] == true,
      hasTables: reply['tables'] == true,
    );
  }

  /// Runs the synthesis half: `y_hat` -> packed 8-bit RGB.
  ///
  /// This is the one inference path that actually works today. [encode] and
  /// [decode] fail with [ImageCodecEntropyPathMissing] until the entropy-side
  /// graph and the rANS coder land.
  Future<Uint8List> decodeLatent(
    Float32List yHat, {
    void Function(double progress)? onProgress,
  }) {
    return _submit(
      op: 'decodeLatent',
      latents: yHat,
      ratePoint: kShippingAeicRatePoint,
      resolution: kImageCodecSquareSize,
      onProgress: onProgress,
    );
  }

  Future<Uint8List> encode(
    Uint8List rgbBytes,
    AeicRatePoint ratePoint,
    int resolution, {
    void Function(double progress)? onProgress,
  }) {
    return _submit(
      op: 'encode',
      bytes: rgbBytes,
      ratePoint: ratePoint,
      resolution: resolution,
      onProgress: onProgress,
    );
  }

  Future<Uint8List> decode(
    Uint8List bitstream,
    AeicRatePoint ratePoint,
    int resolution, {
    void Function(double progress)? onProgress,
  }) {
    return _submit(
      op: 'decode',
      bytes: bitstream,
      ratePoint: ratePoint,
      resolution: resolution,
      onProgress: onProgress,
    );
  }

  Future<Uint8List> _submit({
    required String op,
    Uint8List? bytes,
    Float32List? latents,
    required AeicRatePoint ratePoint,
    required int resolution,
    void Function(double progress)? onProgress,
  }) {
    if (_disposed) {
      return Future.error(StateError('Image codec session disposed.'));
    }
    final id = _nextJobId++;
    final job = _PendingJob(onProgress: onProgress);
    _pending[id] = job;
    _toWorker.send(<String, Object?>{
      'type': 'job',
      'id': id,
      'op': op,
      'bytes': ?bytes,
      'latents': ?latents,
      'rate': ratePoint.wireValue,
      'size': resolution,
    });
    return job.completer.future;
  }

  /// Drops one or both ORT sessions without killing the isolate.
  ///
  /// The paths stay recorded inside the backend, so a released session is
  /// re-created on the next call that needs it. Completes when the worker has
  /// acknowledged, so a caller can rely on the memory being back before it
  /// creates the other session.
  ///
  /// Queued behind any in-flight job, like every other command: releasing the
  /// decoder out from under a running synthesis pass would crash ORT.
  Future<void> release({bool decoder = false, bool entropy = false}) {
    if (!decoder && !entropy) return Future<void>.value();
    if (_disposed) return Future<void>.value();
    final id = _nextJobId++;
    final completer = Completer<void>();
    _pendingReleases[id] = completer;
    _toWorker.send(<String, Object?>{
      'type': 'release',
      'id': id,
      'which': decoder && entropy
          ? 'both'
          : decoder
          ? 'decoder'
          : 'entropy',
    });
    return completer.future;
  }

  /// Cooperative cancel.
  ///
  /// The worker sets a flag that the backend polls at stage boundaries. A
  /// backend sitting inside one long blocking native call cannot be
  /// interrupted this way — for a hard stop, call [dispose], which kills the
  /// isolate outright and frees the model.
  void cancel() {
    if (_disposed) return;
    _toWorker.send(const <String, Object?>{'type': 'cancel'});
  }

  void _handleMessage(Map<String, Object?> message) {
    final id = message['id'];
    final job = id is int ? _pending[id] : null;
    switch (message['type']) {
      case 'progress':
        final value = message['value'];
        if (value is num) {
          job?.onProgress?.call(value.toDouble().clamp(0.0, 1.0));
        }
      case 'result':
        if (id is int) _pending.remove(id);
        final bytes = message['bytes'];
        if (bytes is Uint8List) {
          job?.completer.complete(bytes);
        } else {
          job?.completer.completeError(
            StateError('Image codec returned no bytes.'),
          );
        }
      case 'released':
        if (id is int) {
          final release = _pendingReleases.remove(id);
          if (release != null && !release.isCompleted) {
            release.complete();
          }
        }
      case 'error':
        if (id is int) {
          _pending.remove(id);
          // A release can fail too; never leave its caller hanging.
          final release = _pendingReleases.remove(id);
          if (release != null && !release.isCompleted) {
            release.complete();
          }
        }
        job?.completer.completeError(
          StateError(message['error']?.toString() ?? 'Image codec failed.'),
        );
    }
  }

  void _failAll(Object error) {
    final jobs = _pending.values.toList();
    _pending.clear();
    for (final job in jobs) {
      if (!job.completer.isCompleted) {
        job.completer.completeError(error);
      }
    }
    // Releases resolve rather than fail: the isolate dying IS the memory being
    // freed, which is all the caller was waiting for.
    final releases = _pendingReleases.values.toList();
    _pendingReleases.clear();
    for (final release in releases) {
      if (!release.isCompleted) {
        release.complete();
      }
    }
  }

  /// Kills the isolate and frees the model's resident memory.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _toWorker.send(const <String, Object?>{'type': 'shutdown'});
    // Give the worker one event-loop turn to release the native session
    // cleanly, then take the memory back regardless.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _isolate.kill(priority: Isolate.immediate);
    _failAll(StateError('Image codec session disposed.'));
    _fromWorker.close();
    _errors.close();
  }
}

class _PendingJob {
  final Completer<Uint8List> completer = Completer<Uint8List>();
  final void Function(double progress)? onProgress;

  _PendingJob({this.onProgress});
}

/// The positional payload handed to the codec worker isolate.
///
/// Built and parsed in ONE place on purpose. When these were two hand-written
/// lists, `entropyDecodeGraphPath` was added to the bundle but never to the
/// list, so the worker rebuilt a bundle that could not decode — while
/// `canDecode`, computed on the main isolate where the path existed, said it
/// could. Every decode threw `ImageCodecBundleIncomplete` and told the user to
/// re-download a model that was already correct. The whole suite stayed green,
/// because both halves were individually right.
///
/// APPEND new fields; never insert. The list is positional and the casts are
/// permissive enough that a shifted `tablesPath` would be read as the rate
/// point rather than throwing.
List<Object?> _bootPayload(
  ImageCodecBundle bundle,
  SendPort reply,
  RootIsolateToken? rootToken,
) => <Object?>[
  reply, // 0
  bundle.decoderGraphPath, // 1
  bundle.entropyGraphPath, // 2
  bundle.tablesPath, // 3
  bundle.ratePoint.wireValue, // 4
  rootToken, // 5
  bundle.entropyDecodeGraphPath, // 6
];

/// Rebuilds the bundle from [_bootPayload]. Tolerates a short list so a
/// truncated or older message degrades to "cannot decode" instead of throwing a
/// RangeError inside the isolate, where it would surface as an opaque spawn
/// failure.
ImageCodecBundle _bundleFromBootPayload(List<Object?> boot) => ImageCodecBundle(
  decoderGraphPath: boot[1] as String,
  entropyGraphPath: boot[2] as String?,
  tablesPath: boot[3] as String?,
  ratePoint: parseAeicRatePoint(boot[4] as int? ?? -1),
  entropyDecodeGraphPath: boot.length > 6 ? boot[6] as String? : null,
);

/// Test seams for the boot payload. Not for production use — see
/// `test/services/image_codec_boot_payload_test.dart`, which exists because
/// this connection has broken twice.
@visibleForTesting
List<Object?> debugBootPayloadFor(ImageCodecBundle bundle) =>
    _bootPayload(bundle, _NullSendPort(), null);

@visibleForTesting
ImageCodecBundle debugBundleFromBootPayload(List<Object?> boot) =>
    _bundleFromBootPayload(boot);

/// Stand-in so [debugBootPayloadFor] needs no live isolate.
class _NullSendPort implements SendPort {
  @override
  void send(Object? message) {}

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => 0;
}

/// Entry point of the codec worker isolate.
Future<void> _codecWorkerMain(List<Object?> boot) async {
  final reply = boot[0] as SendPort;
  final bundle = _bundleFromBootPayload(boot);
  final rootToken = boot[5] as RootIsolateToken?;

  if (rootToken == null) {
    reply.send(<String, Object?>{
      'type': 'fatal',
      'error':
          'RootIsolateToken was unavailable, so the ONNX plugin channel cannot '
          'be reached from this isolate. ImageCodecSession.spawn() must be '
          'called from the root isolate.',
    });
    return;
  }
  // Without this the backend's very first invokeMethod throws. Must happen
  // before createImageCodecBackend(), which constructs the plugin wrapper.
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

  final backend = createImageCodecBackend();
  if (backend == null) {
    reply.send(<String, Object?>{
      'type': 'fatal',
      'unimplemented': true,
      'error':
          'no inference backend is compiled into this build '
          '(see lib/services/image_codec_backend.dart)',
    });
    return;
  }

  // The bitstream path is a seam so that image_codec_backend.dart can compile
  // for web, where dart:io does not exist. This worker isolate is native-only,
  // so it is the correct place to close it -- and it must happen BEFORE
  // backend.load(), because load() reads supportsBitstreamCodec to decide
  // whether the codec can encode or decode at all. Left unassigned, the whole
  // entropy path is dead even with kImageCodecBitstreamPathAvailable true.
  imageCodecRansCoderBuilder ??= (path) async =>
      AeicRansCoders(EntropyTables.parse(await File(path).readAsBytes()));

  try {
    await backend.load(bundle);
  } catch (error) {
    reply.send(<String, Object?>{'type': 'fatal', 'error': error.toString()});
    await backend.dispose();
    return;
  }

  final commands = ReceivePort();
  var cancelRequested = false;
  var queue = Future<void>.value();

  reply.send(<String, Object?>{
    'type': 'ready',
    'port': commands.sendPort,
    'backend': backend.name,
    // `bitstream` is the backend's own answer (does this build have the entropy
    // path at all?); `entropy`/`tables` describe what THIS INSTALL supplied. A
    // pre-bundle install reports bitstream:true, tables:false — a state the
    // service must surface as "re-download", not as "your build cannot".
    'bitstream': backend.supportsBitstreamCodec,
    'entropy': bundle.entropyGraphPath != null,
    'tables': bundle.tablesPath != null,
  });

  commands.listen((message) {
    if (message is! Map) return;
    final map = message.cast<String, Object?>();
    switch (map['type']) {
      case 'cancel':
        // Handled on the event loop, so it lands between backend stages.
        cancelRequested = true;
      case 'shutdown':
        commands.close();
        unawaited(backend.dispose());
      case 'release':
        // Queued behind any running job: tearing an ORT session down while it
        // is executing is a native crash, not an exception.
        queue = queue.then((_) async {
          final id = map['id'] as int?;
          try {
            final which = map['which'];
            if (which == 'decoder' || which == 'both') {
              await backend.releaseDecoderSession();
            }
            if (which == 'entropy' || which == 'both') {
              await backend.releaseEntropySession();
            }
            reply.send(<String, Object?>{'type': 'released', 'id': id});
          } catch (error) {
            reply.send(<String, Object?>{
              'type': 'error',
              'id': id,
              'error': error.toString(),
            });
          }
        });
      case 'job':
        queue = queue.then((_) async {
          cancelRequested = false;
          final id = map['id'] as int;
          try {
            final ratePoint = parseAeicRatePoint(
              map['rate'] as int? ?? kShippingAeicRatePoint.wireValue,
            );
            final resolution = map['size'] as int? ?? kImageCodecSquareSize;
            void onProgress(double value) {
              reply.send(<String, Object?>{
                'type': 'progress',
                'id': id,
                'value': value,
              });
            }

            bool shouldCancel() => cancelRequested;

            final Uint8List result;
            switch (map['op']) {
              case 'decodeLatent':
                result = await backend.decodeLatentToRgb(
                  yHat: map['latents'] as Float32List,
                  onProgress: onProgress,
                  shouldCancel: shouldCancel,
                );
              case 'encode':
                result = await backend.encode(
                  rgbBytes: map['bytes'] as Uint8List,
                  ratePoint: ratePoint,
                  resolution: resolution,
                  onProgress: onProgress,
                  shouldCancel: shouldCancel,
                );
              case 'decode':
                result = await backend.decode(
                  bitstream: map['bytes'] as Uint8List,
                  ratePoint: ratePoint,
                  resolution: resolution,
                  onProgress: onProgress,
                  shouldCancel: shouldCancel,
                );
              default:
                throw StateError('Unknown codec op: ${map['op']}');
            }
            reply.send(<String, Object?>{
              'type': 'result',
              'id': id,
              'bytes': result,
            });
          } catch (error, stackTrace) {
            reply.send(<String, Object?>{
              'type': 'error',
              'id': id,
              'error': error.toString(),
              'stack': stackTrace.toString(),
            });
          }
        });
    }
  });
}
