import 'dart:convert';
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
import 'package:meshcore_open/helpers/message_url_image_helper.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
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
import 'package:meshcore_open/widgets/gif_message.dart';
import 'package:meshcore_open/widgets/message_bubble_frame.dart';
import 'package:meshcore_open/widgets/received_image_message.dart';
import 'package:meshcore_open/widgets/shared_contact_card.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

const _contactShareHex =
    '50ba28f599799142622d188469a63f3890d495cdcedd24239052abd364c0283d';
const _contactShareToken = '<$_contactShareHex:1:Bob>';
const _gifToken = 'g:testgif123';
const _markerToken = 'm:45.515232,-122.678385|Camp|poi';
const _urlText = 'Check https://example.com/photo.png';
const _png1x1 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==';

(MeshCoreConnector, List<SingleChildWidget>, ReceivedImageStore)? _shared;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('copy_messages_test');
  String? copiedText;
  late bool previousLoadLinkImages;

  setUpAll(() async {
    previousLoadLinkImages = MessageUrlImageHelper.loadLinkImages.value;
    MessageUrlImageHelper.loadLinkImages.value = false;

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

    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  tearDownAll(() {
    MessageUrlImageHelper.loadLinkImages.value = previousLoadLinkImages;
    _shared = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    copiedText = null;
  });

  /// Scrolls the reversed chat ListView upward toward older items until
  /// [target] is built and centered in the viewport.
  Future<void> scrollToTarget(WidgetTester tester, Finder target) async {
    final scrollable = find.byType(Scrollable).first;
    if (target.evaluate().isEmpty) {
      await tester.dragUntilVisible(
        target,
        scrollable,
        const Offset(0, 200),
        maxIteration: 30,
      );
    }
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await _settle(tester);
  }

  /// Opens the message action sheet by long-pressing the bubble padding
  /// (outside desktop SelectableLinkify) and taps Copy.
  Future<void> copyFromBubbleContaining(
    WidgetTester tester,
    Finder contentFinder,
  ) async {
    await scrollToTarget(tester, contentFinder);
    final bubble = find.ancestor(
      of: contentFinder,
      matching: find.byType(MessageBubbleFrame),
    );
    await tester.longPressAt(tester.getTopLeft(bubble) + const Offset(8, 8));
    await _settle(tester);
    await tester.tap(find.text(_l10n.common_copy));
    await _settle(tester);
  }

  /// Opens the action sheet on a non-text special widget and taps Copy.
  Future<void> copyFromWidget(WidgetTester tester, Finder widgetFinder) async {
    await scrollToTarget(tester, widgetFinder);
    await tester.longPressAt(tester.getCenter(widgetFinder));
    await _settle(tester);
    await tester.tap(find.text(_l10n.common_copy));
    await _settle(tester);
  }

  group('ChannelChatScreen & ChatScreen copy', () {
    testWidgets('copies special channel messages (contact, GIF, location, URL) '
        'and image metadata/caption', (tester) async {
      final (connector, providers, imageStore) = _shared ??= await _connect(
        tester,
      );
      final channel = connector.channels[2];
      final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await tester.runAsync(() async {
        await connector.sendChannelMessage(channel, _contactShareToken);
        await connector.sendChannelMessage(channel, _gifToken);
        await connector.sendChannelMessage(channel, _markerToken);
        await connector.sendChannelMessage(channel, _urlText);

        connector.handleFrameForTest(
          ReviewFrames.channelMessage(
            channelIndex: channel.index,
            sender: 'Maya',
            message: _contactShareToken,
            timestampSecs: nowSecs - 40,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.channelMessage(
            channelIndex: channel.index,
            sender: 'Maya',
            message: _gifToken,
            timestampSecs: nowSecs - 30,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.channelMessage(
            channelIndex: channel.index,
            sender: 'Maya',
            message: _markerToken,
            timestampSecs: nowSecs - 20,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.channelMessage(
            channelIndex: channel.index,
            sender: 'Maya',
            message: _urlText,
            timestampSecs: nowSecs - 10,
          ),
        );

        await imageStore.registerOutgoing(
          channelIndex: channel.index,
          channelId: channel.storageId,
          senderPrefix: 0x1234,
          imgId: 1,
          previewPng: Uint8List.fromList(base64Decode(_png1x1)),
          rate: AeicRatePoint.ft32,
          chunkCount: 2,
          synthesized: true,
          payloadBytes: 156,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await _pump(tester, providers, ChannelChatScreen(channel: channel));

      // Image message (newest, at bottom): long-press -> Copy copies metadata
      // + R6 caption.
      final imageBubble = find.byType(ReceivedImageMessage);
      expect(imageBubble, findsOneWidget);
      await copyFromWidget(tester, imageBubble);
      expect(copiedText, contains(_l10n.receivedImage_awaiting(156, 2)));
      expect(copiedText, contains(_l10n.receivedImage_shareCaption(156)));

      // Received special messages
      await copyFromBubbleContaining(
        tester,
        find
            .textContaining('https://example.com/photo.png', findRichText: true)
            .first,
      );
      expect(copiedText, _urlText);

      await copyFromWidget(tester, find.text(_l10n.chat_poiShared).first);
      expect(copiedText, _markerToken);

      await copyFromWidget(tester, find.byType(GifMessage).first);
      expect(copiedText, _gifToken);

      await copyFromWidget(tester, find.byType(SharedContactCard).first);
      expect(copiedText, _contactShareToken);

      // Sent special messages (further up the transcript)
      await copyFromBubbleContaining(
        tester,
        find
            .textContaining('https://example.com/photo.png', findRichText: true)
            .last,
      );
      expect(copiedText, _urlText);

      await copyFromWidget(tester, find.text(_l10n.chat_poiShared).last);
      expect(copiedText, _markerToken);

      await copyFromWidget(tester, find.byType(GifMessage).last);
      expect(copiedText, _gifToken);

      await copyFromWidget(tester, find.byType(SharedContactCard).last);
      expect(copiedText, _contactShareToken);

      // Verify image action sheet fits 320dp at 1.3x and 2.0x text scale.
      for (final scale in [1.3, 2.0]) {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 568),
              textScaler: TextScaler.linear(scale),
            ),
            child: MultiProvider(
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
                home: ChannelChatScreen(channel: channel),
              ),
            ),
          ),
        );
        await _settle(tester);
        await scrollToTarget(tester, find.byType(ReceivedImageMessage));
        await tester.longPress(find.byType(ReceivedImageMessage));
        await _settle(tester);
        expect(find.text(_l10n.common_copy), findsOneWidget);
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.text(_l10n.common_copy))).pop();
        await _settle(tester);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();

      await _tearDown(tester);
    });

    testWidgets('copies regular, @[username], and special DM messages '
        '(sent and received)', (tester) async {
      final (connector, providers, _) = _shared ??= await _connect(tester);
      final contact = connector.contacts.firstWhere(
        (c) => c.type == advTypeChat,
      );
      final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await tester.runAsync(() async {
        await connector.sendMessage(contact, '@[Maya] DM mention sent');
        await connector.sendMessage(contact, _contactShareToken);
        await connector.sendMessage(contact, _gifToken);
        await connector.sendMessage(contact, _markerToken);
        await connector.sendMessage(contact, _urlText);

        connector.handleFrameForTest(
          ReviewFrames.contactMessage(
            senderPublicKey: contact.publicKey,
            text: 'Regular DM received',
            timestampSecs: nowSecs - 50,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.contactMessage(
            senderPublicKey: contact.publicKey,
            text: '@[Review Radio] DM mention received',
            timestampSecs: nowSecs - 40,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.contactMessage(
            senderPublicKey: contact.publicKey,
            text: _contactShareToken,
            timestampSecs: nowSecs - 30,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.contactMessage(
            senderPublicKey: contact.publicKey,
            text: _gifToken,
            timestampSecs: nowSecs - 20,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.contactMessage(
            senderPublicKey: contact.publicKey,
            text: _markerToken,
            timestampSecs: nowSecs - 10,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.contactMessage(
            senderPublicKey: contact.publicKey,
            text: _urlText,
            timestampSecs: nowSecs - 5,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await _pump(tester, providers, ChatScreen(contact: contact));

      await copyFromBubbleContaining(
        tester,
        find
            .textContaining('https://example.com/photo.png', findRichText: true)
            .first,
      );
      expect(copiedText, _urlText);

      await copyFromWidget(tester, find.text(_l10n.chat_poiShared).first);
      expect(copiedText, _markerToken);

      await copyFromWidget(tester, find.byType(GifMessage).first);
      expect(copiedText, _gifToken);

      await copyFromWidget(tester, find.byType(SharedContactCard).first);
      expect(copiedText, _contactShareToken);

      await copyFromBubbleContaining(
        tester,
        find.textContaining('DM mention received', findRichText: true),
      );
      expect(copiedText, '@[Review Radio] DM mention received');

      await copyFromBubbleContaining(
        tester,
        find.textContaining('Regular DM received', findRichText: true),
      );
      expect(copiedText, 'Regular DM received');

      await copyFromBubbleContaining(
        tester,
        find
            .textContaining('https://example.com/photo.png', findRichText: true)
            .last,
      );
      expect(copiedText, _urlText);

      await copyFromWidget(tester, find.text(_l10n.chat_poiShared).last);
      expect(copiedText, _markerToken);

      await copyFromWidget(tester, find.byType(GifMessage).last);
      expect(copiedText, _gifToken);

      await copyFromWidget(tester, find.byType(SharedContactCard).last);
      expect(copiedText, _contactShareToken);

      await copyFromBubbleContaining(
        tester,
        find.textContaining('DM mention sent', findRichText: true),
      );
      expect(copiedText, '@[Maya] DM mention sent');

      await _tearDown(tester);
    });

    testWidgets('copies sent and received channel replies with @[username] '
        'and leaves regular messages unchanged', (tester) async {
      final (connector, providers, _) = _shared ??= await _connect(tester);
      final channel = connector.channels[1];
      final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await tester.runAsync(() async {
        await connector.sendChannelMessage(channel, 'Plain outgoing');
        connector.handleFrameForTest(
          ReviewFrames.channelMessage(
            channelIndex: channel.index,
            sender: 'Maya',
            message: 'Regular channel hello',
            timestampSecs: nowSecs - 40,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.channelMessage(
            channelIndex: channel.index,
            sender: 'Jordan',
            message: '@[Maya] Matched channel reply',
            timestampSecs: nowSecs - 30,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.channelMessage(
            channelIndex: channel.index,
            sender: 'Sam',
            message: '@[GhostNode] Unmatched channel reply',
            timestampSecs: nowSecs - 20,
          ),
        );
        connector.handleFrameForTest(
          ReviewFrames.channelMessage(
            channelIndex: channel.index,
            sender: 'Ranger Pat',
            message: 'Reply target message',
            timestampSecs: nowSecs - 10,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await _pump(tester, providers, ChannelChatScreen(channel: channel));

      // Reply to Ranger Pat's message via UI composer and send.
      final replyTargetText = find.textContaining(
        'Reply target message',
        findRichText: true,
      );
      await scrollToTarget(tester, replyTargetText);
      final targetBubble = find.ancestor(
        of: replyTargetText,
        matching: find.byType(MessageBubbleFrame),
      );
      await tester.longPressAt(
        tester.getTopLeft(targetBubble) + const Offset(8, 8),
      );
      await _settle(tester);
      await tester.tap(find.text(_l10n.chat_reply));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Sent reply body');
      await _settle(tester);
      await tester.tap(find.byTooltip(_l10n.chat_sendMessage));
      await _settle(tester);

      // 1. Sent reply includes @[Ranger Pat].
      await copyFromBubbleContaining(
        tester,
        find.textContaining('Sent reply body', findRichText: true),
      );
      expect(copiedText, '@[Ranger Pat] Sent reply body');

      // 2. Bulk copy on the sent reply also includes @[Ranger Pat].
      final sentReplyBubble = find.ancestor(
        of: find.textContaining('Sent reply body', findRichText: true),
        matching: find.byType(MessageBubbleFrame),
      );
      await tester.longPressAt(
        tester.getTopLeft(sentReplyBubble) + const Offset(8, 8),
      );
      await _settle(tester);
      await tester.tap(find.text(_l10n.chat_selectMessages));
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await _settle(tester);
      await tester.tap(find.text(_l10n.common_copy));
      await _settle(tester);
      expect(copiedText, '@[Ranger Pat] Sent reply body');

      // 3. Received unmatched reply includes @[GhostNode].
      await copyFromBubbleContaining(
        tester,
        find.textContaining('Unmatched channel reply', findRichText: true),
      );
      expect(copiedText, '@[GhostNode] Unmatched channel reply');

      // 4. Received matched reply includes @[Maya].
      await copyFromBubbleContaining(
        tester,
        find.textContaining('Matched channel reply', findRichText: true),
      );
      expect(copiedText, '@[Maya] Matched channel reply');

      // 5. Regular incoming message unchanged.
      await copyFromBubbleContaining(
        tester,
        find.textContaining('Regular channel hello', findRichText: true).last,
      );
      expect(copiedText, 'Regular channel hello');

      // 6. Regular outgoing message unchanged.
      await copyFromBubbleContaining(
        tester,
        find.textContaining('Plain outgoing', findRichText: true),
      );
      expect(copiedText, 'Plain outgoing');

      await _tearDown(tester);
    });
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
  await tester.pump(const Duration(hours: 2));
}

Future<(MeshCoreConnector, List<SingleChildWidget>, ReceivedImageStore)>
_connect(WidgetTester tester) async {
  final storage = StorageService();
  final connector = MeshCoreConnector();
  final retry = MessageRetryService();
  final settings = AppSettingsService();
  final translation = TranslationService(settings);
  final imageStore = ReceivedImageStore();

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
      ackDelay: const Duration(milliseconds: 50),
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
      ChangeNotifierProvider.value(value: imageStore),
    ],
    imageStore,
  );
}
