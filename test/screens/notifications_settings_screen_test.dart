import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/screens/app_settings_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/network_map/network_map_upload_service.dart';
import 'package:meshcore_open/services/notification_service.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/utils/platform_info.dart';
import 'package:meshcore_open/widgets/mesh_nav_tile.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';
import 'package:meshcore_open/widgets/settings_reveal.dart';

Future<AppSettingsService> _createSettingsService({
  bool notificationsEnabled = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  PrefsManager.reset();
  await PrefsManager.initialize();
  final settings = AppSettingsService();
  await settings.loadSettings();
  if (!notificationsEnabled) {
    await settings.setNotificationsEnabled(false);
  }
  return settings;
}

Widget _buildSectionTestApp({
  required AppSettingsService settings,
  ThemeData? theme,
  double textScale = 1.0,
  Future<bool> Function()? hasPermission,
  Future<bool> Function()? requestPermission,
}) {
  return ChangeNotifierProvider.value(
    value: settings,
    child: MaterialApp(
      theme: theme ?? MeshTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: MeshSettingsTileTheme(
          child: SingleChildScrollView(
            child: MeshCard(
              padding: EdgeInsets.zero,
              child: NotificationsSettingsSection(
                hasPermission: hasPermission,
                requestPermission: requestPermission,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    NotificationService().resetForTest();
    PlatformInfo.debugIsAndroidOverride = null;
  });

  tearDown(() {
    NotificationService().resetForTest();
    PlatformInfo.debugIsAndroidOverride = null;
  });

  testWidgets(
    'notificationsEnabled + OS permission granted shows switch ON, expanded SettingsReveal, and exact row order including Android Background Activity last',
    (tester) async {
      PlatformInfo.debugIsAndroidOverride = true;
      final settings = await _createSettingsService(notificationsEnabled: true);

      await tester.pumpWidget(
        _buildSectionTestApp(
          settings: settings,
          hasPermission: () async => true,
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(NotificationsSettingsSection));
      final l10n = AppLocalizations.of(context);

      final enableTile = tester.widget<SwitchListTile>(
        find.widgetWithText(
          SwitchListTile,
          l10n.appSettings_enableNotifications,
        ),
      );
      expect(enableTile.value, isTrue);
      expect(
        find.text(l10n.appSettings_enableNotificationsSubtitle),
        findsOneWidget,
      );

      final reveal = tester.widget<SettingsReveal>(find.byType(SettingsReveal));
      expect(reveal.visible, isTrue);

      final msgFinder = find.text(l10n.appSettings_messageNotifications);
      final channelFinder = find.text(
        l10n.appSettings_channelMessageNotifications,
      );
      final advertFinder = find.text(
        l10n.appSettings_advertisementNotifications,
      );
      final bgActivityFinder = find.text(l10n.appSettings_batteryOptimization);

      expect(msgFinder, findsOneWidget);
      expect(channelFinder, findsOneWidget);
      expect(advertFinder, findsOneWidget);
      expect(bgActivityFinder, findsOneWidget);

      final msgY = tester.getTopLeft(msgFinder).dy;
      final channelY = tester.getTopLeft(channelFinder).dy;
      final advertY = tester.getTopLeft(advertFinder).dy;
      final bgActivityY = tester.getTopLeft(bgActivityFinder).dy;

      expect(msgY, lessThan(channelY));
      expect(channelY, lessThan(advertY));
      expect(advertY, lessThan(bgActivityY));
    },
  );

  testWidgets(
    'notificationsEnabled + OS permission denied shows switch OFF, hides child toggles, shows denied subtitle, and requests permission on tap',
    (tester) async {
      PlatformInfo.debugIsAndroidOverride = true;
      final settings = await _createSettingsService(notificationsEnabled: true);
      var requestResult = false;
      var requestCalls = 0;

      await tester.pumpWidget(
        _buildSectionTestApp(
          settings: settings,
          hasPermission: () async => false,
          requestPermission: () async {
            requestCalls++;
            return requestResult;
          },
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(NotificationsSettingsSection));
      final l10n = AppLocalizations.of(context);

      SwitchListTile enableTile() => tester.widget<SwitchListTile>(
        find.widgetWithText(
          SwitchListTile,
          l10n.appSettings_enableNotifications,
        ),
      );

      // Even though settings.notificationsEnabled is true, switch is OFF when OS permission is denied.
      expect(settings.settings.notificationsEnabled, isTrue);
      expect(enableTile().value, isFalse);
      expect(
        find.text(l10n.appSettings_notificationPermissionDenied),
        findsOneWidget,
      );
      expect(find.text(l10n.appSettings_messageNotifications), findsNothing);
      expect(
        find.text(l10n.appSettings_channelMessageNotifications),
        findsNothing,
      );
      expect(
        find.text(l10n.appSettings_advertisementNotifications),
        findsNothing,
      );
      expect(find.text(l10n.appSettings_batteryOptimization), findsNothing);
      // No stray Divider when collapsed.
      expect(find.byType(Divider), findsNothing);

      // Tapping switch while permission request is denied keeps it OFF and shows snackbar.
      await tester.tap(find.text(l10n.appSettings_enableNotifications));
      await tester.pumpAndSettle();

      expect(requestCalls, 1);
      expect(enableTile().value, isFalse);
      expect(find.text(l10n.appSettings_messageNotifications), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(l10n.appSettings_notificationPermissionDenied),
        ),
        findsOneWidget,
      );

      // Now grant permission on the next tap: switch turns ON, snackbar appears, and children expand.
      requestResult = true;
      await tester.tap(find.text(l10n.appSettings_enableNotifications));
      await tester.pump();
      await tester.pump(RevealOnEnable.duration);
      await tester.pumpAndSettle();

      expect(requestCalls, 2);
      expect(enableTile().value, isTrue);
      expect(settings.settings.notificationsEnabled, isTrue);
      expect(
        find.text(l10n.appSettings_enableNotificationsSubtitle),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(l10n.appSettings_notificationsEnabled),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.appSettings_messageNotifications), findsOneWidget);
      expect(
        find.text(l10n.appSettings_channelMessageNotifications),
        findsOneWidget,
      );
      expect(
        find.text(l10n.appSettings_advertisementNotifications),
        findsOneWidget,
      );
      expect(find.text(l10n.appSettings_batteryOptimization), findsOneWidget);
    },
  );

  testWidgets('does not flash ON while async OS permission check is in flight', (
    tester,
  ) async {
    final settings = await _createSettingsService(notificationsEnabled: true);
    final completer = Completer<bool>();

    await tester.pumpWidget(
      _buildSectionTestApp(
        settings: settings,
        hasPermission: () => completer.future,
      ),
    );

    final context = tester.element(find.byType(NotificationsSettingsSection));
    final l10n = AppLocalizations.of(context);

    // While async permission check is in flight, switch is OFF and children are hidden,
    // and the normal subtitle is shown rather than flashing an error prematurely.
    final initialTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, l10n.appSettings_enableNotifications),
    );
    expect(initialTile.value, isFalse);
    expect(
      find.text(l10n.appSettings_enableNotificationsSubtitle),
      findsOneWidget,
    );
    expect(find.text(l10n.appSettings_messageNotifications), findsNothing);

    completer.complete(false);
    await tester.pumpAndSettle();

    final settledTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, l10n.appSettings_enableNotifications),
    );
    expect(settledTile.value, isFalse);
    expect(
      find.text(l10n.appSettings_notificationPermissionDenied),
      findsOneWidget,
    );
    expect(find.text(l10n.appSettings_messageNotifications), findsNothing);
  });

  testWidgets(
    'toggling OFF -> ON collapses children out of tree and expands them back',
    (tester) async {
      final settings = await _createSettingsService(notificationsEnabled: true);

      await tester.pumpWidget(
        _buildSectionTestApp(
          settings: settings,
          hasPermission: () async => true,
          requestPermission: () async => true,
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(NotificationsSettingsSection));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.appSettings_messageNotifications), findsOneWidget);

      // Toggle OFF
      await tester.tap(find.text(l10n.appSettings_enableNotifications));
      await tester.pump();
      await tester.pump(RevealOnEnable.duration);
      await tester.pumpAndSettle();

      expect(settings.settings.notificationsEnabled, isFalse);
      expect(find.text(l10n.appSettings_messageNotifications), findsNothing);
      expect(
        find.text(l10n.appSettings_channelMessageNotifications),
        findsNothing,
      );
      expect(
        find.text(l10n.appSettings_advertisementNotifications),
        findsNothing,
      );
      expect(find.byType(Divider), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(l10n.appSettings_notificationsDisabled),
        ),
        findsOneWidget,
      );

      // Toggle back ON
      await tester.tap(find.text(l10n.appSettings_enableNotifications));
      await tester.pump();
      await tester.pump(RevealOnEnable.duration);
      await tester.pumpAndSettle();

      expect(settings.settings.notificationsEnabled, isTrue);
      expect(find.text(l10n.appSettings_messageNotifications), findsOneWidget);
      expect(
        find.text(l10n.appSettings_channelMessageNotifications),
        findsOneWidget,
      );
      expect(
        find.text(l10n.appSettings_advertisementNotifications),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AppLifecycleState.resumed re-checks OS permission for revoke and grant',
    (tester) async {
      final settings = await _createSettingsService(notificationsEnabled: true);
      var osPermissionGranted = true;

      await tester.pumpWidget(
        _buildSectionTestApp(
          settings: settings,
          hasPermission: () async => osPermissionGranted,
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(NotificationsSettingsSection));
      final l10n = AppLocalizations.of(context);

      SwitchListTile enableTile() => tester.widget<SwitchListTile>(
        find.widgetWithText(
          SwitchListTile,
          l10n.appSettings_enableNotifications,
        ),
      );

      expect(enableTile().value, isTrue);
      expect(find.text(l10n.appSettings_messageNotifications), findsOneWidget);

      // User revokes permission in OS settings and resumes app.
      osPermissionGranted = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(RevealOnEnable.duration);
      await tester.pumpAndSettle();

      expect(enableTile().value, isFalse);
      expect(
        find.text(l10n.appSettings_notificationPermissionDenied),
        findsOneWidget,
      );
      expect(find.text(l10n.appSettings_messageNotifications), findsNothing);

      // User grants permission in OS settings and resumes app.
      osPermissionGranted = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(RevealOnEnable.duration);
      await tester.pumpAndSettle();

      expect(enableTile().value, isTrue);
      expect(
        find.text(l10n.appSettings_enableNotificationsSubtitle),
        findsOneWidget,
      );
      expect(find.text(l10n.appSettings_messageNotifications), findsOneWidget);
    },
  );

  testWidgets(
    'AppSettingsScreen integrates NotificationService permission hook',
    (tester) async {
      final settings = await _createSettingsService(notificationsEnabled: true);
      NotificationService().permissionCheckerForTest = () async => false;

      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final connector = MeshCoreConnector();
      final translation = TranslationService(settings);
      final uploads = NetworkMapUploadService(
        connector: connector,
        settings: settings,
      );
      addTearDown(connector.dispose);
      addTearDown(translation.dispose);
      addTearDown(uploads.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: connector),
            ChangeNotifierProvider.value(value: translation),
            ChangeNotifierProvider.value(value: uploads),
          ],
          child: MaterialApp(
            theme: MeshTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AppSettingsScreen));
      final l10n = AppLocalizations.of(context);

      final enableTile = tester.widget<SwitchListTile>(
        find.widgetWithText(
          SwitchListTile,
          l10n.appSettings_enableNotifications,
        ),
      );
      expect(enableTile.value, isFalse);
      expect(
        find.text(l10n.appSettings_notificationPermissionDenied),
        findsOneWidget,
      );
      expect(find.text(l10n.appSettings_messageNotifications), findsNothing);
    },
  );

  for (final isDark in [false, true]) {
    for (final scale in [1.3, 2.0]) {
      for (final granted in [true, false]) {
        testWidgets(
          'NotificationsSettingsSection fits 320dp at ${scale}x in ${isDark ? "dark" : "light"} theme when permission=${granted ? "granted" : "denied"}',
          (tester) async {
            PlatformInfo.debugIsAndroidOverride = true;
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            final settings = await _createSettingsService(
              notificationsEnabled: true,
            );

            await tester.pumpWidget(
              _buildSectionTestApp(
                settings: settings,
                theme: isDark ? MeshTheme.dark() : MeshTheme.light(),
                textScale: scale,
                hasPermission: () async => granted,
              ),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);

            // Verify 48dp minimum touch target height on all rendered tiles.
            final tiles = find.byType(ListTile);
            expect(tiles, findsWidgets);
            for (final element in tiles.evaluate()) {
              final size = tester.getSize(find.byWidget(element.widget));
              expect(size.height, greaterThanOrEqualTo(48));
            }
          },
        );
      }
    }
  }
}
