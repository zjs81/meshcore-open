import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/custom_theme.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/screens/app_settings_screen.dart';
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
import 'package:meshcore_open/storage/history_store.dart';
import 'package:meshcore_open/storage/last_radio_store.dart';
import 'package:meshcore_open/storage/message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/message_bubble_frame.dart';
import 'package:meshcore_open/widgets/message_status_icon.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _radioKey = Uint8List.fromList(List<int>.generate(32, (i) => 0xA0 + i));
final _radioHex = pubKeyToHex(_radioKey);
final _aliceKey = Uint8List.fromList(List<int>.generate(32, (i) => 0x10 + i));
final _psk = Uint8List.fromList(List<int>.generate(16, (i) => 0x40 + i));
final _l10n = lookupAppLocalizations(const Locale('en'));

Future<void> _seedMessages() async {
  final alice = Contact(
    publicKey: _aliceKey,
    name: 'Alice',
    type: advTypeChat,
    pathLength: 1,
    path: Uint8List.fromList([0x22]),
    lastSeen: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
  await (ContactStore()..setPublicKeyHex = _radioHex).saveContacts([alice]);
  final channel = Channel(index: 0, name: 'Base Camp', psk: _psk);
  final channelStore = ChannelStore()..setPublicKeyHex = _radioHex;
  await channelStore.saveChannels([channel]);
  await channelStore.saveSlotChannelIds({0: channel.storageId!});

  await (MessageStore()..setPublicKeyHex = _radioHex)
      .saveMessages(alice.publicKeyHex, [
        Message(
          senderKey: _aliceKey,
          text: 'DM incoming compressed',
          timestamp: DateTime(2026, 11, 21, 10, 11),
          receivedAt: DateTime(2026, 11, 21, 10, 11),
          isOutgoing: false,
          isSmazCompressed: true,
          status: MessageStatus.delivered,
        ),
        Message(
          senderKey: _aliceKey,
          text: 'DM incoming plain',
          timestamp: DateTime(2026, 11, 21, 10, 12),
          receivedAt: DateTime(2026, 11, 21, 10, 12),
          isOutgoing: false,
          isSmazCompressed: false,
          status: MessageStatus.delivered,
        ),
        Message(
          senderKey: _aliceKey,
          text: 'DM outgoing plain',
          timestamp: DateTime(2026, 11, 21, 10, 13),
          receivedAt: DateTime(2026, 11, 21, 10, 13),
          isOutgoing: true,
          isSmazCompressed: false,
          status: MessageStatus.delivered,
        ),
        Message(
          senderKey: _aliceKey,
          text: 'DM outgoing compressed',
          timestamp: DateTime(2026, 11, 21, 10, 14),
          receivedAt: DateTime(2026, 11, 21, 10, 14),
          isOutgoing: true,
          isSmazCompressed: true,
          status: MessageStatus.delivered,
        ),
      ]);

  await (ChannelMessageStore()..setPublicKeyHex = _radioHex)
      .saveChannelMessages(channel.storageId!, [
        ChannelMessage(
          senderName: 'Bob',
          text: 'Channel incoming compressed',
          timestamp: DateTime(2026, 11, 21, 11, 11),
          receivedAt: DateTime(2026, 11, 21, 11, 11),
          isOutgoing: false,
          isSmazCompressed: true,
          status: ChannelMessageStatus.sent,
          channelIndex: 0,
        ),
        ChannelMessage(
          senderName: 'Bob',
          text: 'Channel incoming plain',
          timestamp: DateTime(2026, 11, 21, 11, 12),
          receivedAt: DateTime(2026, 11, 21, 11, 12),
          isOutgoing: false,
          isSmazCompressed: false,
          status: ChannelMessageStatus.sent,
          channelIndex: 0,
        ),
        ChannelMessage(
          senderName: 'Me',
          text: 'Channel outgoing plain',
          timestamp: DateTime(2026, 11, 21, 11, 13),
          receivedAt: DateTime(2026, 11, 21, 11, 13),
          isOutgoing: true,
          isSmazCompressed: false,
          repeatCount: 1,
          status: ChannelMessageStatus.sent,
          channelIndex: 0,
        ),
        ChannelMessage(
          senderName: 'Me',
          text: 'Channel outgoing compressed',
          timestamp: DateTime(2026, 11, 21, 11, 14),
          receivedAt: DateTime(2026, 11, 21, 11, 14),
          isOutgoing: true,
          isSmazCompressed: true,
          repeatCount: 2,
          status: ChannelMessageStatus.sent,
          channelIndex: 0,
        ),
      ]);

  await LastRadioStore().save(
    LastRadio(
      publicKeyHex: _radioHex,
      name: 'Base',
      transport: LastRadio.transportBle,
      bleRemoteId: 'AA:BB:CC:DD:EE:FF',
      savedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    ),
  );
}

class _Harness {
  final MeshCoreConnector connector;
  final AppSettingsService settings;
  final List<dynamic> disposables;

  _Harness(this.connector, this.settings, this.disposables);

  List<ChangeNotifierProvider<ChangeNotifier>> get _unused => const [];

  Widget wrap(Widget home, {ThemeData? theme, double textScale = 1.0}) {
    final storage = StorageService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: connector),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(
          value: disposables[0] as MessageRetryService,
        ),
        ChangeNotifierProvider.value(
          value: disposables[1] as PathHistoryService,
        ),
        ChangeNotifierProvider.value(
          value: disposables[2] as BleDebugLogService,
        ),
        ChangeNotifierProvider.value(
          value: disposables[3] as AppDebugLogService,
        ),
        ChangeNotifierProvider.value(
          value: disposables[4] as ChatTextScaleService,
        ),
        ChangeNotifierProvider.value(
          value: disposables[5] as TranslationService,
        ),
        ChangeNotifierProvider.value(
          value: disposables[6] as UiViewStateService,
        ),
        Provider.value(value: storage),
        ChangeNotifierProvider.value(
          value: disposables[7] as MapTileCacheService,
        ),
        ChangeNotifierProvider.value(
          value: disposables[8] as TimeoutPredictionService,
        ),
        ChangeNotifierProvider.value(
          value: disposables[9] as ImageCodecService,
        ),
        ChangeNotifierProvider.value(
          value: disposables[10] as ReceivedImageStore,
        ),
        ChangeNotifierProvider.value(
          value: disposables[11] as NetworkMapUploadService,
        ),
      ],
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        ),
        home: home,
      ),
    );
  }

  void dispose() {
    assert(_unused.isEmpty);
    connector.dispose();
    settings.dispose();
    for (final d in disposables) {
      if (d is ChangeNotifier) d.dispose();
    }
  }
}

Future<_Harness> _createHarness({bool showIndicator = false}) async {
  SharedPreferences.setMockInitialValues({});
  PrefsManager.reset();
  await PrefsManager.initialize();
  HistoryStore.reset();
  MessageStore().forgetArchive();
  ChannelMessageStore().forgetArchive();
  await _seedMessages();

  final storage = StorageService();
  final settings = AppSettingsService();
  await settings.loadSettings();
  if (showIndicator) {
    await settings.setShowCompressionIndicator(true);
  }
  final connector = MeshCoreConnector();
  final retry = MessageRetryService();
  final pathHistory = PathHistoryService(storage);
  final bleLog = BleDebugLogService();
  final appLog = AppDebugLogService();
  final textScale = ChatTextScaleService();
  final translation = TranslationService(settings);
  final uiView = UiViewStateService();
  final tileCache = MapTileCacheService(appSettingsService: settings);
  final timeoutPred = TimeoutPredictionService(storage);
  final imageCodec = ImageCodecService(settings);
  final receivedImage = ReceivedImageStore();
  final networkMap = NetworkMapUploadService(
    connector: connector,
    settings: settings,
  );
  await connector.restoreLastRadio();
  return _Harness(connector, settings, [
    retry,
    pathHistory,
    bleLog,
    appLog,
    textScale,
    translation,
    uiView,
    tileCache,
    timeoutPred,
    imageCodec,
    receivedImage,
    networkMap,
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync(
    'compression_indicator_test',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempDir.path,
      );

  testWidgets(
    'AppSettingsScreen shows Compression indicator switch and toggles',
    (tester) async {
      late _Harness harness;
      await tester.runAsync(() async {
        harness = await _createHarness();
        await harness.settings.setAutoRouteRotationEnabled(false);
      });
      addTearDown(harness.dispose);

      tester.view.physicalSize = const Size(390, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness.wrap(const AppSettingsScreen()));
      await tester.pumpAndSettle();

      final tileFinder = find.widgetWithText(
        SwitchListTile,
        _l10n.appSettings_showCompressionIndicator,
      );
      await tester.scrollUntilVisible(
        tileFinder,
        60,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final tile = tester.widget<SwitchListTile>(tileFinder);
      expect(tile.value, isFalse);
      expect(
        find.descendant(of: tileFinder, matching: find.byIcon(Icons.compress)),
        findsOneWidget,
      );

      await tester.tap(tileFinder);
      await tester.pumpAndSettle();
      expect(harness.settings.settings.showCompressionIndicator, isTrue);
    },
  );

  testWidgets(
    'DM ChatScreen hides icon when off, shows only on compressed when on',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        late _Harness harness;
        await tester.runAsync(() async {
          harness = await _createHarness(showIndicator: false);
        });
        addTearDown(harness.dispose);

        final contact = harness.connector.contacts.first;
        await tester.pumpWidget(harness.wrap(ChatScreen(contact: contact)));
        await tester.pumpAndSettle();

        expect(find.byType(CompressionIndicator), findsNothing);

        await tester.runAsync(
          () => harness.settings.setShowCompressionIndicator(true),
        );
        await tester.pumpAndSettle();

        // Two compressed messages (1 incoming, 1 outgoing); two plain have none.
        expect(find.byType(CompressionIndicator), findsNWidgets(2));
        expect(
          find.byTooltip(_l10n.messageMeta_smazCompressed),
          findsNWidgets(2),
        );
        expect(
          find.bySemanticsLabel(RegExp(_l10n.messageMeta_smazCompressed)),
          findsNWidgets(2),
        );

        // Incoming compressed message: CompressionIndicator sits after timestamp, no ticks.
        final incomingBubble = find.ancestor(
          of: find.text('DM incoming compressed'),
          matching: find.byType(MessageBubbleFrame),
        );
        final incomingIndicator = find.descendant(
          of: incomingBubble,
          matching: find.byType(CompressionIndicator),
        );
        final incomingTime = find.descendant(
          of: incomingBubble,
          matching: find.text('10:11'),
        );
        expect(incomingIndicator, findsOneWidget);
        expect(
          tester.getTopLeft(incomingIndicator).dx,
          greaterThan(tester.getTopRight(incomingTime).dx),
        );
        expect(
          find.descendant(
            of: incomingBubble,
            matching: find.byType(MessageStatusIcon),
          ),
          findsNothing,
        );

        // Outgoing compressed message: CompressionIndicator sits between timestamp and ticks.
        final outgoingBubble = find.ancestor(
          of: find.text('DM outgoing compressed'),
          matching: find.byType(MessageBubbleFrame),
        );
        final outgoingIndicator = find.descendant(
          of: outgoingBubble,
          matching: find.byType(CompressionIndicator),
        );
        final outgoingTime = find.descendant(
          of: outgoingBubble,
          matching: find.text('10:14'),
        );
        final outgoingTicks = find.descendant(
          of: outgoingBubble,
          matching: find.byType(MessageStatusIcon),
        );
        expect(outgoingIndicator, findsOneWidget);
        expect(
          tester.getTopLeft(outgoingIndicator).dx,
          greaterThan(tester.getTopRight(outgoingTime).dx),
        );
        expect(
          tester.getTopRight(outgoingIndicator).dx,
          lessThanOrEqualTo(tester.getTopLeft(outgoingTicks).dx),
        );

        // Plain messages never show the icon.
        final plainBubble = find.ancestor(
          of: find.text('DM outgoing plain'),
          matching: find.byType(MessageBubbleFrame),
        );
        expect(
          find.descendant(
            of: plainBubble,
            matching: find.byType(CompressionIndicator),
          ),
          findsNothing,
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'ChannelChatScreen hides icon when off, shows between time and ticks when on',
    (tester) async {
      late _Harness harness;
      await tester.runAsync(() async {
        harness = await _createHarness(showIndicator: false);
      });
      addTearDown(harness.dispose);

      final channel = harness.connector.channels.first;
      await tester.pumpWidget(
        harness.wrap(ChannelChatScreen(channel: channel)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompressionIndicator), findsNothing);

      await tester.runAsync(
        () => harness.settings.setShowCompressionIndicator(true),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompressionIndicator), findsNWidgets(2));

      // Outgoing compressed channel message: icon between timestamp and repeat ticks.
      final outgoingBubble = find.ancestor(
        of: find.text('Channel outgoing compressed'),
        matching: find.byType(MessageBubbleFrame),
      );
      final outgoingIndicator = find.descendant(
        of: outgoingBubble,
        matching: find.byType(CompressionIndicator),
      );
      final outgoingTime = find.descendant(
        of: outgoingBubble,
        matching: find.text('11:14'),
      );
      final outgoingTicks = find.descendant(
        of: outgoingBubble,
        matching: find.byType(MessageStatusIcon),
      );
      expect(outgoingIndicator, findsOneWidget);
      expect(
        tester.getTopLeft(outgoingIndicator).dx,
        greaterThan(tester.getTopRight(outgoingTime).dx),
      );
      expect(
        tester.getTopRight(outgoingIndicator).dx,
        lessThanOrEqualTo(tester.getTopLeft(outgoingTicks).dx),
      );

      // Incoming compressed channel message: icon right after timestamp.
      final incomingBubble = find.ancestor(
        of: find.text('Channel incoming compressed'),
        matching: find.byType(MessageBubbleFrame),
      );
      final incomingIndicator = find.descendant(
        of: incomingBubble,
        matching: find.byType(CompressionIndicator),
      );
      final incomingTime = find.descendant(
        of: incomingBubble,
        matching: find.text('11:11'),
      );
      expect(incomingIndicator, findsOneWidget);
      expect(
        tester.getTopLeft(incomingIndicator).dx,
        greaterThan(tester.getTopRight(incomingTime).dx),
      );
    },
  );

  testWidgets('No overflow at 320dp width and 2.0x text scale across themes', (
    tester,
  ) async {
    late _Harness harness;
    await tester.runAsync(() async {
      harness = await _createHarness(showIndicator: true);
    });
    addTearDown(harness.dispose);

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        overflows.add(text.split('\n').first);
      } else {
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);

    final contact = harness.connector.contacts.first;
    final channel = harness.connector.channels.first;

    final themes = [
      MeshTheme.light(),
      MeshTheme.dark(),
      MeshTheme.fromCustom(CustomTheme.presets.first),
    ];

    for (final theme in themes) {
      await tester.pumpWidget(
        harness.wrap(
          ChatScreen(contact: contact),
          theme: theme,
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CompressionIndicator), findsAtLeastNWidgets(1));

      await tester.pumpWidget(
        harness.wrap(
          ChannelChatScreen(channel: channel),
          theme: theme,
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CompressionIndicator), findsAtLeastNWidgets(1));
    }

    FlutterError.onError = previous;
    expect(overflows, isEmpty, reason: overflows.join('\n'));
  });
}
