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

/// Chat screen behaviour that depends on navigation: which conversation is
/// active while chats are covered, and jumping to a search result.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('active_conv_test');
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

  // A chat covered by another page (e.g. one opened from a notification) must
  // stop being the active conversation, and become active again once the page
  // on top is popped, so unread counting matches what is on screen.
  testWidgets('covered chats unregister and re-register when uncovered', (
    tester,
  ) async {
    final (connector, navigatorKey) = await _pumpChannelChat(tester);
    final channelA = connector.channels[0];
    final channelB = connector.channels[1];
    final contact = connector.contacts.firstWhere((c) => c.type == advTypeChat);

    expect(connector.activeChannelIndex, channelA.index);

    // Channel B opened on top (as a notification tap does).
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channelB)),
    );
    await _settle(tester);
    expect(connector.activeChannelIndex, channelB.index);

    navigatorKey.currentState!.pop();
    await _settle(tester);
    expect(connector.activeChannelIndex, channelA.index);

    // A DM on top hides the channel entirely.
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => ChatScreen(contact: contact)),
    );
    await _settle(tester);
    expect(connector.activeChannelIndex, isNull);
    expect(connector.activeContactKey, contact.publicKeyHex);

    navigatorKey.currentState!.pop();
    await _settle(tester);
    expect(connector.activeContactKey, isNull);
    expect(connector.activeChannelIndex, channelA.index);

    // A page pushed without a transition never reports `forward`.
    navigatorKey.currentState!.push(
      _InstantPageRoute(builder: (_) => const Scaffold()),
    );
    await _settle(tester);
    expect(connector.activeChannelIndex, isNull);

    navigatorKey.currentState!.pop();
    await _settle(tester);
    expect(connector.activeChannelIndex, channelA.index);

    await _tearDown(tester);
    expect(connector.activeChannelIndex, isNull);
  });

  testWidgets('tapping a search result closes search and shows the message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final (connector, _) = await _pumpChannelChat(tester);
    final messages = connector.getChannelMessages(connector.channels[0]);
    expect(messages, isNotEmpty);
    // The oldest message: furthest from where the chat opens (the bottom).
    final target = messages.first;
    final word = target.text
        .split(RegExp(r'\s+'))
        .firstWhere((w) => w.length >= 4, orElse: () => target.text);

    await tester.tap(find.byTooltip('Search messages'));
    await _settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TextField),
      ),
      word,
    );
    await _settle(tester);

    // Results show sender + time headers; tap the row holding the target.
    final result = find.descendant(
      of: find.byType(ListView),
      matching: find.textContaining(target.text, findRichText: true),
    );
    expect(result, findsWidgets);
    await tester.tap(result.first);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Search is closed and the message bubble is on screen.
    expect(find.byTooltip('Close search'), findsNothing);
    final bubble = find.textContaining(target.text, findRichText: true);
    expect(bubble, findsWidgets);
    final screen = Offset.zero & const Size(400, 700);
    expect(
      bubble.evaluate().any((e) {
        final box = e.renderObject as RenderBox?;
        if (box == null || !box.hasSize) return false;
        return screen.overlaps(box.localToGlobal(Offset.zero) & box.size);
      }),
      isTrue,
    );

    await _tearDown(tester);
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tearDown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 1));
}

/// One review-radio connection shared by the tests: reconnecting it in the
/// same run does not resend the channel list.
(MeshCoreConnector, List<SingleChildWidget>)? _shared;

/// Connects the review radio (once) and shows the first channel's chat.
Future<(MeshCoreConnector, GlobalKey<NavigatorState>)> _pumpChannelChat(
  WidgetTester tester,
) async {
  final (connector, providers) = _shared ??= await _connect(tester);
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MultiProvider(
      providers: providers,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: MeshTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChannelChatScreen(channel: connector.channels[0]),
      ),
    ),
  );
  await _settle(tester);
  return (connector, navigatorKey);
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
    while ((connector.contacts.isEmpty || connector.channels.length < 2) &&
        DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });
  expect(connector.channels.length, greaterThanOrEqualTo(2));

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

class _InstantPageRoute extends MaterialPageRoute<void> {
  _InstantPageRoute({required super.builder});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;
}
