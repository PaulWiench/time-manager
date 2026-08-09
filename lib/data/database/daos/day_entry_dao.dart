import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'day_entry_dao.g.dart';

@DriftAccessor(tables: [DayEntries])
class DayEntryDao extends DatabaseAccessor<AppDatabase>
    with _$DayEntryDaoMixin {
  DayEntryDao(super.db);

  Future<DayEntry?> forDate(DateTime date) =>
      (select(dayEntries)..where((t) => t.date.equals(date)))
          .getSingleOrNull();

  Stream<DayEntry?> watchForDate(DateTime date) =>
      (select(dayEntries)..where((t) => t.date.equals(date)))
          .watchSingleOrNull();

  Future<List<DayEntry>> forRange(DateTime start, DateTime endExclusive) =>
      (select(dayEntries)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(endExclusive))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  /// Creates the DayEntry for [date] if it doesn't exist yet, per the "lazy
  /// creation" design principle, or overwrites it with recalculated values.
  Future<int> upsert(DayEntriesCompanion entry) =>
      into(dayEntries).insertOnConflictUpdate(entry);

  Future<int> deleteForDate(DateTime date) =>
      (delete(dayEntries)..where((t) => t.date.equals(date))).go();
}
