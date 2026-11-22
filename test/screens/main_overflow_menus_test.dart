import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/screens/channels_screen.dart';
import 'package:meshcore_open/screens/contacts_screen.dart';
import 'package:meshcore_open/screens/map_screen.dart';
import 'package:meshcore_open/screens/settings_screen.dart';
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
import 'package:meshcore_open/widgets/connect_sheet.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

class _TestEnv {
  final MeshCoreConnector connector;
  final UiViewStateService viewState;
  final Widget Function(Widget home, {double textScale}) wrap;

  _TestEnv({
    required this.connector,
    required this.viewState,
    required this.wrap,
  });
}

_TestEnv? _sharedConnected;

Future<_TestEnv> _createConnectedEnv(WidgetTester tester) async {
  if (_sharedConnected != null) {
    _sharedConnected!.viewState.mapPathTrace.active = false;
    return _sharedConnected!;
  }
  final storage = StorageService();
  final connector = MeshCoreConnector();
  final retry = MessageRetryService();
  final settings = AppSettingsService();
  final translation = TranslationService(settings);
  final viewState = UiViewStateService();

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

  return _sharedConnected = _TestEnv(
    connector: connector,
    viewState: viewState,
    wrap: wrap,
  );
}

Future<_TestEnv> _createEnv(
  WidgetTester tester, {
  required bool connected,
}) async {
  final shared = await _createConnectedEnv(tester);
  if (connected) return shared;

  final offlineConnector = MeshCoreConnector();
  addTearDown(offlineConnector.dispose);
  final storage = StorageService();
  final settings = AppSettingsService();
  await tester.runAsync(settings.loadSettings);
  final viewState = UiViewStateService();
  final offlineProviders = [
    ChangeNotifierProvider.value(value: offlineConnector),
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
        connector: offlineConnector,
        settings: settings,
      ),
    ),
  ];

  Widget wrap(Widget home, {double textScale = 1.0}) {
    return MultiProvider(
      providers: offlineProviders,
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
  }

  return _TestEnv(
    connector: offlineConnector,
    viewState: viewState,
    wrap: wrap,
  );
}

Future<void> _pumpSettleFrames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Returns the rendered entries of an open [PopupMenuButton] in top-to-bottom
/// visual order: label strings for [PopupMenuItem]s and `'---'` for
/// [PopupMenuDivider]s.
List<String> _openMenuEntries(WidgetTester tester) {
  final entries = <({double dy, String label})>[];

  for (final element in find.byType(PopupMenuDivider).evaluate()) {
    final box = element.renderObject! as RenderBox;
    final dy = box.localToGlobal(Offset.zero).dy;
    entries.add((dy: dy, label: '---'));
  }

  for (final element
      in find.byWidgetPredicate((w) => w is PopupMenuItem).evaluate()) {
    final box = element.renderObject! as RenderBox;
    final dy = box.localToGlobal(Offset.zero).dy;
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byWidget(element.widget),
        matching: find.byType(Text),
      ),
    );
    entries.add((dy: dy, label: text.data!));
  }

  entries.sort((a, b) => a.dy.compareTo(b.dy));
  return entries.map((e) => e.label).toList();
}

PopupMenuItem<Object?> _menuItemByLabel(String label) {
  return find
          .ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is PopupMenuItem),
          )
          .evaluate()
          .single
          .widget
      as PopupMenuItem<Object?>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync(
    'main_overflow_menus_test',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempDir.path,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  group('mainOverflowTrailingItems helper', () {
    testWidgets('includes leading divider when hasPrecedingItems is true', (
      tester,
    ) async {
      final env = await _createEnv(tester, connected: false);
      late List<PopupMenuEntry<dynamic>> entries;

      await tester.pumpWidget(
        env.wrap(
          Builder(
            builder: (context) => PopupMenuButton<dynamic>(
              itemBuilder: (menuContext) {
                entries = mainOverflowTrailingItems(
                  context,
                  menuContext,
                  hasPrecedingItems: true,
                );
                return entries;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PopupMenuButton<dynamic>));
      await _pumpSettleFrames(tester);

      expect(entries, hasLength(3));
      expect(entries[0], isA<PopupMenuDivider>());
      expect(_openMenuEntries(tester), [
        '---',
        _l10n.common_connect,
        _l10n.settings_title,
      ]);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('omits leading divider when hasPrecedingItems is false', (
      tester,
    ) async {
      final env = await _createEnv(tester, connected: true);
      late List<PopupMenuEntry<dynamic>> entries;

      await tester.pumpWidget(
        env.wrap(
          Builder(
            builder: (context) => PopupMenuButton<dynamic>(
              itemBuilder: (menuContext) {
                entries = mainOverflowTrailingItems(
                  context,
                  menuContext,
                  hasPrecedingItems: false,
                );
                return entries;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PopupMenuButton<dynamic>));
      await _pumpSettleFrames(tester);

      expect(entries, hasLength(2));
      expect(entries[0], isNot(isA<PopupMenuDivider>()));
      expect(_openMenuEntries(tester), [
        _l10n.common_disconnect,
        _l10n.settings_title,
      ]);

      // Tapping Settings uses the screen context safely after the menu pops.
      await tester.tap(find.text(_l10n.settings_title));
      await _pumpSettleFrames(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
    });
  });

  group('Main screen overflow menus order and state', () {
    for (final connected in [true, false]) {
      final stateLabel = connected ? 'connected' : 'disconnected';
      final connectionLabel = connected
          ? _l10n.common_disconnect
          : _l10n.common_connect;

      testWidgets('Contacts overflow menu ($stateLabel)', (tester) async {
        final env = await _createEnv(tester, connected: connected);
        await tester.pumpWidget(env.wrap(const ContactsScreen()));
        await _pumpSettleFrames(tester);

        final button = tester.widget<PopupMenuButton<dynamic>>(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byWidgetPredicate((w) => w is PopupMenuButton),
          ),
        );
        expect(button.tooltip, _l10n.contacts_moreOptions);

        await tester.tap(find.byIcon(Icons.more_vert));
        await _pumpSettleFrames(tester);

        expect(_openMenuEntries(tester), [
          _l10n.addContact_title,
          _l10n.discoveredContacts_Title,
          '---',
          _l10n.contacts_zeroHopAdvert,
          _l10n.contacts_floodAdvert,
          _l10n.contacts_copyAdvertToClipboard,
          _l10n.manualTrace_menuItem,
          '---',
          connectionLabel,
          _l10n.settings_title,
        ]);
        expect(_menuItemByLabel(_l10n.addContact_title).enabled, connected);
        expect(
          _menuItemByLabel(_l10n.discoveredContacts_Title).enabled,
          isTrue,
        );
        expect(
          _menuItemByLabel(_l10n.contacts_zeroHopAdvert).enabled,
          connected,
        );
        expect(_menuItemByLabel(_l10n.contacts_floodAdvert).enabled, connected);
        expect(
          _menuItemByLabel(_l10n.contacts_copyAdvertToClipboard).enabled,
          connected,
        );
        expect(_menuItemByLabel(_l10n.manualTrace_menuItem).enabled, connected);
        expect(_menuItemByLabel(connectionLabel).enabled, isTrue);
        expect(_menuItemByLabel(_l10n.settings_title).enabled, isTrue);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
      });

      testWidgets('Channels overflow menu ($stateLabel)', (tester) async {
        final env = await _createEnv(tester, connected: connected);
        await tester.pumpWidget(env.wrap(const ChannelsScreen()));
        await _pumpSettleFrames(tester);

        final button = tester.widget<PopupMenuButton<dynamic>>(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byWidgetPredicate((w) => w is PopupMenuButton),
          ),
        );
        expect(button.tooltip, _l10n.contacts_moreOptions);

        await tester.tap(find.byIcon(Icons.more_vert));
        await _pumpSettleFrames(tester);

        expect(_openMenuEntries(tester), [
          _l10n.bookmarks_title,
          _l10n.community_manageCommunities,
          '---',
          connectionLabel,
          _l10n.settings_title,
        ]);
        expect(_menuItemByLabel(_l10n.bookmarks_title).enabled, isTrue);
        expect(
          _menuItemByLabel(_l10n.community_manageCommunities).enabled,
          isTrue,
        );
        expect(_menuItemByLabel(connectionLabel).enabled, isTrue);
        expect(_menuItemByLabel(_l10n.settings_title).enabled, isTrue);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
      });

      testWidgets('Map overflow menu ($stateLabel)', (tester) async {
        final env = await _createEnv(tester, connected: connected);
        await tester.pumpWidget(env.wrap(const MapScreen()));
        await _pumpSettleFrames(tester);

        final button = tester.widget<PopupMenuButton<dynamic>>(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byWidgetPredicate((w) => w is PopupMenuButton),
          ),
        );
        expect(button.tooltip, _l10n.contacts_moreOptions);

        await tester.tap(find.byIcon(Icons.more_vert));
        await _pumpSettleFrames(tester);

        final hasSelfLocation =
            env.connector.selfLatitude != null &&
            env.connector.selfLongitude != null;
        expect(_openMenuEntries(tester), [
          if (hasSelfLocation) _l10n.contacts_pathTrace,
          _l10n.manualTrace_menuItem,
          _l10n.map_lineOfSight,
          '---',
          connectionLabel,
          _l10n.settings_title,
        ]);
        expect(_menuItemByLabel(_l10n.manualTrace_menuItem).enabled, connected);
        expect(_menuItemByLabel(_l10n.map_lineOfSight).enabled, isTrue);
        expect(_menuItemByLabel(connectionLabel).enabled, isTrue);
        expect(_menuItemByLabel(_l10n.settings_title).enabled, isTrue);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
      });
    }

    testWidgets(
      'Map overflow menu omits leading divider while building path trace',
      (tester) async {
        final env = await _createEnv(tester, connected: true);
        env.viewState.mapPathTrace.active = true;
        await tester.pumpWidget(env.wrap(const MapScreen()));
        await _pumpSettleFrames(tester);

        await tester.tap(find.byIcon(Icons.more_vert));
        await _pumpSettleFrames(tester);

        expect(_openMenuEntries(tester), [
          _l10n.common_disconnect,
          _l10n.settings_title,
        ]);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
      },
    );
  });

  group('Overflow menus at 320dp with 1.3x and 2.0x text scale', () {
    final screens = <String, Widget Function()>{
      'Contacts': () => const ContactsScreen(),
      'Channels': () => const ChannelsScreen(),
      'Map': () => const MapScreen(),
    };

    for (final entry in screens.entries) {
      for (final scale in [1.3, 2.0]) {
        testWidgets('${entry.key} overflow menu fits 320dp at ${scale}x', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final env = await _createEnv(tester, connected: true);
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

          await tester.pumpWidget(env.wrap(entry.value(), textScale: scale));
          await _pumpSettleFrames(tester);

          await tester.tap(find.byIcon(Icons.more_vert));
          await _pumpSettleFrames(tester);

          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(minutes: 1));
          FlutterError.onError = previous;

          expect(overflows, isEmpty, reason: overflows.join('\n'));
        });
      }
    }
  });
}
