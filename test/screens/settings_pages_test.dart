import 'dart:async';
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
import 'package:meshcore_open/l10n/app_localizations_en.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/screens/about_screen.dart';
import 'package:meshcore_open/screens/contact_settings_screen.dart';
import 'package:meshcore_open/screens/location_picker_screen.dart';
import 'package:meshcore_open/screens/location_settings_screen.dart';
import 'package:meshcore_open/screens/node_name_screen.dart';
import 'package:meshcore_open/screens/privacy_settings_screen.dart';
import 'package:meshcore_open/screens/radio_settings_screen.dart';
import 'package:meshcore_open/screens/settings_screen.dart';
import 'package:meshcore_open/screens/telemetry_screen.dart';
import 'package:meshcore_open/services/app_debug_log_service.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/ble_debug_log_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/services/ui_view_state_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/unsaved_changes_guard.dart';

final _l10n = AppLocalizationsEn();

MeshCoreConnector? _sharedConnector;
AppSettingsService? _sharedSettings;
final _frameLog = BleDebugLogService();

Future<MeshCoreConnector> _connectedConnector(WidgetTester tester) async {
  if (_sharedConnector != null) return _sharedConnector!;
  final storage = StorageService();
  final connector = MeshCoreConnector();
  final settings = AppSettingsService();
  final translation = TranslationService(settings);
  await tester.runAsync(() async {
    await settings.loadSettings();
    connector.initialize(
      retryService: MessageRetryService(),
      pathHistoryService: PathHistoryService(storage),
      appSettingsService: settings,
      translationService: translation,
      bleDebugLogService: _frameLog,
    );
    connector.reviewRadioFactoryForTest = () => ReviewRadio(
      scheduledMessageInterval: const Duration(hours: 1),
      ackDelay: const Duration(milliseconds: 50),
      replyDelay: const Duration(hours: 1),
    );
    await connector.connectReview();
    final end = DateTime.now().add(const Duration(seconds: 8));
    while (connector.selfName == null && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });
  _sharedSettings = settings;
  return _sharedConnector = connector;
}

Widget _app(MeshCoreConnector connector, Widget home) {
  final settings = _sharedSettings ?? AppSettingsService();
  final storage = StorageService();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: connector),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider(create: (_) => PathHistoryService(storage)),
      ChangeNotifierProvider(create: (_) => BleDebugLogService()),
      ChangeNotifierProvider(create: (_) => AppDebugLogService()),
      ChangeNotifierProvider(create: (_) => UiViewStateService()),
      Provider.value(value: storage),
      ChangeNotifierProvider(
        create: (_) => MapTileCacheService(appSettingsService: settings),
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

/// A home screen with one button that pushes [page], so tests can check
/// whether leaving the page really closes it.
Widget _launcher(Widget page) => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => page),
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _waitFor(WidgetTester tester, bool Function() done) async {
  await tester.runAsync(() async {
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (!done() && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });
  await tester.pumpAndSettle();
}

Finder get _saveAction => find.widgetWithText(TextButton, _l10n.common_save);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tempDir = Directory.systemTemp.createTempSync('settings_pages_test');
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

  group('UnsavedChangesGuard', () {
    Widget guarded({required Future<bool> Function() onSave}) =>
        UnsavedChangesGuard(
          hasChanges: true,
          canSave: true,
          message: 'msg',
          onSave: onSave,
          child: Scaffold(appBar: AppBar(), body: const Text('page')),
        );

    Future<void> pumpGuarded(
      WidgetTester tester,
      Future<bool> Function() onSave,
    ) async {
      await tester.pumpWidget(
        _app(MeshCoreConnector(), _launcher(guarded(onSave: onSave))),
      );
      await _open(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(_l10n.repeater_unsavedChangesTitle), findsOneWidget);
    }

    testWidgets('Cancel stays and Discard leaves', (tester) async {
      await pumpGuarded(tester, () async => true);
      await tester.tap(find.text(_l10n.common_cancel));
      await tester.pumpAndSettle();
      expect(find.text('page'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n.repeater_discardChanges));
      await tester.pumpAndSettle();
      expect(find.text('page'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('Save leaves only when saving succeeds', (tester) async {
      var result = false;
      var saves = 0;
      await pumpGuarded(tester, () async {
        saves++;
        return result;
      });
      await tester.tap(find.widgetWithText(FilledButton, _l10n.common_save));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(find.text('page'), findsOneWidget);

      result = true;
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, _l10n.common_save));
      await tester.pumpAndSettle();
      expect(saves, 2);
      expect(find.text('page'), findsNothing);
    });
  });

  testWidgets('SaveToRadioPage reports a failed save and keeps the page', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);
    await tester.pumpWidget(
      _app(
        connector,
        _launcher(
          SaveToRadioPage(
            title: 'Page',
            hasChanges: true,
            onSave: () async => throw StateError('rejected'),
            children: const [Text('field')],
          ),
        ),
      ),
    );
    await _open(tester);
    await tester.tap(_saveAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(_l10n.settings_error('Bad state: rejected')),
      findsOneWidget,
    );
    expect(find.text('field'), findsOneWidget);
    expect(tester.widget<TextButton>(_saveAction).onPressed, isNotNull);
  });

  testWidgets('SaveToRadioPage shows the top bar while saving', (tester) async {
    final connector = await _connectedConnector(tester);
    final reply = Completer<bool>();
    await tester.pumpWidget(
      _app(
        connector,
        _launcher(
          SaveToRadioPage(
            title: 'Page',
            hasChanges: true,
            onSave: () => reply.future,
            children: const [Text('field')],
          ),
        ),
      ),
    );
    await _open(tester);
    final bar = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(LinearProgressIndicator),
    );
    expect(bar, findsNothing);

    await tester.tap(_saveAction);
    await tester.pump();
    expect(bar, findsOneWidget);

    reply.complete(true);
    await tester.pump();
    await tester.pump();
    expect(bar, findsNothing);
  });

  testWidgets('Telemetry moves the top bar for a fetch, not auto-refresh', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);
    // The connect-time sync shows the same bar, so let it finish first.
    await _waitFor(
      tester,
      () =>
          !connector.isLoadingContacts &&
          !connector.isSyncingChannels &&
          !connector.isShowingQueuedMessageSyncProgress,
    );
    await tester.pumpWidget(
      _app(
        connector,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => pushSelfTelemetryScreen(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final bar = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(LinearProgressIndicator),
    );
    // The fetch on open is a user request. The review radio doesn't answer
    // self requests, so it times out after 5s.
    expect(bar, findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(bar, findsNothing);

    final enable = find.text(_l10n.common_enable);
    await tester.ensureVisible(enable);
    await tester.tap(enable);
    await tester.pump();
    expect(find.text(_l10n.common_disable), findsOneWidget);
    expect(bar, findsNothing);

    await tester.tap(find.text(_l10n.common_disable));
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Settings rows open pages, not dialogs', (tester) async {
    final connector = await _connectedConnector(tester);
    // The connected status dot pulses forever, so pump for a fixed time
    // instead of waiting for the screen to settle.
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(_app(connector, const SettingsScreen()));
    await settle();

    final rows = <String, Type>{
      _l10n.settings_nodeName: NodeNameScreen,
      _l10n.settings_radioSettings: RadioSettingsScreen,
      _l10n.settings_location: LocationSettingsScreen,
      _l10n.settings_contactSettings: ContactSettingsScreen,
      _l10n.settings_privacy: PrivacySettingsScreen,
      _l10n.settings_aboutTheApp: AboutScreen,
    };
    for (final MapEntry(key: title, value: page) in rows.entries) {
      await tester.scrollUntilVisible(
        find.text(title),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await settle();
      await tester.tap(find.text(title));
      await settle();
      expect(find.byType(page), findsOneWidget, reason: title);
      expect(find.byType(AlertDialog), findsNothing, reason: title);
      await tester.pageBack();
      await settle();
      expect(find.byType(page), findsNothing, reason: title);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Reboot and Delete All Paths use theme colours and confirm', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(_app(connector, const SettingsScreen()));
    await settle();
    final scheme = Theme.of(
      tester.element(find.byType(SettingsScreen)),
    ).colorScheme;

    final rows = {
      _l10n.settings_rebootDevice: (_l10n.common_reboot, scheme.tertiary),
      _l10n.settings_deleteAllPaths: (_l10n.common_deleteAll, scheme.error),
    };
    for (final MapEntry(key: title, value: (label, color)) in rows.entries) {
      await tester.scrollUntilVisible(
        find.text(title),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await settle();
      expect(tester.widget<Text>(find.text(title)).style?.color, color);

      await tester.tap(find.text(title));
      await settle();
      final confirm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, label),
      );
      expect(confirm.style?.backgroundColor?.resolve({}), color, reason: title);

      // Cancel, so the review radio isn't rebooted.
      await tester.tap(find.text(_l10n.common_cancel));
      await settle();
      expect(find.byType(AlertDialog), findsNothing, reason: title);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Sync Time and Refresh Contacts end with a message', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);
    await tester.pumpWidget(_app(connector, const SettingsScreen()));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Refresh Contacts ends when the review radio sends END_OF_CONTACTS.
    final rows = {
      _l10n.settings_syncTime: _l10n.settings_timeSent,
      _l10n.settings_refreshContacts: _l10n.settings_contactsRefreshed,
    };
    for (final MapEntry(key: title, value: message) in rows.entries) {
      await tester.scrollUntilVisible(
        find.text(title),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(title));
      await tester.pump();
      // Real time lets the reply arrive; pump runs the code waiting for it.
      for (var i = 0; i < 200; i++) {
        if (find.text(message).evaluate().isNotEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text(message), findsOneWidget, reason: title);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Delete All Paths confirms with a snackbar', (tester) async {
    final connector = await _connectedConnector(tester);
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(_app(connector, const SettingsScreen()));
    await settle();
    await tester.scrollUntilVisible(
      find.text(_l10n.settings_deleteAllPaths),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await settle();
    await tester.tap(find.text(_l10n.settings_deleteAllPaths));
    await settle();
    await tester.tap(find.widgetWithText(FilledButton, _l10n.common_deleteAll));
    await settle();
    expect(find.text(_l10n.settings_allPathsDeleted), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Radio Settings shows Save only while something differs', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);
    await tester.pumpWidget(
      _app(connector, RadioSettingsScreen(connector: connector)),
    );
    await tester.pumpAndSettle();
    expect(_saveAction, findsNothing);

    final txField = find.widgetWithText(TextField, _l10n.settings_txPower);
    final original = tester.widget<TextField>(txField).controller!.text;
    final changed = original == '10' ? '11' : '10';
    await tester.enterText(txField, changed);
    await tester.pump();
    expect(_saveAction, findsOneWidget);

    await tester.enterText(txField, original);
    await tester.pump();
    expect(_saveAction, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Location picker fills the coordinate fields', (tester) async {
    final connector = await _connectedConnector(tester);
    await tester.pumpWidget(
      _app(connector, _launcher(const LocationSettingsScreen())),
    );
    await _open(tester);

    await tester.enterText(
      find.widgetWithText(TextField, _l10n.settings_latitude),
      '45.5',
    );
    await tester.enterText(
      find.widgetWithText(TextField, _l10n.settings_longitude),
      '-122.6',
    );
    await tester.tap(find.text(_l10n.location_pickOnMap));
    await tester.pumpAndSettle();
    expect(find.byType(LocationPickerScreen), findsOneWidget);
    expect(find.text('45.500000, -122.600000'), findsOneWidget);

    await tester.tap(find.text(_l10n.locationPicker_useLocation));
    await tester.pumpAndSettle();
    expect(find.byType(LocationPickerScreen), findsNothing);
    expect(find.text('45.500000'), findsOneWidget);
    expect(find.text('-122.600000'), findsOneWidget);
    expect(_saveAction, findsOneWidget);

    // Unsaved coordinates are not dropped silently.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.repeater_discardChanges));
    await tester.pumpAndSettle();
    expect(find.byType(LocationSettingsScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Contact Settings sends the hop limit and reads it back', (
    tester,
  ) async {
    final connector = await _connectedConnector(tester);
    final original = connector.autoAddMaxHops;
    expect(original, isNotNull, reason: 'review radio reports the hop limit');
    await tester.pumpWidget(
      _app(connector, _launcher(const ContactSettingsScreen())),
    );
    await _open(tester);
    String option(int hops) => _l10n.contactsSettings_hopLimitOption(hops);
    expect(find.text(option(original!)), findsOneWidget);

    Future<void> setHops(int hops) async {
      final field = find.byType(DropdownButtonFormField<int>);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await tester.pumpAndSettle();
      // The open menu builds only the rows around the current value.
      final item = find.text(option(hops));
      await tester.scrollUntilVisible(
        item,
        hops < connector.autoAddMaxHops! ? -48 : 48,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(item.last);
      await tester.pumpAndSettle();
      await tester.tap(_saveAction);
      await _waitFor(tester, () => connector.autoAddMaxHops == hops);
    }

    // The last frame of [code] the app sent to the radio.
    List<int> lastSent(int code) => _frameLog.entries
        .lastWhere((e) => e.outgoing && e.payload.first == code)
        .payload;
    int sentCount(int code) => _frameLog.entries
        .where((e) => e.outgoing && e.payload.first == code)
        .length;

    final fetchesBefore = sentCount(cmdGetAutoAddConfig);
    await setHops(8);
    expect(connector.autoAddMaxHops, 8);
    expect(find.text(option(8)), findsOneWidget);
    expect(_saveAction, findsNothing);
    // [CMD_SET_AUTOADD_CONFIG][flags][max hops], then a fetch to read it back.
    expect(lastSent(cmdSetAutoAddConfig), hasLength(3));
    expect(lastSent(cmdSetAutoAddConfig).last, 8);
    expect(sentCount(cmdGetAutoAddConfig), fetchesBefore + 1);

    // Changing only another setting sends the old two-byte frame.
    final overwrite = find.text(_l10n.contactsSettings_overwriteOldestTitle);
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(overwrite);
      await tester.pumpAndSettle();
      await tester.tap(overwrite);
      await tester.pump();
      await tester.tap(_saveAction);
      await _waitFor(tester, () => _saveAction.evaluate().isEmpty);
      expect(lastSent(cmdSetAutoAddConfig), hasLength(2));
    }
    expect(connector.autoAddMaxHops, 8);

    await setHops(original);
    expect(connector.autoAddMaxHops, original);
    expect(lastSent(cmdSetAutoAddConfig), hasLength(3));
    expect(lastSent(cmdSetAutoAddConfig).last, original);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Node Name counts bytes and saves to the radio', (tester) async {
    final connector = await _connectedConnector(tester);
    final originalName = connector.selfName!;
    await tester.pumpWidget(_app(connector, _launcher(const NodeNameScreen())));
    await _open(tester);
    expect(_saveAction, findsNothing);
    expect(
      find.text(_l10n.nodeName_bytesAvailable(maxContactMessageBytes())),
      findsOneWidget,
    );

    // "Ab" is two bytes and the emoji four.
    const newName = 'Ab😀';
    await tester.enterText(find.byType(TextField), newName);
    await tester.pump();
    expect(find.text('6 / 31'), findsOneWidget);
    expect(
      find.text(_l10n.nodeName_bytesAvailable(maxChannelMessageBytes(newName))),
      findsOneWidget,
    );
    expect(maxChannelMessageBytes(newName), 158 - 6);
    expect(_saveAction, findsOneWidget);

    await tester.tap(_saveAction);
    await _waitFor(tester, () => connector.selfName == newName);
    expect(connector.selfName, newName);
    expect(find.text(_l10n.settings_nodeNameUpdated), findsOneWidget);
    expect(_saveAction, findsNothing);

    // Longer names are accepted but can't be saved, and say how far over
    // the limit they are.
    final longName = 'x' * 33;
    await tester.enterText(find.byType(TextField), longName);
    await tester.pump();
    expect(find.text(longName), findsOneWidget);
    expect(find.text('33 / 31'), findsOneWidget);
    expect(find.text(_l10n.nodeName_bytesOver(2)), findsOneWidget);
    expect(tester.widget<TextButton>(_saveAction).onPressed, isNull);

    // Saving from the leave dialog sends the edit, then closes the page.
    await tester.enterText(find.byType(TextField), originalName);
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, _l10n.common_save));
    await _waitFor(tester, () => connector.selfName == originalName);
    expect(connector.selfName, originalName);
    expect(find.byType(NodeNameScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
