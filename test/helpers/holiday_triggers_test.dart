import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/holiday_triggers.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/widgets/holiday_animations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('holidayAnimationFor', () {
    test('every greeting in every language triggers its holiday', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(Locale(locale.languageCode));
        for (final animation in HolidayAnimation.values) {
          final greetings = holidayGreetingsIn(l10n, animation);
          expect(greetings.trim(), isNotEmpty, reason: '$locale $animation');
          for (final phrase in greetings.split('|')) {
            expect(
              holidayAnimationFor('$phrase!'),
              animation,
              reason: '${locale.languageCode}: "$phrase"',
            );
          }
        }
      }
    });

    test('case, punctuation and surrounding words do not matter', () {
      expect(
        holidayAnimationFor('HAPPY HALLOWEEN!!! 🎃'),
        HolidayAnimation.halloween,
      );
      expect(
        holidayAnimationFor('hey all, happy new year’s from the mesh'),
        HolidayAnimation.newYear,
      );
      expect(holidayAnimationFor('#HappyNewYear'), HolidayAnimation.newYear);
      expect(
        holidayAnimationFor('Merry  Christmas, everyone'),
        HolidayAnimation.christmas,
      );
      expect(
        holidayAnimationFor('happy thanksgiving y’all'),
        HolidayAnimation.thanksgiving,
      );
      expect(holidayAnimationFor('FELIZ NAVIDAD'), HolidayAnimation.christmas);
      expect(holidayAnimationFor('С НОВЫМ ГОДОМ!'), HolidayAnimation.newYear);
      expect(holidayAnimationFor('みんな、メリークリスマス！'), HolidayAnimation.christmas);
      expect(holidayAnimationFor('祝大家新年快乐'), HolidayAnimation.newYear);
    });

    test('ordinary messages and near misses do not trigger', () {
      for (final text in [
        '',
        'happy',
        'halloween party at 8?',
        'feliz natalia', // a name, not "feliz natal"
        'my christmas tree fell over',
        'new year plans?',
        'unhappy new yearly report',
        'thanksgiving dinner menu',
      ]) {
        expect(holidayAnimationFor(text), isNull, reason: text);
      }
    });
  });

  group('HolidayTriggerWatcher', () {
    late AppSettingsService settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PrefsManager.initialize();
      settings = AppSettingsService();
    });

    Future<BuildContext> host(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: MaterialApp(
              home: Builder(
                builder: (c) {
                  ctx = c;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      return ctx;
    }

    void send(
      HolidayTriggerWatcher w,
      BuildContext ctx,
      String id,
      String text, {
      Duration age = Duration.zero,
    }) {
      w.onNewest(
        ctx,
        id: id,
        texts: [text],
        receivedAt: DateTime.now().subtract(age),
        originOf: () => const Offset(100, 400),
      );
    }

    testWidgets('plays for new greetings only, once each', (tester) async {
      final ctx = await host(tester);
      final watcher = HolidayTriggerWatcher();

      // A greeting already there when the chat opens stays quiet.
      send(watcher, ctx, 'a', 'Happy Halloween');
      await tester.pump();
      expect(find.byType(HolidayAnimationView), findsNothing);

      send(watcher, ctx, 'b', 'Happy Halloween everyone');
      // It starts after the frame that showed the message, then builds.
      await tester.pump();
      await tester.pump();
      expect(find.byType(HolidayAnimationView), findsOneWidget);

      // Rebuilds with the same newest message do not replay it.
      send(watcher, ctx, 'b', 'Happy Halloween everyone');
      await tester.pumpAndSettle();
      expect(find.byType(HolidayAnimationView), findsNothing);

      // Old messages (e.g. a synced backlog) stay quiet.
      send(watcher, ctx, 'c', 'Merry Christmas', age: const Duration(hours: 3));
      await tester.pump();
      expect(find.byType(HolidayAnimationView), findsNothing);
    });

    testWidgets('each animation runs and cleans up after itself', (
      tester,
    ) async {
      final ctx = await host(tester);
      for (final animation in HolidayAnimation.values) {
        playHolidayAnimation(ctx, animation, origin: const Offset(80, 500));
        await tester.pump();
        expect(find.byType(HolidayAnimationView), findsOneWidget);
        await tester.pump(holidayAnimationDuration(animation) ~/ 2);
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(find.byType(HolidayAnimationView), findsNothing);
      }
    });

    testWidgets('respects the setting and reduced motion', (tester) async {
      await settings.setHolidayAnimationsEnabled(false);
      var ctx = await host(tester);
      playHolidayAnimation(ctx, HolidayAnimation.newYear, origin: Offset.zero);
      await tester.pump();
      expect(find.byType(HolidayAnimationView), findsNothing);

      await settings.setHolidayAnimationsEnabled(true);
      ctx = await host(tester, reduceMotion: true);
      playHolidayAnimation(ctx, HolidayAnimation.newYear, origin: Offset.zero);
      await tester.pump();
      expect(find.byType(HolidayAnimationView), findsNothing);
    });
  });
}
