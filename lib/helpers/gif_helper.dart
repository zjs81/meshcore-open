class GifHelper {
  /// Parse a known GIF format, which can be any of:
  /// g:GIFID
  /// https://media.giphy.com/media/GIFID/giphy.gif
  /// https://giphy.com/gifs/Optional-title-with-dashes-GIFID
  ///
  /// GIFID is a Giphy GIF ID. The https:// is optional (and
  /// can also be http://). The giphy.com/gifs form can also
  /// include a trailing slash.
  ///
  /// Returns null if text is not a valid GIF format
  static String? parseGif(String text) {
    final trimmed = text.trim();
    final match = RegExp(r'^g:([A-Za-z0-9_-]+)$').firstMatch(trimmed);
    if (match != null) {
      return match.group(1);
    }
    final directUrlMatch = RegExp(
      r'^(?:https?:\/\/)?media\.giphy\.com\/media\/([A-Za-z0-9_-]+)\/giphy\.gif$',
    ).firstMatch(trimmed);
    if (directUrlMatch != null) {
      return directUrlMatch.group(1);
    }
    // Giphy understands page URLs with just the ID, or any string and a
    // dash before the ID, and redirects to a page with a dash-separated
    // title, a dash, and the ID. IDs in this form *probably* can't
    // contain dashes.
    final pageMatch = RegExp(
      r'^(?:https?:\/\/)?giphy\.com\/gifs\/(?:[^/?]*-)?([A-Za-z0-9_]+)\/?$',
    ).firstMatch(trimmed);
    return pageMatch?.group(1);
  }

  /// Encode a GIF in a format that parseGif() can parse.
  static String encodeGif(String gifId) {
    return 'g:$gifId';
  }
}
