// Pure-Dart port of the AEIC rANS entropy coder.
//
// Ported from the C++ reference in `aeic/src/cpp/rans/` (rans.h, rans_byte.h,
// rans.cpp), which is itself ryg_rans + CompressAI's unbounded-index range
// coding. The port must be BYTE-IDENTICAL to the C++ coder: a single differing
// byte desynchronises rANS and silently corrupts most of the image. The golden
// vectors under `test/services/golden/` pin that down.
//
// Notes on the port:
//  * Dart `int` is 64-bit and signed; the C++ state is `uint32_t`. Every place
//    the C++ relies on 32-bit behaviour is either provably in-range (the state
//    invariant keeps `x < 2^31`) or masked explicitly with `& 0xFFFFFFFF`.
//  * `>>` on a negative Dart int is arithmetic. All shifted values here are
//    non-negative by construction; `>>>` is used where the shift consumes the
//    state so the intent is unambiguous.
//
// Format recap (see `results/rans_port_spec.md`):
//  * precision 16, bypassPrecision 2, RANS_L = 1 << 23, streamParts 2.
//  * Each `encodeWithIndexes` call is split evenly across the sub-streams:
//    part p covers `[p * (n ~/ parts), ...)`, the last part taking the
//    remainder. Every part accumulates across all calls; flush happens once.
//  * A sub-stream's first 4 bytes are the final rANS state, little-endian.
//  * Container: `flag = ((nParts - 1) << 4) | (hdrLen == 2 ? 1 : 0)`, then the
//    lengths of the first `nParts - 1` sub-streams (hdrLen bytes each, LE),
//    then the sub-streams back to back.
library;

import 'dart:typed_data';

import 'entropy_tables.dart';

/// Lower bound of the rANS normalisation interval (`RANS_BYTE_L`).
const int kRansLowerBound = 1 << 23;

/// Thrown when a bitstream cannot be interpreted.
class RansFormatException implements Exception {
  RansFormatException(this.message);

  final String message;

  @override
  String toString() => 'RansFormatException: $message';
}

/// Splits the shipped bytes into rANS sub-streams. Mirror of
/// `RansDecoder::set_stream`.
List<Uint8List> parseRansContainer(Uint8List stream) {
  if (stream.isEmpty) {
    throw RansFormatException('empty stream');
  }
  final int flag = stream[0];
  final int nStreams = (flag >> 4) + 1;
  final int hdr = (flag & 0x0F) == 1 ? 2 : 4;
  var off = 1;
  final List<int> sizes = <int>[];
  var total = 0;
  for (var i = 0; i < nStreams - 1; i++) {
    if (off + hdr > stream.length) {
      throw RansFormatException('truncated sub-stream size table');
    }
    var sz = 0;
    for (var b = 0; b < hdr; b++) {
      sz |= stream[off + b] << (8 * b);
    }
    off += hdr;
    sizes.add(sz);
    total += sz;
  }
  final int last = stream.length - off - total;
  if (last < 0) {
    throw RansFormatException('sub-stream sizes exceed the stream length');
  }
  sizes.add(last);
  final List<Uint8List> parts = <Uint8List>[];
  var p = off;
  for (final int sz in sizes) {
    if (p + sz > stream.length) {
      throw RansFormatException('truncated sub-stream');
    }
    parts.add(Uint8List.sublistView(stream, p, p + sz));
    p += sz;
  }
  return parts;
}

/// Assembles sub-streams into the bytes that go on the air.
Uint8List buildRansContainer(List<Uint8List> parts) {
  if (parts.isEmpty) {
    throw RansFormatException('no sub-streams');
  }
  if (parts.length > 16) {
    throw RansFormatException('too many sub-streams (${parts.length})');
  }
  var maximum = 0;
  for (var i = 0; i < parts.length - 1; i++) {
    if (parts[i].length > maximum) maximum = parts[i].length;
  }
  final int hdr = maximum > 65535 ? 4 : 2;
  final int flag = ((parts.length - 1) << 4) | (hdr == 2 ? 1 : 0);
  var total = 1 + hdr * (parts.length - 1);
  for (final Uint8List p in parts) {
    total += p.length;
  }
  final Uint8List out = Uint8List(total);
  out[0] = flag;
  var off = 1;
  for (var i = 0; i < parts.length - 1; i++) {
    final int n = parts[i].length;
    for (var b = 0; b < hdr; b++) {
      out[off + b] = (n >> (8 * b)) & 0xFF;
    }
    off += hdr;
  }
  for (final Uint8List p in parts) {
    out.setRange(off, off + p.length, p);
    off += p.length;
  }
  return out;
}

/// Growable (start, range) entry list, stored interleaved in one Int32List.
/// `range == 0` is the bypass sentinel: `start` then carries the raw bits.
class _EntryBuffer {
  Int32List _data = Int32List(2048);
  int _length = 0;

  int get length => _length;

  void add(int start, int range) {
    final int need = (_length + 1) * 2;
    if (need > _data.length) {
      final Int32List bigger = Int32List(_data.length * 2);
      bigger.setRange(0, _data.length, _data);
      _data = bigger;
    }
    _data[_length * 2] = start;
    _data[_length * 2 + 1] = range;
    _length++;
  }

  int startAt(int i) => _data[i * 2];

  int rangeAt(int i) => _data[i * 2 + 1];

  void clear() => _length = 0;
}

/// Growable byte sink used for the reversed encoder output.
class _ByteSink {
  Uint8List _data = Uint8List(4096);
  int _length = 0;

  void add(int byte) {
    if (_length == _data.length) {
      final Uint8List bigger = Uint8List(_data.length * 2);
      bigger.setRange(0, _data.length, _data);
      _data = bigger;
    }
    _data[_length++] = byte & 0xFF;
  }

  /// Returns the bytes in reverse of the order they were added, which is the
  /// order they appear in the sub-stream.
  Uint8List reversedBytes() {
    final Uint8List out = Uint8List(_length);
    for (var i = 0; i < _length; i++) {
      out[i] = _data[_length - 1 - i];
    }
    return out;
  }
}

/// rANS encoder. Call [encodeWithIndexes] once per stage in format order
/// (z, y0, y1, y2, y3), then [finish] exactly once.
class RansEncoder {
  factory RansEncoder(EntropyTables tables, {int? streamParts}) =>
      RansEncoder._(tables, streamParts ?? tables.streamParts);

  RansEncoder._(EntropyTables tables, int streamParts)
    : tables = tables,
      streamParts = streamParts,
      _precision = tables.precision,
      _bypassPrecision = tables.bypassPrecision,
      _entries = List<_EntryBuffer>.generate(
        streamParts,
        (_) => _EntryBuffer(),
      );

  final EntropyTables tables;
  final int streamParts;
  final int _precision;
  final int _bypassPrecision;
  final List<_EntryBuffer> _entries;
  bool _finished = false;

  int get _maxBypassVal => (1 << _bypassPrecision) - 1;

  /// Accumulates one encode call. [symbols] and [indexes] must be the same
  /// length; an index `< 0` emits nothing at all.
  ///
  /// Never pass an odd-length array: the reference splitter (and therefore the
  /// on-air format) mis-sizes the last part's index vector in that case.
  void encodeWithIndexes(
    List<int> symbols,
    List<int> indexes,
    int cdfGroupIndex,
  ) {
    if (_finished) {
      throw StateError('RansEncoder.finish() has already been called');
    }
    if (symbols.length != indexes.length) {
      throw ArgumentError(
        'symbols (${symbols.length}) and indexes (${indexes.length}) differ',
      );
    }
    if (cdfGroupIndex < 0 || cdfGroupIndex >= tables.groups.length) {
      throw ArgumentError('no CDF group $cdfGroupIndex');
    }
    final CdfGroup group = tables.groups[cdfGroupIndex];
    final int total = symbols.length;
    final int each = total ~/ streamParts;
    for (var p = 0; p < streamParts; p++) {
      final int lo = p * each;
      final int hi = p == streamParts - 1 ? total : lo + each;
      _push(_entries[p], symbols, indexes, lo, hi, group);
    }
  }

  void _push(
    _EntryBuffer out,
    List<int> symbols,
    List<int> indexes,
    int lo,
    int hi,
    CdfGroup group,
  ) {
    final Int32List cdf = group.quantizedCdf;
    final Int32List cdfLength = group.cdfLength;
    final Int32List offsets = group.offset;
    final int width = group.cdfWidth;
    final int maxBypassVal = _maxBypassVal;
    final int bypassPrecision = _bypassPrecision;

    for (var i = lo; i < hi; i++) {
      final int cdfIdx = indexes[i];
      if (cdfIdx < 0) {
        continue;
      }
      if (cdfIdx >= group.numCdfs) {
        throw RansFormatException(
          'index $cdfIdx out of range (${group.numCdfs} CDF rows)',
        );
      }
      final int maxValue = cdfLength[cdfIdx] - 2;
      var value = symbols[i] - offsets[cdfIdx];
      var rawVal = 0;
      if (value < 0) {
        rawVal = -2 * value - 1;
        value = maxValue;
      } else if (value >= maxValue) {
        rawVal = 2 * (value - maxValue);
        value = maxValue;
      }

      final int base = cdfIdx * width;
      final int start = cdf[base + value];
      out.add(start, cdf[base + value + 1] - start);

      if (value == maxValue) {
        // Bypass mode: raw bits, `bypassPrecision` at a time.
        var nBypass = 0;
        while ((rawVal >> (nBypass * bypassPrecision)) != 0) {
          nBypass++;
        }
        var val = nBypass;
        while (val >= maxBypassVal) {
          out.add(maxBypassVal, 0);
          val -= maxBypassVal;
        }
        out.add(val, 0);
        for (var j = 0; j < nBypass; j++) {
          out.add((rawVal >> (j * bypassPrecision)) & maxBypassVal, 0);
        }
      }
    }
  }

  /// Flushes every sub-stream and returns the container bytes.
  Uint8List finish() {
    if (_finished) {
      throw StateError('RansEncoder.finish() has already been called');
    }
    _finished = true;
    final List<Uint8List> parts = <Uint8List>[
      for (final _EntryBuffer e in _entries) _flush(e),
    ];
    return buildRansContainer(parts);
  }

  /// Discards accumulated entries so the encoder can be reused.
  void reset() {
    for (final _EntryBuffer e in _entries) {
      e.clear();
    }
    _finished = false;
  }

  Uint8List _flush(_EntryBuffer entries) {
    final _ByteSink sink = _ByteSink();
    // The state is always in [2^23, 2^31); native Dart ints need no masking,
    // but the emission path is written to stay explicitly byte-wise anyway.
    var x = kRansLowerBound;
    final int bypassXMax = (1 << (_precision - _bypassPrecision)) << 15;
    for (var k = entries.length - 1; k >= 0; k--) {
      final int range = entries.rangeAt(k);
      final int start = entries.startAt(k);
      if (range != 0) {
        final int xMax = range << 15;
        while (x >= xMax) {
          sink.add(x & 0xFF);
          x = x >>> 8;
        }
        x = ((x ~/ range) << _precision) + (x % range) + start;
      } else {
        while (x >= bypassXMax) {
          sink.add(x & 0xFF);
          x = x >>> 8;
        }
        x = ((x << _bypassPrecision) | start) & 0xFFFFFFFF;
      }
    }
    // RansEncFlush writes the 32-bit state little-endian at the front of the
    // stream, i.e. in emission order it is the high byte first.
    sink.add((x >>> 24) & 0xFF);
    sink.add((x >>> 16) & 0xFF);
    sink.add((x >>> 8) & 0xFF);
    sink.add(x & 0xFF);
    return sink.reversedBytes();
  }
}

/// rANS decoder. Decoding is INCREMENTAL: construct once over the whole
/// container, then call [decodeStream] per stage in the same order the encoder
/// used (z, y0, y1, y2, y3). Each call resumes the sub-stream states where the
/// previous one left off, because stage i's indexes are unknown until the
/// earlier stages have been decoded and run back through the network.
class RansDecoder {
  factory RansDecoder(
    EntropyTables tables,
    Uint8List stream, {
    int? streamParts,
  }) => RansDecoder._(tables, stream, streamParts ?? tables.streamParts);

  RansDecoder._(EntropyTables tables, Uint8List stream, int expected)
    : tables = tables,
      _precision = tables.precision,
      _bypassPrecision = tables.bypassPrecision,
      _parts = parseRansContainer(stream) {
    if (_parts.length != expected) {
      throw RansFormatException(
        'container has ${_parts.length} sub-streams, expected $expected',
      );
    }
    _states = List<int>.filled(_parts.length, 0);
    _ptrs = List<int>.filled(_parts.length, 0);
    for (var i = 0; i < _parts.length; i++) {
      final Uint8List p = _parts[i];
      if (p.length < 4) {
        throw RansFormatException('sub-stream $i is shorter than 4 bytes');
      }
      _states[i] = p[0] | (p[1] << 8) | (p[2] << 16) | (p[3] << 24);
      _ptrs[i] = 4;
    }
  }

  final EntropyTables tables;
  final int _precision;
  final int _bypassPrecision;
  final List<Uint8List> _parts;
  late final List<int> _states;
  late final List<int> _ptrs;

  int get streamParts => _parts.length;

  /// Decodes one stage. Returns one symbol per entry of [indexes]; positions
  /// whose index is `< 0` yield a literal 0 and consume nothing.
  Int16List decodeStream(List<int> indexes, int cdfGroupIndex) {
    if (cdfGroupIndex < 0 || cdfGroupIndex >= tables.groups.length) {
      throw ArgumentError('no CDF group $cdfGroupIndex');
    }
    final CdfGroup group = tables.groups[cdfGroupIndex];
    final Int32List cdf = group.quantizedCdf;
    final Int32List cdfLength = group.cdfLength;
    final Int32List offsets = group.offset;
    final int width = group.cdfWidth;
    final int mask = (1 << _precision) - 1;
    final int bypassPrecision = _bypassPrecision;
    final int maxBypassVal = (1 << bypassPrecision) - 1;
    final int bypassMask = maxBypassVal;

    final int total = indexes.length;
    final int nParts = _parts.length;
    final int each = total ~/ nParts;
    final Int16List out = Int16List(total);

    for (var pi = 0; pi < nParts; pi++) {
      final int lo = pi * each;
      final int hi = pi == nParts - 1 ? total : lo + each;
      final Uint8List buf = _parts[pi];
      var x = _states[pi];
      var ptr = _ptrs[pi];

      for (var i = lo; i < hi; i++) {
        final int cdfIdx = indexes[i];
        if (cdfIdx < 0) {
          out[i] = 0;
          continue;
        }
        if (cdfIdx >= group.numCdfs) {
          throw RansFormatException(
            'index $cdfIdx out of range (${group.numCdfs} CDF rows)',
          );
        }
        final int n = cdfLength[cdfIdx];
        final int maxValue = n - 2;
        final int base = cdfIdx * width;
        final int cum = x & mask;

        // upper_bound(row[0:n], cum) - 1
        var loo = 0;
        var hii = n;
        while (loo < hii) {
          final int mid = (loo + hii) >> 1;
          if (cdf[base + mid] > cum) {
            hii = mid;
          } else {
            loo = mid + 1;
          }
        }
        final int s = loo - 1;
        if (s < 0 || s >= n - 1) {
          throw RansFormatException('corrupt stream: symbol $s out of range');
        }
        final int start = cdf[base + s];
        final int range = cdf[base + s + 1] - start;

        x = (range * (x >>> _precision) + (x & mask) - start) & 0xFFFFFFFF;
        while (x < kRansLowerBound) {
          if (ptr >= buf.length) {
            throw RansFormatException('sub-stream $pi exhausted');
          }
          x = ((x << 8) | buf[ptr]) & 0xFFFFFFFF;
          ptr++;
        }

        var value = s;
        if (value == maxValue) {
          // Bypass mode. Note the renormalisation here is a single `if`, not a
          // loop -- that asymmetry with the symbol path is part of the format.
          int getBits() {
            final int v = x & bypassMask;
            x = x >>> bypassPrecision;
            if (x < kRansLowerBound) {
              if (ptr >= buf.length) {
                throw RansFormatException('sub-stream $pi exhausted');
              }
              x = ((x << 8) | buf[ptr]) & 0xFFFFFFFF;
              ptr++;
            }
            return v;
          }

          var val = getBits();
          var nBypass = val;
          while (val == maxBypassVal) {
            val = getBits();
            nBypass += val;
          }
          var rawVal = 0;
          for (var j = 0; j < nBypass; j++) {
            rawVal |= getBits() << (j * bypassPrecision);
          }
          value = rawVal >> 1;
          if ((rawVal & 1) != 0) {
            value = -value - 1;
          } else {
            value += maxValue;
          }
        }
        out[i] = value + offsets[cdfIdx];
      }

      _states[pi] = x;
      _ptrs[pi] = ptr;
    }
    return out;
  }
}
