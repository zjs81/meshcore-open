import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/services.dart';

class Utf8LengthLimitingTextInputFormatter extends TextInputFormatter {
  final int maxBytes;
  final String Function(String)? encoder;

  const Utf8LengthLimitingTextInputFormatter(this.maxBytes, {this.encoder});

  int _effectiveByteLength(String text) {
    final effective = encoder != null ? encoder!(text) : text;
    return utf8.encode(effective).length;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (maxBytes <= 0) return oldValue;
    final newBytes = _effectiveByteLength(newValue.text);
    if (newBytes <= maxBytes ||
        newBytes <= _effectiveByteLength(oldValue.text)) {
      return newValue;
    }

    final oldText = oldValue.text;
    final newText = newValue.text;
    var prefix = 0;
    while (prefix < oldText.length &&
        prefix < newText.length &&
        oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }
    if (prefix > 0 &&
        prefix < newText.length &&
        _isLowSurrogate(newText.codeUnitAt(prefix))) {
      prefix--;
    }
    var suffix = 0;
    while (suffix < oldText.length - prefix &&
        suffix < newText.length - prefix &&
        oldText.codeUnitAt(oldText.length - 1 - suffix) ==
            newText.codeUnitAt(newText.length - 1 - suffix)) {
      suffix++;
    }
    final suffixStart = newText.length - suffix;
    if (suffix > 0 && _isLowSurrogate(newText.codeUnitAt(suffixStart))) {
      suffix--;
    }

    final head = newText.substring(0, prefix);
    final tail = newText.substring(newText.length - suffix);
    final inserted = newText.substring(prefix, newText.length - suffix);

    final kept = StringBuffer();
    for (final char in inserted.characters) {
      if (_effectiveByteLength('$head$kept$char$tail') > maxBytes) break;
      kept.write(char);
    }

    final cursor = head.length + kept.length;
    return TextEditingValue(
      text: '$head$kept$tail',
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }

  bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
}

/// Longest name (in UTF-8 bytes) the radio stores for channels and the node
/// advert name: a 32-byte field that keeps one byte for the NUL terminator.
const int maxRadioNameBytes = 31;

int utf8ByteLength(String text) => utf8.encode(text).length;

/// Cuts [text] to at most [maxBytes] UTF-8 bytes without splitting a
/// character (grapheme cluster).
String truncateUtf8(String text, int maxBytes) {
  if (maxBytes <= 0) return '';
  if (utf8ByteLength(text) <= maxBytes) return text;
  final kept = StringBuffer();
  var used = 0;
  for (final char in text.characters) {
    final size = utf8ByteLength(char);
    if (used + size > maxBytes) break;
    kept.write(char);
    used += size;
  }
  return kept.toString();
}

/// Builds `"<label> <suffix>"`, shortening [label] so the whole name fits
/// in [maxRadioNameBytes].
String fitRadioName(String label, String suffix) {
  final suffixPart = ' $suffix';
  final room = maxRadioNameBytes - utf8ByteLength(suffixPart);
  return '${truncateUtf8(label, room)}$suffixPart';
}
