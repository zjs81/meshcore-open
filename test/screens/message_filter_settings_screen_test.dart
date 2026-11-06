import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/message_filter.dart';
import 'package:meshcore_open/screens/filtered_messages_screen.dart';
import 'package:meshcore_open/screens/message_filter_settings_screen.dart';
import 'package:meshcore_open/services/message_filter/message_filter_service.dart';
import 'package:meshcore_open/storage/message_filter_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/widgets/filter_rule_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MessageFilterService service;
  late MeshCoreConnector connector;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    service = MessageFilterService(
      store: MessageFilterStore(),
      trainer: MessageFilterService.trainInline,
    );
    await service.load();
    connector = MeshCoreConnector();
  });

  tearDown(() {
    service.dispose();
    connector.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // Tall enough that every section is laid out without scrolling.
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
          ChangeNotifierProvider<MessageFilterService>.value(value: service),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MessageFilterSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders every section with defaults', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Message filter'), findsOneWidget);
    expect(find.text('Filter messages'), findsOneWidget);
    expect(find.text('Show a small placeholder'), findsOneWidget);
    expect(find.text('Hide completely'), findsOneWidget);
    expect(
      find.text('Hidden messages stay in the Filtered messages list.'),
      findsOneWidget,
    );
    expect(find.text('Filtered messages (0)'), findsOneWidget);
    expect(
      find.text(
        'No rules yet. Add a word, phrase or sender name to hide messages '
        'that match it.',
      ),
      findsOneWidget,
    );
    expect(find.text('Repeated messages'), findsOneWidget);
    expect(find.text('Repeated characters'), findsOneWidget);
    expect(find.text('Learn from Spam taps'), findsOneWidget);
    expect(find.text('0 spam and 0 not-spam examples'), findsOneWidget);
  });

  testWidgets('switches and display choice update the service', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('messageFilter_enabledSwitch')));
    await tester.pumpAndSettle();
    expect(service.settings.enabled, isFalse);

    await tester.tap(find.byKey(const ValueKey('messageFilter_displayHide')));
    await tester.pumpAndSettle();
    expect(service.settings.displayMode, FilterDisplayMode.hide);

    await tester.tap(
      find.byKey(const ValueKey('messageFilter_duplicatesSwitch')),
    );
    await tester.tap(
      find.byKey(const ValueKey('messageFilter_repeatedCharactersSwitch')),
    );
    await tester.tap(
      find.byKey(const ValueKey('messageFilter_learningSwitch')),
    );
    await tester.pumpAndSettle();
    expect(service.settings.duplicates, isFalse);
    expect(service.settings.repeatedCharacters, isFalse);
    expect(service.settings.learning, isFalse);
  });

  testWidgets('add, edit and delete a rule with undo', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('messageFilter_addRuleButton')));
    await tester.pumpAndSettle();
    expect(find.text('Add rule'), findsWidgets);

    // Save stays disabled until something is typed.
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  meshos  ');
    await tester.tap(find.byKey(const ValueKey('filterRuleField_both')));
    await tester.tap(find.byKey(const ValueKey('filterRuleMatch_wholeWord')));
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(service.rules, hasLength(1));
    final rule = service.rules.single;
    expect(rule.pattern, 'meshos');
    expect(rule.field, FilterRuleField.both);
    expect(rule.match, FilterRuleMatch.wholeWord);
    expect(rule.enabled, isTrue);
    expect(find.text('meshos'), findsOneWidget);
    expect(find.text('Both · Whole word'), findsOneWidget);
    expect(find.text('Rule saved'), findsOneWidget);

    // Turn it off from the list.
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey('messageFilter_rule_${rule.id}')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.rules.single.enabled, isFalse);

    // Tap the row to edit; the id and enabled state are kept.
    await tester.tap(find.text('meshos'));
    await tester.pumpAndSettle();
    expect(find.text('Edit rule'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'meshos promo');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(service.rules.single.id, rule.id);
    expect(service.rules.single.pattern, 'meshos promo');
    expect(service.rules.single.enabled, isFalse);

    // Delete, then undo.
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(service.rules, isEmpty);
    expect(find.text('Rule deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(service.rules.single.pattern, 'meshos promo');
  });

  testWidgets('cancelling the dialog adds nothing', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('messageFilter_addRuleButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'spam');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.rules, isEmpty);
  });

  testWidgets('reset learning asks first and clears examples', (tester) async {
    await service.markSpam(sender: 'Bot', text: 'Buy cheap radios now');
    await service.markNotSpam(
      channelId: 'c',
      sender: 'Ann',
      text: 'See you at the meetup',
    );
    await pumpScreen(tester);
    expect(find.text('1 spam and 1 not-spam examples'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('messageFilter_resetLearning')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.spamExampleCount, 1);

    await tester.tap(find.byKey(const ValueKey('messageFilter_resetLearning')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset learning'));
    await tester.pumpAndSettle();
    expect(service.spamExampleCount, 0);
    expect(service.notSpamExampleCount, 0);
    expect(find.text('0 spam and 0 not-spam examples'), findsOneWidget);
  });

  testWidgets('filtered messages tile opens the empty list', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Filtered messages (0)'));
    await tester.pumpAndSettle();
    expect(find.byType(FilteredMessagesScreen), findsOneWidget);
    expect(find.text('Nothing has been filtered.'), findsOneWidget);
  });

  testWidgets('dialog prefills a new rule from a message', (tester) async {
    FilterRule? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showFilterRuleDialog(
                  context,
                  initialPattern: ' Bot ',
                  initialField: FilterRuleField.sender,
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
    expect(find.text('Bot'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result?.pattern, 'Bot');
    expect(result?.field, FilterRuleField.sender);
    expect(result?.match, FilterRuleMatch.contains);
    expect(result?.id, isNotEmpty);
  });
}
