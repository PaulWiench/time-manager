import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'vacation_quota_dao.g.dart';

@DriftAccessor(tables: [VacationQuotas])
class VacationQuotaDao extends DatabaseAccessor<AppDatabase>
    with _$VacationQuotaDaoMixin {
  VacationQuotaDao(super.db);

  Future<VacationQuota?> forYear(int year) =>
      (select(vacationQuotas)..where((t) => t.year.equals(year)))
          .getSingleOrNull();

  Future<int> upsert(VacationQuotasCompanion entry) =>
      into(vacationQuotas).insertOnConflictUpdate(entry);
}
