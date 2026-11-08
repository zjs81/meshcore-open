import '../../models/app_settings.dart' show defaultCyr2LatCharMap;
import '../../models/message_filter.dart';

/// Text helpers shared by the message filter: normalization (so look-alike
/// characters, accents and invisible characters cannot dodge a rule), rule
/// matching and the structured-payload check.
class MessageFilterText {
  MessageFilterText._();

  static final RegExp _whitespace = RegExp(r'\s+', unicode: true);
  static final RegExp _mention = RegExp(r'@\[[^\]]*\]');
  static final RegExp _nonWordChars = RegExp(
    r'[^\p{L}\p{N}\s]+',
    unicode: true,
  );

  /// Shortest run of one character that counts as repeated characters.
  static const int repeatedCharacterRun = 20;

  // Digits are left out: long numbers (frequencies, coordinates, ids) are
  // legitimate. Shorter runs are too: "Noooooooo!", "--------" separators
  // and a row of emoji are ordinary chat.
  static final RegExp _repeatedChars = RegExp(
    '([^\\s\\p{N}])\\1{${repeatedCharacterRun - 1},}',
    unicode: true,
  );

  static final Map<int, String> _foldMap = _buildFoldMap();

  static Map<int, String> _buildFoldMap() {
    final map = <int, String>{};
    void addAll(String chars, String replacement) {
      for (final rune in chars.runes) {
        map[rune] = replacement;
      }
    }

    // Accented Latin (lower case only: input is lower-cased first).
    addAll('àáâãäåāăąǎȁȃạảấầẩẫậắằẳẵặ', 'a');
    addAll('çćĉċč', 'c');
    addAll('ďđ', 'd');
    addAll('èéêëēĕėęěȅȇẹẻẽếềểễệ', 'e');
    addAll('ĝğġģ', 'g');
    addAll('ĥħ', 'h');
    addAll('ìíîïĩīĭįıǐȉȋỉị', 'i');
    addAll('ĵ', 'j');
    addAll('ķ', 'k');
    addAll('ĺļľŀł', 'l');
    addAll('ñńņňŉ', 'n');
    addAll('òóôõöøōŏőǒȍȏọỏốồổỗộớờởỡợơ', 'o');
    addAll('ŕŗř', 'r');
    addAll('śŝşšș', 's');
    addAll('ţťŧț', 't');
    addAll('ùúûüũūŭůűųǔȕȗụủứừửữựư', 'u');
    addAll('ŵ', 'w');
    addAll('ýÿŷỳỵỷỹ', 'y');
    addAll('źżž', 'z');
    map['ß'.runes.first] = 'ss';
    map['æ'.runes.first] = 'ae';
    map['œ'.runes.first] = 'oe';
    map['þ'.runes.first] = 'th';

    // Cyrillic look-alikes (reuse the app's Cyr2Lat table, lower-cased).
    defaultCyr2LatCharMap.forEach((from, to) {
      map[from.toLowerCase().runes.first] = to.toLowerCase();
    });

    // Greek look-alikes.
    const greek = {
      'ο': 'o',
      'α': 'a',
      'ε': 'e',
      'ι': 'i',
      'κ': 'k',
      'ν': 'v',
      'ρ': 'p',
      'τ': 't',
      'υ': 'u',
      'χ': 'x',
    };
    greek.forEach((from, to) => map[from.runes.first] = to);
    return map;
  }

  static bool _isInvisible(int rune) =>
      (rune >= 0x200B && rune <= 0x200D) ||
      rune == 0x2060 ||
      rune == 0xFEFF ||
      rune == 0x00AD;

  static bool _isCombiningMark(int rune) =>
      (rune >= 0x0300 && rune <= 0x036F) ||
      (rune >= 0x1AB0 && rune <= 0x1AFF) ||
      (rune >= 0x1DC0 && rune <= 0x1DFF) ||
      (rune >= 0x20D0 && rune <= 0x20FF) ||
      (rune >= 0xFE20 && rune <= 0xFE2F);

  /// Maps fullwidth and "mathematical" styled letters/digits (bold, italic,
  /// script, …) to plain ASCII, returning null for everything else.
  static int? _foldStyledAscii(int rune) {
    // Fullwidth forms.
    if (rune >= 0xFF41 && rune <= 0xFF5A) return 0x61 + rune - 0xFF41;
    if (rune >= 0xFF21 && rune <= 0xFF3A) return 0x61 + rune - 0xFF21;
    if (rune >= 0xFF10 && rune <= 0xFF19) return 0x30 + rune - 0xFF10;
    // Mathematical alphanumeric symbols: repeating A-Z a-z blocks.
    if (rune >= 0x1D400 && rune <= 0x1D6A3) {
      final offset = (rune - 0x1D400) % 52;
      return 0x61 + (offset < 26 ? offset : offset - 26);
    }
    if (rune >= 0x1D7CE && rune <= 0x1D7FF) {
      return 0x30 + (rune - 0x1D7CE) % 10;
    }
    return null;
  }

  /// Lower-cases, folds accents and look-alike characters, removes invisible
  /// characters and leaves the whitespace untouched.
  static String _fold(String text) {
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      if (_isInvisible(rune) || _isCombiningMark(rune)) continue;
      final styled = _foldStyledAscii(rune);
      if (styled != null) {
        buffer.writeCharCode(styled);
        continue;
      }
      final mapped = _foldMap[rune];
      if (mapped != null) {
        buffer.write(mapped);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Canonical form used for rule matching and classifier features.
  static String normalize(String text) {
    if (text.isEmpty) return '';
    return _fold(text).replaceAll(_whitespace, ' ').trim();
  }

  /// True when [text] contains an `@[name]` mention.
  static bool hasMention(String text) => _mention.hasMatch(text);

  /// Looser form used to detect repeated messages: also drops `@[name]`
  /// mentions, punctuation and emoji so trivial variations still match.
  static String normalizeForDuplicates(String text) {
    final normalized = normalize(text);
    if (normalized.isEmpty) return '';
    return normalized
        .replaceAll(_mention, ' ')
        .replaceAll(_nonWordChars, ' ')
        .replaceAll(_whitespace, ' ')
        .trim();
  }

  /// True when the same visible character appears [repeatedCharacterRun] or
  /// more times in a row (keyboard-mash floods such as "aaaaaaaaaaaaaaaaaaaa").
  ///
  /// Whitespace and digit runs are ignored.
  static bool hasRepeatedCharacters(String text) {
    if (text.length < repeatedCharacterRun) return false;
    return _repeatedChars.hasMatch(_fold(text));
  }

  /// GIF / structured payloads (same check as the channel send path).
  static bool isStructuredPayload(String text) {
    final trimmed = text.trim();
    return trimmed.startsWith('g:') || trimmed.startsWith('m:');
  }

  static final Map<String, RegExp> _wholeWordCache = {};

  static RegExp _wholeWordRegExp(String normalizedPattern) {
    final cached = _wholeWordCache[normalizedPattern];
    if (cached != null) return cached;
    if (_wholeWordCache.length > 256) _wholeWordCache.clear();
    final regExp = RegExp(
      '(?<![\\p{L}\\p{N}])${RegExp.escape(normalizedPattern)}(?![\\p{L}\\p{N}])',
      unicode: true,
    );
    _wholeWordCache[normalizedPattern] = regExp;
    return regExp;
  }

  static bool _matchesNormalized(
    String normalizedPattern,
    FilterRuleMatch match,
    String normalizedTarget,
  ) {
    if (normalizedPattern.isEmpty || normalizedTarget.isEmpty) return false;
    switch (match) {
      case FilterRuleMatch.contains:
        return normalizedTarget.contains(normalizedPattern);
      case FilterRuleMatch.exact:
        return normalizedTarget == normalizedPattern;
      case FilterRuleMatch.wholeWord:
        if (!normalizedTarget.contains(normalizedPattern)) return false;
        return _wholeWordRegExp(normalizedPattern).hasMatch(normalizedTarget);
    }
  }

  /// Whether [rule]'s pattern matches [sender] (ignores the rule's field).
  static bool matchesSender(FilterRule rule, String sender) =>
      _matchesNormalized(
        normalize(rule.pattern),
        rule.match,
        normalize(sender),
      );

  /// Whether [rule]'s pattern matches [text] (ignores the rule's field).
  static bool matchesText(FilterRule rule, String text) =>
      _matchesNormalized(normalize(rule.pattern), rule.match, normalize(text));

  /// Whether [rule] matches the message, honouring the rule's field.
  ///
  /// The rule's `enabled` flag is not checked here; callers decide whether
  /// disabled rules apply.
  static bool matchesRule(
    FilterRule rule, {
    required String sender,
    required String text,
  }) {
    switch (rule.field) {
      case FilterRuleField.sender:
        return matchesSender(rule, sender);
      case FilterRuleField.text:
        return matchesText(rule, text);
      case FilterRuleField.both:
        return matchesSender(rule, sender) || matchesText(rule, text);
    }
  }
}
