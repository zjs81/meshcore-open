import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/entropy_tables.dart';
import 'package:meshcore_open/services/image_codec_backend.dart';
import 'package:meshcore_open/services/image_codec_entropy.dart';

/// End-to-end cross-language conformance for the AEIC entropy path.
///
/// This is deliberately **not** a Dart-encodes-then-Dart-decodes round trip.
/// That shape passes happily with a completely wrong wire format — a swapped
/// mask permutation, a reversed squeeze, an off-by-one in `my_build_indexes` —
/// because both halves make the same mistake. Every assertion here compares
/// Dart against bytes and tensors that Python/ORT/C++ produced:
///
///   ENCODE: recorded encode-graph outputs -> real Dart four-stage loop ->
///           real Dart rANS  ==>  byte-identical to the recorded C++ bitstream.
///   DECODE: recorded C++ bitstream -> real Dart rANS -> real Dart four-stage
///           loop (replaying the recorded decode-side network calls)
///           ==>  y_hat exactly equal, element for element, to the recorded one.
///
/// The only thing faked is [AeicEntropyNetwork]: the neural half is replayed
/// from `.aeicrec` recordings made by `aic/exp/record_entropy_io.py`. The fake
/// asserts on its *inputs* as well as returning outputs — in particular the
/// `base` tensor handed to each decode stage must match the recorded one bit
/// for bit, which is what localises a wrong mask / mergeContext / squeeze to
/// the stage that broke instead of to a garbled final image.
void main() {
  final Directory goldenDir = _resolveGoldenDir();
  final Directory e2eDir = Directory('${goldenDir.path}/e2e');
  final EntropyTables tables = EntropyTables.parse(
    File('${goldenDir.path}/aeic_cdf_ft32.bin').readAsBytesSync(),
  );
  final AeicRansCoderFactory coders = AeicRansCoders(tables);
  final Map<String, dynamic> manifest =
      jsonDecode(File('${e2eDir.path}/manifest.json').readAsStringSync())
          as Map<String, dynamic>;
  final List<Map<String, dynamic>> files = (manifest['files'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  test('recording corpus is present and unmodified', () {
    expect(manifest['format'], 'aeic-entropy-e2e-recording');
    expect(manifest['version'], 1);
    expect(manifest['checkpoint'], 'AEIC_SE_ft32.pkl');
    expect(manifest['size'], 512);
    expect(files.length, 5);
    for (final Map<String, dynamic> rec in files) {
      final File f = File('${e2eDir.path}/${rec['file']}');
      expect(f.existsSync(), isTrue, reason: '${rec['file']} missing');
      final Uint8List raw = f.readAsBytesSync();
      expect(raw.length, rec['bytes'], reason: '${rec['file']} size');
      expect(
        sha256.convert(raw).toString(),
        rec['sha256'],
        reason: '${rec['file']} sha256',
      );
    }
  });

  for (final Map<String, dynamic> rec in files) {
    final String name = rec['file'] as String;
    group(name, () {
      late _Recording r;
      late AeicEntropyGeometry geometry;
      late AeicMaskSet masks;

      setUpAll(() {
        r = _Recording.load('${e2eDir.path}/$name');
        geometry = AeicEntropyGeometry.forResolution(
          r.meta['size'] as int,
          yChannels: (r.meta['y_shape'] as List<dynamic>)[1] as int,
        );
        masks = AeicMaskSet(geometry);
      });

      test('recording shape matches the geometry the codec derives', () {
        expect(r.meta['checkpoint'], 'AEIC_SE_ft32.pkl');
        expect(r.meta['z_cdf_group'], kAeicZCdfGroup);
        expect(r.meta['y_cdf_group'], kAeicYCdfGroup);
        expect(r.meta['byte_order'], 'little');
        expect(r.f32('enc/z_q').length, geometry.zElements);
        expect(r.f32('enc/y_hat').length, geometry.yElements);
        expect(r.f32('dec/y_hat').length, geometry.yElements);
        expect(r.u8('enc/bitstream').length, r.meta['bitstream_bytes']);
        expect(r.calls.length, 5);
        expect(r.calls[0]['kind'], 'hyper_synthesis');
        for (var i = 0; i < 4; i++) {
          expect(r.calls[i + 1]['kind'], 'stage');
          expect(r.calls[i + 1]['stage'], i);
        }
      });

      // The pieces the Dart entropy layer computes on its own between the
      // graph and the coder. Checked against Python directly so a divergence
      // here is attributed to squeeze / my_build_indexes rather than to rANS.
      test('symbols and indexes match the recorded integer arrays', () {
        _expectSameInts(
          aeicToSymbols(r.f32('enc/z_q')),
          r.i16('enc/z_symbols'),
          'z symbols',
        );
        _expectSameInts(
          aeicZIndexes(geometry),
          r.i16('enc/z_indexes'),
          'z indexes',
        );
        for (var s = 0; s < 4; s++) {
          _expectSameInts(
            aeicToSymbols(masks.squeeze(r.f32('enc/yq$s'))),
            r.i16('enc/symbols$s'),
            'stage $s symbols',
          );
          _expectSameInts(
            aeicBuildIndexes(masks.squeeze(r.f32('enc/sc$s'))),
            r.i16('enc/indexes$s'),
            'stage $s indexes',
          );
        }
      });

      test(
        'ENCODE: Dart bitstream is byte-identical to the C++ bitstream',
        () async {
          final _ReplayNetwork network = _ReplayNetwork(r);
          final AeicEntropyCodec codec = AeicEntropyCodec(
            geometry: geometry,
            network: network,
            coders: coders,
          );
          final Uint8List got = await codec.encode(
            Uint8List(geometry.resolution * geometry.resolution * 3),
          );
          expect(network.encodeCalls, 1);
          _expectSameBytes(got, r.u8('enc/bitstream'), name);
          expect(
            sha256.convert(got).toString(),
            r.meta['bitstream_sha256'],
            reason: '$name: bitstream sha256',
          );
        },
      );

      test(
        'DECODE: y_hat from the C++ bitstream is exactly the recorded y_hat',
        () async {
          final _ReplayNetwork network = _ReplayNetwork(r);
          final AeicEntropyCodec codec = AeicEntropyCodec(
            geometry: geometry,
            network: network,
            coders: coders,
          );
          final Float32List got = await codec.decodeToLatent(
            r.u8('enc/bitstream'),
          );
          expect(network.hyperCalls, 1);
          expect(network.stageCalls, <int>[0, 1, 2, 3]);
          _expectSameFloats(got, r.f32('dec/y_hat'), '$name: y_hat');
          // The recording asserts the decoder's latent equals the encoder's; if
          // that holds in Python it must hold here too.
          expect(r.meta['decoded_y_hat_equals_encoder_y_hat'], isTrue);
          _expectSameFloats(got, r.f32('enc/y_hat'), '$name: y_hat vs encoder');
        },
      );

      test('a single flipped bitstream byte does not still pass', () async {
        // Byte 3 is the first payload byte of sub-stream 0 (1-byte flag +
        // 2-byte size header), which the decoder loads straight into the rANS
        // state, so flipping it must change the output. The *last* byte is a
        // poor choice: renormalisation does not always consume the tail, and
        // on two of these five recordings flipping it is genuinely a no-op.
        final Uint8List mutated = Uint8List.fromList(r.u8('enc/bitstream'));
        expect(mutated.length, greaterThan(4));
        mutated[3] ^= 0x01;
        final AeicEntropyCodec codec = AeicEntropyCodec(
          geometry: geometry,
          network: _networkForMutation(r),
          coders: coders,
        );
        Float32List? got;
        try {
          got = await codec.decodeToLatent(mutated);
        } catch (_) {
          // Desync raising is an acceptable outcome; silently matching is not.
          return;
        }
        expect(
          _sameFloats(got, r.f32('dec/y_hat')),
          isFalse,
          reason:
              '$name: corrupting the stream changed nothing — the '
              'comparison is vacuous',
        );
      });
    });
  }
}

/// A replay network for the mutated-stream test: it must NOT assert on its
/// inputs, because a desynchronised decode legitimately feeds it a different
/// `base`. It returns the recorded outputs regardless.
AeicEntropyNetwork _networkForMutation(_Recording r) =>
    _ReplayNetwork(r, strict: false);

/// [AeicEntropyNetwork] that replays one `.aeicrec` recording.
///
/// Returns the ORT tensors Python captured, and — when [strict] — asserts that
/// the tensors the Dart loop hands it are bit-for-bit the ones Python's own
/// decode loop handed the real graph.
class _ReplayNetwork implements AeicEntropyNetwork {
  _ReplayNetwork(this.r, {this.strict = true});

  final _Recording r;
  final bool strict;

  int encodeCalls = 0;
  int hyperCalls = 0;
  final List<int> stageCalls = <int>[];

  @override
  bool get supportsDecodeSide => true;

  @override
  Future<AeicEncodeSideTensors> runEncodeSide(Float32List imageChw) async {
    encodeCalls++;
    return AeicEncodeSideTensors(
      zQ: r.f32('enc/z_q'),
      yQ: <Float32List>[for (var i = 0; i < 4; i++) r.f32('enc/yq$i')],
      scales: <Float32List>[for (var i = 0; i < 4; i++) r.f32('enc/sc$i')],
    );
  }

  @override
  Future<Float32List> runHyperSynthesis(Float32List zQ) async {
    hyperCalls++;
    final Map<String, dynamic> call = r.calls[0];
    if (strict) {
      _expectSameFloats(
        zQ,
        r.f32((call['inputs'] as Map<String, dynamic>)['z_q'] as String),
        'hyper_synthesis input z_q',
      );
    }
    return r.f32((call['outputs'] as Map<String, dynamic>)['base0'] as String);
  }

  @override
  Future<AeicStageParams> runStage(int stage, Float32List base) async {
    stageCalls.add(stage);
    final Map<String, dynamic> call = r.calls[stage + 1];
    expect(call['stage'], stage, reason: 'call table is positional');
    if (strict) {
      _expectSameFloats(
        base,
        r.f32((call['inputs'] as Map<String, dynamic>)['base'] as String),
        'stage $stage input base',
      );
    }
    final Map<String, dynamic> outputs =
        call['outputs'] as Map<String, dynamic>;
    return AeicStageParams(
      meansSupp: r.f32(outputs['means'] as String),
      scalesSupp: r.f32(outputs['scales'] as String),
    );
  }
}

/// Reader for the `.aeicrec` container (magic "AEICREC1", little-endian):
/// 32-byte header, an 8-byte-aligned tensor blob, then a UTF-8 JSON index.
class _Recording {
  _Recording(this.index, this.bytes)
    : _entries = <String, Map<String, dynamic>>{
        for (final Map<String, dynamic> e
            in (index['entries'] as List<dynamic>).cast<Map<String, dynamic>>())
          e['name'] as String: e,
      };

  final Map<String, dynamic> index;
  final Uint8List bytes;
  final Map<String, Map<String, dynamic>> _entries;

  static _Recording load(String path) {
    final Uint8List bytes = File(path).readAsBytesSync();
    final ByteData bd = ByteData.sublistView(bytes);
    final String magic = ascii.decode(bytes.sublist(0, 8));
    if (magic != 'AEICREC1') {
      throw FormatException('bad .aeicrec magic "$magic" in $path');
    }
    final int version = bd.getUint32(8, Endian.little);
    if (version != 1) {
      throw FormatException('.aeicrec version $version in $path');
    }
    final int indexOffset = bd.getUint64(16, Endian.little);
    final int indexLength = bd.getUint32(24, Endian.little);
    final Map<String, dynamic> index =
        jsonDecode(
              utf8.decode(
                bytes.sublist(indexOffset, indexOffset + indexLength),
              ),
            )
            as Map<String, dynamic>;
    return _Recording(index, bytes);
  }

  Map<String, dynamic> get meta => index['meta'] as Map<String, dynamic>;

  List<Map<String, dynamic>> get calls =>
      (index['calls'] as List<dynamic>).cast<Map<String, dynamic>>();

  Map<String, dynamic> _entry(String name, String dtype) {
    final Map<String, dynamic>? e = _entries[name];
    if (e == null) {
      throw StateError('no entry "$name" in recording');
    }
    if (e['dtype'] != dtype) {
      throw StateError('entry "$name" is ${e['dtype']}, wanted $dtype');
    }
    return e;
  }

  Float32List f32(String name) {
    final Map<String, dynamic> e = _entry(name, 'f32');
    return Float32List.sublistView(
      bytes,
      e['offset'] as int,
      (e['offset'] as int) + (e['length'] as int),
    );
  }

  Int16List i16(String name) {
    final Map<String, dynamic> e = _entry(name, 'i16');
    return Int16List.sublistView(
      bytes,
      e['offset'] as int,
      (e['offset'] as int) + (e['length'] as int),
    );
  }

  Uint8List u8(String name) {
    final Map<String, dynamic> e = _entry(name, 'u8');
    return Uint8List.sublistView(
      bytes,
      e['offset'] as int,
      (e['offset'] as int) + (e['length'] as int),
    );
  }
}

void _expectSameBytes(Uint8List got, Uint8List want, String label) {
  final int n = got.length < want.length ? got.length : want.length;
  for (var i = 0; i < n; i++) {
    if (got[i] != want[i]) {
      fail(
        '$label: first byte divergence at offset $i of ${want.length} '
        '(got 0x${got[i].toRadixString(16)}, '
        'want 0x${want[i].toRadixString(16)})',
      );
    }
  }
  expect(
    got.length,
    want.length,
    reason: '$label: length differs (prefix matched)',
  );
}

void _expectSameInts(List<int> got, List<int> want, String label) {
  expect(got.length, want.length, reason: '$label: length');
  for (var i = 0; i < got.length; i++) {
    if (got[i] != want[i]) {
      fail(
        '$label: first divergence at index $i of ${want.length} '
        '(got ${got[i]}, want ${want[i]})',
      );
    }
  }
}

/// Exact equality, element for element — no tolerance. These are integers
/// carried in float32 (symbols + means), so "close" is not the bar.
void _expectSameFloats(Float32List got, Float32List want, String label) {
  expect(got.length, want.length, reason: '$label: length');
  for (var i = 0; i < got.length; i++) {
    if (got[i] != want[i]) {
      fail(
        '$label: first divergence at index $i of ${want.length} '
        '(got ${got[i]}, want ${want[i]}, '
        'diff ${(got[i] - want[i]).abs()})',
      );
    }
  }
}

bool _sameFloats(Float32List a, Float32List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Directory _resolveGoldenDir() {
  for (final String candidate in <String>[
    'test/services/golden',
    '../test/services/golden',
    'golden',
  ]) {
    final Directory d = Directory(candidate);
    if (d.existsSync()) return d;
  }
  return Directory('test/services/golden');
}
