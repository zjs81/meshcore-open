import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/l10n/app_localizations_en.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';
import 'package:meshcore_open/widgets/message_translation_button.dart';

final _l10n = AppLocalizationsEn();

Future<void> _openSheet(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  EdgeInsets padding = const EdgeInsets.only(top: 48, bottom: 34),
  EdgeInsets viewPadding = const EdgeInsets.only(top: 48, bottom: 34),
  EdgeInsets viewInsets = EdgeInsets.zero,
  double textScale = 1.0,
  bool initialEnabled = false,
  String? initialLanguageCode,
  ValueChanged<bool>? onEnabledChanged,
  ValueChanged<String?>? onLanguageSelected,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = FakeViewPadding(
    left: padding.left,
    top: padding.top,
    right: padding.right,
    bottom: padding.bottom,
  );
  tester.view.viewPadding = FakeViewPadding(
    left: viewPadding.left,
    top: viewPadding.top,
    right: viewPadding.right,
    bottom: viewPadding.bottom,
  );
  tester.view.viewInsets = FakeViewPadding(
    left: viewInsets.left,
    top: viewInsets.top,
    right: viewInsets.right,
    bottom: viewInsets.bottom,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetViewInsets);

  await tester.pumpWidget(
    MaterialApp(
      theme: MeshTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            size: size,
            padding: padding,
            viewPadding: viewPadding,
            viewInsets: viewInsets,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: MessageTranslationButton(
              enabled: initialEnabled,
              languageCode: initialLanguageCode,
              onPressed: () => showMessageTranslationSheet(
                context: context,
                enabled: initialEnabled,
                selectedLanguageCode: initialLanguageCode,
                onEnabledChanged: onEnabledChanged ?? (_) {},
                onLanguageSelected: onLanguageSelected ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byType(MessageTranslationButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'sheet respects top safe area, caps height at <= 85%, and shrinks when filtered',
    (tester) async {
      const screenSize = Size(400, 800);
      await _openSheet(
        tester,
        size: screenSize,
        padding: const EdgeInsets.only(top: 48, bottom: 34),
        viewPadding: const EdgeInsets.only(top: 48, bottom: 34),
      );

      expect(find.byType(BottomSheetHeader), findsOneWidget);
      expect(find.text(_l10n.translation_messageTranslation), findsOneWidget);

      final sheetFinder = find.byType(BottomSheet);
      final sheetRect = tester.getRect(sheetFinder);
      final titleTop = tester
          .getTopLeft(find.text(_l10n.translation_messageTranslation))
          .dy;

      // Top edge must stay well below the 48px Android status bar inset.
      expect(sheetRect.top, greaterThan(48.0));
      expect(sheetRect.top, greaterThanOrEqualTo(screenSize.height * 0.15));
      expect(sheetRect.height, lessThanOrEqualTo(screenSize.height * 0.85));
      expect(titleTop - sheetRect.top, inInclusiveRange(16.0, 36.0));

      final unfilteredHeight = sheetRect.height;

      // Filtering down to a single language shrinks the sheet naturally.
      await tester.enterText(find.byType(TextField), 'Spanish');
      await tester.pumpAndSettle();

      final filteredRect = tester.getRect(sheetFinder);
      expect(filteredRect.height, lessThan(unfilteredHeight));
      expect(filteredRect.top, greaterThan(sheetRect.top));
    },
  );

  testWidgets(
    'toggling switch, filtering languages, and selecting target or app language works',
    (tester) async {
      bool? latestEnabled;
      String? latestLanguage = 'fr';

      await _openSheet(
        tester,
        initialEnabled: false,
        initialLanguageCode: latestLanguage,
        onEnabledChanged: (value) => latestEnabled = value,
        onLanguageSelected: (code) => latestLanguage = code,
      );

      expect(find.text(_l10n.translation_composerDisabledHint), findsOneWidget);

      await tester.tap(
        find.widgetWithText(
          SwitchListTile,
          _l10n.translation_translateBeforeSending,
        ),
      );
      await tester.pumpAndSettle();

      expect(latestEnabled, isTrue);
      expect(find.text(_l10n.translation_composerEnabledHint), findsOneWidget);

      // Filter by language name and select Spanish ('es').
      await tester.enterText(find.byType(TextField), 'Spanish');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Spanish'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'German'), findsNothing);

      await tester.tap(find.widgetWithText(ListTile, 'Spanish'));
      await tester.pumpAndSettle();

      expect(latestLanguage, 'es');
      expect(find.byType(BottomSheet), findsNothing);

      // Re-open and select "Use app language" (null).
      await tester.tap(find.byType(MessageTranslationButton));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(ListTile, _l10n.translation_useAppLanguage),
      );
      await tester.pumpAndSettle();

      expect(latestLanguage, isNull);
      expect(find.byType(BottomSheet), findsNothing);
    },
  );

  testWidgets(
    'avoids layout overflow at 320dp width with 1.3x and 2.0x text scale and keyboard insets',
    (tester) async {
      for (final textScale in [1.0, 1.3, 2.0]) {
        for (final keyboardInset in [0.0, 300.0]) {
          bool? toggled;
          String? chosenLanguage;

          await _openSheet(
            tester,
            size: const Size(320, 568),
            padding: const EdgeInsets.only(top: 48, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 48, bottom: 34),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
            textScale: textScale,
            onEnabledChanged: (value) => toggled = value,
            onLanguageSelected: (code) => chosenLanguage = code,
          );

          expect(tester.takeException(), isNull);

          final sheetRect = tester.getRect(find.byType(BottomSheet));
          expect(sheetRect.top, greaterThanOrEqualTo(48.0));

          await Scrollable.ensureVisible(
            tester.element(find.byType(Switch)),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(toggled, isTrue);

          await Scrollable.ensureVisible(
            tester.element(find.byType(TextField)),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'de');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final germanTile = find.widgetWithText(
            ListTile,
            'German',
            skipOffstage: false,
          );
          await Scrollable.ensureVisible(
            tester.element(germanTile),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          await tester.tap(germanTile);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(chosenLanguage, 'de');
        }
      }
    },
  );
}
