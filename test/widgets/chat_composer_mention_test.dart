import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/helpers/mention_search.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/widgets/chat_composer.dart';
import 'package:provider/provider.dart';

final _t = DateTime(2026, 11, 1);

class _ConnectedConnector extends MeshCoreConnector {
  @override
  bool get isConnected => true;
}

MentionCandidate candidate(String name) =>
    MentionCandidate(name: name, lastMessageAt: _t, fallbackAt: _t);

List<MentionCandidate> search(String query) {
  final all = ['Alice', 'Alan', 'Bob'].map(candidate);
  if (query.isEmpty) return all.toList();
  return all
      .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
}

Future<void> _pump(WidgetTester tester, TextEditingController controller) {
  return tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettingsService>.value(
          value: AppSettingsService(),
        ),
        ChangeNotifierProvider<MeshCoreConnector>.value(
          value: _ConnectedConnector(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChatComposer(
            controller: controller,
            focusNode: FocusNode(),
            maxBytes: 200,
            onSend: () {},
            sendTooltip: 'send',
            actionsBuilder: () => const [],
            onAction: (_) {},
            mentionSearch: search,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('typing @ opens the suggestion list', (tester) async {
    final controller = TextEditingController();
    await _pump(tester, controller);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'hi @');
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Alan'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('typed text after @ filters candidates', (tester) async {
    final controller = TextEditingController();
    await _pump(tester, controller);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '@al');
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Alan'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);
  });

  testWidgets('tapping a suggestion inserts the mention at the cursor', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'hi @Al go');
    controller.selection = const TextSelection.collapsed(offset: 6);
    await _pump(tester, controller);

    expect(find.text('Alice'), findsOneWidget);
    await tester.tap(find.text('Alice'));
    await tester.pump();

    expect(controller.text, 'hi @[Alice]  go');
    expect(controller.selection.baseOffset, 'hi @[Alice] '.length);
    expect(find.text('Alice'), findsNothing);
  });

  testWidgets('mid-word @ does not open the list', (tester) async {
    final controller = TextEditingController();
    await _pump(tester, controller);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'mail x@bob');
    await tester.pump();

    expect(find.text('Bob'), findsNothing);
  });

  testWidgets('plain text keeps the list closed', (tester) async {
    final controller = TextEditingController();
    await _pump(tester, controller);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'hello there');
    await tester.pump();

    expect(find.text('Alice'), findsNothing);
  });
}
