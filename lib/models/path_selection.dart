import 'dart:typed_data';

import 'contact.dart';

const int recentAttemptDiversityWindow = 2;

/// What the radio can hear right now, so auto routing can prefer routes that
/// fit where the user currently is (e.g. home vs. work repeaters).
///
/// "Not heard" is weak evidence — repeaters advert rarely and the radio only
/// reports what it hears — so routes that don't fit are deprioritised, never
/// excluded.
class RouteContext {
  /// Whether anything was heard recently. Without that, nothing is known
  /// about the surroundings and every route is treated alike.
  final bool hasNeighbourInfo;

  /// Whether the contact itself was heard with no repeater in between.
  final bool contactHeardDirectly;

  /// Whether the first hop of a route ([pathBytes], [hashWidth] bytes per
  /// hop) was heard directly recently.
  final bool Function(List<int> pathBytes, int hashWidth) firstHopHeard;

  /// The path the radio currently holds for the contact, if any.
  final List<int>? radioPath;

  const RouteContext({
    required this.hasNeighbourInfo,
    required this.contactHeardDirectly,
    required this.firstHopHeard,
    this.radioPath,
  });

  static bool _never(List<int> pathBytes, int hashWidth) => false;

  /// Nothing known: every route is treated alike.
  static const RouteContext unknown = RouteContext(
    hasNeighbourInfo: false,
    contactHeardDirectly: false,
    firstHopHeard: _never,
  );
}

class PathSelection {
  final List<int> pathBytes;
  final int hopCount;
  final bool useFlood;

  const PathSelection({
    required this.pathBytes,
    required this.hopCount,
    required this.useFlood,
  });
}

PathSelection resolvePathSelection(
  Contact contact, {
  PathSelection? selection,
  bool forceFlood = false,
}) {
  if (contact.pathOverride != null) {
    if (contact.pathOverride! < 0) {
      return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
    }
    return PathSelection(
      pathBytes: contact.pathOverrideBytes ?? Uint8List(0),
      hopCount: contact.pathOverride!,
      useFlood: false,
    );
  }

  if (forceFlood || selection?.useFlood == true) {
    return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
  }

  // A route picked from history wins even when the radio holds no path for
  // the contact: it is proven, and flooding would throw that away. A direct
  // (zero-hop) selection has no hop bytes but is still a real path.
  if (selection != null &&
      (selection.pathBytes.isNotEmpty || selection.hopCount == 0)) {
    return PathSelection(
      pathBytes: selection.pathBytes,
      hopCount: selection.hopCount,
      useFlood: false,
    );
  }

  if (contact.pathLength < 0) {
    return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
  }

  return PathSelection(
    pathBytes: contact.path,
    hopCount: contact.pathLength,
    useFlood: false,
  );
}
