import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/screens/filtered_messages_screen.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves a fixed filtered list and records what the screen sends.
class _FakeConnector extends MeshCoreConnector {
  final List<(Channel, ChannelMessage)> entries;
  final List<String> calls = [];
  bool connected = true;

  _FakeConnector(this.entries);

  @override
  bool get isConnected => connected;

  @override
  List<(Channel, ChannelMessage)> recentFilteredChannelMessages({
    int limit = 200,
  }) => List.of(entries);

  @override
  Future<void> markChannelMessageNotSpam(
    Channel channel,
    ChannelMessage message,
  ) async {
    calls.add('notSpam ${message.senderName}');
    _remove([message]);
  }

  @override
  Future<void> markChannelMessagesNotSpam(
    List<(Channel, ChannelMessage)> items,
  ) async {
    calls.add('notSpamMany ${items.map((e) => e.$2.senderName).join(',')}');
    _remove(items.map((e) => e.$2));
  }

  @override
  Future<int> deleteChannelMessages(Iterable<ChannelMessage> messages) async {
    final list = messages.toList();
    calls.add('delete ${list.map((m) => m.senderName).join(',')}');
    _remove(list);
    return list.length;
  }

  // No notifyListeners: the screen rebuilds after a send, and the real
  // notify is debounced by a timer that would outlive the test.
  void _remove(Iterable<ChannelMessage> messages) {
    final ids = {for (final m in messages) m.messageId};
    entries.removeWhere((e) => ids.contains(e.$2.messageId));
  }
}

(Channel, ChannelMessage) _entry(
  int index,
  String channel,
  String sender,
  String text, {
  String reason = 'manual',
  String? detail,
}) => (
  Channel(
    index: index,
    name: channel,
    psk: Uint8List.fromList(List.filled(16, index)),
  ),
  ChannelMessage(
    senderName: sender,
    text: text,
    timestamp: DateTime.now().subtract(Duration(minutes: index)),
    isOutgoing: false,
    channelIndex: index,
    filterReason: reason,
    filterDetail: detail,
  ),
);

Finder _row(String channel) => find.ancestor(
  of: find.text(channel),
  matching: find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('filtered_'),
  ),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<_FakeConnector> openScreen(
    WidgetTester tester, {
    bool connected = true,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final connector = _FakeConnector([
      _entry(
        1,
        'Alpha',
        'Bob',
        'Cheap crypto here',
        reason: 'textRule',
        detail: 'cheap crypto here and everywhere',
      ),
      _entry(2, 'Bravo', 'Dave', 'Hello there'),
      _entry(3, 'Charlie', 'Carol', 'Free crypto tokens'),
    ])..connected = connected;
    addTearDown(connector.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<MeshCoreConnector>.value(
        value: connector,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const FilteredMessagesScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return connector;
  }

  Future<void> search(WidgetTester tester, String query) async {
    if (find.byType(TextField).evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Search messages'));
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }

  Future<void> tapRowNotSpam(WidgetTester tester, String channel) async {
    await tester.tap(
      find.descendant(of: _row(channel), matching: find.text('Not spam')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, List<String> channels) async {
    await tester.longPress(find.text(channels.first));
    await tester.pumpAndSettle();
    for (final channel in channels.skip(1)) {
      await tester.tap(find.text(channel));
      await tester.pumpAndSettle();
    }
  }

  Future<void> waitForTimeout(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  void expectRows(List<String> shown, List<String> hidden) {
    for (final channel in shown) {
      expect(find.text(channel), findsOneWidget, reason: channel);
    }
    for (final channel in hidden) {
      expect(find.text(channel), findsNothing, reason: channel);
    }
  }

  testWidgets('rows show sender and text; a tap on the text selects', (
    tester,
  ) async {
    await openScreen(tester);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Cheap crypto here'), findsOneWidget);
    expect(find.text('Hidden message · Tap to view'), findsNothing);
    // The message is shown, so the rule pattern is not shortened.
    expect(
      find.text('Filtered: matches "cheap crypto here and everywhere"'),
      findsOneWidget,
    );

    // A tap outside selection changes nothing.
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('Cheap crypto here'), findsOneWidget);
    expect(find.textContaining('selected'), findsNothing);
    // Text can be copied outside selection only.
    expect(find.byType(SelectableText), findsNWidgets(3));

    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsNothing);
    await tester.tap(find.text('Free crypto tokens'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    // The check circle beside a card toggles its row too.
    await tester.tap(find.byIcon(Icons.radio_button_unchecked));
    await tester.pumpAndSettle();
    expect(find.text('3 selected'), findsOneWidget);
    // Screen readers still get one selectable, tappable node per row.
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text('Cheap crypto here')),
      isSemantics(hasSelectedState: true, isSelected: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  group('search', () {
    testWidgets('matches message text, sender and channel', (tester) async {
      await openScreen(tester);

      await search(tester, 'CHEAP');
      expectRows(['Alpha'], ['Bravo', 'Charlie']);

      await search(tester, 'carol');
      expectRows(['Charlie'], ['Alpha', 'Bravo']);

      await search(tester, 'brav');
      expectRows(['Bravo'], ['Alpha', 'Charlie']);
    });

    testWidgets('shows a no results state', (tester) async {
      await openScreen(tester);
      await search(tester, 'nothing like this');
      expectRows([], ['Alpha', 'Bravo', 'Charlie']);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No matching messages'), findsOneWidget);
    });

    testWidgets('back and the back arrow close the search, not the page', (
      tester,
    ) async {
      await openScreen(tester);

      await search(tester, 'cheap');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(FilteredMessagesScreen), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expectRows(['Alpha', 'Bravo', 'Charlie'], []);

      await search(tester, 'cheap');
      await tester.tap(find.byTooltip('Close search'));
      await tester.pumpAndSettle();
      expect(find.byType(FilteredMessagesScreen), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expectRows(['Alpha', 'Bravo', 'Charlie'], []);
    });

    testWidgets('leaving selection keeps the keyboard closed', (tester) async {
      await openScreen(tester);
      bool focused() =>
          tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus;

      await tester.tap(find.byTooltip('Search messages'));
      await tester.pumpAndSettle();
      expect(focused(), isTrue);

      await tester.longPress(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.textContaining('selected'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(focused(), isFalse);
    });

    testWidgets('select all selects only the matching rows', (tester) async {
      final connector = await openScreen(tester);
      await search(tester, 'crypto');
      await select(tester, ['Alpha']);
      await tester.tap(find.byTooltip('Select all'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.byTooltip('Not spam'));
      await tester.pumpAndSettle();
      await waitForTimeout(tester);
      expect(connector.calls, ['notSpamMany Bob,Carol']);
    });
  });

  testWidgets('offline: search and selection work, changes do not', (
    tester,
  ) async {
    final connector = await openScreen(tester, connected: false);
    final rowNotSpam = find.ancestor(
      of: find.descendant(of: _row('Alpha'), matching: find.text('Not spam')),
      matching: find.bySubtype<ButtonStyleButton>(),
    );
    expect(tester.widget<ButtonStyleButton>(rowNotSpam).enabled, isFalse);

    await search(tester, 'dave');
    expectRows(['Bravo'], ['Alpha', 'Charlie']);
    await select(tester, ['Bravo']);
    expect(find.text('1 selected'), findsOneWidget);
    for (final tooltip in ['Not spam', 'Delete']) {
      final button = find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(button).onPressed, isNull);
    }
    expect(connector.calls, isEmpty);
  });

  group('undo', () {
    testWidgets('Not spam on a row hides it until Undo', (tester) async {
      final connector = await openScreen(tester);
      await tapRowNotSpam(tester, 'Alpha');
      expectRows(['Bravo', 'Charlie'], ['Alpha']);
      expect(find.text('Marked as not spam'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expectRows(['Alpha', 'Bravo', 'Charlie'], []);
      await waitForTimeout(tester);
      expect(connector.calls, isEmpty);
    });

    testWidgets('Not spam is sent when the snackbar times out', (tester) async {
      final connector = await openScreen(tester);
      await tapRowNotSpam(tester, 'Alpha');
      expect(connector.calls, isEmpty);

      await waitForTimeout(tester);
      expect(connector.calls, ['notSpam Bob']);
      expect(find.text('Undo'), findsNothing);
      expectRows(['Bravo', 'Charlie'], ['Alpha']);
    });

    testWidgets('Not spam is sent when the snackbar is tapped away', (
      tester,
    ) async {
      final connector = await openScreen(tester);
      await tapRowNotSpam(tester, 'Alpha');
      await tester.tap(find.text('Marked as not spam'));
      await tester.pumpAndSettle();
      expect(connector.calls, ['notSpam Bob']);
    });

    testWidgets('a second change sends the first one', (tester) async {
      final connector = await openScreen(tester);
      await tapRowNotSpam(tester, 'Alpha');
      await tapRowNotSpam(tester, 'Bravo');
      expect(connector.calls, ['notSpam Bob']);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expectRows(['Bravo', 'Charlie'], ['Alpha']);
      await waitForTimeout(tester);
      expect(connector.calls, ['notSpam Bob']);
    });

    testWidgets('bulk Not spam hides the rows until Undo', (tester) async {
      final connector = await openScreen(tester);
      await select(tester, ['Alpha', 'Bravo']);
      await tester.tap(find.byTooltip('Not spam'));
      await tester.pumpAndSettle();
      expectRows(['Charlie'], ['Alpha', 'Bravo']);
      expect(find.text('2 messages marked as not spam'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expectRows(['Alpha', 'Bravo', 'Charlie'], []);
      await waitForTimeout(tester);
      expect(connector.calls, isEmpty);

      await select(tester, ['Alpha', 'Bravo']);
      await tester.tap(find.byTooltip('Not spam'));
      await tester.pumpAndSettle();
      await waitForTimeout(tester);
      expect(connector.calls, ['notSpamMany Bob,Dave']);
    });

    testWidgets('bulk Delete asks, then hides the rows until Undo', (
      tester,
    ) async {
      final connector = await openScreen(tester);
      await select(tester, ['Alpha', 'Charlie']);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete messages?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expectRows(['Bravo'], ['Alpha', 'Charlie']);
      expect(find.text('2 messages deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expectRows(['Alpha', 'Bravo', 'Charlie'], []);
      await waitForTimeout(tester);
      expect(connector.calls, isEmpty);

      await select(tester, ['Alpha', 'Charlie']);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      await waitForTimeout(tester);
      expect(connector.calls, ['delete Bob,Carol']);
    });

    testWidgets('leaving the page sends the change and closes the snackbar', (
      tester,
    ) async {
      final connector = await openScreen(tester);
      await tapRowNotSpam(tester, 'Alpha');
      await tester.binding.handlePopRoute();
      await tester.pump();
      // Sent as the page starts to close, not when it is gone, and the
      // spent Undo goes at once.
      expect(connector.calls, ['notSpam Bob']);
      expect(find.text('Undo'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(FilteredMessagesScreen), findsNothing);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('cancelling the delete dialog changes nothing', (tester) async {
      final connector = await openScreen(tester);
      await select(tester, ['Alpha']);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expectRows(['Alpha', 'Bravo', 'Charlie'], []);
      await waitForTimeout(tester);
      expect(connector.calls, isEmpty);
    });

    testWidgets('a radio lost during the delete dialog changes nothing', (
      tester,
    ) async {
      final connector = await openScreen(tester);
      await select(tester, ['Alpha']);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      connector.connected = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expectRows(['Alpha', 'Bravo', 'Charlie'], []);
      expect(find.text('Undo'), findsNothing);
      await waitForTimeout(tester);
      expect(connector.calls, isEmpty);
    });

    testWidgets('another snackbar replacing the Undo applies the change', (
      tester,
    ) async {
      final connector = await openScreen(tester);
      final messenger = tester.state<ScaffoldMessengerState>(
        find.byType(ScaffoldMessenger),
      );
      messenger.showSnackBar(const SnackBar(content: Text('other')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: _row('Alpha'), matching: find.text('Not spam')),
      );
      await tester.pump(const Duration(milliseconds: 50));
      messenger.clearSnackBars();
      messenger.showSnackBar(const SnackBar(content: Text('later')));
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(connector.calls, ['notSpam Bob']);
    });

    testWidgets('hiding the app applies the change', (tester) async {
      final connector = await openScreen(tester);
      await tapRowNotSpam(tester, 'Alpha');
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(connector.calls, ['notSpam Bob']);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      // The spent Undo is gone on the first frame back.
      await tester.pump();
      expect(find.text('Undo'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('removing the page without a pop sends the change', (
      tester,
    ) async {
      final connector = await openScreen(tester);
      await tapRowNotSpam(tester, 'Alpha');
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const Scaffold()),
            (_) => false,
          );
      await tester.pumpAndSettle();
      expect(find.byType(FilteredMessagesScreen), findsNothing);
      expect(connector.calls, ['notSpam Bob']);
      expect(find.text('Undo'), findsNothing);
    });
  });
}
