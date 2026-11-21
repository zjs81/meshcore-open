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
import 'package:meshcore_open/screens/channels_screen.dart';
import 'package:meshcore_open/screens/chat_screen.dart';
import 'package:meshcore_open/screens/contacts_screen.dart';
import 'package:meshcore_open/services/app_debug_log_service.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/ble_debug_log_service.dart';
import 'package:meshcore_open/services/chat_text_scale_service.dart';
import 'package:meshcore_open/services/image_codec_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:meshcore_open/services/message_filter/message_filter_service.dart';
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
import 'package:meshcore_open/utils/contact_filter_types.dart';

final _radioKey = Uint8List.fromList(List<int>.generate(32, (i) => 0xA0 + i));
final _radioHex = pubKeyToHex(_radioKey);

Uint8List _key(int seed) =>
    Uint8List.fromList(List<int>.generate(32, (i) => seed + i));
Uint8List _psk(int seed) =>
    Uint8List.fromList(List<int>.generate(16, (i) => seed + i));

/// Local arrival times, an hour apart. Sender clocks are set far off them.
final _base = DateTime(2026, 11, 20, 12);
DateTime _arrived(int hours) => _base.add(Duration(hours: hours));
final _farFuture = DateTime(2099);
final _farPast = DateTime(2001);

ChannelMessage _channelMessage(
  int slot,
  String text, {
  required DateTime sentAt,
  required DateTime receivedAt,
  String? filterReason,
}) => ChannelMessage(
  senderName: 'Bob',
  text: text,
  timestamp: sentAt,
  receivedAt: receivedAt,
  isOutgoing: false,
  status: ChannelMessageStatus.sent,
  channelIndex: slot,
  filterReason: filterReason,
);

Message _directMessage(
  Uint8List senderKey,
  String text, {
  required DateTime sentAt,
  required DateTime receivedAt,
}) => Message(
  senderKey: senderKey,
  text: text,
  timestamp: sentAt,
  receivedAt: receivedAt,
  isOutgoing: false,
  status: MessageStatus.delivered,
);

/// Seeds the remembered radio with channels (slots in map order) and
/// contacts, each with its saved messages.
Future<void> _seed({
  Map<String, List<ChannelMessage> Function(int slot)> channelMessages =
      const {},
  Map<String, List<Message> Function(Uint8List key)> contactMessages = const {},
}) async {
  final channelStore = ChannelStore()..setPublicKeyHex = _radioHex;
  final messageStore = ChannelMessageStore()..setPublicKeyHex = _radioHex;
  final channels = <Channel>[];
  var slot = 0;
  for (final entry in channelMessages.entries) {
    final channel = Channel(index: slot, name: entry.key, psk: _psk(slot * 16));
    channels.add(channel);
    await messageStore.saveChannelMessages(
      channel.storageId!,
      entry.value(slot),
    );
    slot++;
  }
  await channelStore.saveChannels(channels);
  await channelStore.saveSlotChannelIds({
    for (final c in channels) c.index: c.storageId!,
  });

  final contacts = <Contact>[];
  final directStore = MessageStore()..setPublicKeyHex = _radioHex;
  var seed = 0x10;
  for (final entry in contactMessages.entries) {
    final key = _key(seed);
    seed += 0x20;
    final contact = Contact(
      publicKey: key,
      name: entry.key,
      type: advTypeChat,
      pathLength: 1,
      path: Uint8List.fromList([0x22]),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    contacts.add(contact);
    await directStore.saveMessages(contact.publicKeyHex, entry.value(key));
  }
  await (ContactStore()..setPublicKeyHex = _radioHex).saveContacts(contacts);

  await LastRadioStore().save(
    LastRadio(
      publicKeyHex: _radioHex,
      name: 'Base',
      transport: LastRadio.transportBle,
      bleRemoteId: 'AA:BB:CC:DD:EE:FF',
      savedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    ),
  );
  ChannelMessageStore().forgetArchive();
  MessageStore().forgetArchive();
}

/// Restores the seeded radio into a connector that never connects.
Future<MeshCoreConnector> _connector(
  WidgetTester tester, {
  MessageFilterService? filter,
}) async {
  final connector = MeshCoreConnector();
  addTearDown(connector.dispose);
  if (filter != null) {
    final retry = MessageRetryService();
    addTearDown(retry.dispose);
    connector.initialize(
      retryService: retry,
      pathHistoryService: PathHistoryService(StorageService()),
      messageFilterService: filter,
    );
  }
  await tester.runAsync(connector.restoreLastRadio);
  return connector;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  MeshCoreConnector connector,
  UiViewStateService viewState,
  Widget home,
) async {
  final storage = StorageService();
  final settings = AppSettingsService();
  await tester.runAsync(settings.loadSettings);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: connector),
        ChangeNotifierProvider.value(value: MessageRetryService()),
        ChangeNotifierProvider.value(value: PathHistoryService(storage)),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: BleDebugLogService()),
        ChangeNotifierProvider.value(value: AppDebugLogService()),
        ChangeNotifierProvider.value(value: ChatTextScaleService()),
        ChangeNotifierProvider.value(value: TranslationService(settings)),
        ChangeNotifierProvider.value(value: viewState),
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
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// [names] in the order they appear on screen, top to bottom.
List<String> _screenOrder(WidgetTester tester, List<String> names) {
  final top = {
    for (final name in names) name: tester.getTopLeft(find.text(name).first).dy,
  };
  return [...names]..sort((a, b) => top[a]!.compareTo(top[b]!));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('recency_sort_test');
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
  });

  Future<void> pumpChannels(
    WidgetTester tester, {
    MessageFilterService? filter,
  }) async {
    final connector = await _connector(tester, filter: filter);
    final viewState = UiViewStateService()
      ..setChannelsSortOption(ChannelSortOption.latestMessages);
    await _pumpScreen(tester, connector, viewState, const ChannelsScreen());
  }

  Future<void> pumpContacts(WidgetTester tester) async {
    final connector = await _connector(tester);
    final viewState = UiViewStateService()
      ..setContactsSortOption(ContactSortOption.recentMessages);
    await _pumpScreen(tester, connector, viewState, const ContactsScreen());
  }

  testWidgets('Latest messages sorts channels by local arrival, not sender '
      'clocks far in the future or past', (tester) async {
    await _seed(
      channelMessages: {
        // Oldest arrival, but the sender's clock is decades ahead.
        'Future Clock': (slot) => [
          _channelMessage(
            slot,
            'from the future',
            sentAt: _farFuture,
            receivedAt: _arrived(0),
          ),
        ],
        // Newest arrival, but the sender's clock is decades behind.
        'Past Clock': (slot) => [
          _channelMessage(
            slot,
            'from the past',
            sentAt: _farPast,
            receivedAt: _arrived(2),
          ),
        ],
        'Correct Clock': (slot) => [
          _channelMessage(
            slot,
            'on time',
            sentAt: _arrived(1),
            receivedAt: _arrived(1),
          ),
        ],
        'Quiet': (_) => [],
      },
    );
    await pumpChannels(tester);

    expect(
      _screenOrder(tester, [
        'Future Clock',
        'Past Clock',
        'Correct Clock',
        'Quiet',
      ]),
      ['Past Clock', 'Correct Clock', 'Future Clock', 'Quiet'],
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('A newer message hidden by the message filter does not bump '
      'its channel', (tester) async {
    await _seed(
      channelMessages: {
        'Spammed': (slot) => [
          _channelMessage(
            slot,
            'real message',
            sentAt: _arrived(0),
            receivedAt: _arrived(0),
          ),
          _channelMessage(
            slot,
            'buy now',
            sentAt: _farFuture,
            receivedAt: _arrived(5),
            filterReason: 'rule',
          ),
        ],
        'Normal': (slot) => [
          _channelMessage(
            slot,
            'hello',
            sentAt: _arrived(1),
            receivedAt: _arrived(1),
          ),
        ],
      },
    );
    final filter = MessageFilterService();
    addTearDown(filter.dispose);
    await tester.runAsync(filter.load);
    await pumpChannels(tester, filter: filter);

    expect(_screenOrder(tester, ['Spammed', 'Normal']), ['Normal', 'Spammed']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Channels with equal arrival times fall back to name order', (
    tester,
  ) async {
    List<ChannelMessage> same(int slot) => [
      _channelMessage(slot, 'tie $slot', sentAt: _farFuture, receivedAt: _base),
    ];
    await _seed(
      channelMessages: {'Charlie': same, 'Alpha': same, 'Bravo': same},
    );
    await pumpChannels(tester);

    expect(_screenOrder(tester, ['Charlie', 'Alpha', 'Bravo']), [
      'Alpha',
      'Bravo',
      'Charlie',
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Recent messages sorts contacts by local arrival, not sender '
      'clocks far in the future or past', (tester) async {
    await _seed(
      contactMessages: {
        'Fiona': (key) => [
          _directMessage(
            key,
            'from the future',
            sentAt: _farFuture,
            receivedAt: _arrived(0),
          ),
        ],
        'Paul': (key) => [
          _directMessage(
            key,
            'from the past',
            sentAt: _farPast,
            receivedAt: _arrived(2),
          ),
        ],
        'Carl': (key) => [
          _directMessage(
            key,
            'on time',
            sentAt: _arrived(1),
            receivedAt: _arrived(1),
          ),
        ],
      },
    );
    await pumpContacts(tester);

    expect(_screenOrder(tester, ['Fiona', 'Paul', 'Carl']), [
      'Paul',
      'Carl',
      'Fiona',
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Contacts with equal arrival times fall back to name order', (
    tester,
  ) async {
    List<Message> same(Uint8List key) => [
      _directMessage(key, 'tie', sentAt: _farPast, receivedAt: _base),
    ];
    await _seed(contactMessages: {'Zed': same, 'Amy': same, 'Mo': same});
    await pumpContacts(tester);

    expect(_screenOrder(tester, ['Zed', 'Amy', 'Mo']), ['Amy', 'Mo', 'Zed']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Contact rows still open after the list was replaced by an '
      'empty search result', (tester) async {
    List<Message> none(Uint8List key) => [];
    await _seed(
      contactMessages: {
        'Amy': none,
        'Ben': none,
        'Cal': none,
        'Dee': none,
        'Eve': none,
      },
    );
    final connector = await _connector(tester);
    final viewState = UiViewStateService();
    await _pumpScreen(tester, connector, viewState, const ContactsScreen());
    expect(find.text('Amy'), findsOneWidget);

    viewState.setContactsSearchText('no such contact');
    await tester.pumpAndSettle();
    expect(find.text('Amy'), findsNothing);
    viewState.setContactsSearchText('');
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Amy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(BottomSheet), findsOneWidget);
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ChatScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
