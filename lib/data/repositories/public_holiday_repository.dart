import 'package:drift/drift.dart';

import '../../domain/date_only.dart';
import '../../domain/holiday_calculator.dart';
import '../database/database.dart';
import '../database/enums.dart';
import 'recalculation_service.dart';

/// German public holidays — auto-seeded via [germanNationalHolidays] plus
/// [badenWuerttembergHolidays] (the only region this app's user is in),
/// fully user-editable afterward for any other region/company holiday
/// (Requirements & Scope § 4).
class PublicHolidayRepository {
  final AppDatabase db;
  final RecalculationService recalc;

  PublicHolidayRepository(this.db, this.recalc);

  Future<PublicHoliday?> forDate(DateTime date) =>
      db.publicHolidayDao.forDate(dateOnly(date));

  Stream<PublicHoliday?> watchForDate(DateTime date) =>
      db.publicHolidayDao.watchForDate(dateOnly(date));

  Future<List<PublicHoliday>> forYear(int year) =>
      db.publicHolidayDao.forYear(year);

  Stream<List<PublicHoliday>> watchForYear(int year) =>
      db.publicHolidayDao.watchForYear(year);

  /// Seeds [year]'s national + Baden-Württemberg holidays if they aren't
  /// already present. It checks against every row *including tombstones* —
  /// otherwise a holiday the user deleted would be silently re-added on the
  /// next launch, since a deletion leaves no row to skip.
  Future<void> seedYear(int year) async {
    final existing = await db.publicHolidayDao.allForYearIncludingRemoved(year);
    final existingDates = existing.map((h) => h.date).toSet();

    final seeds = [...germanNationalHolidays(year), ...badenWuerttembergHolidays(year)];
    for (final seed in seeds) {
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

  /// Auto-seeded holidays are tombstoned rather than deleted, so seeding
  /// cannot bring them back; a manual one is the user's own row and simply
  /// goes away.
  Future<void> removeHoliday(DateTime date) async {
    final day = dateOnly(date);
    final existing = await db.publicHolidayDao.forDate(day);
    if (existing?.source == HolidaySource.manual) {
      await db.publicHolidayDao.deleteHoliday(day);
    } else {
      await db.publicHolidayDao.tombstone(day);
    }
    await recalc.recalculateFrom(day);
  }
}
