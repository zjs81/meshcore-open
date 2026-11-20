import 'dart:convert';
import 'dart:typed_data';

/// One routing path observed in a received radio packet, merged across
/// repeats of the same path. Hop hashes stay raw; they are resolved against
/// the current contacts only when drawn.
class ObservedPath {
  final Uint8List pathBytes;
  final int hashWidth;
  final int firstSeenMs;
  final int lastSeenMs;
  final int count;

  const ObservedPath({
    required this.pathBytes,
    required this.hashWidth,
    required this.firstSeenMs,
    required this.lastSeenMs,
    required this.count,
  });

  String get key => base64Encode(pathBytes);

  ObservedPath merge(DateTime seenAt) {
    final nowMs = seenAt.millisecondsSinceEpoch;
    return ObservedPath(
      pathBytes: pathBytes,
      hashWidth: hashWidth,
      firstSeenMs: firstSeenMs,
      lastSeenMs: lastSeenMs > nowMs ? lastSeenMs : nowMs,
      count: count + 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'b': base64Encode(pathBytes),
    'w': hashWidth,
    'f': firstSeenMs,
    'l': lastSeenMs,
    'c': count,
  };

  static ObservedPath fromJson(Map<String, dynamic> json) {
    final pathBytes = base64Decode(json['b'] as String);
    final first = json['f'] as int;
    final last = json['l'] as int;
    return ObservedPath(
      pathBytes: Uint8List.fromList(pathBytes),
      hashWidth: (json['w'] as int? ?? 1).clamp(1, 3),
      firstSeenMs: first,
      lastSeenMs: last < first ? first : last,
      count: json['c'] as int? ?? 1,
    );
  }
}
