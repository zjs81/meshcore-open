import 'package:flutter/foundation.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import '../utils/platform_info.dart';

/// A parsed WGS84 decimal coordinate pair (`latitude, longitude`) found in text.
@immutable
class ParsedCoordinate {
  final double latitude;
  final double longitude;
  final String rawText;
  final int start;
  final int end;

  const ParsedCoordinate({
    required this.latitude,
    required this.longitude,
    required this.rawText,
    required this.start,
    required this.end,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedCoordinate &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          rawText == other.rawText &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(latitude, longitude, rawText, start, end);

  @override
  String toString() =>
      'ParsedCoordinate($latitude, $longitude, "$rawText", $start..$end)';
}

/// Linkify element representing a detected GPS coordinate pair.
class CoordinateElement extends LinkableElement {
  final double latitude;
  final double longitude;

  CoordinateElement({
    required this.latitude,
    required this.longitude,
    required String rawText,
  }) : super(
         rawText,
         buildExternalMapUri(latitude, longitude).toString(),
         rawText,
       );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoordinateElement &&
          super.equals(other) &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(super.hashCode, latitude, longitude);

  @override
  String toString() => "CoordinateElement: '$text' ($latitude, $longitude)";
}

/// Builds a platform-appropriate external maps URI for [latitude] and [longitude].
Uri buildExternalMapUri(
  double latitude,
  double longitude, {
  TargetPlatform? platform,
  bool? isWeb,
}) {
  final normalizedLat = latitude == 0 ? 0.0 : latitude;
  final normalizedLon = longitude == 0 ? 0.0 : longitude;
  final latStr = normalizedLat.toString();
  final lonStr = normalizedLon.toString();

  final web = isWeb ?? PlatformInfo.isWeb;
  if (web) {
    return Uri.parse(
      'https://www.openstreetmap.org/?mlat=$latStr&mlon=$lonStr#map=16/$latStr/$lonStr',
    );
  }

  final targetPlatform = platform ?? defaultTargetPlatform;
  return switch (targetPlatform) {
    TargetPlatform.android => Uri.parse(
      'geo:$latStr,$lonStr?q=$latStr,$lonStr',
    ),
    TargetPlatform.iOS || TargetPlatform.macOS => Uri.parse(
      'https://maps.apple.com/?ll=$latStr,$lonStr&q=$latStr,$lonStr',
    ),
    TargetPlatform.linux ||
    TargetPlatform.windows ||
    TargetPlatform.fuchsia => Uri.parse(
      'https://www.openstreetmap.org/?mlat=$latStr&mlon=$lonStr#map=16/$latStr/$lonStr',
    ),
  };
}

/// Detects decimal `latitude, longitude` GPS coordinates inside [TextElement]s
/// while avoiding URLs, version numbers, integer pairs, and embedded identifiers.
class CoordinateLinkifier extends Linkifier {
  const CoordinateLinkifier();

  static final RegExp _candidateRegex = RegExp(
    r'([+-]?\d+\.\d+),[ \t]*([+-]?\d+\.\d+)',
  );

  // Covers URI schemes and bare domain/path strings that UrlLinkifier leaves
  // as plain text (e.g. geo:..., ftp://..., maps.google.com/?q=...).
  static final RegExp _nonLinkifiedUrlRegex = RegExp(
    r'(?:[a-zA-Z][a-zA-Z0-9+.-]*://|geo:|(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}/)[^\s]*',
  );

  static final RegExp _disallowedBoundaryChar = RegExp(r'[A-Za-z0-9_+-]');
  static final RegExp _asciiDigit = RegExp(r'[0-9]');

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final result = <LinkifyElement>[];
    for (final element in elements) {
      if (element is! TextElement) {
        result.add(element);
        continue;
      }
      result.addAll(_parseSegment(element.text));
    }
    return result;
  }

  static List<LinkifyElement> _parseSegment(String text) {
    final blockedRanges = <({int start, int end})>[
      for (final m in _nonLinkifiedUrlRegex.allMatches(text))
        (start: m.start, end: m.end),
    ];

    final elements = <LinkifyElement>[];
    var cursor = 0;

    for (final match in _candidateRegex.allMatches(text)) {
      if (_isInsideRanges(match.start, match.end, blockedRanges)) {
        continue;
      }
      if (!_hasValidBoundaries(text, match.start, match.end)) {
        continue;
      }

      final lat = double.tryParse(match.group(1)!);
      final lon = double.tryParse(match.group(2)!);
      if (lat == null || lon == null || !lat.isFinite || !lon.isFinite) {
        continue;
      }
      if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) {
        continue;
      }

      if (match.start > cursor) {
        elements.add(TextElement(text.substring(cursor, match.start)));
      }
      elements.add(
        CoordinateElement(
          latitude: lat == 0 ? 0.0 : lat,
          longitude: lon == 0 ? 0.0 : lon,
          rawText: match.group(0)!,
        ),
      );
      cursor = match.end;
    }

    if (elements.isEmpty) {
      return [TextElement(text)];
    }
    if (cursor < text.length) {
      elements.add(TextElement(text.substring(cursor)));
    }
    return elements;
  }

  static bool _isInsideRanges(
    int start,
    int end,
    List<({int start, int end})> ranges,
  ) {
    for (final range in ranges) {
      if (start < range.end && end > range.start) {
        return true;
      }
    }
    return false;
  }

  static bool _hasValidBoundaries(String text, int start, int end) {
    if (start > 0) {
      final prev = text[start - 1];
      if (prev == '.' || _disallowedBoundaryChar.hasMatch(prev)) {
        return false;
      }
    }
    if (end < text.length) {
      final next = text[end];
      if (_disallowedBoundaryChar.hasMatch(next)) {
        return false;
      }
      // Reject version-like continuations (e.g. "1.2,3.4.5"), while allowing
      // trailing sentence periods (e.g. "38.722,-9.139.").
      if (next == '.' &&
          end + 1 < text.length &&
          _asciiDigit.hasMatch(text[end + 1])) {
        return false;
      }
    }
    return true;
  }
}

/// Shared parser returning linkified elements and extracted [ParsedCoordinate]s.
class CoordinateParser {
  CoordinateParser._();

  static const LinkifyOptions linkifyOptions = LinkifyOptions(
    humanize: false,
    defaultToHttps: false,
  );

  static const List<Linkifier> linkifiers = [
    UrlLinkifier(),
    EmailLinkifier(),
    CoordinateLinkifier(),
  ];

  /// Splits [text] into URL, email, coordinate, and plain-text elements.
  static List<LinkifyElement> linkifyWithCoordinates(String text) {
    if (text.isEmpty) return const [];
    var elements = <LinkifyElement>[TextElement(text)];
    for (final linkifier in linkifiers) {
      elements = linkifier.parse(elements, linkifyOptions);
    }
    return elements;
  }

  /// Extracts all valid WGS84 decimal coordinates in [text].
  static List<ParsedCoordinate> parse(String text) {
    if (text.isEmpty) return const [];
    final elements = linkifyWithCoordinates(text);
    final results = <ParsedCoordinate>[];
    var offset = 0;

    for (final element in elements) {
      final raw = element.originText;
      final index = text.indexOf(raw, offset);
      final start = index >= 0 ? index : offset;
      final end = start + raw.length;
      if (element is CoordinateElement) {
        results.add(
          ParsedCoordinate(
            latitude: element.latitude,
            longitude: element.longitude,
            rawText: element.text,
            start: start,
            end: end,
          ),
        );
      }
      offset = end;
    }
    return results;
  }
}
