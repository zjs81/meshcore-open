import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';

Widget _segments(double width, List<String> labels) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (var i = 0; i < labels.length; i++)
                ButtonSegment(value: i, label: MeshSegmentLabel(labels[i])),
            ],
            selected: const {0},
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('short labels lay out on one line at full size', (tester) async {
    await tester.pumpWidget(_segments(360, ['Auto', 'Flood', 'Manual']));
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Flood'), findsOneWidget);
  });

  testWidgets('long labels in narrow segments do not overflow', (tester) async {
    await tester.pumpWidget(
      _segments(240, [
        'Padrão do sistema',
        'Inundação',
        'Automatisch',
        'Manual',
      ]),
    );
    expect(tester.takeException(), isNull);
    final labels = find.byType(MeshSegmentLabel);
    final multi = tester.getSize(labels.at(0));
    final longWord = tester.getSize(labels.at(1));
    final single = tester.getSize(labels.at(3));
    // The multi-word label wraps at its space instead of shrinking further;
    // a single long word stays on one line.
    expect(multi.height, greaterThan(single.height));
    expect(longWord.height, lessThanOrEqualTo(single.height));
    for (var i = 0; i < 4; i++) {
      final box = tester.renderObject<RenderBox>(labels.at(i));
      final parent = box.parent! as RenderBox;
      expect(box.size.width, lessThanOrEqualTo(parent.size.width));
    }
  });

  testWidgets('a colour-only style change reaches the painted text', (
    tester,
  ) async {
    Widget label(Color color) => MaterialApp(
      home: Center(
        child: DefaultTextStyle(
          style: TextStyle(fontSize: 14, color: color),
          child: const MeshSegmentLabel('Flood'),
        ),
      ),
    );
    Color? painted() =>
        (tester.renderObject(find.byType(MeshSegmentLabel)) as dynamic)
                .debugPaintedColor
            as Color?;

    await tester.pumpWidget(label(const Color(0xFF112233)));
    expect(painted(), const Color(0xFF112233));
    await tester.pumpWidget(label(const Color(0xFFEEDDCC)));
    expect(painted(), const Color(0xFFEEDDCC));
  });
}
