import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshcore_open/widgets/sync_progress_overlay.dart';

// The shared top progress bar: 4px, theme colours, keeps its height idle.
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

  test('app bar versions are 4px tall', () {
    expect(const MeshProgressAppBarBottom().preferredSize.height, 4);
    expect(const SyncProgressAppBarBottom().preferredSize.height, 4);
  });
}
