import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/services/node_banner_service.dart';
import 'package:meshcore_open/widgets/get_node_banner.dart';

final _config = NodeBannerConfig(url: Uri.parse('https://example.com/node'));

void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    NodeBannerConfig? config,
    bool hidden = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            bottomNavigationBar: GetNodeBanner(
              loadConfig: () async => hidden ? null : config ?? _config,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the pitch and affiliate link', (tester) async {
    await pumpBanner(tester, size: const Size(390, 844), textScale: 1);
    await tester.pump();

    expect(find.text('Need a new node?'), findsOneWidget);
    expect(find.text('Get one here'), findsOneWidget);
    expect(find.textContaining('Affiliate link'), findsOneWidget);
    // Leaves most of the screen for the device list.
    expect(
      tester.getSize(find.byType(GetNodeBanner)).height,
      lessThan(844 * 0.4),
    );
  });

  testWidgets('lays out on a narrow phone with large text', (tester) async {
    await pumpBanner(tester, size: const Size(320, 800), textScale: 1.5);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses text overrides from the record', (tester) async {
    await pumpBanner(
      tester,
      size: const Size(390, 844),
      textScale: 1,
      config: NodeBannerConfig(
        url: Uri.parse('https://example.com'),
        title: 'Spring sale',
        action: 'Shop now',
      ),
    );
    await tester.pump();

    expect(find.text('Spring sale'), findsOneWidget);
    expect(find.text('Shop now'), findsOneWidget);
    expect(find.textContaining('Affiliate link'), findsOneWidget);
  });

  testWidgets('shows nothing when there is no config', (tester) async {
    await pumpBanner(
      tester,
      size: const Size(390, 844),
      textScale: 1,
      hidden: true,
    );
    await tester.pump();

    expect(find.byType(InkWell), findsNothing);
    expect(tester.getSize(find.byType(GetNodeBanner)).height, 0);
  });
}
