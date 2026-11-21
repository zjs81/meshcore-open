// Byte counter for the AEIC evaluation harness (`eval.py`).
//
// Python runs the encode-side ONNX graph; this turns its tensors into the exact
// bitstream the app would send, using the app's own entropy layer and rANS
// coder rather than a port. A port could drift; this cannot, because it is the
// shipping code.
//
// Usage (from the repository root):
//
//   dart run tools/aeic/eval/aeic_bytes.dart <cdf_table.bin> <tensors.f32>...
//   dart run tools/aeic/eval/aeic_bytes.dart --selftest <recording.aeicrec>...
//
// Each `.f32` file holds little-endian float32 tensors back to back, in this
// order: z_q [1,128,4,4], yq0..yq3 [1,256,16,16], sc0..sc3 [1,256,16,16]. The
// bitstream is written next to it as `.aeic`, and one JSON object per input is
// printed to stdout.
//
// `--selftest` replays the golden `.aeicrec` recordings in
// `test/services/golden/e2e/` and checks that the output is byte-identical to
// the reference C++ bitstream, which shows the harness counts what the app
// sends.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meshcore_open/services/entropy_tables.dart';
import 'package:meshcore_open/services/image_chunk_transport.dart';
import 'package:meshcore_open/services/image_codec_entropy.dart';
import 'package:meshcore_open/services/rans_coder.dart';

const int _resolution = 512;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: aeic_bytes.dart <cdf_table.bin> <tensors.f32>...\n'
      '       aeic_bytes.dart --selftest <recording.aeicrec>...',
    );
    exitCode = 64;
    return;
  }
  if (args.first == '--selftest') {
    exitCode = await _selfTest(args.skip(1).toList());
    return;
  }

  final tables = EntropyTables.parse(File(args.first).readAsBytesSync());
  final geometry = AeicEntropyGeometry.forResolution(_resolution);
  for (final path in args.skip(1)) {
    final tensors = _readTensorFile(path, geometry);
    final stream = await _encode(tables, geometry, tensors);
    final outPath = path.replaceFirst(RegExp(r'\.f32$'), '.aeic');
    File(outPath).writeAsBytesSync(stream);
    stdout.writeln(
      jsonEncode(<String, Object>{
        'file': path,
        'bitstream': outPath,
        'bytes': stream.length,
        'data_chunks': imageDataChunkCount(stream.length),
      }),
    );
  }
}

Future<Uint8List> _encode(
  EntropyTables tables,
  AeicEntropyGeometry geometry,
  AeicEncodeSideTensors tensors,
) {
  final codec = AeicEntropyCodec(
    geometry: geometry,
    network: _FixedNetwork(tensors),
    coders: _Coders(tables),
  );
  // The network ignores its input; encode() only needs a correctly sized RGB
  // buffer to get past its own conversion step.
  return codec.encode(Uint8List(_resolution * _resolution * 3));
}

AeicEncodeSideTensors _readTensorFile(
  String path,
  AeicEntropyGeometry geometry,
) {
  final bytes = File(path).readAsBytesSync();
  final z = geometry.zElements;
  final y = geometry.yElements;
  final expected = (z + 8 * y) * 4;
  if (bytes.length != expected) {
    throw FormatException(
      '$path is ${bytes.length} bytes, expected $expected '
      '(z_q + 4 yq + 4 sc as float32)',
    );
  }
  final all = Float32List.sublistView(bytes);
  Float32List at(int offset, int length) =>
      Float32List.sublistView(all, offset, offset + length);
  return AeicEncodeSideTensors(
    zQ: at(0, z),
    yQ: <Float32List>[for (var i = 0; i < 4; i++) at(z + i * y, y)],
    scales: <Float32List>[for (var i = 0; i < 4; i++) at(z + (4 + i) * y, y)],
  );
}

Future<int> _selfTest(List<String> recordings) async {
  if (recordings.isEmpty) {
    stderr.writeln('--selftest needs at least one .aeicrec file');
    return 64;
  }
  final geometry = AeicEntropyGeometry.forResolution(_resolution);
  var failures = 0;
  for (final path in recordings) {
    final r = _Recording.load(path);
    final tables = EntropyTables.parse(
      File(
        '${File(path).parent.parent.path}/${r.meta['cdf_table']}',
      ).readAsBytesSync(),
    );
    final tensors = AeicEncodeSideTensors(
      zQ: r.f32('enc/z_q'),
      yQ: <Float32List>[for (var i = 0; i < 4; i++) r.f32('enc/yq$i')],
      scales: <Float32List>[for (var i = 0; i < 4; i++) r.f32('enc/sc$i')],
    );
    final got = await _encode(tables, geometry, tensors);
    final want = r.u8('enc/bitstream');
    final ok =
        got.length == want.length &&
        Iterable<int>.generate(got.length).every((i) => got[i] == want[i]);
    if (!ok) failures++;
    stdout.writeln(
      '${ok ? 'ok  ' : 'FAIL'} ${r.meta['stem']}: ${got.length} B '
      '(reference ${want.length} B)',
    );
  }
  return failures == 0 ? 0 : 1;
}

class _FixedNetwork implements AeicEntropyNetwork {
  _FixedNetwork(this.tensors);

  final AeicEncodeSideTensors tensors;

  @override
  bool get supportsDecodeSide => false;

  @override
  Future<AeicEncodeSideTensors> runEncodeSide(Float32List imageChw) async =>
      tensors;

  @override
  Future<Float32List> runHyperSynthesis(Float32List zQ) =>
      throw UnsupportedError('encode only');

  @override
  Future<AeicStageParams> runStage(int stage, Float32List base) =>
      throw UnsupportedError('encode only');
}

class _Coders implements AeicRansCoderFactory {
  _Coders(this.tables);

  final EntropyTables tables;

  @override
  AeicRansEncoder createEncoder() => _Encoder(RansEncoder(tables));

  @override
  AeicRansDecoder createDecoder(Uint8List bitstream) =>
      throw UnsupportedError('encode only');
}

class _Encoder implements AeicRansEncoder {
  _Encoder(this._encoder);

  final RansEncoder _encoder;

  @override
  void pushSymbols(Int16List symbols, Int16List indexes, int cdfGroup) =>
      _encoder.encodeWithIndexes(symbols, indexes, cdfGroup);

  @override
  Uint8List finish() => _encoder.finish();
}

/// Minimal reader for the `.aeicrec` container (see
/// `test/services/image_codec_e2e_test.dart` for the full one).
class _Recording {
  _Recording(this.index, this.bytes)
    : _entries = <String, Map<String, dynamic>>{
        for (final e
            in (index['entries'] as List<dynamic>).cast<Map<String, dynamic>>())
          e['name'] as String: e,
      };

  final Map<String, dynamic> index;
  final Uint8List bytes;
  final Map<String, Map<String, dynamic>> _entries;

  static _Recording load(String path) {
    final bytes = File(path).readAsBytesSync();
    final bd = ByteData.sublistView(bytes);
    if (ascii.decode(bytes.sublist(0, 8)) != 'AEICREC1') {
      throw FormatException('bad .aeicrec magic in $path');
    }
    final indexOffset = bd.getUint64(16, Endian.little);
    final indexLength = bd.getUint32(24, Endian.little);
    final index =
        jsonDecode(
              utf8.decode(
                bytes.sublist(indexOffset, indexOffset + indexLength),
              ),
            )
            as Map<String, dynamic>;
    return _Recording(index, bytes);
  }

  Map<String, dynamic> get meta => index['meta'] as Map<String, dynamic>;

  Map<String, dynamic> _entry(String name) {
    final e = _entries[name];
    if (e == null) throw StateError('no entry "$name" in recording');
    return e;
  }

  Float32List f32(String name) {
    final e = _entry(name);
    final offset = e['offset'] as int;
    return Float32List.sublistView(
      bytes,
      offset,
      offset + (e['length'] as int),
    );
  }

  Uint8List u8(String name) {
    final e = _entry(name);
    final offset = e['offset'] as int;
    return Uint8List.sublistView(bytes, offset, offset + (e['length'] as int));
  }
}
