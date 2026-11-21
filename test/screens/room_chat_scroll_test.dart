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
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/review_mode/review_frames.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
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
import 'package:meshcore_open/storage/message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/unread_divider.dart';

/// Room chats receive their backlog as a burst of messages right after login.
/// These tests feed such a burst into an open room chat and check that the
/// reader's place holds, and that opening the chat still lands where the
/// unread preference says.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('room_scroll_test');
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

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(400, 800);
    view.devicePixelRatio = 1.0;
  });
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .reset(),
  );

  testWidgets('a sync burst keeps the reader on the message they were '
      'reading', (tester) async {
    final (connector, room) = await _openRoom(tester, history: 60);
    final controller = _listController(tester);

    controller.jumpTo(1500);
    await _settle(tester);
    final reading = _lowestVisibleMessage(tester);
    final before = tester.getTopLeft(reading).dy;

    // One at a time, as the radio hands queued posts over, then a batch
    // that lands within a single frame.
    for (var i = 0; i < 5; i++) {
      _receive(connector, room, 'synced single $i');
      await tester.pump();
    }
    for (var i = 0; i < 25; i++) {
      _receive(connector, room, 'synced batch $i');
    }
    await _settle(tester);

    expect(connector.getMessages(room), hasLength(90));
    expect(reading, findsOneWidget);
    expect(tester.getTopLeft(reading).dy, moreOrLessEquals(before));
    await _tearDown(tester);
  });

  testWidgets('a reader starting to scroll up during sync is not pulled '
      'back to the newest message', (tester) async {
    final (connector, room) = await _openRoom(tester, history: 60);
    final controller = _listController(tester);
    expect(controller.position.pixels, 0);

    final gesture = await tester.startGesture(const Offset(200, 400));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 25));
      _receive(connector, room, 'during drag $i');
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await _settle(tester);

    expect(connector.getMessages(room), hasLength(72));
    expect(controller.position.pixels, greaterThan(200));
    await _tearDown(tester);
  });

  testWidgets('first open at the bottom still follows new messages', (
    tester,
  ) async {
    final (connector, room) = await _openRoom(tester, history: 60);
    final controller = _listController(tester);
    expect(controller.position.pixels, 0);

    for (var i = 0; i < 5; i++) {
      _receive(connector, room, 'newest $i');
      await tester.pump();
    }
    await _settle(tester);

    expect(connector.getMessages(room), hasLength(65));
    expect(controller.position.pixels, 0);
    expect(find.text('newest 4', findRichText: true), findsOneWidget);
    await _tearDown(tester);
  });

  testWidgets('jump to oldest unread lands on the divider and holds through '
      'a sync burst', (tester) async {
    final (connector, room) = await _openRoom(
      tester,
      history: 60,
      unread: 30,
      jumpToOldestUnread: true,
    );
    final controller = _listController(tester);
    // history 30 is the oldest of the 30 unread messages.
    final anchor = find.text('history 30', findRichText: true);
    expect(anchor, findsOneWidget);
    expect(find.byType(UnreadDivider), findsOneWidget);
    expect(controller.position.pixels, greaterThan(100));
    final before = tester.getTopLeft(anchor).dy;
    expect(before, inInclusiveRange(0, 800));

    for (var i = 0; i < 10; i++) {
      _receive(connector, room, 'after open $i');
      await tester.pump();
    }
    await _settle(tester);
    expect(connector.getMessages(room), hasLength(70));
    expect(tester.getTopLeft(anchor).dy, moreOrLessEquals(before));
    await _tearDown(tester);
  });

  testWidgets('older pages loaded in an open chat survive new messages', (
    tester,
  ) async {
    final (connector, room) = await _openRoom(tester, history: 230);
    final window = connector.getMessages(room);
    expect(window, hasLength(200));
    final older = await tester.runAsync(
      () => connector.loadOlderMessages(room.publicKeyHex),
    );
    expect(older, isNotEmpty);
    final paged = connector.getMessages(room).length;
    expect(paged, greaterThan(200));

    _receive(connector, room, 'arrives while reading history');
    await _settle(tester);
    expect(connector.getMessages(room), hasLength(paged + 1));
    expect(connector.getMessages(room).first.text, older!.first.text);
    await _tearDown(tester);
  });

  testWidgets('an open chat still caps its window at the stored limit', (
    tester,
  ) async {
    final (connector, room) = await _openRoom(tester, history: 0);
    for (var i = 0; i < MessageStore.maxStoredMessages + 10; i++) {
      _receive(connector, room, 'flood $i');
    }
    final window = connector.getMessages(room);
    expect(window, hasLength(MessageStore.maxStoredMessages));
    expect(window.last.text, 'flood ${MessageStore.maxStoredMessages + 9}');
    await _tearDown(tester);
  });
}

var _timestamp = 1700000000;

void _receive(MeshCoreConnector connector, Contact room, String text) {
  connector.handleFrameForTest(
    ReviewFrames.contactMessage(
      senderPublicKey: room.publicKey,
      text: text,
      timestampSecs: _timestamp++,
    ),
  );
}

ScrollController _listController(WidgetTester tester) => tester
    .widget<ListView>(find.byWidgetPredicate((w) => w is ListView))
    .controller!;

/// The on-screen history message nearest the bottom of the list.
Finder _lowestVisibleMessage(WidgetTester tester) {
  Finder? best;
  var bestY = double.negativeInfinity;
  for (var i = 0; i < 60; i++) {
    final finder = find.text('history $i', findRichText: true);
    if (finder.evaluate().isEmpty) continue;
    final y = tester.getTopLeft(finder).dy;
    if (y > 80 && y < 600 && y > bestY) {
      bestY = y;
      best = finder;
    }
  }
  expect(best, isNotNull, reason: 'a history message should be on screen');
  return best!;
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

/// Connects the review radio, gives its room [history] messages and opens
/// the room chat as a login does, with [unread] of them unread.
Future<(MeshCoreConnector, Contact)> _openRoom(
  WidgetTester tester, {
  required int history,
  int unread = 0,
  bool jumpToOldestUnread = false,
}) async {
  final (connector, providers, settings) = _shared ??= await _connect(tester);
  await tester.runAsync(
    () => settings.setJumpToOldestUnread(jumpToOldestUnread),
  );
  final room = connector.contacts.firstWhere((c) => c.type == advTypeRoom);
  connector.clearMessagesForContact(room);
  await tester.runAsync(() => connector.flushPendingWrites());
  for (var i = 0; i < history; i++) {
    _receive(connector, room, 'history $i');
  }
  expect(connector.getMessages(room), hasLength(history.clamp(0, 200)));
  connector.markContactRead(room.publicKeyHex);
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
        home: ChatScreen(contact: room, initialUnreadCount: unread),
      ),
    ),
  );
  await _settle(tester);
  return (connector, room);
}

/// One review-radio connection shared by the tests: reconnecting it in the
/// same run does not resend the contact list.
(MeshCoreConnector, List<SingleChildWidget>, AppSettingsService)? _shared;

Future<(MeshCoreConnector, List<SingleChildWidget>, AppSettingsService)>
_connect(WidgetTester tester) async {
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
    while (!connector.contacts.any((c) => c.type == advTypeRoom) &&
        DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    // Let the connect-time message sync finish so test frames are not held.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  expect(connector.contacts.any((c) => c.type == advTypeRoom), isTrue);

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
    settings,
  );
}
