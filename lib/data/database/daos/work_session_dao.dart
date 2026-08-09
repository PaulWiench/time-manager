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

  Stream<List<WorkSession>> watchForDate(DateTime date) =>
      (select(workSessions)..where((t) => t.date.equals(date))).watch();

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
