import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/send_attempt_plan.dart';
import 'package:meshcore_open/screens/app_settings_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/network_map/network_map_upload_service.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/widgets/settings_reveal.dart';

void main() {
  testWidgets(
    'routing settings show both retry limits and reveal channel options',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await PrefsManager.initialize();
      final settings = AppSettingsService();
      await settings.loadSettings();
      await settings.updateSettings(
        settings.settings.copyWith(autoRouteRotationEnabled: false),
      );

      tester.view.physicalSize = const Size(800, 8000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AppSettingsScreen));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.appSettings_clearPathOnMaxRetry), findsOneWidget);
      expect(
        find.text(
          l10n.appSettings_directRetries(SendAttemptPlan.defaultDirectRetries),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          l10n.appSettings_floodRetries(SendAttemptPlan.defaultFloodRetries),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          l10n.appSettings_loginAttempts(SendAttemptPlan.defaultLoginAttempts),
        ),
        findsOneWidget,
      );
      // Retry limits stay visible while route rotation is off.
      expect(find.text(l10n.appSettings_autoRouteRotation), findsOneWidget);
      expect(find.text(l10n.appSettings_channelMinHopsCount(2)), findsNothing);
      expect(find.text(l10n.appSettings_resetRoutingToDefault), findsOneWidget);

      final channelSwitch = find.text(l10n.appSettings_channelMinHops);
      await tester.tap(channelSwitch);
      await tester.pump();
      await tester.pump(RevealOnEnable.duration);
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.appSettings_channelMinHopsCount(2)),
        findsOneWidget,
      );
      expect(
        find.text(l10n.appSettings_channelMinHopsRetries(1)),
        findsOneWidget,
      );

      await tester.tap(channelSwitch);
      await tester.pumpAndSettle();
      expect(find.text(l10n.appSettings_channelMinHopsCount(2)), findsNothing);
    },
  );
}
