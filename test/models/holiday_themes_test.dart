import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koni_jxl_flutter/koni_jxl_flutter.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/models/chat_background.dart';
import 'package:meshcore_open/models/custom_theme.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/theme/theme_icons.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';

/// Every bundled picture a holiday theme points at.
List<String> _assetsOf(CustomTheme theme) => [
  for (final icon in theme.icons.values) ?icon.asset,
  ?theme.chatBackground?.asset,
];

void main() {
  test('map marker slots cover every node type', () {
    expect(mapMarkerSlotForNodeType(advTypeChat), ThemeIconSlot.mapChat);
    expect(
      mapMarkerSlotForNodeType(advTypeRepeater),
      ThemeIconSlot.mapRepeater,
    );
    expect(mapMarkerSlotForNodeType(advTypeRoom), ThemeIconSlot.mapRoom);
    expect(mapMarkerSlotForNodeType(advTypeSensor), ThemeIconSlot.mapSensor);
    expect(mapMarkerSlotForNodeType(99), isNull);
    expect(ThemeIconSlot.values.where((s) => s.isMapMarker).map((s) => s.key), [
      'map_chat',
      'map_repeater',
      'map_room',
      'map_sensor',
      'map_self',
    ]);
  });

  test('list avatars and map markers share a node type icon', () {
    const marker = ThemeIconOverride.icon('castle');
    const theme = MeshIconTheme({'map_repeater': marker});
    expect(theme[ThemeIconSlot.repeater], marker);
    expect(theme[ThemeIconSlot.mapRepeater], marker);
    expect(theme[ThemeIconSlot.room], isNull);

    // A slot's own setting wins over its partner's.
    const own = ThemeIconOverride.icon('home');
    const both = MeshIconTheme({'map_room': marker, 'room': own});
    expect(both[ThemeIconSlot.room], own);
    expect(both[ThemeIconSlot.mapRoom], marker);

    for (final slot in ThemeIconSlot.values) {
      expect(slot.partner?.partner ?? slot, slot, reason: slot.key);
    }
  });

  testWidgets('holiday list avatars show the map marker picture', (
    tester,
  ) async {
    final theme = CustomTheme.holidayPresets.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: MeshTheme.fromCustom(theme),
        home: const Column(
          children: [
            AvatarCircle(name: 'Tower', iconSlot: ThemeIconSlot.repeater),
            AvatarCircle(name: 'Zed'),
          ],
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      image.image,
      JxlImageProvider.asset(theme.icons['map_repeater']!.asset!),
    );
    // Chat contacts keep their initials.
    expect(find.text('ZE'), findsOneWidget);
  });

  test('pictures and named icons resolve to the right provider', () {
    expect(themePictureOf(null), isNull);
    expect(themePictureOf(const ThemeIconOverride.icon('park')), isNull);
    expect(
      themePictureOf(
        const ThemeIconOverride.asset('assets/themes/halloween/map_chat.jxl'),
      ),
      isA<JxlImageProvider>(),
    );
  });

  test('holiday themes have unique IDs that resolve', () {
    final all = [...CustomTheme.presets, ...CustomTheme.holidayPresets];
    expect(all.map((t) => t.id).toSet(), hasLength(all.length));
    for (final theme in CustomTheme.holidayPresets) {
      expect(CustomTheme.presetById(theme.id), theme);
      expect(theme.isPreset, isTrue);
      expect(theme.chatBackground?.asset, isNotNull);
      expect(theme.icons.keys, containsAll(['contacts', 'channels', 'map']));
      expect(
        theme.icons.keys,
        containsAll([
          for (final slot in ThemeIconSlot.values)
            if (slot.isMapMarker) slot.key,
        ]),
        reason: '${theme.name} has every map marker',
      );
    }
  });

  test('every holiday picture is a bundled, declared JPEG XL file', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final theme in CustomTheme.holidayPresets) {
      for (final path in _assetsOf(theme)) {
        expect(isThemeAssetPath(path), isTrue, reason: path);
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        expect(looksLikeJxl(file.readAsBytesSync()), isTrue, reason: path);
        final dir = path.substring(0, path.lastIndexOf('/') + 1);
        expect(pubspec, contains('- $dir'), reason: 'pubspec lists $dir');
      }
    }
  });

  testWidgets('holiday pictures decode, icons keep transparency', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final theme in CustomTheme.holidayPresets) {
        final background = await decodeJxlToUiImage(
          File(theme.chatBackground!.asset!).readAsBytesSync(),
        );
        expect(background.height, greaterThan(background.width));
        background.dispose();

        final icon = await decodeJxlToUiImage(
          File(theme.icons['contacts']!.asset!).readAsBytesSync(),
        );
        final pixels = (await icon.toByteData())!;
        // Top-left corner lies outside the round badge.
        expect(pixels.getUint8(3), 0, reason: theme.name);
        icon.dispose();
      }
    });
  });

  test('asset references survive JSON and share codes', () {
    final theme = CustomTheme.holidayPresets.first;
    expect(CustomTheme.fromJson(theme.toJson()), theme);
    final copy = CustomTheme.fromShareCode(theme.toShareCode(), newId: 'x')!;
    expect(copy.chatBackground, theme.chatBackground);
    expect(copy.icons, theme.icons);
  });

  test('shared codes cannot point outside the theme assets', () {
    for (final bad in [
      'assets/images/logo.png',
      'assets/themes/../fonts/Inter.ttf',
      'assets/themes/halloween/background.png',
      '/etc/passwd',
    ]) {
      expect(isThemeAssetPath(bad), isFalse, reason: bad);
      expect(ThemeIconOverride.fromJson({'asset': bad}), isNull);
      expect(ChatBackground.fromJson({'asset': bad}), isNull);
    }
  });

  testWidgets('a holiday theme shows its icon in place of the default', (
    tester,
  ) async {
    final theme = CustomTheme.holidayPresets.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: MeshTheme.fromCustom(theme),
        home: const ThemedIcon(ThemeIconSlot.map),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsNothing);
  });
}
