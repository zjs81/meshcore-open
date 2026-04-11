import 'dart:convert';

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
    if (_effectiveByteLength(newValue.text) <= maxBytes) return newValue;

    final truncated = _truncateToMaxBytes(newValue.text, maxBytes);
    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
      composing: TextRange.empty,
    );
  }

  String _truncateToMaxBytes(String text, int limit) {
    if (encoder != null) {
      final runes = text.runes.toList();
      while (runes.isNotEmpty &&
          _effectiveByteLength(String.fromCharCodes(runes)) > maxBytes) {
        runes.removeLast();
      }
      return String.fromCharCodes(runes);
    }
    final buffer = StringBuffer();
    var used = 0;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final charBytes = utf8.encode(char).length;
      if (used + charBytes > limit) break;
      buffer.write(char);
      used += charBytes;
    }
    return buffer.toString();
  }
}
