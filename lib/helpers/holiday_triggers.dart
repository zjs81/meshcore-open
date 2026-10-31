/// Animation trigger messages: holiday greetings that play a short
/// full-screen animation when they arrive in (or are sent to) an open chat.
///
/// The greetings are translation strings (`holidayGreeting_*` in the ARB
/// files, alternatives separated by `|`). A message is checked against the
/// greetings of *every* app language, since the sender may write in any of
/// them, and matching ignores case and punctuation.
library;

import 'dart:ui' show Locale;

import '../l10n/app_localizations.dart';

enum HolidayAnimation { halloween, thanksgiving, christmas, newYear }

/// The greeting string for [animation] in one language.
String holidayGreetingsIn(AppLocalizations l10n, HolidayAnimation animation) =>
    switch (animation) {
      HolidayAnimation.halloween => l10n.holidayGreeting_halloween,
      HolidayAnimation.thanksgiving => l10n.holidayGreeting_thanksgiving,
      HolidayAnimation.christmas => l10n.holidayGreeting_christmas,
      HolidayAnimation.newYear => l10n.holidayGreeting_newYear,
    };

final RegExp _apostrophes = RegExp("['’‘`´]");
final RegExp _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Scripts written without spaces between words; their greetings are
/// matched anywhere in the text.
final RegExp _unspacedScript = RegExp(r'[぀-ヿ㐀-鿿豈-﫿]');

/// Lowercase, without apostrophes, with every run of punctuation or spaces
/// turned into a single space.
String _normalize(String text) => text
    .toLowerCase()
    .replaceAll(_apostrophes, '')
    .replaceAll(_nonWord, ' ')
    .trim();

class _Matcher {
  final HolidayAnimation animation;

  /// Whole-word phrase with surrounding spaces, e.g. " happy new year ".
  final String spaced;

  /// The phrase with spaces removed, for hashtags and unspaced scripts.
  final String joined;
  final bool unspaced;

  _Matcher(this.animation, String normalized)
    : spaced = ' $normalized ',
      joined = normalized.replaceAll(' ', ''),
      unspaced = _unspacedScript.hasMatch(normalized);
}

/// Matchers for every greeting in every supported language.
List<_Matcher> _buildMatchers() {
  final seen = <(HolidayAnimation, String)>{};
  final matchers = <_Matcher>[];
  for (final locale in AppLocalizations.supportedLocales) {
    final l10n = lookupAppLocalizations(Locale(locale.languageCode));
    for (final animation in HolidayAnimation.values) {
      for (final phrase in holidayGreetingsIn(l10n, animation).split('|')) {
        final normalized = _normalize(phrase);
        // Skip blanks and greetings too short to be meaningful on their own.
        if (normalized.replaceAll(' ', '').length < 3) continue;
        if (seen.add((animation, normalized))) {
          matchers.add(_Matcher(animation, normalized));
        }
      }
    }
  }
  return matchers;
}

final List<_Matcher> _matchers = _buildMatchers();

/// The animation [text] triggers, or null. Greetings must be whole words
/// ("feliz natalia" is not "feliz natal"), except in scripts written
/// without spaces. A greeting run together as one word ("#HappyNewYear")
/// also counts.
HolidayAnimation? holidayAnimationFor(String text) {
  if (text.isEmpty) return null;
  final normalized = _normalize(text);
  if (normalized.isEmpty) return null;
  final spaced = ' $normalized ';
  final joined = normalized.replaceAll(' ', '');
  for (final m in _matchers) {
    if (m.unspaced) {
      if (joined.contains(m.joined)) return m.animation;
    } else if (spaced.contains(m.spaced) || spaced.contains(' ${m.joined} ')) {
      return m.animation;
    }
  }
  return null;
}
