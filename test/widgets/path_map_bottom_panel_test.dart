import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/path_playback.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/path_map_scaffold.dart';
import 'package:meshcore_open/widgets/path_map_ui.dart';

Widget _panel(PathPlaybackController playback) => PathMapBottomPanel(
  header: const Text('3 hops (2.00 km)'),
  combined: false,
  showInferredLegend: true,
  collapsed: false,
  onToggleCollapsed: () {},
  playback: playback,
  selected: null,
  animationEnabled: true,
  onToggleAnimation: () {},
  followEnabled: false,
  onToggleFollow: () {},
  showNoSelfGpsNote: false,
  pathCount: 1,
  hopRowCount: 1,
  summary: null,
  hopList: const SizedBox.shrink(),
);

BoxDecoration _boxDecorationAbove(WidgetTester tester, Finder finder) {
  return tester
          .widget<DecoratedBox>(
            find
                .ancestor(of: finder, matching: find.byType(DecoratedBox))
                .first,
          )
          .decoration
      as BoxDecoration;
}

void main() {
  for (final scenario in [
    (
      name: 'compact portrait',
      size: const Size(320, 568),
      scale: 1.0,
      combined: false,
      collapsed: false,
    ),
    (
      name: 'compact landscape',
      size: const Size(568, 320),
      scale: 1.0,
      combined: false,
      collapsed: false,
    ),
    (
      name: 'large text',
      size: const Size(320, 568),
      scale: 2.0,
      combined: false,
      collapsed: false,
    ),
    (
      name: 'combined paths',
      size: const Size(320, 568),
      scale: 1.0,
      combined: true,
      collapsed: false,
    ),
    (
      name: 'collapsed',
      size: const Size(320, 568),
      scale: 1.0,
      combined: false,
      collapsed: true,
    ),
  ]) {
    testWidgets(
      'path panel fits ${scenario.name} and keeps content accessible',
      (tester) async {
        tester.view.physicalSize = scenario.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final playback = PathPlaybackController(const TestVSync());
        addTearDown(playback.dispose);
        var animationToggles = 0;
        const hopListKey = ValueKey('hop-list');

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Stack(
                children: [
                  PathMapBottomPanel(
                    header: const Text('3 hops (2.00 km)'),
                    combined: scenario.combined,
                    showInferredLegend: true,
                    collapsed: scenario.collapsed,
                    onToggleCollapsed: () {},
                    playback: playback,
                    selected: null,
                    animationEnabled: true,
                    onToggleAnimation: () => animationToggles++,
                    followEnabled: false,
                    onToggleFollow: () {},
                    showNoSelfGpsNote: true,
                    pathCount: scenario.combined ? 3 : 1,
                    hopRowCount: 3,
                    summary: scenario.combined
                        ? Column(
                            children: [
                              for (var i = 1; i <= 3; i++)
                                SizedBox(height: 40, child: Text('Path $i')),
                            ],
                          )
                        : null,
                    hopList: ListView(
                      key: hopListKey,
                      children: [
                        for (var i = 1; i <= 3; i++)
                          SizedBox(height: 60, child: Text('Hop $i')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        final animationButton = find.widgetWithIcon(
          IconButton,
          Icons.animation,
        );
        await tester.ensureVisible(animationButton);
        await tester.pumpAndSettle();
        await tester.tap(animationButton);
        expect(animationToggles, 1);

        if (!scenario.collapsed) {
          expect(
            tester.getSize(find.byKey(hopListKey)).height,
            greaterThanOrEqualTo(60),
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(PathMapBottomPanel)),
          );
          final gpsNote = find.text(l10n.pathMap_noSelfGpsFix);
          await tester.ensureVisible(gpsNote);
          await tester.pumpAndSettle();
          expect(gpsNote.hitTestable(), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Hop 3'),
            60,
            scrollable: find.descendant(
              of: find.byKey(hopListKey),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Hop 3').hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final theme in [
    (name: 'light', data: MeshTheme.light()),
    (name: 'dark', data: MeshTheme.dark()),
  ]) {
    testWidgets('map chrome follows the ${theme.name} theme', (tester) async {
      final playback = PathPlaybackController(const TestVSync());
      addTearDown(playback.dispose);
      final scheme = theme.data.colorScheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: theme.data,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                PathMapDesktopControls(
                  onZoomIn: () {},
                  onZoomOut: () {},
                  onReset: () {},
                ),
                _panel(playback),
              ],
            ),
          ),
        ),
      );

      final panelBox = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(PathMapBottomPanel),
              matching: find.byType(Container),
            )
            .first,
      );
      final panelDecoration = panelBox.decoration! as BoxDecoration;
      expect(
        panelDecoration.color,
        scheme.surfaceContainerLow.withValues(alpha: 0.96),
      );
      expect(panelDecoration.border, Border.all(color: scheme.outlineVariant));

      final controlsDecoration = _boxDecorationAbove(
        tester,
        find.widgetWithIcon(IconButton, Icons.add),
      );
      expect(
        controlsDecoration.color,
        scheme.surfaceContainerLow.withValues(alpha: 0.94),
      );
      final zoomIn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add),
      );
      expect(zoomIn.color, scheme.onSurface);
    });
  }

  testWidgets('top overlays clear the desktop zoom controls', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const selectorKey = ValueKey('selector');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(
            children: [
              PathMapDesktopControls(
                onZoomIn: () {},
                onZoomOut: () {},
                onReset: () {},
              ),
              PathViewModeToggle(mode: PathViewMode.single, onChanged: (_) {}),
              Positioned(
                left: pathMapTopOverlayInset(),
                right: 16,
                top: 60,
                child: const SizedBox(key: selectorKey, height: 120),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    final controls = tester
        .getRect(find.widgetWithIcon(IconButton, Icons.add))
        .expandToInclude(
          tester.getRect(find.widgetWithIcon(IconButton, Icons.my_location)),
        );
    final toggle = tester.getRect(find.byType(SegmentedButton<PathViewMode>));
    final selector = tester.getRect(find.byKey(selectorKey));
    expect(controls.overlaps(toggle), isFalse);
    expect(controls.overlaps(selector), isFalse);
    expect(pathMapTopOverlayInset(TargetPlatform.android), 16);
    debugDefaultTargetPlatformOverride = null;
  });
}
