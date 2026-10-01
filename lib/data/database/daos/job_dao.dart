import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'job_dao.g.dart';

@DriftAccessor(tables: [Jobs, Vacations, AppPreferences])
class JobDao extends DatabaseAccessor<AppDatabase> with _$JobDaoMixin {
  JobDao(super.db);

  /// Active jobs by start date, then ended ones newest first — the order the
  /// switcher and the jobs list show them in.
  Stream<List<Job>> watchAll() => (select(jobs)
        ..orderBy([
          (t) => OrderingTerm(expression: t.endDate.isNull(), mode: OrderingMode.desc),
          (t) => OrderingTerm.desc(t.endDate),
          (t) => OrderingTerm.asc(t.startDate),
        ]))
      .watch();

  Future<List<Job>> all() => select(jobs).get();

  Future<Job?> byId(int id) =>
      (select(jobs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Job?> watchById(int id) =>
      (select(jobs)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> insertJob(JobsCompanion entry) => into(jobs).insert(entry);

  Future<void> updateJob(int id, JobsCompanion entry) =>
      (update(jobs)..where((t) => t.id.equals(id))).write(entry);

  Future<String?> preference(String key) =>
      (select(appPreferences)..where((t) => t.key.equals(key)))
          .map((row) => row.value)
          .getSingleOrNull();

  Stream<String?> watchPreference(String key) =>
      (select(appPreferences)..where((t) => t.key.equals(key)))
          .map((row) => row.value)
          .watchSingleOrNull();

  Future<void> setPreference(String key, String value) => into(appPreferences)
      .insertOnConflictUpdate(AppPreferencesCompanion.insert(key: key, value: value));

  Future<Vacation?> vacationById(String id) =>
      (select(vacations)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<Vacation>> watchVacations(int jobId) =>
      (select(vacations)..where((t) => t.jobId.equals(jobId))).watch();

  Future<void> renameVacation(String id, String? name) =>
      (update(vacations)..where((t) => t.id.equals(id))).write(VacationsCompanion(
        name: Value(name),
        updatedAt: Value(DateTime.now()),
      ));
}
