import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/widgets/filter_rule_dialog.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('floating label is not clipped with keyboard (scale $scale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(scale),
                viewInsets: const EdgeInsets.only(bottom: 150),
              ),
              child: child!,
            );
          },
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFilterRuleDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final scrollRect = tester.getRect(find.byType(SingleChildScrollView));
      final labelRect = tester.getRect(find.byType(InputDecorator));
      // The floating label sits above the field box; the scroll viewport must
      // start above the field with room for it.
      final fieldTop = labelRect.top;
      expect(fieldTop - scrollRect.top, greaterThanOrEqualTo(8 * scale));
    });
  }
}
