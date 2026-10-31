import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/app_settings.dart';
import 'package:meshcore_open/models/custom_theme.dart';
import 'package:meshcore_open/models/holiday_schedule.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const halloween = 'preset:halloween';
const thanksgiving = 'preset:thanksgiving';
const christmas = 'preset:christmas';
const newYear = 'preset:new_year';

String? holidayOn(int year, int month, int day) =>
    activeHolidayFor(DateTime(year, month, day, 13, 30))?.themeId;

void main() {
  group('holiday dates', () {
    test('Thanksgiving is the fourth Thursday of November', () {
      expect(ThemeHoliday.thanksgiving.dateIn(2024), DateTime(2024, 11, 28));
      expect(ThemeHoliday.thanksgiving.dateIn(2025), DateTime(2025, 11, 27));
      expect(ThemeHoliday.thanksgiving.dateIn(2026), DateTime(2026, 11, 26));
      expect(ThemeHoliday.thanksgiving.dateIn(2029), DateTime(2029, 11, 22));
      expect(ThemeHoliday.thanksgiving.dateIn(2018), DateTime(2018, 11, 22));
    });

    test('preset ids exist', () {
      for (final holiday in ThemeHoliday.values) {
        expect(CustomTheme.presetById(holiday.themeId), isNotNull);
      }
    });
  });

  group('activeHolidayFor', () {
    test('Halloween window', () {
      expect(holidayOn(2026, 10, 13), isNull);
      expect(holidayOn(2026, 10, 14), halloween);
      expect(holidayOn(2026, 10, 31), halloween);
    });

    test('Thanksgiving 2026 (Nov 26) window', () {
      expect(holidayOn(2026, 11, 1), isNull);
      expect(holidayOn(2026, 11, 8), isNull);
      expect(holidayOn(2026, 11, 9), thanksgiving);
      expect(holidayOn(2026, 11, 26), thanksgiving);
    });

    test('Nov 1 is Thanksgiving when it falls within 17 days', () {
      // Thanksgiving 2029 is Nov 22, 21 days after Nov 1: none.
      expect(holidayOn(2029, 11, 1), isNull);
      // Thanksgiving 2018 was Nov 22 too; Nov 5 is exactly 17 days out.
      expect(holidayOn(2018, 11, 5), thanksgiving);
      expect(holidayOn(2018, 11, 4), isNull);
    });

    test('Thanksgiving holds until its day, then Christmas waits its turn', () {
      // Thanksgiving is at the latest Nov 28 and Christmas' window opens
      // Dec 8, so those two never compete; the days between have no theme.
      expect(holidayOn(2024, 11, 28), thanksgiving);
      expect(holidayOn(2024, 11, 29), isNull);
      expect(holidayOn(2024, 12, 7), isNull);
      expect(holidayOn(2024, 12, 8), christmas);
    });

    test('Christmas and New Year windows', () {
      expect(holidayOn(2026, 12, 7), isNull);
      expect(holidayOn(2026, 12, 8), christmas);
      // Dec 15 is within 17 days of New Year's too; Christmas is nearer.
      expect(holidayOn(2026, 12, 15), christmas);
      expect(holidayOn(2026, 12, 25), christmas);
      expect(holidayOn(2026, 12, 26), newYear);
      expect(holidayOn(2026, 12, 31), newYear);
      expect(holidayOn(2027, 1, 1), newYear);
      expect(holidayOn(2027, 1, 2), isNull);
    });

    test('year wrap gives the coming New Year occurrence', () {
      final active = activeHolidayFor(DateTime(2026, 12, 26))!;
      expect(active.date, DateTime(2027, 1, 1));
      expect(active.daysAway, 6);
      expect(active.occurrenceKey, 'preset:new_year@2027-01-01');
    });

    test('no holiday in spring or summer', () {
      expect(holidayOn(2026, 3, 15), isNull);
      expect(holidayOn(2026, 7, 4), isNull);
    });
  });

  group('settings JSON', () {
    test('auto switch defaults to true', () {
      expect(AppSettings().holidayAutoSwitch, isTrue);
      expect(AppSettings.fromJson({}).holidayAutoSwitch, isTrue);
      expect(AppSettings().holidayThemeDismissed, isNull);
    });

    test('round-trips', () {
      final settings = AppSettings(
        holidayAutoSwitch: false,
        holidayThemeDismissed: 'preset:christmas@2026-12-25',
      );
      final decoded = AppSettings.fromJson(
        jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.holidayAutoSwitch, isFalse);
      expect(decoded.holidayThemeDismissed, 'preset:christmas@2026-12-25');
      expect(settings.toJson()['holiday_auto_switch'], isFalse);
    });

    test('copyWith can clear the dismissal', () {
      final settings = AppSettings(holidayThemeDismissed: 'x');
      expect(settings.copyWith().holidayThemeDismissed, 'x');
      expect(
        settings.copyWith(holidayThemeDismissed: null).holidayThemeDismissed,
        isNull,
      );
    });
  });

  group('AppSettingsService', () {
    late DateTime now;
    late AppSettingsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      now = DateTime(2026, 7, 1, 12);
      service = AppSettingsService(clock: () => now);
      await service.loadSettings();
    });

    tearDown(() => service.dispose());

    test('holiday theme overrides without touching activeThemeId', () async {
      await service.setActiveTheme('preset:forest');
      final ownId = service.settings.activeThemeId;
      expect(service.activeCustomTheme?.id, ownId);

      now = DateTime(2026, 12, 10, 9);
      expect(service.activeCustomTheme?.id, christmas);
      expect(service.autoHolidayTheme?.id, christmas);
      expect(service.settings.activeThemeId, ownId);
      expect(service.chosenCustomTheme?.id, ownId);

      now = DateTime(2027, 1, 2, 9);
      expect(service.activeCustomTheme?.id, ownId);
      expect(service.autoHolidayTheme, isNull);
    });

    test('stock theme users get the holiday theme too', () {
      now = DateTime(2026, 10, 31, 20);
      expect(service.settings.activeThemeId, isNull);
      expect(service.activeCustomTheme?.id, halloween);
    });

    test('manual pick dismisses only the current occurrence', () async {
      now = DateTime(2026, 10, 20);
      expect(service.activeCustomTheme?.id, halloween);

      await service.setActiveTheme(null);
      expect(service.activeCustomTheme, isNull);
      expect(
        service.settings.holidayThemeDismissed,
        'preset:halloween@2026-10-31',
      );

      now = DateTime(2026, 10, 31, 23);
      expect(service.activeCustomTheme, isNull);

      // Next holiday switches again.
      now = DateTime(2026, 11, 20);
      expect(service.activeCustomTheme?.id, thanksgiving);

      // Next year's Halloween too.
      now = DateTime(2027, 10, 20);
      expect(service.activeCustomTheme?.id, halloween);
    });

    test('picking a stock mode dismisses too', () async {
      now = DateTime(2026, 12, 20);
      expect(service.activeCustomTheme?.id, christmas);
      await service.setThemeMode('dark');
      expect(service.activeCustomTheme, isNull);
      expect(service.settings.themeMode, 'dark');

      now = DateTime(2026, 12, 26);
      expect(service.activeCustomTheme?.id, newYear);
    });

    test(
      'picking the auto-applied holiday preset is not a dismissal',
      () async {
        await service.setActiveTheme('preset:forest');
        final ownId = service.settings.activeThemeId;
        now = DateTime(2026, 12, 20);

        await service.setActiveTheme(christmas);
        expect(service.settings.holidayThemeDismissed, isNull);
        expect(service.settings.activeThemeId, ownId);
        expect(service.activeCustomTheme?.id, christmas);

        now = DateTime(2027, 1, 5);
        expect(service.activeCustomTheme?.id, ownId);
      },
    );

    test('a user who picked the holiday preset keeps it', () async {
      await service.setActiveTheme(halloween);
      now = DateTime(2026, 10, 20);
      expect(service.autoHolidayTheme, isNull);
      expect(service.activeCustomTheme?.id, halloween);
      now = DateTime(2026, 11, 1);
      expect(service.activeCustomTheme?.id, halloween);
    });

    test('auto switch off keeps the user theme', () async {
      await service.setHolidayAutoSwitch(false);
      now = DateTime(2026, 12, 25);
      expect(service.activeCustomTheme, isNull);
      expect(service.autoHolidayTheme, isNull);

      await service.setHolidayAutoSwitch(true);
      expect(service.activeCustomTheme?.id, christmas);
    });

    test('turning auto switch back on forgets the dismissal', () async {
      now = DateTime(2026, 12, 20);
      await service.setThemeMode('light');
      expect(service.activeCustomTheme, isNull);
      await service.setHolidayAutoSwitch(false);
      await service.setHolidayAutoSwitch(true);
      expect(service.settings.holidayThemeDismissed, isNull);
      expect(service.activeCustomTheme?.id, christmas);
    });

    test('date timer runs only once started and while enabled', () async {
      expect(service.hasDateTimer, isFalse);
      service.startDateWatch();
      expect(service.hasDateTimer, isTrue);
      await service.setHolidayAutoSwitch(false);
      expect(service.hasDateTimer, isFalse);
      await service.setHolidayAutoSwitch(true);
      expect(service.hasDateTimer, isTrue);
      service.dispose();
      expect(service.hasDateTimer, isFalse);
      // tearDown disposes again; use a fresh service there.
      service = AppSettingsService(clock: () => now);
    });

    test('date change notifies only when the holiday theme changes', () {
      now = DateTime(2026, 12, 6, 23);
      service.startDateWatch();
      var notified = 0;
      service.addListener(() => notified++);

      now = DateTime(2026, 12, 7, 0, 0, 1);
      service.checkDateChange();
      expect(notified, 0);

      now = DateTime(2026, 12, 8, 0, 0, 1);
      service.checkDateChange();
      expect(notified, 1);
      expect(service.activeCustomTheme?.id, christmas);

      now = DateTime(2026, 12, 9, 0, 0, 1);
      service.checkDateChange();
      expect(notified, 1);

      now = DateTime(2026, 12, 26, 0, 0, 1);
      service.checkDateChange();
      expect(notified, 2);
      expect(service.activeCustomTheme?.id, newYear);
    });
  });
}
