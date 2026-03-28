import 'dart:typed_data';

import 'contact.dart';

const int recentAttemptDiversityWindow = 2;

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

  if (forceFlood || contact.pathLength < 0 || selection?.useFlood == true) {
    return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
  }

  if (selection != null && selection.pathBytes.isNotEmpty) {
    return PathSelection(
      pathBytes: selection.pathBytes,
      hopCount: selection.hopCount,
      useFlood: false,
    );
  }

  return PathSelection(
    pathBytes: contact.path,
    hopCount: contact.pathLength,
    useFlood: false,
  );
}
