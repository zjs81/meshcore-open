import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/link_handler.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/custom_theme.dart';
import 'package:meshcore_open/review_mode/review_frames.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/screens/channel_chat_screen.dart';
import 'package:meshcore_open/screens/chat_screen.dart';
import 'package:meshcore_open/screens/coordinate_map_screen.dart';
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
import 'package:meshcore_open/utils/platform_info.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

(MeshCoreConnector, List<SingleChildWidget>)? _shared;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync(
    'coordinate_messages_test',
  );
  String? copiedText;
  final launchedUrls = <String>[];

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async {
            if (call.method == 'launch' || call.method == 'launchUrl') {
              final args = call.arguments as Map<dynamic, dynamic>;
              launchedUrls.add(args['url'] as String);
              return true;
            }
            if (call.method == 'canLaunch') {
              return true;
            }
            return true;
          },
        );

    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  tearDownAll(() {
    _shared = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    copiedText = null;
    launchedUrls.clear();
  });

  /// Finds the global center of the first substring matching [target] inside
  /// a [RenderParagraph] (mobile) or [RenderEditable] (desktop).
  Offset findSpanOffset(WidgetTester tester, String target) {
    for (final render in tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    )) {
      final plain = render.text.toPlainText();
      final idx = plain.indexOf(target);
      if (idx < 0) continue;
      final boxes = render.getBoxesForSelection(
        TextSelection(baseOffset: idx, extentOffset: idx + target.length),
      );
      if (boxes.isNotEmpty) {
        final localCenter = boxes.first.toRect().center;
        return render.localToGlobal(localCenter);
      }
    }
    for (final state in tester.stateList<EditableTextState>(
      find.byType(EditableText),
    )) {
      final editable = state.renderEditable;
      final plain = editable.plainText;
      final idx = plain.indexOf(target);
      if (idx < 0) continue;
      final boxes = editable.getEndpointsForSelection(
        TextSelection(baseOffset: idx, extentOffset: idx + target.length),
      );
      if (boxes.isNotEmpty) {
        final first = boxes.first.point;
        final last = boxes.last.point;
        final localCenter = Offset((first.dx + last.dx) / 2, first.dy - 6);
        return editable.localToGlobal(localCenter);
      }
    }
    fail('Could not locate rendered span for "$target"');
  }

  for (final isDesktop in [false, true]) {
    final platformLabel = isDesktop ? 'desktop' : 'phone';

    testWidgets(
      'DM message with URL and coordinate: tap opens map, Back preserves scroll, '
      'long-press shows menu, non-coordinate gestures preserved ($platformLabel)',
      (tester) async {
        PlatformInfo.debugIsDesktopOverride = isDesktop;
        addTearDown(() => PlatformInfo.debugIsDesktopOverride = null);

        final (connector, providers) = _shared ??= await _connect(tester);
        final contact = connector.contacts.firstWhere(
          (c) => c.type == advTypeChat,
        );
        final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        const coord = '37.7749, -122.4194';
        const url = 'https://example.com/trail';
        const messageText = 'Check $url and meet at $coord soon';

        await tester.runAsync(() async {
          connector.handleFrameForTest(
            ReviewFrames.contactMessage(
              senderPublicKey: contact.publicKey,
              text: messageText,
              timestampSecs: nowSecs - 60,
            ),
          );
          for (var i = 0; i < 18; i++) {
            connector.handleFrameForTest(
              ReviewFrames.contactMessage(
                senderPublicKey: contact.publicKey,
                text: 'Filler message #$i',
                timestampSecs: nowSecs - 30 + i,
              ),
            );
          }
          connector.handleFrameForTest(
            ReviewFrames.contactMessage(
              senderPublicKey: contact.publicKey,
              text: 'Reply sent at 45.5152, -122.6784',
              timestampSecs: nowSecs,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        await _pumpApp(tester, providers, ChatScreen(contact: contact));

        final scrollable = tester.widget<Scrollable>(
          find.byType(Scrollable).first,
        );
        final controller = scrollable.controller!;
        final targetFinder = find.textContaining(coord, findRichText: true);
        if (targetFinder.evaluate().isEmpty) {
          await tester.dragUntilVisible(
            targetFinder,
            find.byType(Scrollable).first,
            const Offset(0, 200),
            maxIteration: 30,
          );
        }
        await Scrollable.ensureVisible(
          tester.element(targetFinder.first),
          alignment: 0.5,
        );
        await _settle(tester);
        final savedOffset = controller.offset;
        expect(savedOffset, greaterThan(0));

        // 1. Tap coordinate -> opens CoordinateMapScreen with pin + label + centered AppBar.
        final coordCenter = findSpanOffset(tester, coord);
        await tester.tapAt(coordCenter);
        await _settle(tester);

        expect(find.byType(CoordinateMapScreen), findsOneWidget);
        expect(find.text(coord), findsOneWidget);
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.centerTitle, isTrue);
        final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
        expect(
          flutterMap.options.initialCenter.latitude,
          closeTo(37.7749, 1e-6),
        );
        expect(
          flutterMap.options.initialCenter.longitude,
          closeTo(-122.4194, 1e-6),
        );
        expect(find.byIcon(Icons.location_on), findsOneWidget);

        // 2. Pressing Back returns to exact same chat and scroll position.
        await tester.pageBack();
        await _settle(tester);
        expect(find.byType(CoordinateMapScreen), findsNothing);
        expect(find.byType(ChatScreen), findsOneWidget);
        expect(controller.offset, closeTo(savedOffset, 1.0));

        // 3. Long-press coordinate -> opens Copy & Open in maps sheet (NOT bubble menu).
        await tester.longPressAt(findSpanOffset(tester, coord));
        await _settle(tester);
        expect(find.text(_l10n.coordinate_copyLocation), findsOneWidget);
        expect(find.text(_l10n.coordinate_openInMaps), findsOneWidget);
        expect(find.text(_l10n.chat_reply), findsNothing);

        // Copy location writes to clipboard and shows snackbar.
        await tester.tap(find.text(_l10n.coordinate_copyLocation));
        await _settle(tester);
        expect(copiedText, coord);
        expect(find.text(_l10n.coordinate_copied), findsOneWidget);

        // Re-open long-press sheet and tap Open in maps.
        await tester.longPressAt(findSpanOffset(tester, coord));
        await _settle(tester);
        await tester.tap(find.text(_l10n.coordinate_openInMaps));
        await _settle(tester);
        expect(launchedUrls, isNotEmpty);
        expect(launchedUrls.last, contains('37.7749'));
        expect(launchedUrls.last, contains('-122.4194'));

        // 4. Tapping URL still opens existing URL confirmation dialog.
        await tester.tapAt(findSpanOffset(tester, url));
        await _settle(tester);
        expect(find.text(_l10n.chat_openLink), findsOneWidget);
        await tester.tap(find.text(_l10n.common_cancel));
        await _settle(tester);

        // 5. Long-pressing non-coordinate text in same message opens bubble actions.
        if (!isDesktop) {
          await tester.longPressAt(findSpanOffset(tester, 'Check'));
          await _settle(tester);
          expect(find.text(_l10n.chat_addReaction), findsOneWidget);
          Navigator.of(tester.element(find.text(_l10n.chat_addReaction))).pop();
          await _settle(tester);
        }

        await _tearDown(tester);
      },
    );
  }

  testWidgets(
    'Channel messages render coordinates, support tap/long-press, and fit 320dp @ 1.3x & 2.0x',
    (tester) async {
      PlatformInfo.debugIsDesktopOverride = false;
      addTearDown(() => PlatformInfo.debugIsDesktopOverride = null);

      final (connector, providers) = _shared ??= await _connect(tester);
      final channel = connector.channels.first;
      final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const channelCoord = '-33.86882, 151.20929';
      const channelMsg =
          '#wardriving https://meshcore.co.uk at ($channelCoord) SNR 7.5dB';

      await tester.runAsync(() async {
        connector.handleFrameForTest(
          ReviewFrames.channelMessage(
            channelIndex: channel.index,
            sender: 'Maya',
            message: channelMsg,
            timestampSecs: nowSecs - 30,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      final customTheme = MeshTheme.fromCustom(
        CustomTheme(
          id: 'test-forest',
          name: 'Forest',
          background: const Color(0xFF0E1A13),
          accent: const Color(0xFF4ADE80),
        ),
      );

      for (final scale in [1.3, 2.0]) {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final overflows = <String>[];
        final previousError = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.exceptionAsString();
          if (text.contains('overflowed')) {
            overflows.add(text.split('\n').first);
          } else {
            previousError?.call(details);
          }
        };
        addTearDown(() => FlutterError.onError = previousError);

        await _pumpApp(
          tester,
          providers,
          ChannelChatScreen(channel: channel),
          theme: customTheme,
          textScaler: TextScaler.linear(scale),
        );

        final coordFinder = find.textContaining(
          channelCoord,
          findRichText: true,
        );
        if (coordFinder.evaluate().isEmpty) {
          await tester.dragUntilVisible(
            coordFinder,
            find.byType(Scrollable).first,
            const Offset(0, 200),
            maxIteration: 30,
          );
        }
        await Scrollable.ensureVisible(
          tester.element(coordFinder.first),
          alignment: 0.5,
        );
        await _settle(tester);

        // Long-press coordinate in channel message -> bottom sheet fits 320dp without overflow.
        await tester.longPressAt(findSpanOffset(tester, channelCoord));
        await _settle(tester);
        expect(find.text(_l10n.coordinate_copyLocation), findsOneWidget);
        expect(find.text(_l10n.coordinate_openInMaps), findsOneWidget);
        Navigator.of(
          tester.element(find.text(_l10n.coordinate_copyLocation)),
        ).pop();
        await _settle(tester);

        // Tap coordinate -> CoordinateMapScreen fits 320dp without overflow.
        await tester.tapAt(findSpanOffset(tester, channelCoord));
        await _settle(tester);
        expect(find.byType(CoordinateMapScreen), findsOneWidget);

        // Verify 48dp touch targets on CoordinateMapScreen controls & AppBar buttons.
        for (final iconButton in tester.widgetList<IconButton>(
          find.byType(IconButton),
        )) {
          final box = tester.renderObject<RenderBox>(find.byWidget(iconButton));
          expect(box.size.width, greaterThanOrEqualTo(48));
          expect(box.size.height, greaterThanOrEqualTo(48));
        }

        await tester.pageBack();
        await _settle(tester);
        FlutterError.onError = previousError;
        expect(overflows, isEmpty);
      }

      await _tearDown(tester);
    },
  );

  for (final isDesktop in [false, true]) {
    final platformLabel = isDesktop ? 'desktop' : 'phone';

    testWidgets('MeshCoreConnector rebuild mid-press preserves coordinate tap, '
        'coordinate long-press, and URL tap ($platformLabel)', (tester) async {
      PlatformInfo.debugIsDesktopOverride = isDesktop;
      addTearDown(() => PlatformInfo.debugIsDesktopOverride = null);

      final (connector, providers) = _shared ??= await _connect(tester);
      final contact = connector.contacts.firstWhere(
        (c) => c.type == advTypeChat,
      );
      final channel = connector.channels.first;
      var nextSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const coord = '40.7128, -74.0060';
      const url = 'https://example.com/mid-press';
      const messageText = 'Visit $url or $coord now';

      await tester.runAsync(() async {
        connector.handleFrameForTest(
          ReviewFrames.contactMessage(
            senderPublicKey: contact.publicKey,
            text: messageText,
            timestampSecs: nextSecs - 10,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await _pumpApp(tester, providers, ChatScreen(contact: contact));

      Future<void> triggerConnectorRebuild(String label) async {
        nextSecs += 1;
        await tester.runAsync(() async {
          connector.handleFrameForTest(
            ReviewFrames.channelMessage(
              channelIndex: channel.index,
              sender: 'Relay',
              message: 'Rebuild trigger $label',
              timestampSecs: nextSecs,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        await tester.pump();
      }

      // 1. Coordinate tap survives a connector rebuild between pointer down and up.
      final tapCoordGesture = await tester.startGesture(
        findSpanOffset(tester, coord),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await triggerConnectorRebuild('coord-tap');
      await tapCoordGesture.up();
      await _settle(tester);

      expect(find.byType(CoordinateMapScreen), findsOneWidget);
      expect(find.text(coord), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);
      expect(find.byType(CoordinateMapScreen), findsNothing);

      // 2. Coordinate long-press survives a connector rebuild mid-hold.
      final longPressGesture = await tester.startGesture(
        findSpanOffset(tester, coord),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await triggerConnectorRebuild('coord-long-press');
      await tester.pump(const Duration(milliseconds: 350));
      await longPressGesture.up();
      await _settle(tester);

      expect(find.text(_l10n.coordinate_copyLocation), findsOneWidget);
      expect(find.text(_l10n.coordinate_openInMaps), findsOneWidget);
      Navigator.of(
        tester.element(find.text(_l10n.coordinate_copyLocation)),
      ).pop();
      await _settle(tester);

      // 3. Ordinary URL tap survives a connector rebuild between pointer down and up.
      final urlTapGesture = await tester.startGesture(
        findSpanOffset(tester, url),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await triggerConnectorRebuild('url-tap');
      await urlTapGesture.up();
      await _settle(tester);

      expect(find.text(_l10n.chat_openLink), findsOneWidget);
      await tester.tap(find.text(_l10n.common_cancel));
      await _settle(tester);

      await _tearDown(tester);
    });
  }

  testWidgets(
    'buildLinkifyText keeps recognizers across style rebuilds and updates on text change',
    (tester) async {
      PlatformInfo.debugIsDesktopOverride = false;
      addTearDown(() => PlatformInfo.debugIsDesktopOverride = null);

      final (_, providers) = _shared ??= await _connect(tester);
      final stateNotifier = ValueNotifier<({String text, Color color})>((
        text: 'Check https://example.com/a and 37.7749, -122.4194',
        color: Colors.black,
      ));
      addTearDown(stateNotifier.dispose);

      await _pumpApp(
        tester,
        providers,
        Scaffold(
          body: Center(
            child: ValueListenableBuilder<({String text, Color color})>(
              valueListenable: stateNotifier,
              builder: (context, value, _) => LinkHandler.buildLinkifyText(
                context: context,
                text: value.text,
                style: TextStyle(fontSize: 14, color: value.color),
              ),
            ),
          ),
        ),
      );

      // Rebuild with a new style while holding down on the coordinate.
      final gesture = await tester.startGesture(
        findSpanOffset(tester, '37.7749, -122.4194'),
      );
      await tester.pump(const Duration(milliseconds: 50));
      stateNotifier.value = (
        text: stateNotifier.value.text,
        color: Colors.blue,
      );
      await tester.pump();
      await gesture.up();
      await _settle(tester);

      expect(find.byType(CoordinateMapScreen), findsOneWidget);
      expect(find.text('37.7749, -122.4194'), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);

      // Updating text replaces recognizers so tapping the new coordinate opens its pin.
      stateNotifier.value = (
        text: 'Moved to 48.8566, 2.3522',
        color: Colors.blue,
      );
      await _settle(tester);

      await tester.tapAt(findSpanOffset(tester, '48.8566, 2.3522'));
      await _settle(tester);

      expect(find.byType(CoordinateMapScreen), findsOneWidget);
      final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(flutterMap.options.initialCenter.latitude, closeTo(48.8566, 1e-6));
      expect(flutterMap.options.initialCenter.longitude, closeTo(2.3522, 1e-6));

      await _tearDown(tester);
    },
  );
}

Future<void> _pumpApp(
  WidgetTester tester,
  List<SingleChildWidget> providers,
  Widget home, {
  ThemeData? theme,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: providers,
      child: MaterialApp(
        theme: theme ?? MeshTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
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
    while ((connector.contacts.isEmpty ||
            connector.channels.isEmpty ||
            !connector.channelMapConfirmed) &&
        DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });

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
