// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vacation_quota_dao.dart';

// ignore_for_file: type=lint
mixin _$VacationQuotaDaoMixin on DatabaseAccessor<AppDatabase> {
  $JobsTable get jobs => attachedDatabase.jobs;
  $VacationQuotasTable get vacationQuotas => attachedDatabase.vacationQuotas;
  VacationQuotaDaoManager get managers => VacationQuotaDaoManager(this);
}

class VacationQuotaDaoManager {
  final _$VacationQuotaDaoMixin _db;
  VacationQuotaDaoManager(this._db);
  $$JobsTableTableManager get jobs =>
      $$JobsTableTableManager(_db.attachedDatabase, _db.jobs);
  $$VacationQuotasTableTableManager get vacationQuotas =>
      $$VacationQuotasTableTableManager(
        _db.attachedDatabase,
        _db.vacationQuotas,
      );
}
