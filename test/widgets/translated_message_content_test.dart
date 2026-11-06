import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/widgets/translated_message_content.dart';

double _renderedScaleFactor(WidgetTester tester) {
  final linkify = find.byType(Linkify);
  if (linkify.evaluate().isNotEmpty) {
    return tester.widget<Linkify>(linkify.first).textScaleFactor;
  }
  return tester
      .widget<SelectableLinkify>(find.byType(SelectableLinkify).first)
      .textScaleFactor;
}

Future<void> _pump(WidgetTester tester, TextScaler scaler) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: scaler),
        child: const Scaffold(
          body: TranslatedMessageContent(
            displayText: 'hello https://example.com',
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
    expect(_renderedScaleFactor(tester), 1.0);

    await _pump(tester, const TextScaler.linear(2));
    expect(_renderedScaleFactor(tester), 2.0);
  });

  testWidgets('original and translated text both scale', (tester) async {
    await _pump(tester, const TextScaler.linear(1.5));
    final factors = [
      ...tester
          .widgetList<Linkify>(find.byType(Linkify))
          .map((w) => w.textScaleFactor),
      ...tester
          .widgetList<SelectableLinkify>(find.byType(SelectableLinkify))
          .map((w) => w.textScaleFactor),
    ];
    expect(factors, hasLength(2));
    expect(factors, everyElement(1.5));
  });
}
