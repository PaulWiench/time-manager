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

  Future<List<WorkSession>> forDate(DateTime date) =>
      (select(workSessions)..where((t) => t.date.equals(date))).get();

  /// Ordered, so "the active session" and "the last check-out" are decided by
  /// the clock rather than by whatever order SQLite happened to return.
  Stream<List<WorkSession>> watchForDate(DateTime date) =>
      (select(workSessions)
            ..where((t) => t.date.equals(date))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .watch();

  /// The running session, wherever it started. Not keyed to a date: a session
  /// that crosses midnight belongs to the day it began on.
  Stream<WorkSession?> watchActive() => (select(workSessions)
        ..where((t) => t.status.equalsValue(SessionStatus.active))
        ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
        ..limit(1))
      .watchSingleOrNull();

  Future<List<WorkSession>> forRange(DateTime start, DateTime endExclusive) =>
      (select(workSessions)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(endExclusive)))
          .get();

  /// At most one session should ever be active at a time (Requirements §
  /// Core Timer), but this returns the full list rather than assuming that
  /// invariant holds at the query layer.
  Future<List<WorkSession>> activeSessions() =>
      (select(workSessions)
            ..where((t) => t.status.equalsValue(SessionStatus.active)))
          .get();

  Future<int> insertSession(WorkSessionsCompanion entry) =>
      into(workSessions).insert(entry);

  Future<bool> updateSession(WorkSessionsCompanion entry) =>
      update(workSessions).replace(entry);

  Future<int> deleteSession(String id) =>
      (delete(workSessions)..where((t) => t.id.equals(id))).go();
}
