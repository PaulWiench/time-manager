/// Truncates [dt] to its calendar date (midnight, same components as
/// stored in date-keyed tables like DayEntries).
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
