import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/widgets/network_map_opt_in_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ConnectedConnector extends MeshCoreConnector {
  @override
  bool get isConnected => true;
}

void main() {
  late AppSettingsService settings;
  late MeshCoreConnector connector;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    settings = AppSettingsService();
    await settings.loadSettings();
    connector = _ConnectedConnector();
  });

  tearDown(() => connector.dispose());

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSettingsService>.value(value: settings),
          ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => maybeShowNetworkMapOptInDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Share turns uploading on and the prompt never returns', (
    tester,
  ) async {
    await pumpHost(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Help build the network map?'), findsOneWidget);
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(settings.settings.networkMapUploadEnabled, isTrue);
    expect(settings.settings.networkMapPromptShown, isTrue);

    await settings.setNetworkMapUploadEnabled(false);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Help build the network map?'), findsNothing);
  });

  testWidgets('No thanks leaves uploading off and is remembered', (
    tester,
  ) async {
    await pumpHost(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No thanks'));
    await tester.pumpAndSettle();

    expect(settings.settings.networkMapUploadEnabled, isFalse);
    expect(settings.settings.networkMapPromptShown, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Help build the network map?'), findsNothing);
  });

  testWidgets('not shown while no radio is connected', (tester) async {
    connector.dispose();
    connector = MeshCoreConnector();
    await pumpHost(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Help build the network map?'), findsNothing);
    expect(settings.settings.networkMapPromptShown, isFalse);
  });
}
