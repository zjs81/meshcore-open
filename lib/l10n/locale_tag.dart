import 'dart:ui' show Locale;

/// Parses a stored language setting such as `de` or `pt_PT` (also `pt-PT`).
///
/// Most app languages are a bare language code; regional variants carry a
/// country code, which `Locale(tag)` alone would not split out.
Locale localeFromTag(String tag) {
  final parts = tag.split(RegExp('[_-]'));
  if (parts.length > 1 && parts[1].isNotEmpty) {
    return Locale(parts[0], parts[1].toUpperCase());
  }
  return Locale(parts[0]);
}

/// The stored form of [locale]: `de`, or `pt_PT` for a regional variant.
String localeTag(Locale locale) {
  final country = locale.countryCode;
  if (country == null || country.isEmpty) return locale.languageCode;
  return '${locale.languageCode}_$country';
}
