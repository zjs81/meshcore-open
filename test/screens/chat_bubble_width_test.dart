import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/screens/channel_chat_screen.dart';
import 'package:meshcore_open/screens/chat_screen.dart';
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
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/channel_store.dart';
import 'package:meshcore_open/storage/contact_store.dart';
import 'package:meshcore_open/storage/last_radio_store.dart';
import 'package:meshcore_open/storage/message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/utils/platform_info.dart';
import 'package:meshcore_open/widgets/message_bubble_frame.dart';

final _radioKey = Uint8List.fromList(List<int>.generate(32, (i) => 0xA0 + i));
final _radioHex = pubKeyToHex(_radioKey);
final _aliceKey = Uint8List.fromList(List<int>.generate(32, (i) => 0x10 + i));
final _psk = Uint8List.fromList(List<int>.generate(16, (i) => 0x40 + i));

const _long =
    'The ridge trail is washed out past the second bridge, so take the '
    'lower path along the river and meet us at the old ranger station.';

/// Shows the saved radio as connected or offline without a transport, so
/// both states render exactly the same stored transcript.
class _ToggleConnector extends MeshCoreConnector {
  bool connected = false;

  @override
  bool get isConnected => connected;
}

// Two-digit local hour (10:13 PM / 22:13) so narrow 2.0x text checks the wide
// timestamp layout regardless of host timezone.
DateTime _at(int seconds) => DateTime(2023, 11, 14, 22, 13, seconds);

Future<void> _seedRadio({
  bool smazCompressed = false,
  int repeatCount = 0,
}) async {
  final alice = Contact(
    publicKey: _aliceKey,
    name: 'Alice',
    type: advTypeChat,
    pathLength: 1,
    path: Uint8List.fromList([0x22]),
    lastSeen: _at(0),
  );
  await (ContactStore()..setPublicKeyHex = _radioHex).saveContacts([alice]);
  final channel = Channel(index: 0, name: 'Base Camp', psk: _psk);
  final channelStore = ChannelStore()..setPublicKeyHex = _radioHex;
  await channelStore.saveChannels([channel]);
  await channelStore.saveSlotChannelIds({0: channel.storageId!});

  ChannelMessage channelMessage(
    int second,
    String text, {
    required bool outgoing,
    String? translated,
  }) => ChannelMessage(
    senderName: outgoing ? 'Base' : 'Bob',
    text: text,
    translatedText: translated,
    timestamp: _at(second),
    isOutgoing: outgoing,
    isSmazCompressed: smazCompressed,
    repeatCount: repeatCount,
    status: ChannelMessageStatus.sent,
    channelIndex: 0,
  );
  await (ChannelMessageStore()..setPublicKeyHex = _radioHex)
      .saveChannelMessages(channel.storageId!, [
        channelMessage(1, 'ok', outgoing: false),
        channelMessage(2, _long, outgoing: false),
        channelMessage(3, 'on my way', outgoing: true),
        channelMessage(4, _long, outgoing: true),
        channelMessage(
          5,
          'Der Weg ist frei',
          outgoing: false,
          translated: 'The path is clear',
        ),
      ]);

  Message directMessage(
    int second,
    String text, {
    required bool outgoing,
    String? translated,
  }) => Message(
    senderKey: _aliceKey,
    text: text,
    translatedText: translated,
    timestamp: _at(second),
    isOutgoing: outgoing,
    isSmazCompressed: smazCompressed,
    status: MessageStatus.delivered,
  );
  await (MessageStore()..setPublicKeyHex = _radioHex)
      .saveMessages(alice.publicKeyHex, [
        directMessage(1, 'hi', outgoing: false),
        directMessage(2, _long, outgoing: false),
        directMessage(3, 'see you', outgoing: true),
        directMessage(4, _long, outgoing: true),
        directMessage(
          5,
          'Der Weg ist frei',
          outgoing: false,
          translated: 'The path is clear',
        ),
      ]);
  await LastRadioStore().save(
    LastRadio(
      publicKeyHex: _radioHex,
      name: 'Base',
      transport: LastRadio.transportBle,
      bleRemoteId: 'AA:BB:CC:DD:EE:FF',
      savedAt: _at(0),
    ),
  );
}

Future<Widget> _app(
  WidgetTester tester,
  MeshCoreConnector connector,
  Widget home, {
  bool showCompressionIndicator = false,
  bool enableMessageTracing = false,
}) async {
  final storage = StorageService();
  final settings = AppSettingsService();
  await tester.runAsync(() async {
    await settings.loadSettings();
    if (showCompressionIndicator) {
      await settings.setShowCompressionIndicator(true);
    }
    if (enableMessageTracing) {
      await settings.setEnableMessageTracing(true);
    }
  });
  final translation = TranslationService(settings);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: connector),
      ChangeNotifierProvider.value(value: MessageRetryService()),
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
      ChangeNotifierProvider.value(
        value: NetworkMapUploadService(
          connector: connector,
          settings: settings,
        ),
      ),
    ],
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
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Horizontal extent of every rendered bubble, in transcript order.
List<String> _bubbleExtents(WidgetTester tester) {
  final frames = find.byType(MessageBubbleFrame);
  expect(frames, findsWidgets);
  return [
    for (final element in frames.evaluate())
      () {
        final rect = tester.getRect(find.byWidget(element.widget));
        return '${rect.left.toStringAsFixed(1)}..'
            '${rect.right.toStringAsFixed(1)}';
      }(),
  ];
}

Future<List<String>> _render(
  WidgetTester tester,
  _ToggleConnector connector,
  Widget Function() screen, {
  required bool connected,
  bool showCompressionIndicator = false,
  bool enableMessageTracing = false,
  bool expectCompressionIndicator = false,
}) async {
  connector.connected = connected;
  await tester.pumpWidget(
    await _app(
      tester,
      connector,
      screen(),
      showCompressionIndicator: showCompressionIndicator,
      enableMessageTracing: enableMessageTracing,
    ),
  );
  await _settle(tester);
  if (expectCompressionIndicator) {
    expect(find.byType(CompressionIndicator), findsNWidgets(5));
  }
  final extents = _bubbleExtents(tester);
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  return extents;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('bubble_width_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempDir.path,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    ChannelMessageStore().forgetArchive();
    MessageStore().forgetArchive();
    await _seedRadio();
    ChannelMessageStore().forgetArchive();
    MessageStore().forgetArchive();
  });

  // On phones, incoming channel bubbles are swipeable (reply) only while
  // connected; that must not change their size or position. Day separators
  // and bubbles must also fit 320dp at large text sizes.
  for (final desktop in [false, true]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      final label = '${desktop ? 'desktop' : 'phone'}, 320dp, ${scale}x text';

      testWidgets('channel bubbles match connected vs offline ($label)', (
        tester,
      ) async {
        PlatformInfo.debugIsDesktopOverride = desktop;
        addTearDown(() => PlatformInfo.debugIsDesktopOverride = null);
        tester.view.physicalSize = const Size(320, 4000);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final connector = _ToggleConnector();
        addTearDown(connector.dispose);
        await tester.runAsync(connector.restoreLastRadio);
        final channel = connector.channels.single;

        final offline = await _render(
          tester,
          connector,
          () => ChannelChatScreen(channel: channel),
          connected: false,
        );
        final connected = await _render(
          tester,
          connector,
          () => ChannelChatScreen(channel: channel),
          connected: true,
        );
        expect(offline, hasLength(5));
        expect(connected, offline);
      });

      testWidgets('DM bubbles match connected vs offline ($label)', (
        tester,
      ) async {
        PlatformInfo.debugIsDesktopOverride = desktop;
        addTearDown(() => PlatformInfo.debugIsDesktopOverride = null);
        tester.view.physicalSize = const Size(320, 4000);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final connector = _ToggleConnector();
        addTearDown(connector.dispose);
        await tester.runAsync(connector.restoreLastRadio);
        final alice = connector.contacts.single;

        final offline = await _render(
          tester,
          connector,
          () => ChatScreen(contact: alice),
          connected: false,
        );
        final connected = await _render(
          tester,
          connector,
          () => ChatScreen(contact: alice),
          connected: true,
        );
        expect(offline, hasLength(5));
        expect(connected, offline);
      });
    }
  }

  testWidgets(
    'channel and DM bubbles with SMAZ compression indicator fit 320dp, 2.0x text',
    (tester) async {
      ChannelMessageStore().forgetArchive();
      MessageStore().forgetArchive();
      await _seedRadio(smazCompressed: true, repeatCount: 2);
      ChannelMessageStore().forgetArchive();
      MessageStore().forgetArchive();

      PlatformInfo.debugIsDesktopOverride = false;
      addTearDown(() => PlatformInfo.debugIsDesktopOverride = null);
      tester.view.physicalSize = const Size(320, 4000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final connector = _ToggleConnector();
      addTearDown(connector.dispose);
      await tester.runAsync(connector.restoreLastRadio);
      final channel = connector.channels.single;
      final alice = connector.contacts.single;

      final channelOffline = await _render(
        tester,
        connector,
        () => ChannelChatScreen(channel: channel),
        connected: false,
        showCompressionIndicator: true,
        enableMessageTracing: true,
        expectCompressionIndicator: true,
      );
      final channelConnected = await _render(
        tester,
        connector,
        () => ChannelChatScreen(channel: channel),
        connected: true,
        showCompressionIndicator: true,
        enableMessageTracing: true,
        expectCompressionIndicator: true,
      );
      expect(channelOffline, hasLength(5));
      expect(channelConnected, channelOffline);

      final dmOffline = await _render(
        tester,
        connector,
        () => ChatScreen(contact: alice),
        connected: false,
        showCompressionIndicator: true,
        enableMessageTracing: true,
        expectCompressionIndicator: true,
      );
      final dmConnected = await _render(
        tester,
        connector,
        () => ChatScreen(contact: alice),
        connected: true,
        showCompressionIndicator: true,
        enableMessageTracing: true,
        expectCompressionIndicator: true,
      );
      expect(dmOffline, hasLength(5));
      expect(dmConnected, dmOffline);
    },
  );
}
