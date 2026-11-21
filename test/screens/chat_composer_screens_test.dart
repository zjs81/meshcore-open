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
import 'package:meshcore_open/widgets/chat_background.dart';
import 'package:meshcore_open/widgets/chat_composer.dart';
import 'package:meshcore_open/widgets/message_bubble_frame.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

/// Both chat screens show the same composer, as the footer of the chat
/// background, and the channel reply preview sits inside its bubble.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('chat_composer_test');
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

  Finder composerIn(Type screen) => find.descendant(
    of: find.descendant(
      of: find.byType(screen),
      matching: find.byType(ChatBackdrop),
    ),
    matching: find.byType(ChatComposer),
  );

  testWidgets('DM chat shows the redesigned composer', (tester) async {
    final (connector, providers) = _shared ??= await _connect(tester);
    final contact = connector.contacts.firstWhere((c) => c.type == advTypeChat);
    await _pump(tester, providers, ChatScreen(contact: contact));

    expect(composerIn(ChatScreen), findsOneWidget);
    expect(find.byTooltip(_l10n.chat_selectSendAction), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);

    await tester.enterText(find.byType(TextField), 'hello');
    await _settle(tester);
    expect(find.byTooltip(_l10n.chat_selectSendAction), findsNothing);
    expect(find.byTooltip(_l10n.chat_sendMessageTo(contact.name)), findsOne);
    await _tearDown(tester);
  });

  testWidgets('channel chat shows the same composer with the reply preview '
      'inside the bubble', (tester) async {
    final (connector, providers) = _shared ??= await _connect(tester);
    final channel = connector.channels[0];
    await _pump(tester, providers, ChannelChatScreen(channel: channel));

    expect(composerIn(ChannelChatScreen), findsOneWidget);
    expect(find.byTooltip(_l10n.chat_selectSendAction), findsOneWidget);
    expect(find.byType(ChatComposerQuote), findsNothing);

    final incoming = connector
        .getChannelMessages(channel)
        .lastWhere((m) => !m.isOutgoing);
    final bubble = find.ancestor(
      of: find.textContaining(incoming.text, findRichText: true),
      matching: find.byType(MessageBubbleFrame),
    );
    await tester.longPressAt(tester.getTopLeft(bubble) + const Offset(4, 4));
    await _settle(tester);
    await tester.tap(find.text(_l10n.chat_reply));
    await _settle(tester);

    final quote = find.byType(ChatComposerQuote);
    expect(
      find.descendant(of: find.byKey(ChatComposer.bubbleKey), matching: quote),
      findsOneWidget,
    );
    expect(find.text(_l10n.chat_replyingTo(incoming.senderName)), findsOne);

    await tester.tap(find.byTooltip(_l10n.chat_cancelReply));
    await _settle(tester);
    expect(quote, findsNothing);
    await _tearDown(tester);
  });
}

Future<void> _pump(
  WidgetTester tester,
  List<SingleChildWidget> providers,
  Widget home,
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
        home: home,
      ),
    ),
  );
  await _settle(tester);
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

/// One review-radio connection shared by the tests.
(MeshCoreConnector, List<SingleChildWidget>)? _shared;

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
    while ((connector.contacts.isEmpty || connector.channels.isEmpty) &&
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
