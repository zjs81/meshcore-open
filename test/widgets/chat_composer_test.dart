import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/helpers/gif_helper.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/chat_background.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/chat_background_service.dart';
import 'package:meshcore_open/services/chat_background_image_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/byte_count_input.dart';
import 'package:meshcore_open/widgets/chat_background.dart';
import 'package:meshcore_open/widgets/chat_composer.dart';
import 'package:meshcore_open/widgets/connect_sheet.dart';
import 'package:meshcore_open/widgets/gif_message.dart';
import 'package:meshcore_open/widgets/message_translation_button.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

class _Connector extends MeshCoreConnector {
  bool connected = true;

  @override
  bool get isConnected => connected;
}

class _Harness {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  final connector = _Connector();
  late final AppSettingsService settings;
  late final ChatBackgroundService backgrounds;
  int sends = 0;
  final actions = <String>[];

  void dispose() {
    controller.dispose();
    focusNode.dispose();
    connector.dispose();
  }
}

Future<_Harness> _harness(WidgetTester tester) async {
  final h = _Harness();
  // A date with no holiday nearby, so no holiday chat background applies.
  h.settings = AppSettingsService(clock: () => DateTime(2026, 7, 1));
  await tester.runAsync(h.settings.loadSettings);
  h.backgrounds = ChatBackgroundService(
    h.settings,
    imageStore: InMemoryChatBackgroundImageStore(),
  );
  addTearDown(h.dispose);
  return h;
}

Widget _app(
  _Harness h, {
  int maxBytes = 160,
  Widget? replyPreview,
  bool disableAnimations = false,
  Brightness brightness = Brightness.light,
}) {
  final composer = ChatComposer(
    controller: h.controller,
    focusNode: h.focusNode,
    maxBytes: maxBytes,
    onSend: () => h.sends++,
    sendTooltip: _l10n.chat_sendMessage,
    actionsBuilder: () => [
      ChatComposerAction(
        id: 'gif',
        icon: Icons.gif_box,
        label: _l10n.chat_sendGif,
      ),
    ],
    onAction: h.actions.add,
    replyPreview: replyPreview,
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MeshCoreConnector>.value(value: h.connector),
      ChangeNotifierProvider.value(value: h.settings),
      ChangeNotifierProvider.value(value: h.backgrounds),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.light
          ? MeshTheme.light()
          : MeshTheme.dark(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: ChatBackdrop(
          chatKey: 'contact:test',
          footer: composer,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

Finder get _plus => find.byTooltip(_l10n.chat_selectSendAction);
Finder get _send => find.byTooltip(_l10n.chat_sendMessage);
Finder get _bubble => find.byKey(ChatComposer.bubbleKey);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  testWidgets('right circle is + when empty and Send with text', (
    tester,
  ) async {
    final h = await _harness(tester);
    await tester.pumpWidget(_app(h));
    await tester.pumpAndSettle();

    // No separate "+" on the left: one round button only.
    expect(_plus, findsOneWidget);
    expect(_send, findsNothing);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);

    // "+" opens the screen's action menu.
    await tester.tap(_plus);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.chat_sendGif));
    await tester.pumpAndSettle();
    expect(h.actions, ['gif']);

    // Whitespace doesn't count as text.
    await _type(tester, '   ');
    expect(_plus, findsOneWidget);

    await _type(tester, 'On my way');
    expect(_plus, findsNothing);
    expect(_send, findsOneWidget);
    await tester.tap(_send);
    expect(h.sends, 1);

    await _type(tester, '');
    expect(_plus, findsOneWidget);
    expect(_send, findsNothing);
  });

  testWidgets('round button has a 48dp touch target and sits right of the '
      'bubble', (tester) async {
    final h = await _harness(tester);
    await tester.pumpWidget(_app(h));
    await tester.pumpAndSettle();

    final plus = find.widgetWithIcon(IconButton, Icons.add);
    final size = tester.getSize(plus);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(
      tester.getTopLeft(plus).dx,
      greaterThanOrEqualTo(tester.getTopRight(_bubble).dx),
    );
    // Single-line bubble is about one touch target tall.
    expect(tester.getSize(_bubble).height, inInclusiveRange(44, 52));
  });

  testWidgets('swap animates, and is instant with animations disabled', (
    tester,
  ) async {
    final h = await _harness(tester);
    await tester.pumpWidget(_app(h));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Mid-transition both icons are on screen.
    expect(_plus, findsOneWidget);
    expect(_send, findsOneWidget);
    await tester.pumpAndSettle();
    expect(_plus, findsNothing);

    final reduced = await _harness(tester);
    await tester.pumpWidget(_app(reduced, disableAnimations: true));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.pump();
    await tester.pump();
    expect(_plus, findsNothing);
    expect(_send, findsOneWidget);
  });

  testWidgets('field grows to 5 lines then scrolls, buttons stay at the '
      'bottom', (tester) async {
    final h = await _harness(tester);
    await tester.pumpWidget(_app(h, maxBytes: 1000));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 1);
    expect(field.maxLines, kComposerMaxLines);

    await _type(tester, 'one');
    final oneLine = tester.getSize(find.byType(TextField)).height;
    final sendBottom = tester.getBottomLeft(_send).dy;
    final bubbleBottom = tester.getBottomLeft(_bubble).dy;

    await _type(tester, List.filled(5, 'line').join('\n'));
    final fiveLines = tester.getSize(find.byType(TextField)).height;
    expect(fiveLines, greaterThan(oneLine * 2));

    await _type(tester, List.filled(12, 'line').join('\n'));
    expect(tester.getSize(find.byType(TextField)).height, fiveLines);

    // The panel grows upwards; the send button keeps its place at the
    // bottom of the bubble.
    expect(tester.getBottomLeft(_send).dy, sendBottom);
    expect(tester.getBottomLeft(_bubble).dy, bubbleBottom);
  });

  testWidgets('a short window still lets the field wrap onto two lines', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 260);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = await _harness(tester);
    await tester.pumpWidget(_app(h, maxBytes: 1000));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).maxLines,
      greaterThanOrEqualTo(2),
    );
  });

  testWidgets('byte counter shows only past the warning threshold and '
      'takes no space before', (tester) async {
    final h = await _harness(tester);
    await tester.pumpWidget(_app(h, maxBytes: 20));
    await tester.pumpAndSettle();
    final emptyHeight = tester.getSize(_bubble).height;

    await _type(tester, 'a' * 14); // 70 %: not past the threshold
    expect(find.text('14 / 20'), findsNothing);
    expect(tester.getSize(_bubble).height, emptyHeight);

    await _type(tester, 'a' * 15);
    final counter = find.text('15 / 20');
    expect(counter, findsOneWidget);
    expect(find.descendant(of: _bubble, matching: counter), findsOneWidget);
    // Bottom-right of the bubble.
    expect(
      tester.getCenter(counter).dx,
      greaterThan(tester.getCenter(_bubble).dx),
    );
    expect(
      tester.getCenter(counter).dy,
      greaterThan(tester.getCenter(find.byType(TextField)).dy),
    );

    // The byte limit itself is unchanged.
    await _type(tester, 'a' * 30);
    expect(h.controller.text.length, 20);
  });

  testWidgets('ByteCountedTextField defaults are unchanged for other '
      'screens', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ByteCountedTextField(maxBytes: 20, controller: controller),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLines, isNull);
    // The counter row keeps its place while hidden.
    expect(find.text('0 / 20'), findsOneWidget);
  });

  testWidgets('reply preview renders inside the top of the bubble and can '
      'be dismissed', (tester) async {
    final h = await _harness(tester);
    var dismissed = false;
    await tester.pumpWidget(
      _app(
        h,
        replyPreview: ChatComposerQuote(
          title: _l10n.chat_replyingTo('Bob'),
          content: const Text('see you at camp'),
          onDismiss: () => dismissed = true,
          dismissTooltip: _l10n.chat_cancelReply,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final quote = find.byType(ChatComposerQuote);
    expect(find.descendant(of: _bubble, matching: quote), findsOneWidget);
    expect(find.text(_l10n.chat_replyingTo('Bob')), findsOneWidget);
    expect(
      tester.getBottomLeft(quote).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(TextField)).dy),
    );

    await tester.tap(find.byTooltip(_l10n.chat_cancelReply));
    expect(dismissed, isTrue);
  });

  testWidgets('GIF preview sits in the bubble, sends on Enter and can be '
      'removed', (tester) async {
    final h = await _harness(tester);
    await tester.pumpWidget(_app(h));
    await tester.pumpAndSettle();

    h.controller.text = GifHelper.encodeGif('abc123');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.descendant(of: _bubble, matching: find.byType(GifMessage)),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(_send, findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(h.sends, 1);

    await tester.tap(find.byTooltip(_l10n.chat_removeGif));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(h.controller.text, isEmpty);
    expect(find.byType(TextField), findsOneWidget);
    expect(_plus, findsOneWidget);
  });

  testWidgets('translate button sits inside the bubble when enabled', (
    tester,
  ) async {
    final h = await _harness(tester);
    await tester.runAsync(() => h.settings.setTranslationEnabled(true));
    await tester.pumpWidget(_app(h));
    await tester.pumpAndSettle();

    final translate = find.byType(MessageTranslationButton);
    expect(find.descendant(of: _bubble, matching: translate), findsOneWidget);
    expect(
      tester.getCenter(translate).dx,
      greaterThan(tester.getCenter(find.byType(TextField)).dx),
    );
    expect(
      find.descendant(of: translate, matching: find.byType(Tooltip)),
      findsOneWidget,
    );
  });

  testWidgets('panel is solid without a chat background and transparent '
      'over one', (tester) async {
    final h = await _harness(tester);
    await tester.pumpWidget(_app(h));
    await tester.pumpAndSettle();

    final scheme = MeshTheme.light().colorScheme;
    Color bubbleColor() =>
        ((tester.widget<DecoratedBox>(_bubble).decoration as BoxDecoration)
                .color)
            as Color;
    final panelFill = find.ancestor(
      of: _bubble,
      matching: find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == scheme.surface,
      ),
    );
    expect(panelFill, findsOneWidget);
    expect(bubbleColor(), scheme.surfaceContainerHigh);

    await tester.runAsync(
      () => h.backgrounds.setChatBackground(
        'contact:test',
        const ChatBackground.color(Color(0xFF1E3A8A)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatBackgroundLayer), findsOneWidget);
    expect(panelFill, findsNothing);
    // Incoming-bubble colour keeps the text readable over the background.
    expect(bubbleColor(), scheme.surfaceContainerLow);
  });

  testWidgets('offline bar uses the same bubble and height as the composer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await _harness(tester);
    await tester.pumpWidget(_app(h));
    await tester.pumpAndSettle();
    final composerTop = tester.getTopLeft(_bubble).dy;
    final composerHeight = tester.getSize(_bubble).height;

    h.connector.connected = false;
    h.connector.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.byType(OfflineComposerBar), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ConnectButton), findsOneWidget);
    expect(find.text(_l10n.chat_composerOffline), findsOneWidget);
    final decoration =
        tester.widget<DecoratedBox>(_bubble).decoration as BoxDecoration;
    expect(
      decoration.borderRadius,
      BorderRadius.circular(kComposerBubbleRadius),
    );
    expect(tester.getSize(_bubble).height, composerHeight);
    expect(tester.getTopLeft(_bubble).dy, composerTop);

    // The draft survives and comes back with the radio.
    h.controller.text = 'draft';
    h.connector.connected = true;
    h.connector.notifyListeners();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'draft',
    );
  });

  for (final scale in [1.3, 2.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('fits 320dp at ${scale}x text (${brightness.name})', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final h = await _harness(tester);
        await tester.runAsync(() => h.settings.setTranslationEnabled(true));
        await tester.pumpWidget(
          _app(
            h,
            maxBytes: 20,
            brightness: brightness,
            replyPreview: ChatComposerQuote(
              title: _l10n.chat_replyingTo('A very long sender name here'),
              content: const Text(
                'a long quoted message that must ellipsize',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onDismiss: () {},
              dismissTooltip: _l10n.chat_cancelReply,
              // A long region chip, as a channel reply shows.
              trailing: Text(
                _l10n.channels_regionSetTo('north-west-valley'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byTooltip(_l10n.chat_cancelReply), findsOneWidget);
        await _type(tester, 'a' * 19);
        expect(tester.takeException(), isNull);

        // With the keyboard up, a long draft still fits: the field caps its
        // lines to the room left.
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        await _type(tester, List.filled(8, 'line').join('\n'));
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();

        h.connector.connected = false;
        h.connector.notifyListeners();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
