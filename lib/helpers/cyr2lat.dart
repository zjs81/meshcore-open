class Cyr2Lat {
  static Map<String, String> _charMap = {
    'А': 'A',
    'В': 'B',
    'Е': 'E',
    'Ё': 'E',
    'З': '3',
    'К': 'K',
    'М': 'M',
    'Н': 'H',
    'О': 'O',
    'Р': 'P',
    'С': 'C',
    'Т': 'T',
    'Х': 'X',
    'Ь': 'b',
    'а': 'a',
    'е': 'e',
    'ё': 'e',
    'о': 'o',
    'р': 'p',
    'с': 'c',
    'у': 'y',
    'х': 'x',
  };

  // Non-greedy so only the leading "@[name] " mention is treated as the
  // sender prefix, not everything up to the last "] " in the message.
  static final RegExp _prefixRegExp = RegExp(r'@\[[\S\s]+?\] ');

  static void setCharMap(Map<String, String> charMap) {
    _charMap = Map.from(charMap);
  }

  static String encode(String text) {
    if (text.isEmpty) return text;
    final buffer = StringBuffer();

    final senderName = extractSenderName(text);
    final msgText = removeSenderName(text);

    for (final rune in msgText.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_charMap[char] ?? char);
    }

    return senderName + buffer.toString();
  }

  static String removeSenderName(String text) {
    final match = _prefixRegExp.matchAsPrefix(text);
    if (match != null) {
      return text.substring(match.end);
    }
    return text;
  }

  static String extractSenderName(String text) {
    final match = _prefixRegExp.matchAsPrefix(text);
    if (match != null) {
      return match.group(0) ?? '';
    }
    return '';
  }
}
