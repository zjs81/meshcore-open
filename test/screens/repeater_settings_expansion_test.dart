import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/screens/repeater_settings_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

void main() {
  // Regression: the Advanced and Identity Keys cards keep their expanded flag
  // in PageStorage. Their TextFields' inner Scrollables used to share that
  // identifier, read the bool as a scroll offset and fail to build (a grey
  // box in release builds).
  testWidgets('expanding Advanced and Identity Keys builds their text fields', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
    // Tall enough that both cards fit without scrolling.
    tester.view.physicalSize = const Size(1080, 24000);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MeshCoreConnector()),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepeaterSettingsScreen(
            repeater: Contact(
              publicKey: Uint8List(32),
              name: 'Repeater',
              type: 2,
              pathLength: 0,
              path: Uint8List(0),
              lastSeen: DateTime(2026),
            ),
            password: 'x',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RepeaterSettingsScreen)),
    );
    for (final title in [
      l10n.repeater_advancedSettings,
      l10n.repeater_keySettings,
    ]) {
      await tester.tap(find.text(title));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }

    expect(
      find.widgetWithText(TextField, l10n.repeater_txDelay),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextField, l10n.repeater_prvKey),
      findsOneWidget,
    );
  });
}
