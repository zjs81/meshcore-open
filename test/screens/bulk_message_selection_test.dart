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

/// Multi-select in channels, direct chats and rooms: taps must register
/// within 250 ms (no double-tap recognizer may hold them back), and direct
/// and room chats offer the same bulk actions as channels.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('bulk_selection_test');
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
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  testWidgets('direct and room chats: bulk bookmark saves every selected '
      'message', (tester) async {
    // One test for both: a bookmark write started in fake time only finishes
    // inside that test, and the next write queues behind it.
    for (final room in [false, true]) {
      final p = room ? 'room' : 'dm';
      _view(tester, const Size(400, 800));
      final (connector, chat) = await _pumpChat(tester, room: room);
      // Room posts name their author by key prefix; the bookmark must carry
      // that author's name, not the room server's.
      final authors = connector.contacts
          .where((c) => c.type == advTypeChat)
          .take(2)
          .toList();
      final posts = ['by author one', 'by author two'];
      if (room) {
        expect(authors, hasLength(2));
        for (var i = 0; i < 2; i++) {
          connector.handleFrameForTest(
            _roomPost(chat, authors[i], posts[i], _stamp++),
          );
        }
        await _settle(tester);
      }
      await _enterChatSelection(tester, '$p 8');
      await tester.tap(
        find.textContaining('$p 9', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 250));
      if (room) {
        for (final post in posts) {
          await tester.tap(
            find.textContaining(post, findRichText: true),
            warnIfMissed: false,
          );
          await tester.pump(const Duration(milliseconds: 250));
        }
      }
      await tester.tap(find.byTooltip('Bookmark'));
      await _settle(tester);
      // Bookmarks are stored per radio in the preferences; the writes
      // started in fake time need real time to finish.
      final prefs = PrefsManager.instance;
      String stored() => [
        for (final key in prefs.getKeys())
          if (key.startsWith('message_bookmarks_')) prefs.getString(key) ?? '',
      ].join();
      for (
        var i = 0;
        i < 200 && !stored().contains(room ? posts[1] : '$p 9');
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      final saved = stored();
      expect(saved, contains('"text":"$p 8"'));
      expect(saved, contains('"text":"$p 9"'));
      expect(saved, isNot(contains('"text":"$p 7"')));
      if (room) {
        for (var i = 0; i < 2; i++) {
          final entry = RegExp(
            '\\{[^{}]*"text":"${posts[i]}"[^{}]*\\}',
          ).firstMatch(saved)?.group(0);
          expect(entry, isNotNull, reason: 'missing ${posts[i]}');
          expect(entry, contains('"senderName":"${authors[i].name}"'));
          expect(entry, isNot(contains('"senderName":"${chat.name}"')));
        }
      }
      expect(find.textContaining('selected'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
    await _tearDown(tester);
  });

  group('instant selection taps', () {
    testWidgets('channel: a tap selects within 250 ms and two taps 100 ms '
        'apart both select', (tester) async {
      _view(tester, const Size(400, 800));
      await _pumpChannel(tester);
      await _enterChannelSelection(tester);
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(
        find.textContaining('History 38', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(
        find.textContaining('History 37', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('3 selected'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));

      // A lone tap needs no extra time either.
      await tester.tap(
        find.textContaining('History 36', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
      await _tearDown(tester);
    });

    testWidgets('channel: a single frame after the tap already shows it', (
      tester,
    ) async {
      _view(tester, const Size(400, 800));
      await _pumpChannel(tester);
      await _enterChannelSelection(tester);
      await tester.tap(
        find.textContaining('History 38', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      await _tearDown(tester);
    });

    testWidgets('direct chat: taps select within 250 ms', (tester) async {
      _view(tester, const Size(400, 800));
      final dm = await _pumpChat(tester, room: false);
      await _enterChatSelection(tester, 'dm 9');
      await tester.tap(
        find.textContaining('dm 8', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(
        find.textContaining('dm 7', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('3 selected'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
      expect(dm.$1.getMessages(dm.$2), isNotEmpty);
      await _tearDown(tester);
    });

    testWidgets('room chat: taps select within 250 ms', (tester) async {
      _view(tester, const Size(400, 800));
      await _pumpChat(tester, room: true);
      await _enterChatSelection(tester, 'room 9');
      await tester.tap(
        find.textContaining('room 8', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(
        find.textContaining('room 7', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('3 selected'), findsOneWidget);
      await _tearDown(tester);
    });

    testWidgets('long press on a row toggles it while selecting', (
      tester,
    ) async {
      _view(tester, const Size(400, 800));
      await _pumpChat(tester, room: false);
      await _enterChatSelection(tester, 'dm 9');
      await tester.longPress(
        find.textContaining('dm 8', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('2 selected'), findsOneWidget);
      await tester.longPress(
        find.textContaining('dm 8', findRichText: true),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('1 selected'), findsOneWidget);
      await _tearDown(tester);
    });
  });

  for (final room in [false, true]) {
    final name = room ? 'room chat' : 'direct chat';
    final p = room ? 'room' : 'dm';

    group('$name bulk actions', () {
      testWidgets('back clears the selection instead of leaving', (
        tester,
      ) async {
        _view(tester, const Size(400, 800));
        await _pumpChat(tester, room: room);
        await _enterChatSelection(tester, '$p 9');
        await tester.tap(
          find.textContaining('$p 8', findRichText: true),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('2 selected'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.textContaining('selected'), findsNothing);
        expect(find.byType(ChatScreen), findsOneWidget);
        await _tearDown(tester);
      });

      testWidgets('copy puts the selected messages oldest first', (
        tester,
      ) async {
        _view(tester, const Size(400, 800));
        await _pumpChat(tester, room: room);
        await _enterChatSelection(tester, '$p 8');
        await tester.tap(
          find.textContaining('$p 5', findRichText: true),
          warnIfMissed: false,
        );
        await tester.tap(
          find.textContaining('$p 9', findRichText: true),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byTooltip('Copy'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(clipboard, '$p 5\n$p 8\n$p 9');
        expect(find.textContaining('selected'), findsNothing);
        await _tearDown(tester);
      });

      testWidgets('delete asks first, then removes the selected messages', (
        tester,
      ) async {
        _view(tester, const Size(400, 800));
        final (connector, contact) = await _pumpChat(tester, room: room);
        await _enterChatSelection(tester, '$p 8');
        await tester.tap(
          find.textContaining('$p 9', findRichText: true),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byTooltip('Delete'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(
          find.text('Delete 2 messages from this device?'),
          findsOneWidget,
        );
        await tester.tap(find.text('Delete'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 250));
        final texts = connector.getMessages(contact).map((m) => m.text);
        expect(texts, isNot(contains('$p 8')));
        expect(texts, isNot(contains('$p 9')));
        expect(texts, contains('$p 7'));
        await _tearDown(tester);
      });

      testWidgets('resend confirms, cancel does nothing, confirm resends', (
        tester,
      ) async {
        _view(tester, const Size(400, 800));
        final (connector, contact) = await _pumpChat(
          tester,
          room: room,
          outgoing: true,
        );
        List<String> ids() => [
          for (final m in connector.getMessages(contact))
            if (m.isOutgoing) m.messageId,
        ];
        final before = ids();
        expect(before, hasLength(2));

        await _enterChatSelection(tester, '$p out 1');
        await tester.tap(
          find.textContaining('$p out 2', findRichText: true),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byTooltip('Resend'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(
          find.text('Resend 2 selected outgoing messages to this contact?'),
          findsOneWidget,
        );

        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(ids(), before);
        expect(find.text('2 selected'), findsOneWidget);

        await tester.tap(find.byTooltip('Resend'));
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.widgetWithText(FilledButton, 'Resend'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump(const Duration(milliseconds: 250));
        final after = ids();
        expect(after, hasLength(2));
        expect(after, isNot(before));
        expect(find.textContaining('selected'), findsNothing);
        await _tearDown(tester);
      });
    });
  }

  group('no overflow at 320 dp', () {
    for (final scale in [1.3, 2.0]) {
      testWidgets('channel selection bar at ${scale}x text', (tester) async {
        _view(tester, const Size(320, 700));
        await _pumpChannel(tester, textScale: scale);
        await _enterChannelSelection(tester);
        await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.takeException(), isNull);
        await _tearDown(tester);
      });

      testWidgets('direct chat selection bar at ${scale}x text', (
        tester,
      ) async {
        _view(tester, const Size(320, 700));
        await _pumpChat(tester, room: false, outgoing: true, textScale: scale);
        await _enterChatSelection(tester, 'dm out 2');
        expect(find.byTooltip('Resend'), findsOneWidget);
        expect(find.byTooltip('Delete'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _tearDown(tester);
      });
    }
  });
}

/// A room-server post: a signed contact message whose 4-byte "signature" is
/// the author's public key prefix.
Uint8List _roomPost(Contact room, Contact author, String text, int stamp) {
  final writer = BufferWriter();
  writer.writeByte(respCodeContactMsgRecvV3);
  writer.writeByte(24);
  writer.writeByte(0);
  writer.writeByte(0);
  writer.writeBytes(Uint8List.fromList(room.publicKey.sublist(0, 6)));
  writer.writeByte(0xFF);
  writer.writeByte(txtTypeSigned);
  writer.writeUInt32LE(stamp);
  writer.writeBytes(Uint8List.fromList(author.publicKey.sublist(0, 4)));
  writer.writeString(text);
  writer.writeByte(0);
  return writer.toBytes();
}

String? clipboard;

void _view(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tearDown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  // Let writes started during the test finish, so they cannot stall the
  // next test's preferences writes.
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 25));
  }
  await tester.pump(const Duration(minutes: 1));
}

/// Opens the message action sheet for the message showing [text] (by calling
/// its long-press handler: a real long press on bubble text starts text
/// selection in tests) and picks "Select messages".
Future<void> _enterSelectionFrom(WidgetTester tester, Finder message) async {
  // The row's long-press detector wraps the bubble, so it is an ancestor of
  // the message text whatever the text scale.
  final detector = find
      .ancestor(
        of: message.first,
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onLongPress != null,
        ),
      )
      .first
      .evaluate()
      .single;
  (detector.widget as GestureDetector).onLongPress!();
  await _settle(tester);
  await tester.ensureVisible(find.text('Select messages'));
  await tester.pump();
  await tester.tap(find.text('Select messages'));
  await _settle(tester);
}

Future<void> _enterChannelSelection(WidgetTester tester) => _enterSelectionFrom(
  tester,
  find.textContaining('History 39', findRichText: true),
);

Future<void> _enterChatSelection(WidgetTester tester, String text) =>
    _enterSelectionFrom(tester, find.textContaining(text, findRichText: true));

(MeshCoreConnector, List<SingleChildWidget>)? _shared;

Widget _app(List<SingleChildWidget> providers, Widget home, double textScale) =>
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    );

var _stamp = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 100000;

Future<MeshCoreConnector> _pumpChannel(
  WidgetTester tester, {
  double textScale = 1.0,
}) async {
  final (connector, providers) = _shared ??= await _connect(tester);
  final channel = connector.channels[0];
  if (connector.getChannelMessages(channel).length < 40) {
    for (var i = 0; i < 40; i++) {
      connector.handleFrameForTest(
        ReviewFrames.channelMessage(
          channelIndex: channel.index,
          sender: 'Alice',
          message: 'History $i',
          timestampSecs: _stamp + i * 60,
        ),
      );
    }
  }
  await tester.pumpWidget(
    _app(providers, ChannelChatScreen(channel: channel), textScale),
  );
  await _settle(tester);
  return connector;
}

/// Shows a direct chat (or the review radio's room) holding ten incoming
/// messages "dm 0".."dm 9" / "room 0".."room 9", plus two outgoing ones when
/// [outgoing].
Future<(MeshCoreConnector, Contact)> _pumpChat(
  WidgetTester tester, {
  required bool room,
  bool outgoing = false,
  double textScale = 1.0,
  bool fresh = false,
}) async {
  final (connector, providers) = fresh
      ? await _connect(tester)
      : (_shared ??= await _connect(tester));
  final contact = connector.contacts.firstWhere(
    (c) => room ? c.type == advTypeRoom : c.type == advTypeChat,
  );
  final p = room ? 'room' : 'dm';
  connector.clearMessagesForContact(contact);
  await tester.runAsync(() => connector.flushPendingWrites());
  for (var i = 0; i < 10; i++) {
    connector.handleFrameForTest(
      ReviewFrames.contactMessage(
        senderPublicKey: contact.publicKey,
        text: '$p $i',
        timestampSecs: _stamp++,
      ),
    );
  }
  if (outgoing) {
    await tester.runAsync(() async {
      await connector.sendMessage(contact, '$p out 1');
      await connector.sendMessage(contact, '$p out 2');
    });
  }
  connector.markContactRead(contact.publicKeyHex);
  await tester.pumpWidget(
    _app(providers, ChatScreen(contact: contact), textScale),
  );
  await _settle(tester);
  return (connector, contact);
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
    while ((!connector.contacts.any((c) => c.type == advTypeRoom) ||
            !connector.contacts.any((c) => c.type == advTypeChat) ||
            connector.channels.length < 2) &&
        DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
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
