import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koni_jxl_flutter/koni_jxl_flutter.dart';
import 'package:meshcore_open/models/chat_background.dart';
import 'package:meshcore_open/models/custom_theme.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/chat_background_image_store.dart';
import 'package:meshcore_open/services/chat_background_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/widgets/chat_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _green = Color(0xFF166534);
const _navy = Color(0xFF1E3A8A);

CustomTheme _theme({ChatBackground? background, bool everywhere = false}) =>
    CustomTheme(
      id: 'custom:bg',
      name: 'Bg',
      background: const Color(0xFF000000),
      accent: const Color(0xFFFACC15),
      chatBackground: background,
      chatBackgroundEverywhere: everywhere,
    );

Future<Uint8List> _pngBytes(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const Color(0xFF3366CC),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  late AppSettingsService settings;
  late InMemoryChatBackgroundImageStore images;
  late ChatBackgroundService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
    // A date with no holiday nearby, so no automatic holiday theme (and its
    // chat background) gets in the way.
    settings = AppSettingsService(clock: () => DateTime(2026, 7, 1));
    images = InMemoryChatBackgroundImageStore();
    service = ChatBackgroundService(settings, imageStore: images);
  });

  group('ChatBackground', () {
    test('storage JSON round-trips and fade is clamped', () {
      const color = ChatBackground.color(_green, fade: 0.5);
      expect(ChatBackground.fromJson(color.toJson()), color);
      const image = ChatBackground.image('abc', fade: 0.3);
      expect(ChatBackground.fromJson(image.toJson()), image);
      expect(
        ChatBackground.fromJson({'color': '#000000', 'fade': 5})!.fade,
        ChatBackground.maxFade,
      );
      expect(ChatBackground.fromJson({'fade': 0.5}), isNull);
    });

    test('share JSON carries colors and attached pictures only', () {
      expect(const ChatBackground.image('abc').toShareJson(), isNull);
      final withBytes = const ChatBackground.image(
        'abc',
      ).withInlineImage(Uint8List.fromList([1, 2, 3]));
      final shared = ChatBackground.fromJson(withBytes.toShareJson())!;
      expect(shared.inlineImage, [1, 2, 3]);
      expect(shared.imageId, isNull);
    });
  });

  group('themes', () {
    test('chat background persists with the theme', () {
      final theme = _theme(
        background: const ChatBackground.image('pic'),
        everywhere: true,
      );
      expect(CustomTheme.fromJson(theme.toJson()), theme);
    });

    test('share codes keep colors but never a local image ID', () {
      final colored = _theme(
        background: const ChatBackground.color(_navy),
        everywhere: true,
      );
      final shared = CustomTheme.fromShareCode(
        colored.toShareCode(),
        newId: 'x',
      )!;
      expect(shared.chatBackground, colored.chatBackground);
      expect(shared.chatBackgroundEverywhere, isTrue);

      final pictured = _theme(background: const ChatBackground.image('pic'));
      final noBytes = CustomTheme.fromShareCode(
        pictured.toShareCode(),
        newId: 'x',
      )!;
      expect(noBytes.chatBackground, isNull);

      // A hand-written code pointing at a local ID is ignored too.
      final forged = CustomTheme.fromShareCode(
        '{"name":"F","background":"#000","accent":"#fff",'
        '"chatBackground":{"image":"pic"}}',
        newId: 'x',
      )!;
      expect(forged.chatBackground, isNull);
    });
  });

  group('resolve', () {
    const key = 'channel:abc';

    test('chat background beats the theme by default', () async {
      expect(service.resolve(key), isNull);

      await settings.saveCustomTheme(
        _theme(background: const ChatBackground.color(_navy)),
        apply: true,
      );
      expect(service.resolve(key)?.color, _navy);
      expect(service.overridingTheme, isNull);

      await service.setChatBackground(key, const ChatBackground.color(_green));
      expect(service.resolve(key)?.color, _green);
      expect(service.resolve('channel:other')?.color, _navy);
    });

    test('"use in every chat" lets the theme win', () async {
      await service.setChatBackground(key, const ChatBackground.color(_green));
      await settings.saveCustomTheme(
        _theme(background: const ChatBackground.color(_navy), everywhere: true),
        apply: true,
      );
      expect(service.resolve(key)?.color, _navy);
      expect(service.overridingTheme?.name, 'Bg');
      // The chat keeps its own choice for when the theme changes.
      expect(service.chatBackground(key)?.color, _green);

      await settings.setActiveTheme(null);
      expect(service.resolve(key)?.color, _green);
    });

    test('per-chat backgrounds survive a restart', () async {
      await service.setChatBackground(
        key,
        const ChatBackground.color(_green, fade: 0.7),
      );
      final reloaded = ChatBackgroundService(settings, imageStore: images);
      expect(reloaded.chatBackground(key), service.chatBackground(key));
      await service.setChatBackground(key, null);
      expect(
        ChatBackgroundService(settings, imageStore: images).chatBackground(key),
        isNull,
      );
    });
  });

  group('pictures', () {
    testWidgets('are shrunk and stored as JPEG XL', (tester) async {
      final id = await tester.runAsync(() async {
        return service.addImage(await _pngBytes(1600, 800));
      });
      expect(id, isNotNull);
      final stored = images.images[id]!;
      expect(looksLikeJxl(stored), isTrue);
      final size = await tester.runAsync(() async {
        final image = await decodeJxlToUiImage(stored);
        final s = Size(image.width.toDouble(), image.height.toDouble());
        image.dispose();
        return s;
      });
      expect(size, const Size(1080, 540));

      expect(
        await tester.runAsync(
          () => service.addImage(Uint8List.fromList([1, 2, 3])),
        ),
        isNull,
      );
    });

    testWidgets('travel with themes and come back as stored pictures', (
      tester,
    ) async {
      final id = (await tester.runAsync(
        () async => service.addImage(await _pngBytes(40, 30)),
      ))!;
      final theme = _theme(background: ChatBackground.image(id, fade: 0.5));

      final embedded = (await tester.runAsync(
        () => service.embedThemeImages(theme),
      ))!;
      final code = embedded.toShareCode();
      final received = CustomTheme.fromShareCode(code, newId: 'new')!;
      expect(received.chatBackground!.inlineImage, isNotNull);

      final stored = (await tester.runAsync(
        () => service.storeThemeImages(received),
      ))!;
      final storedId = stored.chatBackground!.imageId!;
      expect(images.images[storedId], isNotNull);
      expect(stored.chatBackground!.inlineImage, isNull);
      expect(stored.chatBackground!.fade, 0.5);
    });

    testWidgets('unused pictures are cleaned up', (tester) async {
      await tester.runAsync(() async {
        final kept = (await service.addImage(await _pngBytes(20, 20)))!;
        final themed = (await service.addImage(await _pngBytes(21, 20)))!;
        final orphan = (await service.addImage(await _pngBytes(22, 20)))!;
        await service.setChatBackground(
          'contact:a',
          ChatBackground.image(kept),
        );
        await settings.saveCustomTheme(
          _theme(background: ChatBackground.image(themed)),
        );
        await service.collectGarbage();
        expect(images.images.keys, unorderedEquals([kept, themed]));
        expect(images.images.containsKey(orphan), isFalse);
      });
    });
  });

  testWidgets('ChatBackdrop paints the resolved background', (tester) async {
    await service.setChatBackground(
      'contact:a',
      const ChatBackground.color(_green),
    );
    Widget host(String key) => ChangeNotifierProvider.value(
      value: service,
      child: MaterialApp(
        home: ChatBackdrop(chatKey: key, child: const Text('hi')),
      ),
    );
    await tester.pumpWidget(host('contact:a'));
    expect(find.byType(ChatBackgroundLayer), findsOneWidget);
    expect(find.text('hi'), findsOneWidget);

    await tester.pumpWidget(host('contact:b'));
    expect(find.byType(ChatBackgroundLayer), findsNothing);

    // Works (and draws nothing) without the service, e.g. in older tests.
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatBackdrop(chatKey: 'x', child: Text('hi')),
      ),
    );
    expect(find.text('hi'), findsOneWidget);
  });
}
