import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koni_jxl_flutter/koni_jxl_flutter.dart';
import 'package:meshcore_open/models/custom_theme.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/theme/theme_icons.dart';
import 'package:meshcore_open/utils/theme_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final png = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);
  final theme = CustomTheme(
    id: 'custom:1',
    name: 'Iconic',
    background: const Color(0xFF000000),
    accent: const Color(0xFFFACC15),
    icons: {
      'map': const ThemeIconOverride.icon('park'),
      'send': ThemeIconOverride.image(png),
    },
  );

  group('theme icons', () {
    test('icons survive JSON and share codes', () {
      expect(CustomTheme.fromJson(theme.toJson()), theme);
      final imported = CustomTheme.fromShareCode(
        theme.toShareCode(),
        newId: 'x',
      )!;
      expect(imported.icons['send']!.imageBytes, png);
      expect(imported.icons['map']!.icon, 'park');
    });

    test('unknown slots, unknown icons and bad pictures are dropped', () {
      final icons = parseThemeIcons({
        'map': {'icon': 'not_an_icon'},
        'nope': {'icon': 'park'},
        'send': {'image': '%%%'},
        'contacts': {'icon': 'rocket_launch'},
      });
      expect(icons.keys, ['contacts']);
    });

    test('slot keys are unique and catalog names resolve', () {
      final keys = ThemeIconSlot.values.map((s) => s.key).toSet();
      expect(keys.length, ThemeIconSlot.values.length);
    });

    test('custom theme carries its icons into ThemeData', () {
      final data = MeshTheme.fromCustom(theme);
      expect(data.extension<MeshIconTheme>()![ThemeIconSlot.map]!.icon, 'park');
      expect(MeshTheme.dark().extension<MeshIconTheme>()!.overrides, isEmpty);
    });

    testWidgets('ThemedIcon shows the override or the default', (tester) async {
      Widget host(ThemeData data) => MaterialApp(
        theme: data,
        home: const Row(
          children: [
            ThemedIcon(ThemeIconSlot.map),
            ThemedIcon(ThemeIconSlot.channels),
          ],
        ),
      );
      await tester.pumpWidget(host(MeshTheme.fromCustom(theme)));
      expect(find.byIcon(Icons.park), findsOneWidget);
      expect(find.byIcon(Icons.tag), findsOneWidget);

      await tester.pumpWidget(host(MeshTheme.dark()));
      await tester.pumpAndSettle(); // theme change animates
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });

    testWidgets('pictures are shrunk to a lossless JPEG XL', (tester) async {
      final big = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 400, 200),
          Paint()..color = const Color(0xFFFF0000),
        );
        final image = await recorder.endRecording().toImage(400, 200);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      final shrunk = await tester.runAsync(() => shrinkThemeIconImage(big!));
      expect(looksLikeJxl(shrunk!), isTrue);
      final size = await tester.runAsync(() async {
        final image = await decodeJxlToUiImage(shrunk);
        return Size(image.width.toDouble(), image.height.toDouble());
      });
      expect(size, const Size(128, 64));
      expect(
        await tester.runAsync(
          () => shrinkThemeIconImage(Uint8List.fromList([1, 2, 3])),
        ),
        isNull,
      );
    });
  });

  group('jsonl files', () {
    var n = 0;
    String newId() => 'id${n++}';

    test('one theme per line round-trips', () {
      final second = CustomTheme.presets.first;
      final text = encodeThemesJsonl([theme, second]);
      expect(text.trim().split('\n'), hasLength(2));
      final decoded = decodeThemesJsonl(text, newId: newId);
      expect(decoded, hasLength(2));
      expect(decoded[0], theme.copyWith(id: decoded[0].id));
      expect(decoded[1].name, second.name);
      expect(decoded[0].id, isNot(decoded[1].id));
    });

    test('bad and blank lines are skipped', () {
      final text =
          '\n{"name":"A","background":"#000","accent":"#fff"}\n'
          'garbage\n\r\n{"name":"B","background":"#fff","accent":"#000"}\r\n';
      expect(decodeThemesJsonl(text, newId: newId).map((t) => t.name), [
        'A',
        'B',
      ]);
    });

    test('a pretty-printed single theme is accepted', () {
      const text =
          '{\n  "name": "Pretty",\n  "background": "#000",\n'
          '  "accent": "#fff"\n}\n';
      expect(decodeThemesJsonl(text, newId: newId).single.name, 'Pretty');
    });

    test('file stems are safe', () {
      expect(themeFileStem('My Cool Theme!'), 'my-cool-theme');
      expect(themeFileStem('   '), 'theme');
    });

    test('import skips duplicates and assigns unique IDs', () async {
      SharedPreferences.setMockInitialValues({});
      await PrefsManager.initialize();
      final service = AppSettingsService();
      final themes = decodeThemesJsonl(
        encodeThemesJsonl([theme, CustomTheme.presets.first]),
        newId: service.newCustomThemeId,
      );
      expect(await service.importCustomThemes(themes), 2);
      final again = decodeThemesJsonl(
        encodeThemesJsonl([theme]),
        newId: service.newCustomThemeId,
      );
      expect(await service.importCustomThemes(again), 0);
      final ids = service.settings.customThemes.map((t) => t.id).toSet();
      expect(ids, hasLength(2));
    });
  });
}
