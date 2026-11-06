import 'custom_theme.dart';

/// How many days before a holiday its theme starts being applied
/// automatically. The holiday day itself is distance 0.
const int holidayThemeLeadDays = 17;

/// The holidays that have an automatic theme, in calendar order.
enum ThemeHoliday {
  halloween('${CustomTheme.presetIdPrefix}halloween'),
  thanksgiving('${CustomTheme.presetIdPrefix}thanksgiving'),
  christmas('${CustomTheme.presetIdPrefix}christmas'),
  newYear('${CustomTheme.presetIdPrefix}new_year');

  const ThemeHoliday(this.themeId);

  /// ID of the matching preset in [CustomTheme.holidayPresets].
  final String themeId;

  /// The holiday's date in [year]: Halloween Oct 31, US Thanksgiving (the
  /// fourth Thursday of November), Christmas Dec 25, New Year's Day Jan 1.
  DateTime dateIn(int year) {
    switch (this) {
      case ThemeHoliday.halloween:
        return DateTime(year, 10, 31);
      case ThemeHoliday.thanksgiving:
        final nov1 = DateTime(year, 11, 1);
        final toThursday = (DateTime.thursday - nov1.weekday + 7) % 7;
        return DateTime(year, 11, 1 + toThursday + 21);
      case ThemeHoliday.christmas:
        return DateTime(year, 12, 25);
      case ThemeHoliday.newYear:
        return DateTime(year, 1, 1);
    }
  }
}

/// One occurrence of a [ThemeHoliday] that is currently within its window.
class ActiveHoliday {
  final ThemeHoliday holiday;

  /// Local date (midnight) of this occurrence of the holiday.
  final DateTime date;

  /// Whole days from today until [date]; 0 on the holiday itself.
  final int daysAway;

  const ActiveHoliday(this.holiday, this.date, this.daysAway);

  String get themeId => holiday.themeId;

  /// Identifies this occurrence, e.g. `preset:christmas@2026-12-25`, so a
  /// dismissal applies to one year's holiday only.
  String get occurrenceKey {
    String two(int v) => v.toString().padLeft(2, '0');
    return '$themeId@${date.year}-${two(date.month)}-${two(date.day)}';
  }

  @override
  bool operator ==(Object other) =>
      other is ActiveHoliday &&
      other.holiday == holiday &&
      other.date == date &&
      other.daysAway == daysAway;

  @override
  int get hashCode => Object.hash(holiday, date, daysAway);

  @override
  String toString() => 'ActiveHoliday($occurrenceKey, $daysAway days away)';
}

/// The holiday whose theme should be showing on [today] (local date; the
/// time of day is ignored), or null when none is close enough.
///
/// For each holiday the next occurrence on or after today is taken (today
/// counts, and the year wraps, so on Dec 20 New Year's is the coming Jan 1).
/// Holidays 0..[holidayThemeLeadDays] days away are candidates and the
/// nearest one wins. That means a holiday keeps its theme up to and including
/// its own day even if a later holiday's window has opened (Thanksgiving
/// before Christmas, Christmas before New Year's), and the next holiday takes
/// over the day after. Once a holiday has passed and no other is within the
/// window, null is returned and the user's own theme applies again.
ActiveHoliday? activeHolidayFor(DateTime today) {
  // Day arithmetic in UTC so daylight-saving shifts never skew the count.
  final day = DateTime.utc(today.year, today.month, today.day);
  ActiveHoliday? best;
  for (final holiday in ThemeHoliday.values) {
    var date = holiday.dateIn(today.year);
    var target = DateTime.utc(date.year, date.month, date.day);
    if (target.isBefore(day)) {
      date = holiday.dateIn(today.year + 1);
      target = DateTime.utc(date.year, date.month, date.day);
    }
    final daysAway = target.difference(day).inDays;
    if (daysAway > holidayThemeLeadDays) continue;
    if (best == null || daysAway < best.daysAway) {
      best = ActiveHoliday(holiday, date, daysAway);
    }
  }
  return best;
}
