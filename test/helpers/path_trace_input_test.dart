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
}
