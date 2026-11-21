import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/helpers/chat_scroll_controller.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/review_mode/review_frames.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/screens/channel_chat_screen.dart';
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

/// Selecting messages must not move the transcript: picking, selecting all
/// and clearing are not new messages, and the composer getting its focus back
/// when the action sheet closes is not the user opening the keyboard.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('selection_scroll_test');
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

  testWidgets('selecting from far up the history keeps the scroll offset', (
    tester,
  ) async {
    _useSmallView(tester);
    await _pumpChannelChat(tester);

    // The composer has focus (keyboard open) while the user reads back.
    await tester.tap(find.byType(TextField).last);
    await _settle(tester);
    await _scrollTo(tester, 600);

    await _startSelection(tester);
    expect(find.text('1 selected'), findsOneWidget);
    expect(_position(tester).pixels, 600);

    // Select a few more.
    for (var i = 0; i < 2; i++) {
      await _tapVisibleUnselected(tester);
      expect(_position(tester).pixels, 600);
    }
    expect(find.text('3 selected'), findsOneWidget);

    // Select all from the selection app bar's menu.
    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    await tester.tap(find.text('Select all'));
    await _settle(tester);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
    expect(_position(tester).pixels, 600);

    // End selection.
    await tester.tap(find.byTooltip('Clear selection'));
    await _settle(tester);
    expect(find.byTooltip('Clear selection'), findsNothing);
    expect(_position(tester).pixels, 600);

    // Losing focus with nothing on top, then tapping the composer, still jumps
    // to the newest message.
    FocusManager.instance.primaryFocus?.unfocus();
    await _settle(tester);
    await tester.tap(find.byType(TextField).last);
    await _settle(tester);
    expect(_position(tester).pixels, 0);

    await _tearDown(tester);
  });

  testWidgets('selection near the bottom does not snap to the newest message', (
    tester,
  ) async {
    _useSmallView(tester);
    await _pumpChannelChat(tester);
    await _scrollTo(tester, 600);
    await _startSelection(tester);

    // Inside the "at bottom" threshold, where a new message would snap.
    await _scrollTo(tester, 60);

    await _tapVisibleUnselected(tester);
    expect(find.text('2 selected'), findsOneWidget);
    expect(_position(tester).pixels, 60);

    await tester.tap(find.byTooltip('Clear selection'));
    await _settle(tester);
    expect(_position(tester).pixels, 60);

    await _tearDown(tester);
  });

  testWidgets('incoming messages during selection behave as before', (
    tester,
  ) async {
    _useSmallView(tester);
    final connector = await _pumpChannelChat(tester);
    final channelIndex = connector.channels[0].index;

    await _scrollTo(tester, 600);
    await _startSelection(tester);

    // Reading back: a new message must not pull the view down.
    _receive(connector, channelIndex, 'Arrives while reading back');
    await _settle(tester);
    expect(find.text('1 selected'), findsOneWidget);
    expect(_position(tester).pixels, greaterThanOrEqualTo(600));

    // Near the bottom: a new message still scrolls into view.
    await _scrollTo(tester, 60);
    _receive(connector, channelIndex, 'Arrives while at the bottom');
    await _settle(tester);
    expect(find.text('1 selected'), findsOneWidget);
    expect(_position(tester).pixels, 0);

    await _tearDown(tester);
  });
}

void _useSmallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

ScrollPosition _position(WidgetTester tester) => tester
    .widget<ListView>(
      find.byWidgetPredicate(
        (w) => w is ListView && w.controller is ChatScrollController,
      ),
    )
    .controller!
    .position;

/// Jumps to [pixels] from the bottom. Jumps twice: the first lays out
/// messages whose heights were only estimated, which can correct the offset.
Future<void> _scrollTo(WidgetTester tester, double pixels) async {
  for (var i = 0; i < 2; i++) {
    _position(tester).jumpTo(pixels);
    await _settle(tester);
  }
  expect(_position(tester).pixels, pixels);
}

/// Long-presses a message in the middle of the screen and picks "Select
/// messages" from its action sheet. The long-press callback is invoked
/// directly: in tests a real long press on the bubble text starts text
/// selection instead.
Future<void> _startSelection(WidgetTester tester) async {
  final detector = find
      .byWidgetPredicate((w) => w is GestureDetector && w.onLongPress != null)
      .evaluate()
      .firstWhere((e) {
        final box = e.renderObject! as RenderBox;
        final y = box.localToGlobal(box.size.center(Offset.zero)).dy;
        return y > 150 && y < 450;
      });
  (detector.widget as GestureDetector).onLongPress!();
  await _settle(tester);
  await tester.ensureVisible(find.text('Select messages'));
  await tester.pump();
  await tester.tap(find.text('Select messages'));
  await _settle(tester);
}

/// Taps the selection circle of an unselected message on screen.
Future<void> _tapVisibleUnselected(WidgetTester tester) async {
  final list = tester.getRect(
    find.byWidgetPredicate(
      (w) => w is ListView && w.controller is ChatScrollController,
    ),
  );
  final circle = find
      .byIcon(Icons.radio_button_unchecked)
      .evaluate()
      .firstWhere((e) {
        final box = e.renderObject! as RenderBox;
        return list.contains(box.localToGlobal(box.size.center(Offset.zero)));
      });
  await tester.tap(find.byWidget(circle.widget));
  await _settle(tester);
}

var _received = 0;

void _receive(MeshCoreConnector connector, int channelIndex, String text) {
  connector.handleFrameForTest(
    ReviewFrames.channelMessage(
      channelIndex: channelIndex,
      sender: 'Alice',
      message: text,
      timestampSecs:
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60 * ++_received,
    ),
  );
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

/// Connects the review radio (once), seeds a long history and shows the
/// first channel's chat.
Future<MeshCoreConnector> _pumpChannelChat(WidgetTester tester) async {
  final firstRun = _shared == null;
  final (connector, providers) = _shared ??= await _connect(tester);
  if (firstRun) {
    final base = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 10000;
    for (var i = 0; i < 40; i++) {
      connector.handleFrameForTest(
        ReviewFrames.channelMessage(
          channelIndex: connector.channels[0].index,
          sender: 'Alice',
          message: 'History message $i with enough words to wrap a line',
          timestampSecs: base + i * 60,
        ),
      );
    }
  }
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
        home: ChannelChatScreen(channel: connector.channels[0]),
      ),
    ),
  );
  await _settle(tester);
  return connector;
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
