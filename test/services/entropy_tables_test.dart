import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/entropy_tables.dart';

/// Structural checks on the shipped CDF table file. The invariants here are the
/// ones the rANS coder relies on; if any of them breaks, encoding silently
/// produces garbage rather than failing loudly.
void main() {
  final Directory goldenDir = _resolveGoldenDir();
  final Uint8List raw = File(
    '${goldenDir.path}/aeic_cdf_ft32.bin',
  ).readAsBytesSync();
  final Map<String, dynamic> manifest =
      jsonDecode(File('${goldenDir.path}/manifest.json').readAsStringSync())
          as Map<String, dynamic>;
  final EntropyTables tables = EntropyTables.parse(raw);

  test('header matches the manifest', () {
    expect(raw.length, manifest['table_bytes']);
    expect(tables.version, 1);
    expect(tables.precision, manifest['precision']);
    expect(tables.bypassPrecision, manifest['bypass_precision']);
    expect(tables.streamParts, manifest['stream_parts']);
    expect(tables.groups.length, 2);
  });

  test('group shapes match the manifest', () {
    final List<Map<String, dynamic>> meta =
        (manifest['table_groups'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
    for (var g = 0; g < 2; g++) {
      final CdfGroup group = tables.groups[g];
      expect(group.numCdfs, meta[g]['rows'], reason: 'group $g rows');
      expect(group.cdfWidth, meta[g]['width'], reason: 'group $g width');
      expect(group.quantizedCdf.length, group.numCdfs * group.cdfWidth);

      var lenMin = 1 << 30, lenMax = -(1 << 30);
      var offMin = 1 << 30, offMax = -(1 << 30);
      for (var r = 0; r < group.numCdfs; r++) {
        lenMin = group.cdfLength[r] < lenMin ? group.cdfLength[r] : lenMin;
        lenMax = group.cdfLength[r] > lenMax ? group.cdfLength[r] : lenMax;
        offMin = group.offset[r] < offMin ? group.offset[r] : offMin;
        offMax = group.offset[r] > offMax ? group.offset[r] : offMax;
      }
      expect(lenMin, meta[g]['cdf_length_min']);
      expect(lenMax, meta[g]['cdf_length_max']);
      expect(offMin, meta[g]['offset_min']);
      expect(offMax, meta[g]['offset_max']);
    }
    expect(tables.zGroup.numCdfs, 128);
    expect(tables.zGroup.cdfWidth, 19);
    expect(tables.yGroup.numCdfs, 64);
    expect(tables.yGroup.cdfWidth, 3133);
  });

  test('every CDF row is a valid, gap-free distribution', () {
    for (var g = 0; g < tables.groups.length; g++) {
      final CdfGroup group = tables.groups[g];
      for (var r = 0; r < group.numCdfs; r++) {
        final int n = group.cdfLength[r];
        expect(n, greaterThanOrEqualTo(2), reason: 'group $g row $r length');
        expect(n, lessThanOrEqualTo(group.cdfWidth));
        expect(group.cdfAt(r, 0), 0, reason: 'group $g row $r first');
        expect(
          group.cdfAt(r, n - 1),
          1 << 16,
          reason: 'group $g row $r terminal',
        );
        for (var c = 0; c + 1 < n; c++) {
          final int gap = group.cdfAt(r, c + 1) - group.cdfAt(r, c);
          expect(
            gap,
            greaterThanOrEqualTo(1),
            reason: 'group $g row $r has a zero-frequency symbol at $c',
          );
        }
        for (var c = n; c < group.cdfWidth; c++) {
          expect(group.cdfAt(r, c), 0, reason: 'group $g row $r padding at $c');
        }
      }
    }
  });

  test('index-quantizer block parses', () {
    final IndexQuantizerParams p = tables.indexQuantizer;
    expect(p.scalesLevels, 64);
    expect(p.scaleTable.length, 64);
    expect(p.logScaleMin, closeTo(-2.2072749131897207, 1e-15));
    expect(p.logScaleStep, closeTo(0.12305479932808384, 1e-15));
    expect(p.scaleThreshold, closeTo(0.08, 1e-7));
    expect(p.scaleFloor, closeTo(1e-5, 1e-11));
    expect(p.scaleTable.first, closeTo(0.11, 1e-5));
    expect(p.scaleTable.last, closeTo(256.0, 1e-3));
    for (var i = 1; i < p.scaleTable.length; i++) {
      expect(p.scaleTable[i], greaterThan(p.scaleTable[i - 1]));
    }
  });

  test('rejects a corrupt magic', () {
    final Uint8List bad = Uint8List.fromList(raw.sublist(0, 4096));
    bad[3] ^= 0xFF;
    expect(
      () => EntropyTables.parse(bad),
      throwsA(isA<EntropyTableFormatException>()),
    );
  });

  test('rejects a truncated file', () {
    expect(
      () => EntropyTables.parse(Uint8List.fromList(raw.sublist(0, 1024))),
      throwsA(isA<EntropyTableFormatException>()),
    );
  });

  test('rejects trailing garbage', () {
    final Uint8List extra = Uint8List(raw.length + 1)
      ..setRange(0, raw.length, raw);
    expect(
      () => EntropyTables.parse(extra),
      throwsA(isA<EntropyTableFormatException>()),
    );
  });
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
