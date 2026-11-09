import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/chat_jump.dart';

/// A reversed chat-style list with uneven row heights, so the list's extent
/// estimate is wrong and the helper has to walk to the target.
Widget _list(ScrollController controller, int count) {
  return MaterialApp(
    home: Scaffold(
      body: ListView.builder(
        reverse: true,
        controller: controller,
        itemCount: count,
        itemBuilder: (context, index) => SizedBox(
          key: ValueKey('row$index'),
          height: 40.0 + (index % 7) * 30,
          child: Text('row $index'),
        ),
      ),
    ),
  );
}

void main() {
  for (final target in [0, 7, 250, 499]) {
    testWidgets('brings row $target of 500 on screen', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_list(controller, 500));

      late bool found;
      final done = scrollListToIndex(
        controller: controller,
        targetIndex: target,
        itemCount: 500,
        isMounted: () => true,
      ).then((value) => found = value);
      // Drive frames until the helper finishes.
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await done;

      expect(found, isTrue);
      final row = find.byKey(ValueKey('row$target'));
      expect(row, findsOneWidget);
      final rect = tester.getRect(row);
      final screen = tester.getRect(find.byType(ListView));
      expect(screen.overlaps(rect), isTrue);
    });
  }

  // Codex's case: older rows much taller than recent ones, so the first
  // estimate lands hundreds of rows short.
  testWidgets('reaches a row far past rows of a very different height', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            reverse: true,
            controller: controller,
            itemCount: 2000,
            itemBuilder: (_, i) => SizedBox(
              key: ValueKey('row$i'),
              height: i < 1000 ? 60 : 300,
              child: Text('row $i'),
            ),
          ),
        ),
      ),
    );
    bool? found;
    final done = scrollListToIndex(
      controller: controller,
      targetIndex: 1500,
      itemCount: 2000,
      isMounted: () => true,
    ).then((v) => found = v);
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await done;
    expect(found, isTrue);
    expect(find.byKey(const ValueKey('row1500')), findsOneWidget);
  });

  testWidgets('rejects an index outside the list', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_list(controller, 10));
    expect(
      await scrollListToIndex(
        controller: controller,
        targetIndex: 10,
        itemCount: 10,
        isMounted: () => true,
      ),
      isFalse,
    );
  });
}
