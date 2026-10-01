import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'vacation_quota_dao.g.dart';

@DriftAccessor(tables: [VacationQuotas])
class VacationQuotaDao extends DatabaseAccessor<AppDatabase>
    with _$VacationQuotaDaoMixin {
  VacationQuotaDao(super.db);

  Future<VacationQuota?> forYear(int jobId, int year) =>
      (select(vacationQuotas)..where((t) => t.jobId.equals(jobId) & t.year.equals(year)))
          .getSingleOrNull();

  Stream<VacationQuota?> watchForYear(int jobId, int year) =>
      (select(vacationQuotas)..where((t) => t.jobId.equals(jobId) & t.year.equals(year)))
          .watchSingleOrNull();

  /// The most recent year at or before [year] that has a row — a quota is set
  /// once and stands until changed, not re-entered every January.
  Future<VacationQuota?> standingFor(int jobId, int year) => (select(vacationQuotas)
        ..where((t) => t.jobId.equals(jobId) & t.year.isSmallerOrEqualValue(year))
        ..orderBy([(t) => OrderingTerm.desc(t.year)])
        ..limit(1))
      .getSingleOrNull();

  Stream<VacationQuota?> watchStandingFor(int jobId, int year) => (select(vacationQuotas)
        ..where((t) => t.jobId.equals(jobId) & t.year.isSmallerOrEqualValue(year))
        ..orderBy([(t) => OrderingTerm.desc(t.year)])
        ..limit(1))
      .watchSingleOrNull();

  Future<int> upsert(VacationQuotasCompanion entry) =>
      into(vacationQuotas).insertOnConflictUpdate(entry);
}
