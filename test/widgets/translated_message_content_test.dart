import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/link_handler.dart';
import 'package:meshcore_open/models/custom_theme.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';
import 'package:meshcore_open/widgets/message_bubble_frame.dart';
import 'package:meshcore_open/widgets/translated_message_content.dart';

List<double> _renderedScaleFactors(WidgetTester tester) {
  final editables = tester
      .stateList<EditableTextState>(find.byType(EditableText))
      .map((s) => s.renderEditable.textScaler.scale(16) / 16)
      .toList();
  if (editables.isNotEmpty) return editables;
  return tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .map((p) => p.textScaler.scale(16) / 16)
      .toList();
}

Future<void> _pump(WidgetTester tester, TextScaler scaler) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: scaler),
        child: const Scaffold(
          body: TranslatedMessageContent(
            displayText: 'hello https://example.com at 37.7749, -122.4194',
            originalText: 'bonjour',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('message body follows the system text scale', (tester) async {
    await _pump(tester, TextScaler.noScaling);
    expect(_renderedScaleFactors(tester), everyElement(1.0));

    await _pump(tester, const TextScaler.linear(2));
    expect(_renderedScaleFactors(tester), everyElement(2.0));
  });

  testWidgets('original and translated text both scale', (tester) async {
    await _pump(tester, const TextScaler.linear(1.5));
    final factors = _renderedScaleFactors(tester);
    expect(factors, hasLength(2));
    expect(factors, everyElement(1.5));
  });

  testWidgets(
    'coordinate style meets WCAG AA contrast across light, dark, and custom themes',
    (tester) async {
      final customForest = CustomTheme(
        id: 'forest',
        name: 'Forest',
        background: const Color(0xFF0E1A13),
        accent: const Color(0xFF4ADE80),
      );
      final themes = [
        MeshTheme.light(),
        MeshTheme.dark(),
        MeshTheme.fromCustom(customForest),
      ];

      for (final theme in themes) {
        for (final isOutgoing in [false, true]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Builder(
                builder: (context) {
                  final colors = MessageBubbleColors.of(
                    context,
                    isOutgoing: isOutgoing,
                  );
                  final coordStyle = LinkHandler.defaultCoordinateStyle(
                    context,
                    TextStyle(color: colors.text, fontSize: 14),
                    backgroundColor: colors.background,
                  );
                  expect(coordStyle.decoration, TextDecoration.underline);
                  expect(
                    meshContrastRatio(coordStyle.color!, colors.background),
                    greaterThanOrEqualTo(4.5),
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        }
      }
    },
  );
}
