import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/models/custom_theme.dart';
import 'package:meshcore_open/models/send_attempt_plan.dart';
import 'package:meshcore_open/screens/app_settings_screen.dart';
import 'package:meshcore_open/screens/repeater_settings_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/network_map/network_map_upload_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';
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
      expect(
        find.text(l10n.appSettings_repeatersAndRooms.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(l10n.appSettings_clockSyncAfterLogin), findsOneWidget);
      expect(
        find.text(l10n.appSettings_loginPasswordAutofocus),
        findsOneWidget,
      );
      expect(
        find.text(l10n.appSettings_autoFetchRepeaterSettings),
        findsOneWidget,
      );

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

  testWidgets(
    'routing and repeaters/rooms rows and clock-sync selector have leading 24px icons with aligned titles',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      final settings = AppSettingsService();
      await settings.loadSettings();
      await settings.updateSettings(
        settings.settings.copyWith(channelMinHopsEnabled: true),
      );

      tester.view.physicalSize = const Size(800, 8000);
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

      final topLevelTitles = [
        l10n.appSettings_clearPathOnMaxRetry,
        l10n.appSettings_directRetries(settings.settings.directRetries),
        l10n.appSettings_floodRetries(settings.settings.floodRetries),
        l10n.appSettings_autoRouteRotation,
        l10n.appSettings_channelMinHops,
        l10n.appSettings_resetRoutingToDefault,
        l10n.appSettings_clockSyncAfterLogin,
        l10n.appSettings_loginPasswordAutofocus,
        l10n.appSettings_loginAttempts(settings.settings.loginAttempts),
        l10n.appSettings_autoFetchRepeaterSettings,
        l10n.appSettings_resetRepeaterRoomSettings,
      ];
      final revealedTitles = [
        l10n.appSettings_channelMinHopsCount(settings.settings.channelMinHops),
        l10n.appSettings_channelMinHopsRetries(
          settings.settings.channelMinHopsRetries,
        ),
        l10n.appSettings_channelMinHopsCountRepeaters,
      ];

      double expectRowLeadingIcon(String title) {
        final titleFinder = find.text(title);
        expect(titleFinder, findsOneWidget, reason: 'Missing row "$title"');
        final tileFinder = find.ancestor(
          of: titleFinder,
          matching: find.byType(ListTile),
        );
        expect(tileFinder, findsOneWidget, reason: 'No ListTile for "$title"');
        final iconFinder = find.descendant(
          of: tileFinder,
          matching: find.byType(Icon),
        );
        final icons = tester.widgetList<Icon>(iconFinder).toList();
        final titleRect = tester.getRect(titleFinder);
        final leadingIcons = [
          for (var i = 0; i < icons.length; i++)
            if (tester.getRect(iconFinder.at(i)).right < titleRect.left)
              (icon: icons[i], rect: tester.getRect(iconFinder.at(i))),
        ];
        expect(
          leadingIcons,
          hasLength(1),
          reason: 'Expected 1 leading icon for "$title"',
        );
        expect(
          leadingIcons.single.icon.size,
          24,
          reason: 'Leading icon for "$title" must be 24px',
        );
        expect(
          leadingIcons.single.rect.size,
          const Size(24, 24),
          reason: 'Rendered leading icon for "$title" must be 24x24',
        );
        return titleRect.left;
      }

      final topTitleLefts = [
        for (final title in topLevelTitles) expectRowLeadingIcon(title),
      ];
      for (final left in topTitleLefts) {
        expect(left, closeTo(topTitleLefts.first, 0.5));
      }

      final revealedTitleLefts = [
        for (final title in revealedTitles) expectRowLeadingIcon(title),
      ];
      for (final left in revealedTitleLefts) {
        expect(left, closeTo(topTitleLefts.first + 16, 0.5));
      }

      // Check the Default / On / Off clock-sync selector on RepeaterSettingsScreen.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: connector),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: MaterialApp(
            theme: MeshTheme.light(),
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

      final rContext = tester.element(find.byType(RepeaterSettingsScreen));
      final rL10n = AppLocalizations.of(rContext);
      final selectorTitle = find.text(rL10n.repeater_clockSyncAfterLogin);
      await tester.ensureVisible(selectorTitle);
      await tester.pump();

      expect(
        find.byType(SegmentedButton<RepeaterClockSyncOverride>),
        findsOneWidget,
      );
      for (final label in [
        rL10n.repeater_clockSyncDefault,
        rL10n.repeater_clockSyncOn,
        rL10n.repeater_clockSyncOff,
      ]) {
        expect(
          find.byWidgetPredicate(
            (w) => w is MeshSegmentLabel && w.text == label,
          ),
          findsOneWidget,
        );
      }

      final clockIconFinder = find.byIcon(Icons.schedule);
      expect(clockIconFinder, findsOneWidget);
      final clockIcon = tester.widget<Icon>(clockIconFinder);
      expect(clockIcon.size, 24);
      final clockIconRect = tester.getRect(clockIconFinder);
      final selectorTitleRect = tester.getRect(selectorTitle);
      expect(clockIconRect.size, const Size(24, 24));
      expect(selectorTitleRect.left - clockIconRect.right, closeTo(16, 0.5));
    },
  );

  for (final scale in [1.3, 2.0]) {
    testWidgets(
      'routing, repeaters/rooms, and clock-sync selector fit 320dp at ${scale}x',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        PrefsManager.reset();
        await PrefsManager.initialize();
        final settings = AppSettingsService();
        await settings.loadSettings();
        await settings.updateSettings(
          settings.settings.copyWith(channelMinHopsEnabled: true),
        );

        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

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
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const AppSettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(AppSettingsScreen));
        final l10n = AppLocalizations.of(context);
        for (final label in [
          l10n.appSettings_clearPathOnMaxRetry,
          l10n.appSettings_directRetries(settings.settings.directRetries),
          l10n.appSettings_floodRetries(settings.settings.floodRetries),
          l10n.appSettings_channelMinHopsCount(
            settings.settings.channelMinHops,
          ),
          l10n.appSettings_channelMinHopsRetries(
            settings.settings.channelMinHopsRetries,
          ),
          l10n.appSettings_channelMinHopsCountRepeaters,
          l10n.appSettings_resetRoutingToDefault,
          l10n.appSettings_clockSyncAfterLogin,
          l10n.appSettings_loginPasswordAutofocus,
          l10n.appSettings_loginAttempts(settings.settings.loginAttempts),
          l10n.appSettings_autoFetchRepeaterSettings,
          l10n.appSettings_resetRepeaterRoomSettings,
        ]) {
          await tester.scrollUntilVisible(
            find.text(label),
            200,
            maxScrolls: 100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump();
          expect(find.text(label), findsOneWidget);
        }

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: connector),
              ChangeNotifierProvider.value(value: settings),
            ],
            child: MaterialApp(
              theme: MeshTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
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

        final rContext = tester.element(find.byType(RepeaterSettingsScreen));
        final rL10n = AppLocalizations.of(rContext);
        await tester.scrollUntilVisible(
          find.text(rL10n.repeater_clockSyncAfterLogin),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(find.text(rL10n.repeater_clockSyncAfterLogin), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is MeshSegmentLabel &&
                w.text == rL10n.repeater_clockSyncDefault,
          ),
          findsOneWidget,
        );

        FlutterError.onError = previous;
        expect(overflows, isEmpty, reason: overflows.join('\n'));
      },
    );
  }

  for (final entry in <(String, ThemeData)>[
    ('light', MeshTheme.light()),
    ('dark', MeshTheme.dark()),
    for (final preset in [
      ...CustomTheme.presets,
      ...CustomTheme.holidayPresets,
    ])
      ('custom:${preset.name}', MeshTheme.fromCustom(preset)),
  ]) {
    testWidgets(
      'slider inactive track, tick marks, and drag bubble contrast inside SettingsReveal and MeshCard (${entry.$1})',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        PrefsManager.reset();
        await PrefsManager.initialize();
        final settings = AppSettingsService();
        await settings.loadSettings();
        await settings.updateSettings(
          settings.settings.copyWith(channelMinHopsEnabled: true),
        );

        tester.view.physicalSize = const Size(800, 8000);
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
              theme: entry.$2,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const AppSettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final screenContext = tester.element(find.byType(AppSettingsScreen));
        final l10n = AppLocalizations.of(screenContext);
        final scheme = entry.$2.colorScheme;

        final revealFinder = find.byType(SettingsReveal).first;
        final revealMaterial = tester.widget<Material>(
          find
              .descendant(of: revealFinder, matching: find.byType(Material))
              .first,
        );
        final revealBg = revealMaterial.color!;
        expect(revealBg, scheme.surfaceContainerHighest);

        final directRowFinder = find.ancestor(
          of: find.text(
            l10n.appSettings_directRetries(settings.settings.directRetries),
          ),
          matching: find.byType(SettingsValueSlider),
        );
        final directCardMaterial = tester.widget<Material>(
          find
              .ancestor(of: directRowFinder, matching: find.byType(Material))
              .first,
        );
        final cardBg = directCardMaterial.color!;
        expect(cardBg, scheme.surfaceContainerLow);

        final hopsRowFinder = find.ancestor(
          of: find.text(
            l10n.appSettings_channelMinHopsCount(
              settings.settings.channelMinHops,
            ),
          ),
          matching: find.byType(SettingsValueSlider),
        );
        final revealedSliderFinder = find.descendant(
          of: hopsRowFinder,
          matching: find.byType(Slider),
        );
        final directSliderFinder = find.descendant(
          of: directRowFinder,
          matching: find.byType(Slider),
        );

        for (final sliderFinder in [revealedSliderFinder, directSliderFinder]) {
          final sliderContext = tester.element(sliderFinder);
          final sliderTheme = SliderTheme.of(sliderContext);
          final inactiveTrack = sliderTheme.inactiveTrackColor!;
          final inactiveTick = sliderTheme.inactiveTickMarkColor!;
          final activeTick = sliderTheme.activeTickMarkColor!;
          final valueIndicator = sliderTheme.valueIndicatorColor!;

          expect(inactiveTrack.a, 1.0);
          expect(inactiveTrack, isNot(revealBg));
          expect(inactiveTrack, isNot(cardBg));

          expect(
            meshContrastRatio(inactiveTrack, revealBg),
            greaterThanOrEqualTo(2.1),
            reason: 'Inactive track must stand out on SettingsReveal',
          );
          expect(
            meshContrastRatio(inactiveTrack, cardBg),
            greaterThanOrEqualTo(2.5),
            reason: 'Inactive track must stand out on MeshCard',
          );
          expect(
            meshContrastRatio(inactiveTick, inactiveTrack),
            greaterThanOrEqualTo(2.5),
            reason: 'Inactive tick marks must stand out on inactive track',
          );
          expect(
            meshContrastRatio(activeTick, sliderTheme.activeTrackColor!),
            greaterThanOrEqualTo(1.8),
            reason: 'Active tick marks must stand out on active track',
          );
          expect(
            meshContrastRatio(valueIndicator, revealBg),
            greaterThanOrEqualTo(3.0),
            reason: 'Drag bubble must stand out on SettingsReveal',
          );
          expect(
            meshContrastRatio(valueIndicator, cardBg),
            greaterThanOrEqualTo(3.0),
            reason: 'Drag bubble must stand out on MeshCard',
          );
        }
      },
    );
  }
}
