import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/utf8_length_limiter.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/widgets/marker_label_dialog.dart';

/// Pumps a button that opens the dialog and records what it returns.
Future<List<String?>> _open(
  WidgetTester tester, {
  String defaultLabel = 'Camp',
}) async {
  final results = <String?>[];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              results.add(
                await showMarkerLabelDialog(
                  context,
                  lat: 47.5,
                  lon: -122.25,
                  defaultLabel: defaultLabel,
                  flags: 'poi',
                  confirmText: 'Share',
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  group('marker label helpers', () {
    test('sanitizeMarkerLabel replaces the field separator and newlines', () {
      expect(sanitizeMarkerLabel(' Camp | north\nside '), 'Camp / north side');
    });

    test('formatMarkerText cannot be split by a label', () {
      expect(
        formatMarkerText(1.5, -2.25, 'a|b', 'poi'),
        'm:1.500000,-2.250000|a/b|poi',
      );
    });

    test('label budget keeps the whole marker within both limits', () {
      final budget = markerLabelByteBudget(-90, -180, 'poi');
      final marker = formatMarkerText(-90, -180, 'x' * budget, 'poi');
      expect(budget, greaterThan(0));
      expect(utf8ByteLength(marker), lessThanOrEqualTo(127));
    });

    test('hasShareableLocation rejects missing and 0,0 positions', () {
      expect(hasShareableLocation(null, 10), isFalse);
      expect(hasShareableLocation(0, 0), isFalse);
      expect(hasShareableLocation(91, 0), isFalse);
      expect(hasShareableLocation(47.5, -122.25), isTrue);
    });
  });

  group('MarkerLabelDialog', () {
    testWidgets('confirm returns the sanitised label', (tester) async {
      final results = await _open(tester);
      await tester.enterText(find.byType(TextField), 'Camp | north');
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(results, ['Camp / north']);
    });

    testWidgets('keyboard Send submits, and empty falls back to default', (
      tester,
    ) async {
      final results = await _open(tester, defaultLabel: 'Home');
      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(results, ['Home']);
    });

    testWidgets('cancel returns null', (tester) async {
      final results = await _open(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results, [null]);
    });

    testWidgets('input is limited to the byte budget', (tester) async {
      final budget = markerLabelByteBudget(47.5, -122.25, 'poi');
      final results = await _open(tester);
      await tester.enterText(find.byType(TextField), 'y' * (budget + 50));
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(utf8ByteLength(results.single!), lessThanOrEqualTo(budget));
    });
  });
}
