/// Truncates [dt] to its calendar date (midnight, same components as
/// stored in date-keyed tables like DayEntries).
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Steps a date-only [DateTime] forward or backward by [days] calendar
/// days. Unlike `date.add(Duration(days: days))`, this stays exact across a
/// DST transition — `Duration`-based arithmetic operates on the underlying
/// instant, so adding 24h across a spring-forward boundary lands on 01:00
/// local instead of midnight, which then silently fails every downstream
/// `date.equals(...)` lookup. Always use this for stepping calendar dates
/// (loop counters, range boundaries); reserve `Duration` arithmetic for
/// genuine elapsed-time math.
DateTime shiftDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Steps a date-only [DateTime] by whole calendar months, keeping the day of
/// the month where it exists and clamping where it does not — 31 March back one
/// month is 28 February, not 3 March.
///
/// `DateTime(y, m + n, d)` overflows rather than clamping, which is harmless
/// for the first of a month and wrong for every other day.
DateTime shiftMonths(DateTime date, int months) {
  final target = DateTime(date.year, date.month + months);
  // Day zero of the following month is the last day of this one.
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  return DateTime(target.year, target.month, date.day.clamp(1, lastDay));
}

/// The Monday of [date]'s week. Weeks start on Monday throughout the app —
/// ISO-8601, which is also how the work-days setting numbers its days.
DateTime startOfWeek(DateTime date) => shiftDays(date, -(date.weekday - 1));

/// The ISO-8601 week number of [date], 1–53.
///
/// A week belongs to the year that owns its Thursday, which is why the answer
/// cannot be derived from the date's own year: 1 January 2027 is a Friday, and
/// so falls in week 53 of 2026.
int isoWeekNumber(DateTime date) {
  final thursday = shiftDays(date, 4 - date.weekday);
  return (_ordinalDay(thursday) - 1) ~/ 7 + 1;
}

/// Day of the year, 1–366, counted from the calendar rather than from a
/// [Duration] — subtracting two midnights across a DST boundary yields 23 or
/// 25 hours, and `inDays` would quietly truncate that to the wrong day.
int _ordinalDay(DateTime date) {
  const beforeMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final leap = (date.year % 4 == 0 && date.year % 100 != 0) || date.year % 400 == 0;
  return beforeMonth[date.month - 1] + date.day + (leap && date.month > 2 ? 1 : 0);
}
