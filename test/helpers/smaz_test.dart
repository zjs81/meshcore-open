import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/smaz.dart';

int _utf8Len(String s) => utf8.encode(s).length;

Uint8List _raw(String s) =>
    Smaz.compressBytes(Uint8List.fromList(utf8.encode(s)));

/// Sent size, raw SMAZ size and base64 wire size for [text].
({int plain, int raw, int wire, int sent}) _measure(String text) {
  final raw = _raw(text);
  return (
    plain: _utf8Len(text),
    raw: raw.length,
    wire: _utf8Len('s:${base64Encode(raw)}'),
    sent: _utf8Len(Smaz.encodeIfSmaller(text)),
  );
}

void main() {
  group('compression results', () {
    test('lowercase English compresses well', () {
      const text = 'hello there, how are you doing today?';
      final m = _measure(text);
      expect((m.plain, m.raw, m.wire, m.sent), (37, 20, 30, 30));
      expect(Smaz.encodeIfSmaller(text), startsWith('s:'));
    });

    test('sentence case compresses, a little less', () {
      const text = 'Hello there, how are you doing today?';
      final m = _measure(text);
      expect((m.plain, m.raw, m.wire, m.sent), (37, 22, 34, 34));
      expect(Smaz.encodeIfSmaller(text), startsWith('s:'));
    });

    test('mixed case with many capitals barely compresses', () {
      const mixed = 'Meeting at Headquarters on Monday afternoon';
      const lower = 'meeting at headquarters on monday afternoon';
      expect(_measure(mixed).wire, 42);
      expect(_measure(mixed).plain, 43);
      expect(Smaz.encodeIfSmaller(mixed), startsWith('s:'));
      // The same words in lowercase save far more.
      expect(_measure(lower).wire, 34);
      expect(_measure(lower).raw, 24);
      // Each capital that is not in the codebook costs 2 bytes.
      expect(_measure(mixed).raw - _measure(lower).raw, 4);
    });

    test('all caps is longer than the plain text, so it is sent plain', () {
      const text = 'HELLO THERE, HOW ARE YOU DOING TODAY?';
      final m = _measure(text);
      expect((m.plain, m.raw, m.wire, m.sent), (37, 50, 70, 37));
      expect(Smaz.encodeIfSmaller(text), text);
    });

    test('a reply prefix costs the same in either case', () {
      expect(
        _raw('@[Alice] hello there, how are you?').length,
        _raw('@[alice] hello there, how are you?').length,
      );
      // 34 bytes plain, 34 bytes encoded: not strictly smaller, sent plain.
      const text = '@[Alice] hello there, how are you?';
      expect(_measure(text).wire, _measure(text).plain);
      expect(Smaz.encodeIfSmaller(text), text);
    });
  });

  group('non-ASCII text', () {
    test('Cyrillic round-trips as raw bytes but is sent plain', () {
      const text = 'Привет, как дела сегодня?';
      final m = _measure(text);
      expect((m.plain, m.raw, m.wire, m.sent), (45, 52, 74, 45));
      expect(Smaz.encodeIfSmaller(text), text);
      // The byte-level codec is still lossless.
      expect(utf8.decode(Smaz.decompressBytes(_raw(text))), text);
    });

    test('emoji survives a compressed round trip', () {
      const text =
          'see you soon 😀 the best of luck with the new house and the garden';
      final encoded = Smaz.encodeIfSmaller(text);
      expect(encoded, startsWith('s:'));
      expect(_utf8Len(encoded), lessThan(_utf8Len(text)));
      expect(Smaz.tryDecodePrefixed(encoded), text);
    });

    test('a short emoji message is not smaller, so it is sent plain', () {
      const text = 'see you soon 😀 the best';
      final m = _measure(text);
      expect((m.plain, m.raw, m.wire, m.sent), (26, 17, 26, 26));
      expect(Smaz.encodeIfSmaller(text), text);
    });
  });

  group('encodeIfSmaller falls back to plain text', () {
    test('short strings', () {
      for (final text in ['hi', 'ok', 'Hello', 'the']) {
        expect(Smaz.encodeIfSmaller(text), text, reason: text);
      }
    });

    test('empty string', () {
      expect(Smaz.encodeIfSmaller(''), '');
    });

    test('sent form is never longer than the plain text', () {
      for (final text in [
        'a',
        'Hello',
        'HELLO THERE, HOW ARE YOU DOING TODAY?',
        'the quick brown fox jumps over the lazy dog',
        'Привет, как дела?',
        '12345 67890',
      ]) {
        expect(
          _utf8Len(Smaz.encodeIfSmaller(text)),
          lessThanOrEqualTo(_utf8Len(text)),
          reason: text,
        );
      }
    });
  });

  group('round trip', () {
    test('tryDecodePrefixed restores what encodeIfSmaller produced', () {
      for (final text in [
        'hello there, how are you doing today?',
        'Hello there, how are you doing today?',
        'Meeting at Headquarters on Monday afternoon',
        'the quick brown fox jumps over the lazy dog',
        '@[Alice] hello there, how are you doing today my friend?',
      ]) {
        final encoded = Smaz.encodeIfSmaller(text);
        expect(encoded, startsWith('s:'), reason: text);
        expect(Smaz.tryDecodePrefixed(encoded), text, reason: text);
      }
    });

    test('the decoder ignores leading whitespace', () {
      const text = 'hello there, how are you doing today?';
      expect(Smaz.tryDecodePrefixed('  ${Smaz.encodeIfSmaller(text)}'), text);
    });

    test('plain text is not a compressed payload', () {
      expect(Smaz.tryDecodePrefixed('hello there'), isNull);
      expect(Smaz.tryDecodePrefixed('s:'), isNull);
    });
  });

  group('"s:" guard', () {
    test('text that already starts with "s:" is never re-encoded', () {
      const text = 's:hello there, how are you doing today?';
      expect(Smaz.encodeIfSmaller(text), text);
    });

    test('plain "s:" text is not mistaken for a compressed payload', () {
      expect(Smaz.tryDecodePrefixed('s:test'), isNull);
      expect(Smaz.tryDecodePrefixed('s:hello'), isNull);
      // Valid base64 that is not what the encoder would have produced.
      expect(Smaz.tryDecodePrefixed('s:AAAA'), isNull);
    });

    test('malformed payloads return null instead of throwing', () {
      expect(Smaz.tryDecodePrefixed('s:!!!!'), isNull);
      // Truncated verbatim escape (0xFE with no byte after it).
      expect(Smaz.tryDecodePrefixed('s:${base64Encode([254])}'), isNull);
    });
  });
}
