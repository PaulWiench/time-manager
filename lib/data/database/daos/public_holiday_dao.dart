import 'package:drift/drift.dart';

import '../../database/enums.dart';
import '../database.dart';
import '../tables.dart';

part 'public_holiday_dao.g.dart';

@DriftAccessor(tables: [PublicHolidays])
class PublicHolidayDao extends DatabaseAccessor<AppDatabase>
    with _$PublicHolidayDaoMixin {
  PublicHolidayDao(super.db);

  Future<PublicHoliday?> forDate(DateTime date) =>
      (select(publicHolidays)..where((t) => t.date.equals(date) & _live(t)))
          .getSingleOrNull();

  Stream<PublicHoliday?> watchForDate(DateTime date) =>
      (select(publicHolidays)..where((t) => t.date.equals(date) & _live(t)))
          .watchSingleOrNull();

  /// Removed holidays stay in the table as tombstones so seeding won't
  /// re-add them (see [HolidaySource.removed]); nothing else should see them.
  Expression<bool> _live(PublicHolidays t) =>
      t.source.equals(HolidaySource.removed.name).not();

  /// Every row for the year including tombstones — only seeding needs this.
  Future<List<PublicHoliday>> allForYearIncludingRemoved(int year) {
    final start = DateTime(year);
    final end = DateTime(year + 1);
    return (select(publicHolidays)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)))
        .get();
  }

  /// Tombstones an auto-seeded holiday; manual ones are deleted outright,
  /// since nothing would ever re-create them.
  Future<void> tombstone(DateTime date) async {
    await (update(publicHolidays)..where((t) => t.date.equals(date)))
        .write(const PublicHolidaysCompanion(source: Value(HolidaySource.removed)));
  }

  Future<List<PublicHoliday>> forYear(int year) => _forYearQuery(year).get();

  Stream<List<PublicHoliday>> watchForYear(int year) => _forYearQuery(year).watch();

  SimpleSelectStatement<PublicHolidays, PublicHoliday> _forYearQuery(int year) {
    final start = DateTime(year);
    final end = DateTime(year + 1);
    return select(publicHolidays)
      ..where((t) =>
          t.date.isBiggerOrEqualValue(start) &
          t.date.isSmallerThanValue(end) &
          _live(t));
  }

  Future<int> upsertHoliday(PublicHolidaysCompanion entry) =>
      into(publicHolidays).insertOnConflictUpdate(entry);

  Future<int> deleteHoliday(DateTime date) =>
      (delete(publicHolidays)..where((t) => t.date.equals(date))).go();
}
