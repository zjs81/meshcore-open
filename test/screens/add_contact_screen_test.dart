import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/l10n/app_localizations_en.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/screens/add_contact_screen.dart';
import 'package:meshcore_open/screens/contacts_screen.dart';
import 'package:meshcore_open/screens/discovery_screen.dart';
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

final _l10n = AppLocalizationsEn();

MeshCoreConnector? _sharedConnector;

Future<MeshCoreConnector> _connectedConnector(WidgetTester tester) async {
  if (_sharedConnector != null) {
    return _sharedConnector!;
  }
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
      ackDelay: const Duration(milliseconds: 50),
      replyDelay: const Duration(hours: 1),
    );
    await connector.connectReview();
    final end = DateTime.now().add(const Duration(seconds: 8));
    while (!connector.hasLoadedContacts && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });
  _sharedConnector = connector;
  return connector;
}

Widget _wrapApp({
  required MeshCoreConnector connector,
  required Widget home,
  ThemeData? theme,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) {
  final storage = StorageService();
  final settings = AppSettingsService();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: connector),
      ChangeNotifierProvider(create: (_) => MessageRetryService()),
      ChangeNotifierProvider(create: (_) => PathHistoryService(storage)),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider(create: (_) => BleDebugLogService()),
      ChangeNotifierProvider(create: (_) => AppDebugLogService()),
      ChangeNotifierProvider(create: (_) => ChatTextScaleService()),
      ChangeNotifierProvider(create: (_) => TranslationService(settings)),
      ChangeNotifierProvider(create: (_) => UiViewStateService()),
      Provider.value(value: storage),
      ChangeNotifierProvider(
        create: (_) => MapTileCacheService(appSettingsService: settings),
      ),
      ChangeNotifierProvider(create: (_) => TimeoutPredictionService(storage)),
      ChangeNotifierProvider(create: (_) => ImageCodecService(settings)),
      ChangeNotifierProvider(create: (_) => ReceivedImageStore()),
      ChangeNotifierProvider(
        create: (_) =>
            NetworkMapUploadService(connector: connector, settings: settings),
      ),
    ],
    child: MaterialApp(
      theme: theme ?? MeshTheme.dark(),
      locale: locale,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('add_contact_test');
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

  tearDownAll(() {
    _sharedConnector?.dispose();
    _sharedConnector = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('validates empty fields and invalid public key', (tester) async {
    final connector = await _connectedConnector(tester);

    await tester.pumpWidget(
      _wrapApp(connector: connector, home: const AddContactScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text(_l10n.addContact_title), findsOneWidget);
    expect(find.text(_l10n.addContact_infoBanner), findsOneWidget);
    expect(find.text(_l10n.contacts_addContactFromClipboard), findsOneWidget);
    expect(find.text(_l10n.addContact_fromDiscovered), findsOneWidget);
    expect(find.text(_l10n.contacts_scanQrCode), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.addContact_nameRequired), findsOneWidget);
    expect(find.text(_l10n.addContact_publicKeyRequired), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Repeater One');
    await tester.enterText(find.byType(TextFormField).last, 'abcd');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.addContact_publicKeyInvalid), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('selects contact type and submits manual contact', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);

    final keyHex = List.generate(
      32,
      (i) => (i + 1).toRadixString(16).padLeft(2, '0'),
    ).join();

    await tester.pumpWidget(
      _wrapApp(
        connector: connector,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddContactScreen()),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Change Contact Type from Chat to Repeater.
    expect(find.text(_l10n.contact_typeChat), findsOneWidget);
    await tester.tap(find.text(_l10n.contact_typeChat));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.contact_typeRepeater), findsOneWidget);
    expect(find.text(_l10n.contact_typeRoom), findsOneWidget);
    expect(find.text(_l10n.contact_typeSensor), findsOneWidget);

    await tester.tap(find.text(_l10n.contact_typeRepeater));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.contact_typeRepeater), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '  North Ridge  ');
    await tester.enterText(
      find.byType(TextFormField).last,
      '  0x${keyHex.toUpperCase()}  ',
    );

    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.check));
      final end = DateTime.now().add(const Duration(seconds: 5));
      while (!connector.contacts.any((c) => c.publicKeyHex == keyHex) &&
          DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    final added = connector.contacts.firstWhere(
      (c) => c.publicKeyHex == keyHex,
    );
    expect(added.name, 'North Ridge');
    expect(added.type, advTypeRepeater);
    expect(find.byType(AddContactScreen), findsNothing);
    expect(find.text(_l10n.discoveredContacts_contactAdded), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('bare hex key in clipboard fills Public Key and focuses Name', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);

    final keyHex = 'ab' * 32;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': '  0x${keyHex.toUpperCase()} \n'};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      _wrapApp(connector: connector, home: const AddContactScreen()),
    );
    await tester.pumpAndSettle();

    // Trigger empty validation error first, then ensure pasting a bare key clears it.
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.addContact_publicKeyRequired), findsOneWidget);

    await tester.tap(find.text(_l10n.contacts_addContactFromClipboard));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextField>(find.byType(TextField).first);
    final keyField = tester.widget<TextField>(find.byType(TextField).last);
    expect(keyField.controller!.text, keyHex);
    expect(nameField.focusNode!.hasFocus, isTrue);
    expect(find.text(_l10n.addContact_publicKeyRequired), findsNothing);
    expect(find.text(_l10n.addContact_clipboardKeyLoaded), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('empty and invalid clipboard show feedback snackbars', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);

    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') {
            return clipboardText == null
                ? null
                : <String, dynamic>{'text': clipboardText};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      _wrapApp(connector: connector, home: const AddContactScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_l10n.contacts_addContactFromClipboard));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.contacts_clipboardEmpty), findsOneWidget);

    clipboardText = 'not-a-valid-key-or-uri';
    await tester.tap(find.text(_l10n.contacts_addContactFromClipboard));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.contacts_invalidAdvertFormat), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rejects adding own public key manually', (tester) async {
    final connector = await _connectedConnector(tester);

    await tester.pumpWidget(
      _wrapApp(connector: connector, home: const AddContactScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Self');
    await tester.enterText(
      find.byType(TextFormField).last,
      connector.selfPublicKeyHex,
    );
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.contactShare_isYou), findsOneWidget);
    expect(find.byType(AddContactScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('meshcore:// contact URI in clipboard imports contact', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);

    final keyHex = 'cd' * 32;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{
              'text': 'meshcore://contact/add?name=UriPeer&public_key=$keyHex',
            };
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      _wrapApp(
        connector: connector,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddContactScreen()),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text(_l10n.contacts_addContactFromClipboard));
      final end = DateTime.now().add(const Duration(seconds: 5));
      while (!connector.contacts.any((c) => c.publicKeyHex == keyHex) &&
          DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    expect(connector.contacts.any((c) => c.name == 'UriPeer'), isTrue);
    expect(find.byType(AddContactScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Contacts FAB and menu item both open AddContactScreen', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);

    await tester.pumpWidget(
      _wrapApp(connector: connector, home: const ContactsScreen()),
    );
    await tester.pumpAndSettle();

    // Entry point 1: Contacts FAB.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(AddContactScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AddContactScreen), findsNothing);

    // Entry point 2: Overflow menu item.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.addContact_title));
    await tester.pumpAndSettle();
    expect(find.byType(AddContactScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('navigates to Discovered Contacts and adds a discovered node', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);

    final discoveredKey = Uint8List.fromList(List<int>.filled(32, 0x5E));
    final discoveredKeyHex = pubKeyToHex(discoveredKey);
    const name = 'Discovered Node';
    final frameData = ByteData(1 + 32 + 3 + 64 + 32 + 4 + 12);
    final frame = frameData.buffer.asUint8List();
    frame[0] = pushCodeNewAdvert;
    frame.setRange(1, 33, discoveredKey);
    frame[33] = advTypeChat;
    frame[35] = 0xFF;
    frame.setRange(100, 100 + name.length, name.codeUnits);
    frameData.setUint32(132, 1700000000, Endian.little);
    connector.handleFrameForTest(frame);

    await tester.pumpWidget(
      _wrapApp(connector: connector, home: const AddContactScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_l10n.addContact_fromDiscovered));
    await tester.pumpAndSettle();

    expect(find.byType(DiscoveryScreen), findsOneWidget);
    expect(find.text(name), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.person_add_alt_1));
      final end = DateTime.now().add(const Duration(seconds: 5));
      while (!connector.contacts.any(
            (c) => c.publicKeyHex == discoveredKeyHex,
          ) &&
          DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    expect(
      connector.contacts.any((c) => c.publicKeyHex == discoveredKeyHex),
      isTrue,
    );
    expect(find.text(_l10n.discoveredContacts_contactAdded), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('disconnected manual submit shows offline error snackbar', (
    tester,
  ) async {
    final connector = MeshCoreConnector();
    addTearDown(connector.dispose);
    final keyHex = 'ef' * 32;

    await tester.pumpWidget(
      _wrapApp(connector: connector, home: const AddContactScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Offline Node');
    await tester.enterText(find.byType(TextFormField).last, keyHex);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.settings_notConnectedError), findsOneWidget);
    expect(find.byType(AddContactScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final (label, theme, locale) in [
    ('light en', MeshTheme.light(), const Locale('en')),
    ('dark en', MeshTheme.dark(), const Locale('en')),
    ('dark de', MeshTheme.dark(), const Locale('de')),
  ]) {
    for (final scale in [1.3, 2.0]) {
      testWidgets('fits 320dp width at ${scale}x in $label', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final connector = await _connectedConnector(tester);

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

        await tester.pumpWidget(
          _wrapApp(
            connector: connector,
            home: const AddContactScreen(),
            theme: theme,
            locale: locale,
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();

        FlutterError.onError = previous;
        expect(overflows, isEmpty, reason: overflows.join('\n'));
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
