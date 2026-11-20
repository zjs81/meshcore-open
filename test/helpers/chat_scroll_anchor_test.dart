import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/chat_scroll_anchor.dart';

/// A reversed chat list of rows with uneven heights. [add] appends newer
/// rows, which land at index 0 below everything else.
class _Harness {
  final controller = ScrollController();
  final anchor = ChatScrollAnchor();
  var items = List.generate(100, (i) => 'm$i');
  late StateSetter _setState;

  Widget build() => MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) {
          _setState = setState;
          final rows = items.reversed.toList();
          return AnchoredChatListView.builder(
            scrollAnchor: anchor,
            reverse: true,
            controller: controller,
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, i) => SizedBox(
              height: 40.0 + (int.parse(rows[i].substring(1)) % 5) * 20,
              child: Text(rows[i]),
            ),
          );
        },
      ),
    ),
  );

  void add(int count, {bool anchored = true}) {
    _setState(() {
      final start = items.length;
      items = [...items, for (var i = 0; i < count; i++) 'n${start + i}'];
      if (anchored) anchor.rowsInsertedBelow(count);
    });
  }
}

void main() {
  for (final count in [1, 3, 30, 300]) {
    testWidgets('$count rows added below keep the visible rows in place', (
      tester,
    ) async {
      final harness = _Harness();
      addTearDown(harness.controller.dispose);
      await tester.pumpWidget(harness.build());
      harness.controller.jumpTo(2000);
      await tester.pump();
      final row = find.text('m72');
      expect(row, findsOneWidget);
      final before = tester.getTopLeft(row).dy;

      harness.add(count);
      await tester.pump();

      expect(row, findsOneWidget);
      expect(tester.getTopLeft(row).dy, moreOrLessEquals(before));
      expect(harness.controller.position.pixels, greaterThan(2000));
    });
  }

  testWidgets('without the anchor the rows on screen move', (tester) async {
    final harness = _Harness();
    addTearDown(harness.controller.dispose);
    await tester.pumpWidget(harness.build());
    harness.controller.jumpTo(2000);
    await tester.pump();
    final before = tester.getTopLeft(find.text('m72')).dy;

    harness.add(3, anchored: false);
    await tester.pump();

    expect(tester.getTopLeft(find.text('m72')).dy, isNot(before));
  });

  testWidgets('a list at the bottom is left at the bottom', (tester) async {
    final harness = _Harness();
    addTearDown(harness.controller.dispose);
    await tester.pumpWidget(harness.build());

    harness.add(3, anchored: false);
    await tester.pump();

    expect(harness.controller.position.pixels, 0);
    expect(find.text('n102'), findsOneWidget);
  });
}
