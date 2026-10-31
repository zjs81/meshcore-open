import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/custom_theme.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/quick_switch_bar.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final custom = CustomTheme.holidayPresets.first;

  test('stock themes keep the fixed map palette', () {
    for (final data in [MeshTheme.dark(), MeshTheme.light()]) {
      final map = data.extension<MeshMapTheme>()!;
      expect(map.accent, MapPalette.selected);
      expect(map.tileTint, isNull);
      expect(map.followsTheme, isFalse);
    }
  });

  test('custom themes tint the map with their own colors', () {
    final map = MeshTheme.fromCustom(custom).extension<MeshMapTheme>()!;
    expect(map.accent, custom.accent);
    expect(map.tileTint, custom.background);
    expect(map.followsTheme, isTrue);
  });

  group('tile layer', () {
    late MapTileCacheService tiles;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PrefsManager.initialize();
      tiles = MapTileCacheService(
        appSettingsService: AppSettingsService(),
        cacheManager: _NoCache(),
      );
    });

    Future<List<ColorFiltered>> filtersFor(
      WidgetTester tester,
      ThemeData theme,
    ) async {
      late Widget layer;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              layer = tiles.buildTileLayer(context);
              return const SizedBox();
            },
          ),
        ),
      );
      final found = <ColorFiltered>[];
      Widget? w = layer;
      while (w is ColorFiltered) {
        found.add(w);
        w = w.child;
      }
      return found;
    }

    testWidgets('custom themes wash their background over the tiles', (
      tester,
    ) async {
      final filters = await filtersFor(tester, MeshTheme.fromCustom(custom));
      expect(
        filters.first.colorFilter,
        ColorFilter.mode(
          custom.background.withValues(alpha: MeshMapTheme.tileTintStrength),
          BlendMode.srcATop,
        ),
      );
    });

    testWidgets('the stock light theme leaves tiles untouched', (tester) async {
      expect(await filtersFor(tester, MeshTheme.light()), isEmpty);
    });
  });

  testWidgets('map tab bar follows a custom theme', (tester) async {
    Future<Color?> panelColor(ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuickSwitchBar(
              selectedIndex: 2,
              onDestinationSelected: (_) {},
              highContrast: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(); // theme changes animate
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(QuickSwitchBar),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).color;
    }

    expect(await panelColor(MeshTheme.dark()), MapPalette.panelDark);
    expect(await panelColor(MeshTheme.fromCustom(custom)), Colors.transparent);
  });
}

/// Never touched: these tests only inspect the widget tree.
class _NoCache implements BaseCacheManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
