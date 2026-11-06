import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/models/custom_theme.dart';
import 'package:meshcore_open/screens/theme_editor_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('hex colors', () {
    test('parse long, short and bare forms', () {
      expect(parseHexColor('#0EA5E9'), const Color(0xFF0EA5E9));
      expect(parseHexColor('0ea5e9'), const Color(0xFF0EA5E9));
      expect(parseHexColor('#fff'), const Color(0xFFFFFFFF));
      expect(parseHexColor(' #000000 '), const Color(0xFF000000));
    });

    test('reject invalid input', () {
      expect(parseHexColor('#12'), isNull);
      expect(parseHexColor('#GGGGGG'), isNull);
      expect(parseHexColor(42), isNull);
      expect(parseHexColor(null), isNull);
    });

    test('format as uppercase #RRGGBB', () {
      expect(colorToHex(const Color(0xFF0ea5e9)), '#0EA5E9');
      expect(colorToHex(const Color(0x800000FF)), '#0000FF');
    });
  });

  group('CustomTheme', () {
    const theme = CustomTheme(
      id: 'custom:1',
      name: 'Forest',
      background: Color(0xFF0E1A13),
      accent: Color(0xFF4ADE80),
    );

    test('brightness comes from the background', () {
      expect(theme.isDark, isTrue);
      expect(theme.copyWith(background: Colors.white).isDark, isFalse);
    });

    test('JSON round-trips', () {
      expect(CustomTheme.fromJson(theme.toJson()), theme);
    });

    test('share code round-trips under a new ID', () {
      final imported = CustomTheme.fromShareCode(
        theme.toShareCode(),
        newId: 'custom:2',
      );
      expect(imported, theme.copyWith(id: 'custom:2'));
    });

    test('hand-written share code is accepted', () {
      final imported = CustomTheme.fromShareCode(
        '{"name": "Mine", "background": "#fff", "accent": "1d4ed8"}',
        newId: 'x',
      );
      expect(imported?.name, 'Mine');
      expect(imported?.isDark, isFalse);
    });

    test('bad share codes are rejected', () {
      for (final code in [
        '',
        'not json',
        '[]',
        '{"name": "", "background": "#000", "accent": "#fff"}',
        '{"name": "X", "background": "nope", "accent": "#fff"}',
        '{"name": "X", "background": "#000"}',
      ]) {
        expect(
          CustomTheme.fromShareCode(code, newId: 'x'),
          isNull,
          reason: code,
        );
      }
    });

    test('preset IDs are unique and resolvable', () {
      final ids = CustomTheme.presets.map((p) => p.id).toSet();
      expect(ids.length, CustomTheme.presets.length);
      for (final preset in [
        ...CustomTheme.presets,
        ...CustomTheme.holidayPresets,
      ]) {
        expect(preset.isPreset, isTrue);
        expect(CustomTheme.presetById(preset.id), preset);
      }
    });
  });

  group('MeshTheme.fromCustom', () {
    test('every preset yields readable text and buttons', () {
      for (final preset in [
        ...CustomTheme.presets,
        ...CustomTheme.holidayPresets,
      ]) {
        final data = MeshTheme.fromCustom(preset);
        final scheme = data.colorScheme;
        expect(
          data.brightness,
          preset.isDark ? Brightness.dark : Brightness.light,
        );
        expect(scheme.surface, preset.background);
        expect(scheme.primary, preset.accent);
        expect(
          _contrast(scheme.onSurface, scheme.surface),
          greaterThan(7),
          reason: preset.name,
        );
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThan(3),
          reason: preset.name,
        );
        final bubble = data.extension<MeshBubbleTheme>()!;
        expect(
          _contrast(bubble.meInk, bubble.me),
          greaterThan(4.5),
          reason: preset.name,
        );
      }
    });

    test('stock themes keep the standard bubble', () {
      expect(
        MeshTheme.dark().extension<MeshBubbleTheme>(),
        MeshBubbleTheme.standard,
      );
    });
  });

  group('settings', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PrefsManager.initialize();
    });

    test('custom themes and the active ID persist', () {
      const theme = CustomTheme(
        id: 'custom:1',
        name: 'Mine',
        background: Color(0xFF000000),
        accent: Color(0xFFFACC15),
      );
      final settings = AppSettings(
        customThemes: const [theme],
        activeThemeId: theme.id,
      );
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.customThemes, [theme]);
      expect(restored.activeThemeId, theme.id);
      expect(AppSettings.fromJson(const {}).customThemes, isEmpty);
    });

    test('service saves, applies, resolves and deletes themes', () async {
      final service = AppSettingsService();
      const theme = CustomTheme(
        id: 'custom:1',
        name: 'Mine',
        background: Color(0xFF000000),
        accent: Color(0xFFFACC15),
      );
      await service.saveCustomTheme(theme, apply: true);
      expect(service.activeCustomTheme, theme);

      await service.saveCustomTheme(theme.copyWith(name: 'Renamed'));
      expect(service.settings.customThemes.single.name, 'Renamed');

      await service.setActiveTheme(CustomTheme.presets.first.id);
      expect(service.activeCustomTheme, CustomTheme.presets.first);

      await service.setThemeMode('light');
      expect(service.activeCustomTheme, isNull);

      await service.setActiveTheme(theme.id);
      await service.deleteCustomTheme(theme.id);
      expect(service.settings.customThemes, isEmpty);
      expect(service.activeCustomTheme, isNull);
    });
  });

  testWidgets('editor saves and applies a new theme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
    final service = AppSettingsService();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: service,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ThemeEditorScreen(),
        ),
      ),
    );

    final list = find.byType(Scrollable).first;
    final save = find.text('Save and use');
    Future<void> tapSave() async {
      await tester.scrollUntilVisible(save, 200, scrollable: list);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
    }

    // Saving without a name is refused.
    await tapSave();
    await tester.pumpAndSettle();
    expect(find.text('Give your theme a name'), findsOneWidget);
    expect(service.settings.customThemes, isEmpty);

    await tester.scrollUntilVisible(
      find.byType(TextField).first,
      -200,
      scrollable: list,
    );
    await tester.enterText(find.byType(TextField).first, 'Night Owl');
    final accentHex = find.widgetWithText(TextField, '#0EA5E9');
    await tester.scrollUntilVisible(accentHex, 200, scrollable: list);
    await tester.enterText(accentHex, '#FACC15');
    await tester.pump();
    await tapSave();
    await tester.pumpAndSettle();

    final saved = service.settings.customThemes.single;
    expect(saved.name, 'Night Owl');
    expect(saved.accent, const Color(0xFFFACC15));
    expect(service.activeCustomTheme, saved);
  });
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
