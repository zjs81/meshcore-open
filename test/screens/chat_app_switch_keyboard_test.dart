import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/review_mode/review_frames.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/screens/channel_chat_screen.dart';
import 'package:meshcore_open/screens/chat_screen.dart';
import 'package:meshcore_open/services/app_debug_log_service.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/ble_debug_log_service.dart';
import 'package:meshcore_open/services/chat_text_scale_service.dart';
import 'package:meshcore_open/services/image_codec_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/received_image_store.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/timeout_prediction_service.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/services/ui_view_state_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/chat_composer.dart';

const _screen = Size(400, 800);
const _keyboard = 300.0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('app_switch_kb_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempDir.path,
      );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  // Android/iOS keep focus on the composer across an app switch; the OS may
  // or may not bring the keyboard back. Layout must follow the reported
  // inset, and the draft, focus and reading position must survive.
  for (final keyboardBack in [true, false]) {
    for (final atBottom in [false, true]) {
      final keyboard = keyboardBack ? 'keyboard back' : 'OS closed keyboard';
      final reading = atBottom ? 'at the bottom' : 'reading history';
      testWidgets('mobile app switch: $keyboard, $reading', (tester) async {
        tester.view.physicalSize = _screen;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pumpChannelChat(tester);
        await tester.tap(_composerField);
        tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
        await _settle(tester);
        await tester.enterText(_composerField, 'half written');
        await _settle(tester);

        if (!atBottom) {
          await tester.drag(find.byType(ListView).first, const Offset(0, 300));
          await _settle(tester);
        }
        final offsetBefore = _list(tester).position.pixels;
        expect(offsetBefore, atBottom ? 0 : greaterThan(100));
        expect(_composerBottom(tester), closeTo(_screen.height - _keyboard, 1));

        // Switch away; the OS hides the keyboard while the app is hidden.
        _goBackground(tester);
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pump();

        _goForeground(tester);
        if (keyboardBack) {
          tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
        }
        await _settle(tester);

        final inset = keyboardBack ? _keyboard : 0.0;
        expect(_composerBottom(tester), closeTo(_screen.height - inset, 1));
        expect(_composer(tester).focusNode.hasFocus, isTrue);
        expect(_composer(tester).controller.text, 'half written');
        expect(_list(tester).position.pixels, closeTo(offsetBefore, 1));

        // Tapping the field opens the keyboard again above the composer.
        await tester.tap(_composerField);
        tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
        await _settle(tester);
        expect(_composerBottom(tester), closeTo(_screen.height - _keyboard, 1));
        expect(_composer(tester).controller.text, 'half written');

        await _tearDown(tester);
      });
    }
  }

  // Desktop and web take focus away when the window goes inactive and restore
  // it on resume. That restore used to count as "keyboard opened" and jumped
  // the transcript to the newest message.
  testWidgets('desktop app switch keeps the reading position', (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpChannelChat(tester);
    await tester.tap(_composerField);
    await _settle(tester);
    await tester.enterText(_composerField, 'half written');
    // Mouse-wheel up through the history; the composer keeps focus.
    _list(tester).jumpTo(300);
    await _settle(tester);

    _goBackground(tester);
    await tester.pump();
    expect(_composer(tester).focusNode.hasFocus, isFalse);
    _goForeground(tester);
    await _settle(tester);

    expect(_composer(tester).focusNode.hasFocus, isTrue);
    expect(_composer(tester).controller.text, 'half written');
    expect(_list(tester).position.pixels, closeTo(300, 1));

    // A real click on the composer still jumps to the newest message.
    _composer(tester).focusNode.unfocus();
    await _settle(tester);
    await tester.tap(_composerField);
    await _settle(tester);
    expect(_list(tester).position.pixels, 0);

    await _tearDown(tester);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets(
    'desktop app switch when focus is not restored does not swallow the next tap',
    (tester) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpChannelChat(tester);
      await tester.tap(_composerField);
      await _settle(tester);
      _list(tester).jumpTo(300);
      await _settle(tester);

      _goBackground(tester);
      await tester.pump();
      expect(_composer(tester).focusNode.hasFocus, isFalse);
      // User returns and interacts elsewhere (e.g. opens search) so focus is
      // not restored to the composer on resume.
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      _goForeground(tester);
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await _settle(tester);

      expect(_composer(tester).focusNode.hasFocus, isFalse);
      expect(_list(tester).position.pixels, closeTo(300, 1));

      await tester.tap(_composerField);
      await _settle(tester);
      expect(_composer(tester).focusNode.hasFocus, isTrue);
      expect(_list(tester).position.pixels, 0);

      await _tearDown(tester);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'DM chat: desktop app switch and dialog close keep reading position',
    (tester) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpDirectChat(tester);
      await tester.tap(_composerField);
      await _settle(tester);
      _list(tester).jumpTo(300);
      await _settle(tester);

      // App switch away and back restores focus without jumping to bottom.
      _goBackground(tester);
      await tester.pump();
      expect(_composer(tester).focusNode.hasFocus, isFalse);
      _goForeground(tester);
      await _settle(tester);

      expect(_composer(tester).focusNode.hasFocus, isTrue);
      expect(_list(tester).position.pixels, closeTo(300, 1));

      // Opening and closing a dialog over the chat returns focus without jumping.
      await tester.tap(find.byIcon(Icons.more_vert));
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.info_outline));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await _settle(tester);

      expect(_list(tester).position.pixels, closeTo(300, 1));

      // Losing focus in the foreground and tapping again still jumps to bottom.
      _composer(tester).focusNode.unfocus();
      await _settle(tester);
      await tester.tap(_composerField);
      await _settle(tester);
      expect(_list(tester).position.pixels, 0);

      await _tearDown(tester);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}

final _composerField = find.descendant(
  of: find.byType(ChatComposer),
  matching: find.byType(EditableText),
);

EditableText _composer(WidgetTester tester) =>
    tester.widget<EditableText>(_composerField);

void _goBackground(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _goForeground(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

ScrollController _list(WidgetTester tester) => tester
    .widget<ListView>(find.byWidgetPredicate((w) => w is ListView).first)
    .controller!;

double _composerBottom(WidgetTester tester) =>
    tester.getBottomLeft(find.byType(ChatComposer)).dy;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tearDown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 1));
}

(MeshCoreConnector, List<SingleChildWidget>)? _shared;

Future<MeshCoreConnector> _pumpChannelChat(WidgetTester tester) async {
  final (connector, providers) = _shared ??= await _connect(tester);
  await _pumpScreen(
    tester,
    providers,
    ChannelChatScreen(channel: connector.channels[0]),
  );
  return connector;
}

Future<MeshCoreConnector> _pumpDirectChat(WidgetTester tester) async {
  final (connector, providers) = _shared ??= await _connect(tester);
  final contact = connector.contacts.firstWhere((c) => c.type == advTypeChat);
  if (connector.getMessages(contact).length < 40) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (var i = 0; i < 40; i++) {
      connector.handleFrameForTest(
        ReviewFrames.contactMessage(
          senderPublicKey: contact.publicKey,
          text: 'Direct history line $i about the weather on the hill',
          timestampSecs: now - 4000 + i,
        ),
      );
    }
  }
  await _pumpScreen(tester, providers, ChatScreen(contact: contact));
  return connector;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  List<SingleChildWidget> providers,
  Widget screen,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: providers,
      child: MaterialApp(
        theme: MeshTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await _settle(tester);
}

Future<(MeshCoreConnector, List<SingleChildWidget>)> _connect(
  WidgetTester tester,
) async {
  final storage = StorageService();
  final connector = MeshCoreConnector();
  final retry = MessageRetryService();
  final settings = AppSettingsService();
  final translation = TranslationService(settings);
  await tester.runAsync(() async {
    await settings.loadSettings();
    connector.initialize(
      retryService: retry,
      pathHistoryService: PathHistoryService(storage),
      appSettingsService: settings,
      translationService: translation,
    );
    connector.reviewRadioFactoryForTest = () => ReviewRadio(
      scheduledMessageInterval: const Duration(hours: 1),
      ackDelay: const Duration(hours: 1),
      replyDelay: const Duration(hours: 1),
    );
    await connector.connectReview();
    final end = DateTime.now().add(const Duration(seconds: 8));
    while (connector.channels.isEmpty && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    // Enough history that the transcript scrolls with or without a keyboard.
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (var i = 0; i < 40; i++) {
      connector.handleFrameForTest(
        ReviewFrames.channelMessage(
          channelIndex: 0,
          sender: 'Tester',
          message: 'History line number $i about the weather on the hill',
          timestampSecs: now - 4000 + i,
        ),
      );
    }
    while (connector.getChannelMessages(connector.channels[0]).length < 40 &&
        DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });
  expect(connector.channels, isNotEmpty);

  return (
    connector,
    <SingleChildWidget>[
      ChangeNotifierProvider.value(value: connector),
      ChangeNotifierProvider.value(value: retry),
      ChangeNotifierProvider.value(value: PathHistoryService(storage)),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: BleDebugLogService()),
      ChangeNotifierProvider.value(value: AppDebugLogService()),
      ChangeNotifierProvider.value(value: ChatTextScaleService()),
      ChangeNotifierProvider.value(value: translation),
      ChangeNotifierProvider.value(value: UiViewStateService()),
      Provider.value(value: storage),
      ChangeNotifierProvider.value(
        value: MapTileCacheService(appSettingsService: settings),
      ),
      ChangeNotifierProvider.value(value: TimeoutPredictionService(storage)),
      ChangeNotifierProvider.value(value: ImageCodecService(settings)),
      ChangeNotifierProvider.value(value: ReceivedImageStore()),
    ],
  );
}
