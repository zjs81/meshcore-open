import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/entropy_tables.dart';
import 'package:meshcore_open/services/rans_coder.dart';

/// Golden-vector conformance for the pure-Dart rANS port.
///
/// The bar is byte-identical: encoding the golden symbol/index arrays must
/// reproduce the exact bitstream the C++ coder produced, and decoding that
/// bitstream must reproduce the exact symbols. A single differing byte
/// desynchronises rANS and silently corrupts most of an image.
void main() {
  final Directory goldenDir = _resolveGoldenDir();
  final EntropyTables tables = EntropyTables.parse(
    File('${goldenDir.path}/aeic_cdf_ft32.bin').readAsBytesSync(),
  );
  final Map<String, dynamic> manifest =
      jsonDecode(File('${goldenDir.path}/manifest.json').readAsStringSync())
          as Map<String, dynamic>;
  final List<Map<String, dynamic>> images =
      (manifest['images'] as List<dynamic>).cast<Map<String, dynamic>>();
  final List<Map<String, dynamic>> synthetic =
      (manifest['synthetic'] as List<dynamic>).cast<Map<String, dynamic>>();

  test('golden corpus is complete', () {
    expect(images.length, 10);
    expect(synthetic.length, 7);
    expect(manifest['stream_parts'], 2);
    expect(manifest['reference_port_selfcheck'], <String, dynamic>{
      'ok': 17,
      'total': 17,
    });
  });

  group('image vectors', () {
    for (final Map<String, dynamic> rec in images) {
      final String stem = rec['stem'] as String;
      test('$stem encodes and decodes byte-identically', () {
        final Map<String, List<int>> arrays = _readGoldenVector(
          File(
            '${goldenDir.path}/vectors/${rec['vector_file']}',
          ).readAsBytesSync(),
        );
        final Uint8List want = File(
          '${goldenDir.path}/vectors/${rec['bitstream_file']}',
        ).readAsBytesSync();

        // Call order is part of the format: z, then y0..y3.
        final List<_Call> calls = <_Call>[
          _Call(arrays['z_q']!, arrays['z_indexes']!, 0),
          for (var i = 0; i < 4; i++)
            _Call(arrays['y_q$i']!, arrays['y_indexes$i']!, 1),
        ];

        final RansEncoder encoder = RansEncoder(tables);
        for (final _Call c in calls) {
          encoder.encodeWithIndexes(c.symbols, c.indexes, c.group);
        }
        _expectSameBytes(encoder.finish(), want, stem);

        // One decoder, five incremental calls sharing the sub-stream states.
        final RansDecoder decoder = RansDecoder(tables, want);
        for (final _Call c in calls) {
          _expectSameSymbols(decoder.decodeStream(c.indexes, c.group), c, stem);
        }

        final List<Uint8List> parts = parseRansContainer(want);
        expect(
          parts.map((Uint8List p) => p.length).toList(),
          (rec['substream_sizes'] as List<dynamic>).cast<int>(),
        );
        expect(want[0], rec['container_flag']);
      });
    }
  });

  group('synthetic vectors', () {
    for (final Map<String, dynamic> rec in synthetic) {
      final String name = rec['name'] as String;
      test('$name encodes and decodes byte-identically', () {
        final int group = rec['cdf_group'] as int;
        final Map<String, List<int>> arrays = _readGoldenVector(
          File(
            '${goldenDir.path}/vectors/${rec['vector_file']}',
          ).readAsBytesSync(),
        );
        final Uint8List want = File(
          '${goldenDir.path}/vectors/${rec['bitstream_file']}',
        ).readAsBytesSync();
        final _Call call = _Call(arrays['symbols']!, arrays['indexes']!, group);

        final RansEncoder encoder = RansEncoder(tables);
        encoder.encodeWithIndexes(call.symbols, call.indexes, call.group);
        _expectSameBytes(encoder.finish(), want, name);

        final RansDecoder decoder = RansDecoder(tables, want);
        _expectSameSymbols(
          decoder.decodeStream(call.indexes, call.group),
          call,
          name,
        );

        final List<Uint8List> parts = parseRansContainer(want);
        expect(
          parts.map((Uint8List p) => p.length).toList(),
          (rec['substream_sizes'] as List<dynamic>).cast<int>(),
        );
        expect(want[0], rec['container_flag']);
      });
    }
  });

  test('container round-trips through build/parse', () {
    final List<Uint8List> parts = <Uint8List>[
      Uint8List.fromList(<int>[1, 2, 3, 4, 5]),
      Uint8List.fromList(<int>[9, 8, 7]),
    ];
    final Uint8List packed = buildRansContainer(parts);
    expect(packed[0], 0x11);
    final List<Uint8List> back = parseRansContainer(packed);
    expect(back.length, 2);
    expect(back[0], parts[0]);
    expect(back[1], parts[1]);
  });

  test('a flipped bitstream byte would be caught', () {
    // Guards the comparison itself against being vacuous.
    final Map<String, List<int>> arrays = _readGoldenVector(
      File('${goldenDir.path}/vectors/synth_y_tiny.gv').readAsBytesSync(),
    );
    final Uint8List want = File(
      '${goldenDir.path}/vectors/synth_y_tiny.bin',
    ).readAsBytesSync();
    final Uint8List mutated = Uint8List.fromList(want);
    mutated[mutated.length - 1] ^= 0x01;
    final RansEncoder encoder = RansEncoder(tables);
    encoder.encodeWithIndexes(arrays['symbols']!, arrays['indexes']!, 1);
    final Uint8List got = encoder.finish();
    expect(got, equals(want));
    expect(got, isNot(equals(mutated)));
  });

  test('encoder rejects a second finish()', () {
    final RansEncoder encoder = RansEncoder(tables);
    encoder.finish();
    expect(encoder.finish, throwsStateError);
  });
}

class _Call {
  _Call(this.symbols, this.indexes, this.group);

  final List<int> symbols;
  final List<int> indexes;
  final int group;
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

void _expectSameSymbols(Int16List got, _Call call, String label) {
  expect(got.length, call.symbols.length, reason: '$label: length');
  for (var i = 0; i < got.length; i++) {
    // idx < 0 is asymmetric: it emits nothing on encode, decodes as literal 0.
    final int want = call.indexes[i] < 0 ? 0 : call.symbols[i];
    if (got[i] != want) {
      fail(
        '$label: first symbol divergence at $i '
        '(got ${got[i]}, want $want, index ${call.indexes[i]})',
      );
    }
  }
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

/// Reads a `.gv` golden-vector container.
///
///   char[8] magic "AEICGV\0\x01", u32 version, u32 nArrays,
///   nArrays x { char[16] name, u32 dtype (0=int16, 1=int32), u32 count },
///   then the payloads back to back, little-endian.
Map<String, List<int>> _readGoldenVector(Uint8List raw) {
  const List<int> magic = <int>[0x41, 0x45, 0x49, 0x43, 0x47, 0x56, 0x00, 0x01];
  for (var i = 0; i < magic.length; i++) {
    if (raw[i] != magic[i]) {
      throw FormatException('bad .gv magic at byte $i');
    }
  }
  final ByteData bd = ByteData.view(
    raw.buffer,
    raw.offsetInBytes,
    raw.lengthInBytes,
  );
  final int version = bd.getUint32(8, Endian.little);
  if (version != 1) {
    throw FormatException('unsupported .gv version $version');
  }
  final int n = bd.getUint32(12, Endian.little);
  var off = 16;
  final List<String> names = <String>[];
  final List<int> dtypes = <int>[];
  final List<int> counts = <int>[];
  for (var i = 0; i < n; i++) {
    final List<int> nameBytes = raw.sublist(off, off + 16);
    var end = nameBytes.indexOf(0);
    if (end < 0) end = nameBytes.length;
    names.add(ascii.decode(nameBytes.sublist(0, end)));
    dtypes.add(bd.getUint32(off + 16, Endian.little));
    counts.add(bd.getUint32(off + 20, Endian.little));
    off += 24;
  }
  final Map<String, List<int>> out = <String, List<int>>{};
  for (var k = 0; k < n; k++) {
    final int count = counts[k];
    if (dtypes[k] == 0) {
      final Int16List a = Int16List(count);
      for (var i = 0; i < count; i++) {
        a[i] = bd.getInt16(off + i * 2, Endian.little);
      }
      off += count * 2;
      out[names[k]] = a;
    } else {
      final Int32List a = Int32List(count);
      for (var i = 0; i < count; i++) {
        a[i] = bd.getInt32(off + i * 4, Endian.little);
      }
      off += count * 4;
      out[names[k]] = a;
    }
  }
  if (off != raw.length) {
    throw FormatException('.gv trailing data: $off of ${raw.length}');
  }
  return out;
}
