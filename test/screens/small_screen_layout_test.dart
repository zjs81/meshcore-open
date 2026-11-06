import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/screens/app_debug_log_screen.dart';
import 'package:meshcore_open/screens/app_settings_screen.dart';
import 'package:meshcore_open/screens/ble_debug_log_screen.dart';
import 'package:meshcore_open/screens/channel_chat_screen.dart';
import 'package:meshcore_open/screens/channel_message_path_screen.dart';
import 'package:meshcore_open/screens/channels_screen.dart';
import 'package:meshcore_open/screens/chat_screen.dart';
import 'package:meshcore_open/screens/chrome_required_screen.dart';
import 'package:meshcore_open/screens/companion_radio_stats_screen.dart';
import 'package:meshcore_open/screens/contacts_screen.dart';
import 'package:meshcore_open/screens/discovery_screen.dart';
import 'package:meshcore_open/screens/line_of_sight_map_screen.dart';
import 'package:meshcore_open/screens/map_cache_screen.dart';
import 'package:meshcore_open/screens/map_screen.dart';
import 'package:meshcore_open/screens/neighbors_screen.dart';
import 'package:meshcore_open/screens/path_trace_map.dart';
import 'package:meshcore_open/screens/region_management_screen.dart';
import 'package:meshcore_open/screens/repeater_cli_screen.dart';
import 'package:meshcore_open/screens/repeater_hub_screen.dart';
import 'package:meshcore_open/screens/repeater_settings_screen.dart';
import 'package:meshcore_open/screens/repeater_status_screen.dart';
import 'package:meshcore_open/screens/scanner_screen.dart';
import 'package:meshcore_open/screens/settings_screen.dart';
import 'package:meshcore_open/screens/tcp_screen.dart';
import 'package:meshcore_open/screens/telemetry_screen.dart';
import 'package:meshcore_open/screens/usb_screen.dart';
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

/// Renders every screen on a small phone (320x568, the narrowest common
/// width) at several text scales, plus a desktop window, and fails on any
/// layout overflow.
const _layouts = [
  (Size(320, 568), [1.0, 1.3, 2.0]),
  (Size(1280, 800), [1.0]),
];

class _Env {
  final MeshCoreConnector connector;
  final List<SingleChildWidget> providers;
  _Env(this.connector, this.providers);
}

Future<_Env> _connect(WidgetTester tester) async {
  final storage = StorageService();
  final connector = MeshCoreConnector();
  final retry = MessageRetryService();
  final settings = AppSettingsService();
  final translation = TranslationService(settings);
  final env = _Env(connector, [
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
    ChangeNotifierProvider.value(
      value: NetworkMapUploadService(connector: connector, settings: settings),
    ),
  ]);
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
    while ((connector.contacts.isEmpty || connector.channels.isEmpty) &&
        DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });
  return env;
}

Contact _contactOfType(MeshCoreConnector c, int type) => c.contacts.firstWhere(
  (x) => x.type == type,
  orElse: () => c.contacts.first,
);

_Env? _shared;

typedef _ScreenBuilder = Widget Function(MeshCoreConnector c);

/// Screens that open a sheet after the first frame, keyed like [_screens].
final Map<String, Future<void> Function(WidgetTester t, MeshCoreConnector c)>
_interactions = {
  'Contacts options sheet': (t, _) async {
    // At large text the first contact can start below the fold.
    await t.drag(find.byType(RefreshIndicator), const Offset(0, -150));
    await t.pump(const Duration(milliseconds: 500));
    await t.longPress(
      find
          .byWidgetPredicate((w) => w.runtimeType.toString() == '_ContactTile')
          .first,
    );
  },
  'Contacts add sheet': (t, _) async {
    await t.tap(find.byType(FloatingActionButton));
  },
};

final Map<String, _ScreenBuilder> _screens = {
  'Contacts options sheet': (_) => const ContactsScreen(),
  'Contacts add sheet': (_) => const ContactsScreen(),
  'Scanner': (_) => const ScannerScreen(),
  'Tcp': (_) => const TcpScreen(),
  'Usb': (_) => const UsbScreen(),
  'ChromeRequired': (_) => const ChromeRequiredScreen(),
  'Contacts': (_) => const ContactsScreen(),
  'Channels': (_) => const ChannelsScreen(),
  'Settings': (_) => const SettingsScreen(),
  'AppSettings': (_) => const AppSettingsScreen(),
  'Discovery': (_) => const DiscoveryScreen(),
  'RegionManagement': (_) => const RegionManagementScreen(),
  'MapCache': (_) => const MapCacheScreen(),
  'CompanionRadioStats': (_) => const CompanionRadioStatsScreen(),
  'AppDebugLog': (_) => const AppDebugLogScreen(),
  'BleDebugLog': (_) => const BleDebugLogScreen(),
  'Map': (_) => const MapScreen(),
  'Chat': (c) => ChatScreen(contact: _contactOfType(c, advTypeChat)),
  'ChannelChat': (c) => ChannelChatScreen(channel: c.channels.first),
  'ChannelMessagePath': (c) {
    final msgs = c.getChannelMessages(c.channels.first);
    return ChannelMessagePathScreen(message: msgs.last);
  },
  'Telemetry': (c) => TelemetryScreen(contact: _contactOfType(c, advTypeChat)),
  'RepeaterHub': (c) => RepeaterHubScreen(
    repeater: _contactOfType(c, advTypeRepeater),
    password: '',
    isAdmin: true,
  ),
  'RepeaterStatus': (c) => RepeaterStatusScreen(
    repeater: _contactOfType(c, advTypeRepeater),
    password: '',
  ),
  'RepeaterSettings': (c) => RepeaterSettingsScreen(
    repeater: _contactOfType(c, advTypeRepeater),
    password: '',
  ),
  'RepeaterCli': (c) => RepeaterCliScreen(
    repeater: _contactOfType(c, advTypeRepeater),
    password: '',
  ),
  'Neighbors': (c) => NeighborsScreen(
    repeater: _contactOfType(c, advTypeRepeater),
    password: '',
  ),
  'PathTraceMap': (c) {
    final r = _contactOfType(c, advTypeRepeater);
    return PathTraceMapScreen(
      title: 'Trace',
      path: r.publicKey.sublist(0, 1),
      targetContact: r,
    );
  },
  'LineOfSightMap': (_) => const LineOfSightMapScreen(
    title: 'Line of sight',
    candidates: [
      LineOfSightEndpoint(label: 'A', point: LatLng(45.5, -122.6)),
      LineOfSightEndpoint(label: 'B', point: LatLng(45.6, -122.7)),
    ],
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('small_screen_test');
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

  final variants = [
    for (final entry in _screens.entries) (entry, false),
    // Repeater screens add a banner while the companion radio is offline.
    for (final entry in _screens.entries)
      if (entry.key.startsWith('Repeater') || entry.key == 'Neighbors')
        (entry, true),
  ];
  for (final (entry, offline) in variants) {
    for (final (size, scales) in _layouts) {
      for (final scale in scales) {
        final state = offline ? ' (radio offline)' : '';
        testWidgets('${entry.key}$state fits ${size.width.toInt()}dp at '
            '${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final shared = _shared ??= await _connect(tester);
          final env = offline
              ? _Env(shared.connector, [
                  ChangeNotifierProvider.value(value: MeshCoreConnector()),
                  ...shared.providers.skip(1),
                ])
              : shared;
          final overflows = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (details) {
            final text = details.exceptionAsString();
            if (!text.contains('overflowed')) {
              previous?.call(details);
              return;
            }
            // The creation location names the overflowing Flex in lib/.
            final where = RegExp(r'lib/[\w/]+\.dart:\d+')
                .allMatches(details.toString())
                .map((m) => m[0])
                .toSet()
                .join(', ');
            overflows.add('${text.split('\n').first} at $where');
          };
          addTearDown(() => FlutterError.onError = previous);

          await tester.pumpWidget(
            MultiProvider(
              providers: env.providers,
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
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: entry.value(env.connector),
              ),
            ),
          );
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          final interaction = _interactions[entry.key];
          if (interaction != null) {
            await interaction(tester, env.connector);
            for (var i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          }
          await tester.pumpWidget(const SizedBox());
          // Let one-shot timers (scan and request timeouts) run out.
          await tester.pump(const Duration(minutes: 1));

          FlutterError.onError = previous;
          expect(overflows, isEmpty, reason: overflows.join('\n---\n'));
        });
      }
    }
  }
}
