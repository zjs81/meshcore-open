import 'package:flutter_test/flutter_test.dart';

int? consumePendingCommandContext(
  List<int> queue, {
  Set<int>? matchingCommands,
}) {
  if (queue.isEmpty) {
    return null;
  }
  if (matchingCommands == null || matchingCommands.isEmpty) {
    return queue.removeAt(0);
  }

  final index = queue.indexWhere(matchingCommands.contains);
  if (index == -1) {
    return null;
  }
  return queue.removeAt(index);
}

void clearPendingCommandContexts(List<int> queue, Set<int> matchingCommands) {
  if (queue.isEmpty || matchingCommands.isEmpty) {
    return;
  }
  queue.removeWhere(matchingCommands.contains);
}

void main() {
  group('pending command context cleanup', () {
    test('clears stale login contexts after a terminal login outcome', () {
      final queue = <int>[26, 31, 26, 26];

      final consumed = consumePendingCommandContext(
        queue,
        matchingCommands: <int>{26},
      );
      clearPendingCommandContexts(queue, <int>{26});

      expect(consumed, 26);
      expect(queue, <int>[31]);
    });

    test('does not clear unrelated command contexts', () {
      final queue = <int>[31, 40, 59];

      clearPendingCommandContexts(queue, <int>{26});

      expect(queue, <int>[31, 40, 59]);
    });
  });
}
