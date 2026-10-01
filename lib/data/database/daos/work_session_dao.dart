import 'package:drift/drift.dart';

import '../database.dart';
import '../enums.dart';
import '../tables.dart';

part 'work_session_dao.g.dart';

@DriftAccessor(tables: [WorkSessions])
class WorkSessionDao extends DatabaseAccessor<AppDatabase>
    with _$WorkSessionDaoMixin {
  WorkSessionDao(super.db);

  Future<WorkSession?> byId(String id) =>
      (select(workSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<WorkSession>> forDate(int jobId, DateTime date) =>
      (select(workSessions)..where((t) => t.jobId.equals(jobId) & t.date.equals(date))).get();

  /// Ordered, so "the active session" and "the last check-out" are decided by
  /// the clock rather than by whatever order SQLite happened to return.
  Stream<List<WorkSession>> watchForDate(int jobId, DateTime date) =>
      (select(workSessions)
            ..where((t) => t.jobId.equals(jobId) & t.date.equals(date))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .watch();

  /// The running session, wherever it started. Not keyed to a date: a session
  /// that crosses midnight belongs to the day it began on.
  Stream<WorkSession?> watchActive(int jobId) => (select(workSessions)
        ..where((t) => t.jobId.equals(jobId) & t.status.equalsValue(SessionStatus.active))
        ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
        ..limit(1))
      .watchSingleOrNull();

  Future<List<WorkSession>> forRange(int jobId, DateTime start, DateTime endExclusive) =>
      (select(workSessions)
            ..where((t) =>
                t.jobId.equals(jobId) &
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(endExclusive)))
          .get();

  /// At most one session should be active per job (jobs may run in
  /// parallel, so across jobs there can be several), but this returns the
  /// full list rather than assuming that invariant holds at the query layer.
  /// [jobId] null means every job's — the overnight rollover closes them all.
  Future<List<WorkSession>> activeSessions([int? jobId]) =>
      (select(workSessions)
            ..where((t) =>
                t.status.equalsValue(SessionStatus.active) &
                (jobId == null ? const Constant(true) : t.jobId.equals(jobId))))
          .get();

  /// The latest session that ended before [before] on [jobId]'s [date], for
  /// the "started earlier?" lower limit.
  Future<WorkSession?> lastCompletedBefore(int jobId, DateTime date, DateTime before) =>
      (select(workSessions)
            ..where((t) =>
                t.jobId.equals(jobId) &
                t.date.equals(date) &
                t.status.equalsValue(SessionStatus.completed) &
                t.endTime.isSmallerOrEqualValue(before))
            ..orderBy([(t) => OrderingTerm.desc(t.endTime)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertSession(WorkSessionsCompanion entry) =>
      into(workSessions).insert(entry);

  Future<bool> updateSession(WorkSessionsCompanion entry) =>
      update(workSessions).replace(entry);

  Future<int> deleteSession(String id) =>
      (delete(workSessions)..where((t) => t.id.equals(id))).go();
}
