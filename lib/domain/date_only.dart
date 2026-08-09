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
