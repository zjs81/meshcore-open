import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/l10n/app_localizations_en.dart';
import 'package:meshcore_open/models/message_filter.dart';
import 'package:meshcore_open/widgets/filtered_message_ghost.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ListView(children: [child])),
    ),
  );
}

void main() {
  group('FilteredMessageGhost', () {
    testWidgets('single message: copy, reason, tap target', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        FilteredMessageGhost(
          count: 1,
          reason: 'Filtered: repeated message',
          onTap: () => taps++,
        ),
      );

      expect(find.text('Hidden message · Tap to view'), findsOneWidget);
      expect(find.text('Filtered: repeated message'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byTooltip('Hidden by your message filter'), findsOneWidget);

      final inkWell = find.byType(InkWell);
      expect(tester.getSize(inkWell).height, greaterThanOrEqualTo(48));

      await tester.tap(find.byType(FilteredMessageGhost));
      expect(taps, 1);
    });

    testWidgets('expanded header offers one-tap collapse', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        FilteredMessageGhost(
          count: 4,
          reason: 'Filtered: repeated message',
          expanded: true,
          onTap: () => taps++,
        ),
      );

      expect(
        find.text('Showing 4 hidden messages · Tap to hide'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      await tester.tap(find.byType(FilteredMessageGhost));
      expect(taps, 1);

      await _pump(
        tester,
        FilteredMessageGhost(
          count: 1,
          reason: 'Filtered: repeated message',
          expanded: true,
          onTap: () {},
        ),
      );
      expect(find.text('Showing hidden message · Tap to hide'), findsOneWidget);
    });

    testWidgets('run: plural copy and semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        FilteredMessageGhost(
          count: 3,
          reason: 'Filtered: repeated characters',
          onTap: () {},
        ),
      );

      expect(find.text('3 hidden messages · Tap to view'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          '3 hidden messages · Tap to view. Filtered: repeated characters',
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byType(FilteredMessageGhost)),
        matchesSemantics(
          isButton: true,
          hasTapAction: true,
          label:
              '3 hidden messages · Tap to view. Filtered: repeated characters',
        ),
      );
      handle.dispose();
    });

    testWidgets('screen-reader tap reveals the run', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await _pump(
        tester,
        FilteredMessageGhost(count: 2, reason: 'r', onTap: () => taps++),
      );
      final node = tester.getSemantics(find.byType(FilteredMessageGhost));
      node.owner!.performAction(node.id, SemanticsAction.tap);
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('grows with the chat text scale', (tester) async {
      await _pump(
        tester,
        FilteredMessageGhost(count: 1, reason: 'r', onTap: () {}),
      );
      final small = tester.getSize(find.byType(InkWell)).height;
      await _pump(
        tester,
        FilteredMessageGhost(count: 1, reason: 'r', textScale: 2, onTap: () {}),
      );
      final large = tester.getSize(find.byType(InkWell)).height;
      expect(large, greaterThan(small));
    });
  });

  group('FilteredMessageBanner', () {
    testWidgets('shows the reason and both actions', (tester) async {
      var notSpam = 0;
      var hide = 0;
      await _pump(
        tester,
        FilteredMessageBanner(
          reason: 'Filtered: you marked this as spam',
          color: Colors.black,
          onNotSpam: () => notSpam++,
          onHide: () => hide++,
        ),
      );

      expect(find.text('Filtered: you marked this as spam'), findsOneWidget);
      await tester.tap(find.text('Not spam'));
      await tester.tap(find.text('Hide'));
      expect(notSpam, 1);
      expect(hide, 1);
      for (final label in ['Not spam', 'Hide']) {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byType(TextButton),
        );
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      }
    });
  });

  test('messageFilterReasonLabel covers every reason', () {
    final l10n = AppLocalizationsEn();
    expect(
      messageFilterReasonLabel(l10n, 'textRule', 'meshos'),
      'Filtered: matches "meshos"',
    );
    expect(
      messageFilterReasonLabel(l10n, 'senderRule', 'Bot'),
      'Filtered: sender "Bot"',
    );
    expect(
      messageFilterReasonLabel(l10n, 'crossSenderDuplicate', null),
      'Filtered: same message from several senders',
    );
    expect(
      messageFilterReasonLabel(l10n, 'unknown-reason', null),
      'Filtered: you marked this as spam',
    );
    final longPattern = 'Buy cheap radios now at example dot com today';
    final label = messageFilterReasonLabel(l10n, 'textRule', longPattern);
    expect(label, isNot(contains(longPattern)));
    expect(label, 'Filtered: matches "Buy cheap radios now at…"');
    expect(shortFilterDetail('a\n  b'), 'a b');
    for (final reason in FilterReason.values) {
      expect(
        messageFilterReasonLabel(l10n, filterReasonToJson(reason), 'x'),
        startsWith('Filtered:'),
      );
    }
  });

  group('FilteredMessageRun', () {
    Widget run({required bool expanded, bool reduceMotion = false}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: ListView(
              children: [
                FilteredMessageRun(
                  count: 2,
                  reason: 'Filtered: repeated message',
                  expanded: expanded,
                  onToggle: () {},
                  buildMessages: (_) => const [
                    SizedBox(height: 60, child: Text('first copy')),
                    SizedBox(height: 60, child: Text('second copy')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    double bodyHeight(WidgetTester tester) =>
        tester.getSize(find.byType(FilteredMessageRun)).height -
        tester.getSize(find.byType(FilteredMessageGhost)).height;

    testWidgets('animates open and closed in place', (tester) async {
      await tester.pumpWidget(run(expanded: false));
      expect(find.text('first copy'), findsNothing);
      expect(bodyHeight(tester), 0);

      await tester.pumpWidget(run(expanded: true));
      await tester.pump(filteredRunAnimationDuration ~/ 2);
      final midOpen = bodyHeight(tester);
      expect(midOpen, greaterThan(0));
      expect(midOpen, lessThan(120));
      await tester.pumpAndSettle();
      expect(bodyHeight(tester), closeTo(120, 0.01));
      expect(find.text('first copy'), findsOneWidget);
      expect(
        find.text('Showing 2 hidden messages · Tap to hide'),
        findsOneWidget,
      );

      await tester.pumpWidget(run(expanded: false));
      await tester.pump(filteredRunAnimationDuration ~/ 2);
      final midClose = bodyHeight(tester);
      expect(midClose, greaterThan(0));
      expect(midClose, lessThan(120));
      await tester.pumpAndSettle();
      expect(find.text('first copy'), findsNothing);
      expect(bodyHeight(tester), 0);
    });

    testWidgets('reduced motion switches instantly', (tester) async {
      await tester.pumpWidget(run(expanded: false, reduceMotion: true));
      await tester.pumpWidget(run(expanded: true, reduceMotion: true));
      await tester.pump();
      expect(bodyHeight(tester), closeTo(120, 0.01));
      await tester.pumpWidget(run(expanded: false, reduceMotion: true));
      await tester.pump();
      expect(bodyHeight(tester), 0);
    });
  });
}
