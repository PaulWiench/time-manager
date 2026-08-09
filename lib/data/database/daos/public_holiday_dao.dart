import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'public_holiday_dao.g.dart';

@DriftAccessor(tables: [PublicHolidays])
class PublicHolidayDao extends DatabaseAccessor<AppDatabase>
    with _$PublicHolidayDaoMixin {
  PublicHolidayDao(super.db);

  Future<PublicHoliday?> forDate(DateTime date) =>
      (select(publicHolidays)..where((t) => t.date.equals(date)))
          .getSingleOrNull();

  Future<List<PublicHoliday>> forYear(int year) {
    final start = DateTime(year);
    final end = DateTime(year + 1);
    return (select(publicHolidays)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .get();
  }

  Future<int> upsertHoliday(PublicHolidaysCompanion entry) =>
      into(publicHolidays).insertOnConflictUpdate(entry);

  Future<int> deleteHoliday(DateTime date) =>
      (delete(publicHolidays)..where((t) => t.date.equals(date))).go();
}
