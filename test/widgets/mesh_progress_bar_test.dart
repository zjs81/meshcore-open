import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshcore_open/widgets/sync_progress_overlay.dart';

// The shared top progress bar: 4px, theme colours, keeps its height idle,
// stays for a minimum time and fades out.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Column(children: [child])),
  );

  testWidgets('idle bar keeps its 4px height and draws nothing', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MeshProgressBar(active: false)));
    expect(tester.getSize(find.byType(MeshProgressBar)).height, 4);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('active bar fills with the theme colour', (tester) async {
    await tester.pumpWidget(host(const MeshProgressBar(value: 0.5)));
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.5);
    expect(bar.minHeight, 4);
    expect(bar.color, isNull);
    expect(bar.backgroundColor, isNull);
  });

  final indicator = find.byType(LinearProgressIndicator);
  // The fade ends on the first frame after MeshProgressBar.fadeOut.
  final pastFade = MeshProgressBar.fadeOut + const Duration(milliseconds: 50);
  double opacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find.descendant(
          of: find.byType(MeshProgressBar),
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity
      .value;

  testWidgets('a quick task keeps the bar for the minimum time, then fades', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MeshProgressBar()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(host(const MeshProgressBar(active: false)));
    expect(indicator, findsOneWidget);
    expect(opacity(tester), 1);

    // 50ms short of the minimum time.
    await tester.pump(
      MeshProgressBar.minVisible - const Duration(milliseconds: 150),
    );
    expect(opacity(tester), 1);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(MeshProgressBar.fadeOut ~/ 2);
    expect(opacity(tester), inExclusiveRange(0, 1));
    await tester.pump(pastFade);
    expect(indicator, findsNothing);
    expect(tester.getSize(find.byType(MeshProgressBar)).height, 4);
  });

  testWidgets('a long task fades out as soon as it ends', (tester) async {
    await tester.pumpWidget(host(const MeshProgressBar()));
    await tester.pump(const Duration(seconds: 2));
    // Past the minimum time, but the task is still running.
    expect(opacity(tester), 1);
    await tester.pumpWidget(host(const MeshProgressBar(active: false)));
    await tester.pump(pastFade);
    expect(indicator, findsNothing);
  });

  testWidgets('a task restarting within the minimum time keeps its start', (
    tester,
  ) async {
    final step = MeshProgressBar.minVisible ~/ 5;
    await tester.pumpWidget(host(const MeshProgressBar()));
    await tester.pump(step);
    await tester.pumpWidget(host(const MeshProgressBar(active: false)));
    await tester.pump(step);
    await tester.pumpWidget(host(const MeshProgressBar()));
    await tester.pump(step);
    await tester.pumpWidget(host(const MeshProgressBar(active: false)));
    // Counted from the first show, the minimum has passed, so the fade runs.
    await tester.pump(step * 3);
    await tester.pump(MeshProgressBar.fadeOut ~/ 2);
    expect(opacity(tester), lessThan(1));
  });

  testWidgets('a task starting during the fade gets the minimum time again', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MeshProgressBar()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(host(const MeshProgressBar(active: false)));
    await tester.pump(MeshProgressBar.fadeOut ~/ 2);
    expect(opacity(tester), lessThan(1));

    // A quick task during the fade: the bar comes back for the minimum time.
    await tester.pumpWidget(host(const MeshProgressBar()));
    await tester.pump();
    expect(opacity(tester), 1);
    await tester.pumpWidget(host(const MeshProgressBar(active: false)));
    await tester.pump(
      MeshProgressBar.minVisible - const Duration(milliseconds: 50),
    );
    expect(opacity(tester), 1);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(pastFade);
    expect(indicator, findsNothing);
  });

  testWidgets('the bar follows the progress while active', (tester) async {
    await tester.pumpWidget(host(const MeshProgressBar(value: 0.2)));
    await tester.pumpWidget(host(const MeshProgressBar(value: 0.6)));
    expect(tester.widget<LinearProgressIndicator>(indicator).value, 0.6);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the bar keeps the last progress while it fades', (tester) async {
    await tester.pumpWidget(host(const MeshProgressBar(value: 0.7)));
    await tester.pumpWidget(host(const MeshProgressBar(active: false)));
    expect(tester.widget<LinearProgressIndicator>(indicator).value, 0.7);
    await tester.pumpWidget(const SizedBox());
  });

  test('app bar versions are 4px tall', () {
    expect(const MeshProgressAppBarBottom().preferredSize.height, 4);
    expect(const SyncProgressAppBarBottom().preferredSize.height, 4);
  });
}
