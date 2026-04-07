import 'dart:convert';

import 'package:flutter/services.dart';

String truncateToUtf8Bytes(String text, int maxBytes) {
  if (maxBytes <= 0) return '';

  final buffer = StringBuffer();
  var usedBytes = 0;
  for (final rune in text.runes) {
    final character = String.fromCharCode(rune);
    final characterBytes = utf8.encode(character).length;
    if (usedBytes + characterBytes > maxBytes) break;
    buffer.write(character);
    usedBytes += characterBytes;
  }

  return buffer.toString();
}

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
    if (_effectiveByteLength(newValue.text) <= maxBytes) return newValue;

    final truncated = _truncate(newValue.text);
    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
      composing: TextRange.empty,
    );
  }

  String _truncate(String text) {
    if (encoder == null) return truncateToUtf8Bytes(text, maxBytes);
    final runes = text.runes.toList();
    while (runes.isNotEmpty &&
        _effectiveByteLength(String.fromCharCodes(runes)) > maxBytes) {
      runes.removeLast();
    }
    return String.fromCharCodes(runes);
  }
}
