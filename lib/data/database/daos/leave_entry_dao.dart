import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'leave_entry_dao.g.dart';

@DriftAccessor(tables: [LeaveEntries])
class LeaveEntryDao extends DatabaseAccessor<AppDatabase>
    with _$LeaveEntryDaoMixin {
  LeaveEntryDao(super.db);

  Future<List<LeaveEntry>> forDate(DateTime date) =>
      (select(leaveEntries)..where((t) => t.date.equals(date))).get();

  Stream<List<LeaveEntry>> watchForDate(DateTime date) =>
      (select(leaveEntries)..where((t) => t.date.equals(date))).watch();

  SimpleSelectStatement<$LeaveEntriesTable, LeaveEntry> _year(int year) {
    final start = DateTime(year);
    final end = DateTime(year + 1);
    return select(leaveEntries)
      ..where((t) =>
          t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end));
  }

  Future<List<LeaveEntry>> forYear(int year) => _year(year).get();

  /// Watched rather than fetched, so the year list and the Stats leave ring
  /// both follow an add or a remove without anyone having to invalidate them.
  Stream<List<LeaveEntry>> watchForYear(int year) => _year(year).watch();

  Future<int> insertLeave(LeaveEntriesCompanion entry) =>
      into(leaveEntries).insert(entry);

  Future<bool> updateLeave(LeaveEntriesCompanion entry) =>
      update(leaveEntries).replace(entry);

  Future<int> deleteLeave(String id) =>
      (delete(leaveEntries)..where((t) => t.id.equals(id))).go();
}
