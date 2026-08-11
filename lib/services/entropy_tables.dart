// Parser for the AEIC CDF table file (`aeic_cdf_ft32.bin`) that ships inside the
// image-codec model bundle.
//
// The file is produced by `exp/export_golden.py::write_table_file` in the AEIC
// research repo. Layout, all little-endian, tightly packed, no padding:
//
//   off  type      field
//   0    char[8]   magic            = "AEICCDF\x01"
//   8    u32       version          = 1
//   12   u32       precision        = 16
//   16   u32       bypassPrecision  = 2
//   20   u32       streamParts      = 2
//   24   u32       numGroups        = 2
//   28   ...       group blocks (group 0 = z, group 1 = y)
//        ...       index-quantizer block
//        char[4]   "END\0"
//
// group block:
//   u32      numCdfs   R
//   u32      cdfWidth  W
//   i32[R]   cdfLength      row r is valid only on [0, cdfLength[r])
//   i32[R]   offset         symbol offset for row r
//   i32[R*W] quantizedCdf   row-major
//
// index-quantizer block:
//   char[4]  "IDXP"
//   f64      logScaleMin
//   f64      logScaleStep
//   u32      scalesLevels
//   f32      scaleThreshold   (scale below this => index -1)
//   f32      scaleFloor
//   f32[N]   scaleTable
library;

import 'dart:typed_data';

/// Thrown when the CDF table file is malformed or of an unsupported version.
class EntropyTableFormatException implements Exception {
  EntropyTableFormatException(this.message);

  final String message;

  @override
  String toString() => 'EntropyTableFormatException: $message';
}

/// One CDF group (z = entropy bottleneck, y = Gaussian conditional).
class CdfGroup {
  CdfGroup({
    required this.numCdfs,
    required this.cdfWidth,
    required this.cdfLength,
    required this.offset,
    required this.quantizedCdf,
  });

  /// Number of CDF rows (`R`).
  final int numCdfs;

  /// Stride of a row in [quantizedCdf] (`W`). Entries beyond
  /// `cdfLength[row]` are padding and must never be read.
  final int cdfWidth;

  /// Valid length of each row; `cdfLength[r] - 2` is the escape symbol.
  final Int32List cdfLength;

  /// Symbol offset per row.
  final Int32List offset;

  /// Row-major CDF table, `R * W` entries.
  final Int32List quantizedCdf;

  /// Value at `[row][col]`.
  int cdfAt(int row, int col) => quantizedCdf[row * cdfWidth + col];
}

/// Constants needed to reproduce `my_build_indexes` (the scale -> CDF-row
/// quantizer). Carried for completeness; the shipping encoder gets its index
/// arrays straight out of the ONNX graph instead of recomputing them here,
/// because Dart's `log` is not bit-identical to ORT's float32 `Log`.
class IndexQuantizerParams {
  IndexQuantizerParams({
    required this.logScaleMin,
    required this.logScaleStep,
    required this.scalesLevels,
    required this.scaleThreshold,
    required this.scaleFloor,
    required this.scaleTable,
  });

  final double logScaleMin;
  final double logScaleStep;
  final int scalesLevels;
  final double scaleThreshold;
  final double scaleFloor;
  final Float32List scaleTable;
}

/// The parsed contents of `aeic_cdf_ft32.bin`.
class EntropyTables {
  EntropyTables({
    required this.version,
    required this.precision,
    required this.bypassPrecision,
    required this.streamParts,
    required this.groups,
    required this.indexQuantizer,
  });

  static const List<int> magic = <int>[
    0x41, 0x45, 0x49, 0x43, 0x43, 0x44, 0x46, 0x01, // "AEICCDF\x01"
  ];

  /// Format version. Only version 1 is understood.
  final int version;

  /// rANS probability precision in bits (16).
  final int precision;

  /// Bits per bypass symbol (2).
  final int bypassPrecision;

  /// Number of interleaved rANS sub-streams the bitstream is split into (2).
  final int streamParts;

  /// CDF groups in file order: index 0 = z, index 1 = y.
  final List<CdfGroup> groups;

  final IndexQuantizerParams indexQuantizer;

  /// The `z` (entropy bottleneck) group.
  CdfGroup get zGroup => groups[0];

  /// The `y` (Gaussian conditional) group.
  CdfGroup get yGroup => groups[1];

  /// Parses the table file. Throws [EntropyTableFormatException] on any
  /// structural problem.
  static EntropyTables parse(Uint8List bytes) {
    if (bytes.length < 32) {
      throw EntropyTableFormatException('file too short (${bytes.length} B)');
    }
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) {
        throw EntropyTableFormatException('bad magic at byte $i');
      }
    }
    final ByteData bd = ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    var off = 8;

    int u32() {
      _need(bytes, off, 4);
      final int v = bd.getUint32(off, Endian.little);
      off += 4;
      return v;
    }

    final int version = u32();
    if (version != 1) {
      throw EntropyTableFormatException('unsupported version $version');
    }
    final int precision = u32();
    final int bypassPrecision = u32();
    final int streamParts = u32();
    final int numGroups = u32();
    if (precision <= 0 || precision > 16) {
      throw EntropyTableFormatException('bad precision $precision');
    }
    if (bypassPrecision <= 0 || bypassPrecision >= precision) {
      throw EntropyTableFormatException('bad bypassPrecision $bypassPrecision');
    }
    if (streamParts < 1 || streamParts > 16) {
      throw EntropyTableFormatException('bad streamParts $streamParts');
    }
    if (numGroups < 1 || numGroups > 64) {
      throw EntropyTableFormatException('bad numGroups $numGroups');
    }

    Int32List i32(int count) {
      _need(bytes, off, count * 4);
      final Int32List out = Int32List(count);
      var p = off;
      for (var i = 0; i < count; i++) {
        out[i] = bd.getInt32(p, Endian.little);
        p += 4;
      }
      off = p;
      return out;
    }

    final List<CdfGroup> groups = <CdfGroup>[];
    for (var g = 0; g < numGroups; g++) {
      final int r = u32();
      final int w = u32();
      if (r <= 0 || w <= 0 || r > 1 << 20 || w > 1 << 24) {
        throw EntropyTableFormatException('group $g has bad shape ${r}x$w');
      }
      final Int32List cdfLength = i32(r);
      final Int32List offset = i32(r);
      final Int32List cdf = i32(r * w);
      for (var row = 0; row < r; row++) {
        final int n = cdfLength[row];
        if (n < 2 || n > w) {
          throw EntropyTableFormatException(
            'group $g row $row has cdfLength $n (width $w)',
          );
        }
      }
      groups.add(
        CdfGroup(
          numCdfs: r,
          cdfWidth: w,
          cdfLength: cdfLength,
          offset: offset,
          quantizedCdf: cdf,
        ),
      );
    }

    _need(bytes, off, 4);
    if (bytes[off] != 0x49 ||
        bytes[off + 1] != 0x44 ||
        bytes[off + 2] != 0x58 ||
        bytes[off + 3] != 0x50) {
      throw EntropyTableFormatException('missing IDXP block at byte $off');
    }
    off += 4;
    _need(bytes, off, 8 + 8 + 4 + 4 + 4);
    final double logScaleMin = bd.getFloat64(off, Endian.little);
    final double logScaleStep = bd.getFloat64(off + 8, Endian.little);
    final int levels = bd.getUint32(off + 16, Endian.little);
    final double scaleThreshold = bd.getFloat32(off + 20, Endian.little);
    final double scaleFloor = bd.getFloat32(off + 24, Endian.little);
    off += 28;
    if (levels <= 0 || levels > 1 << 20) {
      throw EntropyTableFormatException('bad scalesLevels $levels');
    }
    _need(bytes, off, levels * 4);
    final Float32List scaleTable = Float32List(levels);
    for (var i = 0; i < levels; i++) {
      scaleTable[i] = bd.getFloat32(off + i * 4, Endian.little);
    }
    off += levels * 4;

    _need(bytes, off, 4);
    if (bytes[off] != 0x45 ||
        bytes[off + 1] != 0x4E ||
        bytes[off + 2] != 0x44 ||
        bytes[off + 3] != 0x00) {
      throw EntropyTableFormatException('missing END trailer at byte $off');
    }
    off += 4;
    if (off != bytes.length) {
      throw EntropyTableFormatException(
        'trailing data: parsed $off of ${bytes.length} bytes',
      );
    }

    return EntropyTables(
      version: version,
      precision: precision,
      bypassPrecision: bypassPrecision,
      streamParts: streamParts,
      groups: groups,
      indexQuantizer: IndexQuantizerParams(
        logScaleMin: logScaleMin,
        logScaleStep: logScaleStep,
        scalesLevels: levels,
        scaleThreshold: scaleThreshold,
        scaleFloor: scaleFloor,
        scaleTable: scaleTable,
      ),
    );
  }

  static void _need(Uint8List bytes, int off, int count) {
    if (off < 0 || off + count > bytes.length) {
      throw EntropyTableFormatException(
        'truncated file: needed $count bytes at $off of ${bytes.length}',
      );
    }
  }
}
