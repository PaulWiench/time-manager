// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_holiday_dao.dart';

// ignore_for_file: type=lint
mixin _$PublicHolidayDaoMixin on DatabaseAccessor<AppDatabase> {
  $PublicHolidaysTable get publicHolidays => attachedDatabase.publicHolidays;
  PublicHolidayDaoManager get managers => PublicHolidayDaoManager(this);
}

class PublicHolidayDaoManager {
  final _$PublicHolidayDaoMixin _db;
  PublicHolidayDaoManager(this._db);
  $$PublicHolidaysTableTableManager get publicHolidays =>
      $$PublicHolidaysTableTableManager(
        _db.attachedDatabase,
        _db.publicHolidays,
      );
}
