import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/screens/repeater_regions_screen.dart';
import 'package:meshcore_open/screens/repeater_settings_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

void main() {
  group('parseRepeaterRegionNames', () {
    test('splits comma-separated names', () {
      expect(parseRepeaterRegionNames('*,eu,nl-ov'), ['*', 'eu', 'nl-ov']);
    });

    test('-none- and empty replies yield no names', () {
      expect(parseRepeaterRegionNames('-none-'), isEmpty);
      expect(parseRepeaterRegionNames(''), isEmpty);
    });

    test('strips the hashtag prefix', () {
      expect(parseRepeaterRegionNames('#eu, nl'), ['eu', 'nl']);
    });
  });

  group('parseRepeaterRegionHome', () {
    test('parses the current home region', () {
      expect(parseRepeaterRegionHome(' home is eu'), 'eu');
      expect(parseRepeaterRegionHome('home is now eu'), 'eu');
    });

    test('wildcard home parses as none', () {
      expect(parseRepeaterRegionHome(' home is *'), isNull);
    });

    test('unrelated reply parses as none', () {
      expect(parseRepeaterRegionHome('Err - ??'), isNull);
    });
  });

  group('parseRepeaterRegionDefault', () {
    test('parses the current default scope', () {
      expect(parseRepeaterRegionDefault(' default scope is eu'), 'eu');
      expect(parseRepeaterRegionDefault('default scope is now eu'), 'eu');
    });

    test('null scope parses as none', () {
      expect(parseRepeaterRegionDefault(' default scope is <null>'), isNull);
    });
  });

  group('isRepeaterRegionError', () {
    test('Err replies are errors', () {
      expect(isRepeaterRegionError('Err - unknown region'), isTrue);
      expect(isRepeaterRegionError(''), isTrue);
    });

    test('success replies are not errors', () {
      expect(isRepeaterRegionError('OK'), isFalse);
      expect(isRepeaterRegionError('OK - (flood allowed)'), isFalse);
      expect(isRepeaterRegionError('-none-'), isFalse);
    });
  });

  testWidgets('repeater settings show access and regions entries', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
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
    // SectionHeader renders its label upper-case.
    expect(
      find.text(l10n.repeater_accessRegionsTitle.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(l10n.repeater_aclTitle), findsOneWidget);
    expect(find.text(l10n.repeater_regionsTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('regions screen reports a hint before the first load', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MeshCoreConnector(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepeaterRegionsScreen(
            repeater: Contact(
              publicKey: Uint8List(32),
              name: 'Repeater',
              type: 2,
              pathLength: 0,
              path: Uint8List(0),
              lastSeen: DateTime(2026),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RepeaterRegionsScreen)),
    );
    // Disconnected radio: the load aborts and the hint stays visible.
    expect(find.text(l10n.repeater_regionsLoadHint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
