import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/utf8_length_limiter.dart';

TextEditingValue _value(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

void main() {
  const formatter = Utf8LengthLimitingTextInputFormatter(5);

  test('accepts edits within the limit', () {
    final result = formatter.formatEditUpdate(_value('ab'), _value('abc'));
    expect(result.text, 'abc');
  });

  test('clips only the inserted text and keeps the end of the draft', () {
    // Paste "XYZ" at the start of "abc" (limit 5 bytes).
    final result = formatter.formatEditUpdate(
      _value('abc', 0),
      _value('XYZabc', 3),
    );
    expect(result.text, 'XYabc');
    expect(result.selection.baseOffset, 2);
  });

  test('rejects an insertion in the middle when full', () {
    final result = formatter.formatEditUpdate(
      _value('abcde', 2),
      _value('abXcde', 3),
    );
    expect(result.text, 'abcde');
    expect(result.selection.baseOffset, 2);
  });

  test('does not split a multi-code-point grapheme', () {
    // Family emoji is 18 UTF-8 bytes, so it cannot fit in the 4 bytes left.
    final result = formatter.formatEditUpdate(
      _value('a'),
      _value('a\u{1F468}‍\u{1F469}‍\u{1F467}'),
    );
    expect(result.text, 'a');
  });

  test('keeps whole emoji that fit', () {
    const limiter = Utf8LengthLimitingTextInputFormatter(9);
    final result = limiter.formatEditUpdate(
      _value('a'),
      _value('a\u{1F600}\u{1F601}'),
    );
    expect(result.text, 'a\u{1F600}\u{1F601}');
    final clipped = const Utf8LengthLimitingTextInputFormatter(
      8,
    ).formatEditUpdate(_value('a'), _value('a\u{1F600}\u{1F601}'));
    expect(clipped.text, 'a\u{1F600}');
  });

  test('replacing one emoji with another sharing a surrogate stays valid', () {
    const limiter = Utf8LengthLimitingTextInputFormatter(5);
    final result = limiter.formatEditUpdate(
      _value('a\u{1F600}'),
      _value('a\u{1F601}\u{1F602}'),
    );
    expect(result.text, 'a\u{1F601}');
  });

  test('allows deletions even when the text is already over the limit', () {
    final result = formatter.formatEditUpdate(
      _value('abcdefg'),
      _value('abcdef'),
    );
    expect(result.text, 'abcdef');
  });

  test('truncateUtf8 never splits a multi-byte character', () {
    // 'й' is 2 bytes; 31 bytes would land mid-character.
    final name = 'й' * 20;
    final cut = truncateUtf8(name, maxRadioNameBytes);
    expect(utf8ByteLength(cut), 30);
    expect(cut, 'й' * 15);
    expect(truncateUtf8('short', maxRadioNameBytes), 'short');
  });

  test('fitRadioName keeps the suffix and fits the radio field', () {
    final fitted = fitRadioName('A' * 40, 'Public');
    expect(fitted.endsWith(' Public'), isTrue);
    expect(utf8ByteLength(fitted), maxRadioNameBytes);
    expect(fitRadioName('Hikers', 'Public'), 'Hikers Public');
  });

  test('encoder counts a hashtag prefix toward the byte limit', () {
    final formatter = Utf8LengthLimitingTextInputFormatter(
      maxRadioNameBytes,
      encoder: (text) => '#$text',
    );
    final result = formatter.formatEditUpdate(_value(''), _value('a' * 40));
    expect(result.text, 'a' * 30);
  });
}
