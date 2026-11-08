import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';

enum PathTraceInputError {
  empty,
  invalidHex,
  oddLength,
  mixedWidths,
  unsupportedWidth,
  tooManyHops,
}

class PathTraceInput {
  final int hopWidth;
  final List<Uint8List> hops;
  final Uint8List bytes;

  const PathTraceInput({
    required this.hopWidth,
    required this.hops,
    required this.bytes,
  });
}

class PathTraceParseResult {
  final PathTraceInput? input;
  final PathTraceInputError? error;

  const PathTraceParseResult.ok(PathTraceInput this.input) : error = null;
  const PathTraceParseResult.error(PathTraceInputError this.error)
    : input = null;

  bool get isValid => input != null;
}

class PathTraceInputParser {
  static final RegExp _separators = RegExp(r'[,\s>→/\-]+');
  static final RegExp _hex = RegExp(r'^[0-9a-fA-F]+$');

  static PathTraceParseResult parse(String text, int defaultWidth) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const PathTraceParseResult.error(PathTraceInputError.empty);
    }
    final tokens = trimmed
        .split(_separators)
        .where((t) => t.isNotEmpty)
        .map(_stripPrefix)
        .toList();
    if (tokens.isEmpty) {
      return const PathTraceParseResult.error(PathTraceInputError.empty);
    }
    for (final t in tokens) {
      if (t.isEmpty || !_hex.hasMatch(t)) {
        return const PathTraceParseResult.error(PathTraceInputError.invalidHex);
      }
    }

    final List<String> hopStrings;
    final int width;
    if (tokens.length == 1) {
      final only = tokens.first;
      if (only.length.isOdd) {
        return const PathTraceParseResult.error(PathTraceInputError.oddLength);
      }
      final w = defaultWidth.clamp(1, maxPathHashWidth).toInt();
      if (only.length % (w * 2) != 0) {
        return const PathTraceParseResult.error(PathTraceInputError.oddLength);
      }
      width = w;
      hopStrings = [
        for (var i = 0; i < only.length; i += w * 2)
          only.substring(i, i + w * 2),
      ];
    } else {
      for (final t in tokens) {
        if (t.length.isOdd) {
          return const PathTraceParseResult.error(
            PathTraceInputError.oddLength,
          );
        }
      }
      final len = tokens.first.length;
      if (tokens.any((t) => t.length != len)) {
        return const PathTraceParseResult.error(
          PathTraceInputError.mixedWidths,
        );
      }
      width = len ~/ 2;
      if (width < 1 || width > maxPathHashWidth) {
        return const PathTraceParseResult.error(
          PathTraceInputError.unsupportedWidth,
        );
      }
      hopStrings = tokens;
    }

    if (hopStrings.length * width > maxPathSize) {
      return const PathTraceParseResult.error(PathTraceInputError.tooManyHops);
    }
    final hops = [
      for (final s in hopStrings)
        Uint8List.fromList([
          for (var i = 0; i < s.length; i += 2)
            int.parse(s.substring(i, i + 2), radix: 16),
        ]),
    ];
    final bytes = Uint8List.fromList([for (final h in hops) ...h]);
    return PathTraceParseResult.ok(
      PathTraceInput(hopWidth: width, hops: hops, bytes: bytes),
    );
  }

  static String _stripPrefix(String t) =>
      (t.startsWith('0x') || t.startsWith('0X')) ? t.substring(2) : t;
}
