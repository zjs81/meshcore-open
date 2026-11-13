import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/path_trace_input.dart';

void main() {
  PathTraceParseResult p(String s, [int w = 1]) =>
      PathTraceInputParser.parse(s, w);

  test('comma separated, case-insensitive', () {
    final r = p('a1,B2,c3').input!;
    expect(r.hopWidth, 1);
    expect(r.bytes, [0xa1, 0xb2, 0xc3]);
    expect(r.hops.length, 3);
  });

  test('mixed separators and 0x prefixes', () {
    final r = p('0xA1 > b2 → 0Xc3/d4\n-e5').input!;
    expect(r.bytes, [0xa1, 0xb2, 0xc3, 0xd4, 0xe5]);
  });

  test('two and three byte hops define width', () {
    expect(p('a1b2,c3d4', 1).input!.hopWidth, 2);
    final r = p('a1b2c3 d4e5f6', 1).input!;
    expect(r.hopWidth, 3);
    expect(r.hops.last, [0xd4, 0xe5, 0xf6]);
  });

  test('continuous string splits by default width', () {
    expect(p('a1b2c3d4', 1).input!.hops.length, 4);
    expect(p('a1b2c3d4', 2).input!.hops.length, 2);
    expect(p('a1b2c3', 3).input!.hopWidth, 3);
    expect(p('a1b2c3', 2).error, PathTraceInputError.oddLength);
  });

  test('errors', () {
    expect(p('  ').error, PathTraceInputError.empty);
    expect(p('a1,zz').error, PathTraceInputError.invalidHex);
    expect(p('a1,b').error, PathTraceInputError.oddLength);
    expect(p('abc').error, PathTraceInputError.oddLength);
    expect(p('a1,b2c3').error, PathTraceInputError.mixedWidths);
    expect(p('a1b2c3d4,e5f6a7b8').error, PathTraceInputError.unsupportedWidth);
  });

  test('too many hops', () {
    final ok = List.filled(64, 'aa').join(',');
    expect(p(ok).isValid, isTrue);
    expect(p('$ok,bb').error, PathTraceInputError.tooManyHops);
    final wide = List.filled(22, 'aabbcc').join(',');
    expect(p(wide).error, PathTraceInputError.tooManyHops);
  });

  group('traceFitsInRequest', () {
    PathTraceInput hops(int count, int width) => PathTraceInputParser.parse(
      List.generate(count, (i) => 'ab' * width).join(','),
      width,
    ).input!;

    test('round trip of 21 three-byte hops exceeds the frame limit', () {
      // 41 hops x 4-byte trace prefixes + 10-byte header = 174 > 172.
      expect(traceFitsInRequest(hops(21, 3), roundTrip: true), isFalse);
      expect(traceFitsInRequest(hops(21, 3), roundTrip: false), isTrue);
    });

    test('round trip of 20 three-byte hops fits', () {
      // 39 x 4 + 10 = 166.
      expect(traceFitsInRequest(hops(20, 3), roundTrip: true), isTrue);
    });

    test('hop count is capped at 64 even when bytes fit', () {
      // 33 one-byte hops round trip = 65 hops.
      expect(traceFitsInRequest(hops(33, 1), roundTrip: true), isFalse);
      expect(traceFitsInRequest(hops(32, 1), roundTrip: true), isTrue);
    });
  });
}
