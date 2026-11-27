import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/message_filter.dart';
import 'package:meshcore_open/screens/filtered_messages_screen.dart';
import 'package:meshcore_open/screens/message_filter_rules_screen.dart';
import 'package:meshcore_open/screens/message_filter_settings_screen.dart';
import 'package:meshcore_open/services/message_filter/message_filter_service.dart';
import 'package:meshcore_open/storage/message_filter_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/widgets/filter_rule_dialog.dart';
import 'package:meshcore_open/widgets/mesh_nav_tile.dart';
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

  /// Opens the Rules page from the main page.
  Future<void> openRules(WidgetTester tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('messageFilter_rulesRow')));
    await tester.pumpAndSettle();
    expect(find.byType(MessageFilterRulesScreen), findsOneWidget);
  }

  testWidgets('renders every section with defaults', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Message Filter'), findsOneWidget);
    expect(
      find.text(
        "Hides spam and repeated messages in channels. It runs in the app "
        "only and doesn't affect your companion radio.",
      ),
      findsOneWidget,
    );
    expect(find.text('Filter Messages'), findsOneWidget);
    expect(find.text('Hide Completely'), findsOneWidget);
    expect(
      find.text('Hide filtered messages instead of showing a placeholder'),
      findsOneWidget,
    );
    expect(find.text('Filtered Messages (0)'), findsOneWidget);
    // Section headers are shown in upper case.
    expect(find.text('YOUR RULES'), findsOneWidget);
    expect(find.text('Rules (0)'), findsOneWidget);
    expect(
      find.text('Hide messages by word, phrase or sender name'),
      findsOneWidget,
    );
    expect(find.text('Repeated Messages'), findsOneWidget);
    expect(
      find.text('Sent again by one person, or by 3 or more people'),
      findsOneWidget,
    );
    expect(find.text('Sends to Count as a Repeat: 2'), findsOneWidget);
    expect(find.text('Repeated Characters'), findsOneWidget);
    expect(find.text('Learn from Spam Reports'), findsOneWidget);
    expect(find.text('0 marked as spam, 0 as not spam'), findsOneWidget);
    expect(find.text('Reset Learning'), findsOneWidget);
  });

  testWidgets('settings stay visible while Filter Messages is off', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('messageFilter_enabledSwitch')));
    await tester.pumpAndSettle();
    expect(service.settings.enabled, isFalse);
    expect(find.text('FILTERING'), findsOneWidget);
    for (final key in [
      'messageFilter_displayHide',
      'messageFilter_rulesRow',
      'messageFilter_duplicatesSwitch',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
  });

  testWidgets('repeat sends shows only while Repeated Messages is on', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(
      find.byKey(const ValueKey('messageFilter_repeatSends')),
      findsOneWidget,
    );

    expect(find.text('Sends to Count as a Repeat: 2'), findsOneWidget);
    final slider = find.descendant(
      of: find.byKey(const ValueKey('messageFilter_repeatSends')),
      matching: find.byType(Slider),
    );
    expect(tester.widget<Slider>(slider).min, 2);
    expect(tester.widget<Slider>(slider).max, 5);
    expect(tester.widget<Slider>(slider).divisions, 3);
    tester.widget<Slider>(slider).onChanged!(3);
    await tester.pumpAndSettle();
    expect(service.settings.repeatSends, 3);
    expect(find.text('Sends to Count as a Repeat: 3'), findsOneWidget);
    expect(
      find.text('One person, each send within 10 minutes of the last'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('messageFilter_duplicatesSwitch')),
    );
    await tester.pumpAndSettle();
    expect(service.settings.duplicates, isFalse);
    expect(
      find.byKey(const ValueKey('messageFilter_repeatSends')),
      findsNothing,
    );
    expect(service.settings.repeatSends, 3);
  });

  testWidgets('Rules row shows the count and opens the rules page', (
    tester,
  ) async {
    await service.addRule(
      const FilterRule(
        id: 'a',
        pattern: 'meshos',
        field: FilterRuleField.text,
        match: FilterRuleMatch.contains,
      ),
    );
    await service.addRule(
      const FilterRule(
        id: 'b',
        pattern: 'Bot',
        field: FilterRuleField.sender,
        match: FilterRuleMatch.exact,
      ),
    );
    await pumpScreen(tester);
    expect(find.text('Rules (2)'), findsOneWidget);
    // The rules themselves are on their own page.
    expect(find.text('meshos'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('messageFilter_rulesRow')));
    await tester.pumpAndSettle();
    expect(find.byType(MessageFilterRulesScreen), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('meshos'), findsOneWidget);
    expect(find.text('Bot'), findsOneWidget);
    expect(find.text('Sender name · Exact'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await service.removeRule('b');
    await tester.pumpAndSettle();
    expect(find.text('Rules (1)'), findsOneWidget);
  });

  testWidgets('empty rules page shows the empty state', (tester) async {
    await openRules(tester);
    expect(find.text('No rules yet'), findsOneWidget);
    expect(
      find.text(
        'Add a word, phrase or sender name to hide messages that match it',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('messageFilter_addRuleButton')),
      findsOneWidget,
    );
    expect(find.byTooltip('Search rules'), findsNothing);
    expect(find.byTooltip('Select rules'), findsNothing);
  });

  testWidgets('switches and display choice update the service', (tester) async {
    await pumpScreen(tester);

    final hideSwitch = find.byKey(const ValueKey('messageFilter_displayHide'));
    await tester.tap(hideSwitch);
    await tester.pumpAndSettle();
    expect(service.settings.displayMode, FilterDisplayMode.hide);
    await tester.tap(hideSwitch);
    await tester.pumpAndSettle();
    expect(service.settings.displayMode, FilterDisplayMode.placeholder);

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
    await openRules(tester);

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
    expect(find.text('meshos promo'), findsOneWidget);
  });

  testWidgets('cancelling the dialog adds nothing', (tester) async {
    await openRules(tester);
    await tester.tap(find.byKey(const ValueKey('messageFilter_addRuleButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'spam');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.rules, isEmpty);
  });

  group('Rules search and selection', () {
    final addButton = find.byKey(const ValueKey('messageFilter_addRuleButton'));
    final bulkDelete = find.descendant(
      of: find.byType(AppBar),
      matching: find.widgetWithIcon(IconButton, Icons.delete_outline),
    );
    Finder ruleRow(String id) => find.byKey(ValueKey('messageFilter_rule_$id'));
    List<String> ruleIds() => service.rules.map((r) => r.id).toList();

    /// Adds rules with ids r0, r1, ... in order.
    Future<void> addRules(List<String> patterns) async {
      for (var i = 0; i < patterns.length; i++) {
        await service.addRule(FilterRule(id: 'r$i', pattern: patterns[i]));
      }
    }

    bool searchFocused(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus;

    Future<void> search(WidgetTester tester, String query) async {
      await tester.tap(find.byTooltip('Search rules'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();
    }

    testWidgets('search filters rules; back closes it before the page', (
      tester,
    ) async {
      await addRules(['Meshos promo', 'Spam Bot', 'cheap radios']);
      await openRules(tester);
      final semantics = tester.ensureSemantics();
      final delete = find.descendant(
        of: ruleRow('r0'),
        matching: find.byTooltip('Delete'),
      );
      expect(
        tester.getSemantics(delete),
        isSemantics(label: 'Meshos promo', tooltip: 'Delete'),
      );
      expect(
        tester.getSemantics(
          find.descendant(of: ruleRow('r0'), matching: find.byType(Switch)),
        ),
        isSemantics(label: 'Meshos promo'),
      );
      semantics.dispose();

      await tester.tap(find.byTooltip('Search rules'));
      await tester.pumpAndSettle();
      expect(searchFocused(tester), isTrue);
      await tester.enterText(find.byType(TextField), 'SPAM');
      await tester.pumpAndSettle();
      expect(find.text('Spam Bot'), findsOneWidget);
      expect(find.text('Meshos promo'), findsNothing);
      expect(find.text('cheap radios'), findsNothing);
      expect(find.byTooltip('Select rules'), findsNothing);
      expect(addButton, findsNothing);

      await tester.enterText(find.byType(TextField), 'antenna');
      await tester.pumpAndSettle();
      expect(find.text('No matching rules'), findsOneWidget);
      expect(
        find.text('Try a different word or check the spelling'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search_off), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MessageFilterRulesScreen), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Meshos promo'), findsOneWidget);
      expect(addButton, findsOneWidget);

      await search(tester, 'cheap');
      await tester.tap(find.byTooltip('Close search'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Spam Bot'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MessageFilterRulesScreen), findsNothing);
    });

    testWidgets('select button starts selection; back leaves it first', (
      tester,
    ) async {
      await addRules(['Meshos promo', 'Spam Bot']);
      await openRules(tester);

      await tester.tap(find.byTooltip('Select rules'));
      await tester.pumpAndSettle();
      expect(find.text('0 selected'), findsOneWidget);
      expect(addButton, findsNothing);
      expect(tester.widget<IconButton>(bulkDelete).onPressed, isNull);
      // Row switches and delete buttons are off, so taps select.
      for (final s in tester.widgetList<Switch>(find.byType(Switch))) {
        expect(s.onChanged, isNull);
      }
      expect(
        tester
            .widget<IconButton>(
              find.descendant(
                of: ruleRow('r0'),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );

      // A tap selects instead of opening the editor.
      await tester.tap(find.text('Spam Bot'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Edit rule'), findsNothing);
      expect(
        find.descendant(
          of: ruleRow('r1'),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      final semantics = tester.ensureSemantics();
      expect(tester.getSemantics(ruleRow('r1')), isSemantics(isSelected: true));
      semantics.dispose();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.textContaining('selected'), findsNothing);
      expect(find.byType(MessageFilterRulesScreen), findsOneWidget);
      expect(addButton, findsOneWidget);
      expect(bulkDelete, findsNothing);
    });

    testWidgets('long-press, Select all in a search, delete and Undo', (
      tester,
    ) async {
      await addRules(['promo one', 'Spam Bot', 'promo two', 'other']);
      await openRules(tester);
      await search(tester, 'promo');

      await tester.longPress(find.text('promo one'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(addButton, findsNothing);

      // Back leaves selection and keeps the search, with the keyboard closed.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.textContaining('selected'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(searchFocused(tester), isFalse);
      expect(find.text('Spam Bot'), findsNothing);

      await tester.longPress(find.text('promo one'));
      await tester.pumpAndSettle();

      // One selected rule also asks; system Back closes only the dialog.
      await tester.tap(bulkDelete);
      await tester.pumpAndSettle();
      expect(
        find.text('Delete 1 rule from the message filter?'),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Delete rules?'), findsNothing);
      expect(ruleIds(), ['r0', 'r1', 'r2', 'r3']);
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byTooltip('Select all'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);

      // Delete asks first; Cancel keeps the rules and the selection.
      await tester.tap(bulkDelete);
      await tester.pumpAndSettle();
      expect(find.text('Delete rules?'), findsOneWidget);
      expect(
        find.text('Delete 2 rules from the message filter?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(ruleIds(), ['r0', 'r1', 'r2', 'r3']);
      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(bulkDelete);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(ruleIds(), ['r1', 'r3']);
      expect(find.text('2 rules deleted'), findsOneWidget);
      expect(find.textContaining('selected'), findsNothing);
      expect(find.text('No matching rules'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(ruleIds(), ['r0', 'r1', 'r2', 'r3']);
      expect(find.text('promo one'), findsOneWidget);
      expect(find.text('promo two'), findsOneWidget);
    });

    testWidgets('bulk Turn off and Turn on with Undo', (tester) async {
      await addRules(['alpha', 'beta', 'gamma']);
      await service.updateRule(service.rules[2].copyWith(enabled: false));
      await openRules(tester);
      List<bool> enabled() => service.rules.map((r) => r.enabled).toList();

      Future<void> selectAndOpenMenu(List<String> patterns) async {
        await tester.tap(find.byTooltip('Select rules'));
        await tester.pumpAndSettle();
        for (final pattern in patterns) {
          await tester.tap(find.text(pattern));
        }
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('More options'));
        await tester.pumpAndSettle();
      }

      await selectAndOpenMenu(['alpha', 'beta']);
      // Both are on already.
      expect(
        tester
            .widget<PopupMenuItem<void>>(
              find.ancestor(
                of: find.text('Turn on'),
                matching: find.byType(PopupMenuItem<void>),
              ),
            )
            .enabled,
        isFalse,
      );
      await tester.tap(find.text('Turn off'));
      await tester.pumpAndSettle();
      expect(enabled(), [false, false, false]);
      expect(find.text('2 rules turned off'), findsOneWidget);
      expect(find.textContaining('selected'), findsNothing);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(enabled(), [true, true, false]);

      await selectAndOpenMenu(['beta', 'gamma']);
      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();
      expect(enabled(), [true, true, true]);
      expect(find.text('1 rule turned on'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(enabled(), [true, true, false]);
    });

    testWidgets('edit and add offer Undo', (tester) async {
      await addRules(['meshos']);
      await openRules(tester);

      await tester.tap(find.text('meshos'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'meshos promo');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(service.rules.single.pattern, 'meshos promo');
      expect(find.text('Rule saved'), findsOneWidget);
      // Turned off after the edit: Undo keeps it off.
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(service.rules.single.pattern, 'meshos');
      expect(service.rules.single.enabled, isFalse);
      expect(find.text('meshos'), findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'spam');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(service.rules.map((r) => r.pattern), ['meshos', 'spam']);
      expect(find.text('Rule saved'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(service.rules.map((r) => r.pattern), ['meshos']);
      expect(find.text('spam'), findsNothing);
    });
  });

  testWidgets('reset learning asks first and clears examples', (tester) async {
    await pumpScreen(tester);
    // Disabled with no examples.
    expect(
      tester
          .widget<MeshNavTile>(
            find.byKey(const ValueKey('messageFilter_resetLearning')),
          )
          .onTap,
      isNull,
    );
    expect(find.text('Nothing learned yet'), findsOneWidget);

    await service.markSpam(sender: 'Bot', text: 'Buy cheap radios now');
    await service.markNotSpam(
      channelId: 'c',
      sender: 'Ann',
      text: 'See you at the meetup',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 marked as spam, 1 as not spam'), findsOneWidget);
    expect(
      find.text(
        'Forget everything learned from messages marked as spam and recent '
        'messages',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('messageFilter_resetLearning')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.spamExampleCount, 1);

    await tester.tap(find.byKey(const ValueKey('messageFilter_resetLearning')));
    await tester.pumpAndSettle();
    expect(find.text('Reset Learning'), findsNWidgets(2));
    expect(
      find.text(
        'Forget everything the filter has learned? Your rules are kept.',
      ),
      findsOneWidget,
    );
    final confirm = find.widgetWithText(FilledButton, 'Reset');
    final context = tester.element(confirm);
    expect(
      tester.widget<FilledButton>(confirm).style?.backgroundColor?.resolve({}),
      Theme.of(context).colorScheme.error,
    );
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(service.spamExampleCount, 0);
    expect(service.notSpamExampleCount, 0);
    expect(find.text('0 marked as spam, 0 as not spam'), findsOneWidget);
    expect(find.text('Nothing learned yet'), findsOneWidget);
    // Disabled, so it drops the error colour (design.md).
    final reset = tester.widget<MeshNavTile>(
      find.byKey(const ValueKey('messageFilter_resetLearning')),
    );
    expect(reset.onTap, isNull);
    expect(reset.titleColor, isNull);
    expect(reset.iconColor, isNull);
  });

  testWidgets('undo puts a deleted rule back in its place', (tester) async {
    for (final (id, pattern) in [('a', 'first'), ('b', 'second')]) {
      await service.addRule(
        FilterRule(
          id: id,
          pattern: pattern,
          field: FilterRuleField.text,
          match: FilterRuleMatch.contains,
        ),
      );
    }
    await openRules(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('messageFilter_rule_a')),
        matching: find.byTooltip('Delete'),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.rules.map((r) => r.id), ['b']);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(service.rules.map((r) => r.id), ['a', 'b']);
  });

  testWidgets('filtered messages tile opens the empty list', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Filtered Messages (0)'));
    await tester.pumpAndSettle();
    expect(find.byType(FilteredMessagesScreen), findsOneWidget);
    expect(find.text('No filtered messages'), findsOneWidget);
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
