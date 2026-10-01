import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'leave_entry_dao.g.dart';

@DriftAccessor(tables: [LeaveEntries])
class LeaveEntryDao extends DatabaseAccessor<AppDatabase>
    with _$LeaveEntryDaoMixin {
  LeaveEntryDao(super.db);

  Future<List<LeaveEntry>> forDate(int jobId, DateTime date) =>
      (select(leaveEntries)..where((t) => t.jobId.equals(jobId) & t.date.equals(date))).get();

  Stream<List<LeaveEntry>> watchForDate(int jobId, DateTime date) =>
      (select(leaveEntries)..where((t) => t.jobId.equals(jobId) & t.date.equals(date))).watch();

  SimpleSelectStatement<$LeaveEntriesTable, LeaveEntry> _year(int jobId, int year) {
    final start = DateTime(year);
    final end = DateTime(year + 1);
    return select(leaveEntries)
      ..where((t) =>
          t.jobId.equals(jobId) &
          t.date.isBiggerOrEqualValue(start) &
          t.date.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);
  }

  Future<List<LeaveEntry>> forYear(int jobId, int year) => _year(jobId, year).get();

  /// Watched rather than fetched, so the year list and the Stats leave ring
  /// both follow an add or a remove without anyone having to invalidate them.
  Stream<List<LeaveEntry>> watchForYear(int jobId, int year) => _year(jobId, year).watch();

  /// Every day of one vacation booking, in date order.
  Future<List<LeaveEntry>> forVacation(String vacationId) =>
      (select(leaveEntries)
            ..where((t) => t.vacationId.equals(vacationId))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  Stream<List<LeaveEntry>> watchForVacation(String vacationId) =>
      (select(leaveEntries)
            ..where((t) => t.vacationId.equals(vacationId))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .watch();

  Future<int> insertLeave(LeaveEntriesCompanion entry) =>
      into(leaveEntries).insert(entry);

  Future<bool> updateLeave(LeaveEntriesCompanion entry) =>
      update(leaveEntries).replace(entry);

  Future<int> deleteLeave(String id) =>
      (delete(leaveEntries)..where((t) => t.id.equals(id))).go();
}
