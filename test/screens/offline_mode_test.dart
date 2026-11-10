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
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/screens/channel_chat_screen.dart';
import 'package:meshcore_open/screens/channels_screen.dart';
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
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/channel_store.dart';
import 'package:meshcore_open/storage/contact_store.dart';
import 'package:meshcore_open/storage/last_radio_store.dart';
import 'package:meshcore_open/storage/message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/chat_composer.dart';
import 'package:meshcore_open/widgets/connect_sheet.dart';

final _radioKey = Uint8List.fromList(List<int>.generate(32, (i) => 0xA0 + i));
final _radioHex = pubKeyToHex(_radioKey);
final _aliceKey = Uint8List.fromList(List<int>.generate(32, (i) => 0x10 + i));
final _psk = Uint8List.fromList(List<int>.generate(16, (i) => 0x40 + i));

final _l10n = lookupAppLocalizations(const Locale('en'));

Future<void> _seedRadio() async {
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
  await (ChannelMessageStore()..setPublicKeyHex = _radioHex)
      .saveChannelMessages(channel.storageId!, [
        ChannelMessage(
          senderName: 'Bob',
          text: 'camp is up',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1700000001000),
          isOutgoing: false,
          status: ChannelMessageStatus.sent,
          channelIndex: 0,
        ),
      ]);
  await (MessageStore()..setPublicKeyHex = _radioHex)
      .saveMessages(alice.publicKeyHex, [
        Message(
          senderKey: _aliceKey,
          text: 'hi there',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1700000002000),
          isOutgoing: false,
          status: MessageStatus.delivered,
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

Future<Widget> _app(
  WidgetTester tester,
  MeshCoreConnector connector,
  Widget home,
) async {
  final storage = StorageService();
  final settings = AppSettingsService();
  await tester.runAsync(settings.loadSettings);
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

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() condition, {
  int seconds = 8,
}) async {
  await tester.runAsync(() async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (!condition()) {
      if (DateTime.now().isAfter(end)) fail('Timed out waiting for condition');
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });
}

/// Restores the seeded radio into a connector that never connects.
Future<MeshCoreConnector> _offlineConnector(WidgetTester tester) async {
  final connector = MeshCoreConnector();
  addTearDown(connector.dispose);
  await tester.runAsync(connector.restoreLastRadio);
  expect(connector.isConnected, isFalse);
  expect(connector.channels, isNotEmpty);
  return connector;
}

PopupMenuItem<Object?> _menuItem(String label) =>
    find
            .ancestor(
              of: find.text(label),
              matching: find.byWidgetPredicate((w) => w is PopupMenuItem),
            )
            .evaluate()
            .single
            .widget
        as PopupMenuItem<Object?>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('offline_mode_test');
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

  testWidgets('Channels screen stays put offline with saved data and a '
      'Connect control', (tester) async {
    final connector = await _offlineConnector(tester);
    await tester.pumpWidget(
      await _app(tester, connector, const ChannelsScreen()),
    );
    await _settle(tester);

    expect(find.byType(ChannelsScreen), findsOneWidget);
    expect(find.text('Base Camp'), findsOneWidget);
    expect(find.byType(ConnectButton), findsOneWidget);
    expect(find.text(_l10n.appBar_offlineSubtitle('Base')), findsOneWidget);
    // Adding a channel needs the radio.
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    expect(find.text(_l10n.common_connect), findsWidgets);
    expect(find.text(_l10n.common_disconnect), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Contacts screen stays put offline and disables radio actions', (
    tester,
  ) async {
    final connector = await _offlineConnector(tester);
    await tester.pumpWidget(
      await _app(tester, connector, const ContactsScreen()),
    );
    await _settle(tester);

    expect(find.byType(ContactsScreen), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.byType(ConnectButton), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    expect(_menuItem(_l10n.contacts_floodAdvert).enabled, isFalse);
    expect(_menuItem(_l10n.contacts_zeroHopAdvert).enabled, isFalse);
    expect(_menuItem(_l10n.contacts_addContactFromClipboard).enabled, isFalse);
    expect(_menuItem(_l10n.common_connect).enabled, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Channel chat offline is read-only', (tester) async {
    final connector = await _offlineConnector(tester);
    await tester.pumpWidget(
      await _app(
        tester,
        connector,
        ChannelChatScreen(channel: connector.channels.single),
      ),
    );
    await _settle(tester);

    expect(find.textContaining('camp is up'), findsWidgets);
    expect(find.byType(OfflineComposerBar), findsOneWidget);
    expect(find.text(_l10n.chat_composerOffline), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ConnectButton), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    expect(_menuItem(_l10n.channels_editChannel).enabled, isFalse);
    expect(_menuItem(_l10n.contact_clearChat).enabled, isFalse);
    expect(_menuItem(_l10n.channels_deleteChannel).enabled, isFalse);
    // Per-device preferences stay available.
    expect(_menuItem(_l10n.chatBackground_title).enabled, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('DM chat offline is read-only', (tester) async {
    final connector = await _offlineConnector(tester);
    final alice = connector.contacts.single;
    await tester.pumpWidget(
      await _app(tester, connector, ChatScreen(contact: alice)),
    );
    await _settle(tester);

    expect(find.textContaining('hi there'), findsWidgets);
    expect(find.byType(OfflineComposerBar), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    expect(_menuItem(_l10n.contact_clearChat).enabled, isFalse);
    expect(_menuItem(_l10n.contact_telemetry).enabled, isFalse);
    expect(_menuItem(_l10n.contact_info).enabled, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a draft typed while connected survives a disconnect and '
      'reconnect', (tester) async {
    final connector = MeshCoreConnector();
    addTearDown(connector.dispose);
    connector.reviewRadioFactoryForTest = () => ReviewRadio(
      scheduledMessageInterval: const Duration(hours: 1),
      ackDelay: const Duration(hours: 1),
      replyDelay: const Duration(hours: 1),
    );
    await tester.runAsync(connector.connectReview);
    await _waitFor(tester, () => connector.contacts.isNotEmpty);
    final contact = connector.contacts.firstWhere((c) => c.type == advTypeChat);

    await tester.pumpWidget(
      await _app(tester, connector, ChatScreen(contact: contact)),
    );
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'half written');
    await _settle(tester);

    await tester.runAsync(connector.disconnect);
    // Connector notifications are debounced on a real timer.
    await _waitFor(tester, () => !connector.isConnected);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await _settle(tester);
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byType(OfflineComposerBar), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.runAsync(connector.connectReview);
    await _waitFor(tester, () => connector.isConnected);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await _settle(tester);
    expect(find.byType(OfflineComposerBar), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'half written');

    await tester.runAsync(connector.disconnect);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
