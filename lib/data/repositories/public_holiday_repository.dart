import 'package:drift/drift.dart';

import '../../domain/date_only.dart';
import '../../domain/holiday_calculator.dart';
import '../database/database.dart';
import '../database/enums.dart';
import 'recalculation_service.dart';

/// German public holidays — auto-seeded via [germanNationalHolidays], fully
/// user-editable afterward (Requirements & Scope § 4).
class PublicHolidayRepository {
  final AppDatabase db;
  final RecalculationService recalc;

  PublicHolidayRepository(this.db, this.recalc);

  Future<PublicHoliday?> forDate(DateTime date) =>
      db.publicHolidayDao.forDate(dateOnly(date));

  Future<List<PublicHoliday>> forYear(int year) =>
      db.publicHolidayDao.forYear(year);

  /// Seeds [year]'s national holidays if they aren't already present —
  /// won't overwrite a holiday the user has already edited/removed, since
  /// it only inserts rows that don't yet exist for those dates.
  Future<void> seedYear(int year) async {
    final existing = await db.publicHolidayDao.forYear(year);
    final existingDates = existing.map((h) => h.date).toSet();

    for (final seed in germanNationalHolidays(year)) {
      if (existingDates.contains(seed.date)) continue;
      await db.publicHolidayDao.upsertHoliday(PublicHolidaysCompanion.insert(
        date: seed.date,
        name: seed.name,
        source: HolidaySource.auto,
      ));
      await recalc.recalculateFrom(seed.date);
    }
  }

  Future<void> setHoliday({
    required DateTime date,
    required String name,
    double fraction = 1.0,
  }) async {
    final day = dateOnly(date);
    await db.publicHolidayDao.upsertHoliday(PublicHolidaysCompanion.insert(
      date: day,
      name: name,
      fraction: Value(fraction),
      source: HolidaySource.manual,
    ));
    await recalc.recalculateFrom(day);
  }

  Future<void> removeHoliday(DateTime date) async {
    final day = dateOnly(date);
    await db.publicHolidayDao.deleteHoliday(day);
    await recalc.recalculateFrom(day);
  }
}
