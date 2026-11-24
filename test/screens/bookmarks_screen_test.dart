import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/bookmarked_message.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/screens/bookmarks_screen.dart';
import 'package:meshcore_open/screens/channel_chat_screen.dart';
import 'package:meshcore_open/screens/chat_screen.dart';
import 'package:meshcore_open/screens/contacts_screen.dart';
import 'package:meshcore_open/services/app_debug_log_service.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/ble_debug_log_service.dart';
import 'package:meshcore_open/services/chat_text_scale_service.dart';
import 'package:meshcore_open/services/image_codec_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/network_map/network_map_upload_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/received_image_store.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/timeout_prediction_service.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/services/ui_view_state_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';
import 'package:meshcore_open/widgets/message_bubble_frame.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

class _TestEnv {
  final MeshCoreConnector connector;
  final Widget Function(Widget home, {double textScale}) wrap;

  _TestEnv({required this.connector, required this.wrap});
}

_TestEnv? _sharedEnv;

Future<T> _pumpFuture<T>(WidgetTester tester, Future<T> future) async {
  var done = false;
  late T result;
  Object? error;
  StackTrace? stack;
  future.then(
    (value) {
      result = value;
      done = true;
    },
    onError: (Object e, StackTrace s) {
      error = e;
      stack = s;
      done = true;
    },
  );
  for (var i = 0; i < 50 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  if (!done) {
    throw StateError('Timed out pumping future in FakeAsync');
  }
  if (error != null) Error.throwWithStackTrace(error!, stack!);
  return result;
}

Future<_TestEnv> _createEnv(WidgetTester tester) async {
  if (_sharedEnv != null) {
    final existing = _sharedEnv!;
    final bookmarks = await _pumpFuture(
      tester,
      existing.connector.loadBookmarkedMessages(),
    );
    for (final bookmark in bookmarks) {
      await _pumpFuture(
        tester,
        existing.connector.setBookmarkedMessage(bookmark, isBookmarked: false),
      );
    }
    for (final channel in existing.connector.channels) {
      for (final msg in existing.connector.getChannelMessages(channel)) {
        if (msg.isBookmarked) {
          await _pumpFuture(
            tester,
            existing.connector.setBookmarkedMessage(
              BookmarkedMessage.fromChannel(
                message: msg,
                channelId: channel.storageId ?? 'slot:${channel.index}',
                channelName: channel.name,
                senderName: msg.senderName,
              ),
              isBookmarked: false,
            ),
          );
        }
      }
    }
    return existing;
  }
  late final StorageService storage;
  late final MeshCoreConnector connector;
  late final MessageRetryService retry;
  late final AppSettingsService settings;
  late final TranslationService translation;
  late final UiViewStateService viewState;

  await tester.runAsync(() async {
    storage = StorageService();
    connector = MeshCoreConnector();
    retry = MessageRetryService();
    settings = AppSettingsService();
    translation = TranslationService(settings);
    viewState = UiViewStateService();
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
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  });

  final providers = [
    ChangeNotifierProvider.value(value: connector),
    ChangeNotifierProvider.value(value: retry),
    ChangeNotifierProvider.value(value: PathHistoryService(storage)),
    ChangeNotifierProvider.value(value: settings),
    ChangeNotifierProvider.value(value: BleDebugLogService()),
    ChangeNotifierProvider.value(value: AppDebugLogService()),
    ChangeNotifierProvider.value(value: ChatTextScaleService()),
    ChangeNotifierProvider.value(value: translation),
    ChangeNotifierProvider.value(value: viewState),
    Provider.value(value: storage),
    ChangeNotifierProvider.value(
      value: MapTileCacheService(appSettingsService: settings),
    ),
    ChangeNotifierProvider.value(value: TimeoutPredictionService(storage)),
    ChangeNotifierProvider.value(value: ImageCodecService(settings)),
    ChangeNotifierProvider.value(value: ReceivedImageStore()),
    ChangeNotifierProvider.value(
      value: NetworkMapUploadService(connector: connector, settings: settings),
    ),
  ];

  Widget wrap(Widget home, {double textScale = 1.0}) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        key: UniqueKey(),
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
  }

  return _sharedEnv = _TestEnv(connector: connector, wrap: wrap);
}

Future<void> _pumpFrames(WidgetTester tester, [int count = 8]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _segmentByText(String label) =>
    find.byWidgetPredicate((w) => w is MeshSegmentLabel && w.text == label);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('bookmarks_screen_test');
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

  testWidgets(
    'Contacts overflow menu includes Bookmarks after Discovered Contacts and opens BookmarksScreen',
    (tester) async {
      final env = await _createEnv(tester);
      await tester.pumpWidget(env.wrap(const ContactsScreen()));
      await _pumpFrames(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await _pumpFrames(tester);

      expect(find.text(_l10n.discoveredContacts_Title), findsOneWidget);
      expect(find.text(_l10n.bookmarks_title), findsOneWidget);

      await tester.tap(find.text(_l10n.bookmarks_title));
      await _pumpFrames(tester);

      expect(find.byType(BookmarksScreen), findsOneWidget);
      // No split pill when opened from main Contacts screen.
      expect(find.byType(SegmentedButton<bool>), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
    },
  );

  testWidgets(
    'ChannelChatScreen and ChatScreen overflow menus open BookmarksScreen with split pill filter',
    (tester) async {
      final env = await _createEnv(tester);
      final channel = env.connector.channels.firstWhere(
        (c) => c.name == 'Public',
      );
      final contact = env.connector.contacts.firstWhere(
        (c) => c.name == 'Maya',
      );

      final channelBookmark = BookmarkedMessage(
        sourceType: BookmarkSourceType.channel,
        sourceId: channel.storageId ?? 'slot:${channel.index}',
        sourceName: channel.name,
        messageId: 'ch-msg-1',
        senderName: 'Maya',
        text: 'Public channel bookmarked note',
        timestamp: DateTime(2026, 1, 1, 10),
        receivedAt: DateTime(2026, 1, 1, 10),
        isOutgoing: false,
      );
      final contactBookmark = BookmarkedMessage(
        sourceType: BookmarkSourceType.contact,
        sourceId: contact.publicKeyHex,
        sourceName: contact.name,
        messageId: 'dm-msg-1',
        senderName: contact.name,
        text: 'Direct message bookmarked note',
        timestamp: DateTime(2026, 1, 1, 11),
        receivedAt: DateTime(2026, 1, 1, 11),
        isOutgoing: false,
      );

      await _pumpFuture(
        tester,
        env.connector.setBookmarkedMessage(channelBookmark, isBookmarked: true),
      );
      await _pumpFuture(
        tester,
        env.connector.setBookmarkedMessage(contactBookmark, isBookmarked: true),
      );

      // 1. Open from ChannelChatScreen
      await tester.pumpWidget(env.wrap(ChannelChatScreen(channel: channel)));
      await _pumpFrames(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await _pumpFrames(tester);
      expect(find.text(_l10n.bookmarks_title), findsOneWidget);

      await tester.tap(find.text(_l10n.bookmarks_title));
      await _pumpFrames(tester);

      expect(find.byType(BookmarksScreen), findsOneWidget);
      expect(find.byType(SegmentedButton<bool>), findsOneWidget);
      expect(_segmentByText(_l10n.listFilter_all), findsOneWidget);
      expect(_segmentByText('#Public'), findsOneWidget);

      // Defaults to current channel's bookmarks only.
      expect(find.text('Public channel bookmarked note'), findsOneWidget);
      expect(find.text('Direct message bookmarked note'), findsNothing);

      // Tap "All" segment to view all bookmarks across the app.
      await tester.tap(_segmentByText(_l10n.listFilter_all));
      await _pumpFrames(tester);

      expect(find.text('Public channel bookmarked note'), findsOneWidget);
      expect(find.text('Direct message bookmarked note'), findsOneWidget);

      // Tap "#Public" segment to scope back to channel.
      await tester.tap(_segmentByText('#Public'));
      await _pumpFrames(tester);

      expect(find.text('Public channel bookmarked note'), findsOneWidget);
      expect(find.text('Direct message bookmarked note'), findsNothing);

      // 2. Open from ChatScreen (contact DM)
      await tester.pumpWidget(env.wrap(ChatScreen(contact: contact)));
      await _pumpFrames(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await _pumpFrames(tester);
      expect(find.text(_l10n.bookmarks_title), findsOneWidget);

      await tester.tap(find.text(_l10n.bookmarks_title));
      await _pumpFrames(tester);

      expect(find.byType(BookmarksScreen), findsOneWidget);
      expect(_segmentByText(_l10n.listFilter_all), findsOneWidget);
      expect(_segmentByText('Maya'), findsOneWidget);
      expect(find.text('Direct message bookmarked note'), findsOneWidget);
      expect(find.text('Public channel bookmarked note'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
    },
  );

  testWidgets(
    'Search in BookmarksScreen finds matching bookmarks and jumping highlights target card',
    (tester) async {
      final env = await _createEnv(tester);
      final b1 = BookmarkedMessage(
        sourceType: BookmarkSourceType.channel,
        sourceId: 'slot:0',
        sourceName: 'Public',
        messageId: 'm1',
        senderName: 'Sam',
        text: 'Alpha repeater check on ridge',
        timestamp: DateTime(2026, 1, 1, 9),
        receivedAt: DateTime(2026, 1, 1, 9),
        isOutgoing: false,
      );
      final b2 = BookmarkedMessage(
        sourceType: BookmarkSourceType.contact,
        sourceId: 'contact-1',
        sourceName: 'Maya',
        messageId: 'm2',
        senderName: 'Maya',
        text: 'Bravo solar battery voltage update',
        timestamp: DateTime(2026, 1, 1, 10),
        receivedAt: DateTime(2026, 1, 1, 10),
        isOutgoing: false,
      );

      await _pumpFuture(
        tester,
        env.connector.setBookmarkedMessage(b1, isBookmarked: true),
      );
      await _pumpFuture(
        tester,
        env.connector.setBookmarkedMessage(b2, isBookmarked: true),
      );

      await tester.pumpWidget(env.wrap(const BookmarksScreen()));
      await _pumpFrames(tester);

      await tester.tap(find.byIcon(Icons.search));
      await _pumpFrames(tester);

      await tester.enterText(find.byType(TextField), 'solar');
      await tester.pump(const Duration(milliseconds: 350));
      await _pumpFrames(tester);

      expect(
        find.textContaining('Bravo solar battery voltage update'),
        findsOneWidget,
      );
      expect(find.textContaining('Alpha repeater check'), findsNothing);

      // Tap the search result to close search and highlight the card.
      await tester.tap(
        find.textContaining('Bravo solar battery voltage update'),
      );
      await _pumpFrames(tester);

      // Search field closed and AnimatedContainer highlight is active.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(AnimatedContainer), findsOneWidget);

      // Highlight clears after 2 seconds.
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(AnimatedContainer), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
    },
  );

  testWidgets(
    'Single removal and bulk removal in BookmarksScreen show confirmation AlertDialog',
    (tester) async {
      final env = await _createEnv(tester);
      final b1 = BookmarkedMessage(
        sourceType: BookmarkSourceType.channel,
        sourceId: 'slot:0',
        sourceName: 'Public',
        messageId: 'm1',
        senderName: 'Sam',
        text: 'First bookmarked message',
        timestamp: DateTime(2026, 1, 1, 9),
        receivedAt: DateTime(2026, 1, 1, 9),
        isOutgoing: false,
      );
      final b2 = BookmarkedMessage(
        sourceType: BookmarkSourceType.channel,
        sourceId: 'slot:0',
        sourceName: 'Public',
        messageId: 'm2',
        senderName: 'Maya',
        text: 'Second bookmarked message',
        timestamp: DateTime(2026, 1, 1, 10),
        receivedAt: DateTime(2026, 1, 1, 10),
        isOutgoing: false,
      );
      final b3 = BookmarkedMessage(
        sourceType: BookmarkSourceType.contact,
        sourceId: 'contact-1',
        sourceName: 'Maya',
        messageId: 'm3',
        senderName: 'Maya',
        text: 'Third bookmarked message',
        timestamp: DateTime(2026, 1, 1, 11),
        receivedAt: DateTime(2026, 1, 1, 11),
        isOutgoing: false,
      );

      await _pumpFuture(
        tester,
        env.connector.setBookmarkedMessage(b1, isBookmarked: true),
      );
      await _pumpFuture(
        tester,
        env.connector.setBookmarkedMessage(b2, isBookmarked: true),
      );
      await _pumpFuture(
        tester,
        env.connector.setBookmarkedMessage(b3, isBookmarked: true),
      );

      await tester.pumpWidget(env.wrap(const BookmarksScreen()));
      await _pumpFrames(tester);

      expect(find.text('Third bookmarked message'), findsOneWidget);

      // 1. Single remove -> Cancel keeps bookmark intact.
      await tester.tap(find.byIcon(Icons.bookmark_remove_outlined).first);
      await _pumpFrames(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(_l10n.bookmarks_removeConfirmTitle), findsOneWidget);
      expect(find.text(_l10n.bookmarks_removeConfirmMessage), findsOneWidget);

      await tester.tap(find.text(_l10n.common_cancel));
      await _pumpFrames(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Third bookmarked message'), findsOneWidget);

      // 2. Single remove -> Confirm removes bookmark.
      await tester.tap(find.byIcon(Icons.bookmark_remove_outlined).first);
      await _pumpFrames(tester);
      await tester.tap(find.text(_l10n.common_remove));
      await _pumpFrames(tester);

      expect(find.text('Third bookmarked message'), findsNothing);
      expect(find.text('Second bookmarked message'), findsOneWidget);
      expect(find.text('First bookmarked message'), findsOneWidget);

      // 3. Long-press to enter bulk selection mode and select both remaining bookmarks.
      await tester.longPress(find.text('Second bookmarked message'));
      await _pumpFrames(tester);

      expect(find.text(_l10n.chat_selectedCount(1)), findsOneWidget);
      await tester.tap(
        find.text('First bookmarked message'),
        warnIfMissed: false,
      );
      await _pumpFrames(tester);
      expect(find.text(_l10n.chat_selectedCount(2)), findsOneWidget);

      // Tap bulk delete icon -> Cancel keeps both bookmarks.
      await tester.tap(find.byIcon(Icons.delete_outline));
      await _pumpFrames(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text(_l10n.bookmarks_removeSelectedConfirmTitle),
        findsOneWidget,
      );
      expect(
        find.text(_l10n.bookmarks_removeSelectedConfirmMessage(2)),
        findsOneWidget,
      );

      await tester.tap(find.text(_l10n.common_cancel));
      await _pumpFrames(tester);
      expect(find.text('Second bookmarked message'), findsOneWidget);
      expect(find.text('First bookmarked message'), findsOneWidget);

      // Tap bulk delete icon -> Confirm removes selected bookmarks.
      await tester.tap(find.byIcon(Icons.delete_outline));
      await _pumpFrames(tester);
      await tester.tap(find.text(_l10n.common_remove));
      await _pumpFrames(tester);

      expect(find.text(_l10n.bookmarks_empty), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
    },
  );

  testWidgets(
    'ChannelChatScreen bulk selection bookmarks selected messages and in-chat remove prompts for confirmation',
    (tester) async {
      final env = await _createEnv(tester);
      final channel = env.connector.channels.firstWhere(
        (c) => c.name == 'Hiking Group',
      );

      await tester.pumpWidget(env.wrap(ChannelChatScreen(channel: channel)));
      await _pumpFrames(tester);

      final messages = env.connector.getChannelMessages(channel);
      expect(messages.length, greaterThanOrEqualTo(2));
      final firstMsg = messages[messages.length - 1];
      final secondMsg = messages[messages.length - 2];

      Future<void> longPressBubble(String text) async {
        final bubble = find.ancestor(
          of: find.text(text),
          matching: find.byType(MessageBubbleFrame),
        );
        await tester.longPressAt(
          tester.getTopLeft(bubble) + const Offset(8, 8),
        );
        await _pumpFrames(tester);
      }

      // Long-press newest message to open action sheet -> Select messages
      await longPressBubble(firstMsg.text);

      await tester.tap(find.text(_l10n.chat_selectMessages));
      await _pumpFrames(tester);

      // Select second message too
      await tester.tap(find.text(secondMsg.text), warnIfMissed: false);
      await _pumpFrames(tester);
      expect(find.text(_l10n.chat_selectedCount(2)), findsOneWidget);

      // Tap bulk Bookmark action in selection AppBar
      final bookmarkBtn = find.byTooltip(_l10n.chat_bookmark);
      expect(bookmarkBtn, findsOneWidget);
      await tester.tap(bookmarkBtn);
      await _pumpFrames(tester);

      final saved = await _pumpFuture(
        tester,
        env.connector.loadBookmarkedMessages(),
      );
      expect(saved, hasLength(2));

      // Now long-press the bookmarked message in ChannelChatScreen and tap "Remove bookmark"
      await longPressBubble(firstMsg.text);
      expect(find.text(_l10n.chat_removeBookmark), findsOneWidget);

      await tester.tap(find.text(_l10n.chat_removeBookmark));
      await _pumpFrames(tester);

      // Confirmation dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(_l10n.bookmarks_removeConfirmTitle), findsOneWidget);

      // Cancel keeps it bookmarked
      await tester.tap(find.text(_l10n.common_cancel));
      await _pumpFrames(tester);
      expect(
        await _pumpFuture(tester, env.connector.loadBookmarkedMessages()),
        hasLength(2),
      );

      // Confirm removes the bookmark
      await longPressBubble(firstMsg.text);
      await tester.tap(find.text(_l10n.chat_removeBookmark));
      await _pumpFrames(tester);
      await tester.tap(find.text(_l10n.common_remove));
      await _pumpFrames(tester);

      expect(
        await _pumpFuture(tester, env.connector.loadBookmarkedMessages()),
        hasLength(1),
      );

      // Also verify ChatScreen (direct message) bookmark removal confirmation dialog
      final contact = env.connector.contacts.firstWhere(
        (c) => c.name == 'Maya',
      );
      await tester.pumpWidget(env.wrap(ChatScreen(contact: contact)));
      await _pumpFrames(tester);

      final dmMessages = env.connector.getMessages(contact);
      expect(dmMessages, isNotEmpty);
      final dmMsg = dmMessages.last;

      // Bookmark the DM first
      await longPressBubble(dmMsg.text);
      await tester.tap(find.text(_l10n.chat_bookmark));
      await _pumpFrames(tester);
      expect(
        await _pumpFuture(tester, env.connector.loadBookmarkedMessages()),
        hasLength(2),
      );

      // Long-press and tap Remove bookmark -> Cancel keeps it
      await longPressBubble(dmMsg.text);
      await tester.tap(find.text(_l10n.chat_removeBookmark));
      await _pumpFrames(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text(_l10n.common_cancel));
      await _pumpFrames(tester);
      expect(
        await _pumpFuture(tester, env.connector.loadBookmarkedMessages()),
        hasLength(2),
      );

      // Confirm removes it
      await longPressBubble(dmMsg.text);
      await tester.tap(find.text(_l10n.chat_removeBookmark));
      await _pumpFrames(tester);
      await tester.tap(find.text(_l10n.common_remove));
      await _pumpFrames(tester);
      expect(
        await _pumpFuture(tester, env.connector.loadBookmarkedMessages()),
        hasLength(1),
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
    },
  );

  group('BookmarksScreen fits 320dp at 1.3x and 2.0x text scale', () {
    for (final scale in [1.3, 2.0]) {
      testWidgets('no layout overflow at 320dp and ${scale}x text scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final env = await _createEnv(tester);
        final channel = env.connector.channels.firstWhere(
          (c) => c.name == 'Hiking Group',
        );
        await _pumpFuture(
          tester,
          env.connector.setBookmarkedMessage(
            BookmarkedMessage(
              sourceType: BookmarkSourceType.channel,
              sourceId: channel.storageId ?? 'slot:${channel.index}',
              sourceName: channel.name,
              messageId: 'scale-msg-1',
              senderName: 'Ranger Pat',
              text:
                  'Checking layout on 320dp screen with large text scale enabled.',
              timestamp: DateTime(2026, 1, 1, 12),
              receivedAt: DateTime(2026, 1, 1, 12),
              isOutgoing: false,
            ),
            isBookmarked: true,
          ),
        );

        final overflows = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.exceptionAsString();
          if (!text.contains('overflowed')) {
            previous?.call(details);
            return;
          }
          overflows.add(text.split('\n').first);
        };
        addTearDown(() => FlutterError.onError = previous);

        await tester.pumpWidget(
          env.wrap(
            BookmarksScreen(
              initialSourceType: BookmarkSourceType.channel,
              initialSourceId: channel.storageId ?? 'slot:${channel.index}',
              sourceIdAliases: [?channel.storageId, 'slot:${channel.index}'],
              initialSourceName: '#${channel.name}',
            ),
            textScale: scale,
          ),
        );
        await _pumpFrames(tester);

        // Enter bulk selection mode and open remove confirmation dialog at scale
        await tester.longPress(
          find.textContaining('Checking layout on 320dp screen'),
        );
        await _pumpFrames(tester);
        await tester.tap(find.byIcon(Icons.delete_outline));
        await _pumpFrames(tester);
        await tester.tap(find.text(_l10n.common_cancel));
        await _pumpFrames(tester);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
        FlutterError.onError = previous;

        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }
  });
}
