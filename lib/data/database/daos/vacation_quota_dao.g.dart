// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vacation_quota_dao.dart';

// ignore_for_file: type=lint
mixin _$VacationQuotaDaoMixin on DatabaseAccessor<AppDatabase> {
  $VacationQuotasTable get vacationQuotas => attachedDatabase.vacationQuotas;
  VacationQuotaDaoManager get managers => VacationQuotaDaoManager(this);
}

class VacationQuotaDaoManager {
  final _$VacationQuotaDaoMixin _db;
  VacationQuotaDaoManager(this._db);
  $$VacationQuotasTableTableManager get vacationQuotas =>
      $$VacationQuotasTableTableManager(
        _db.attachedDatabase,
        _db.vacationQuotas,
      );
}
