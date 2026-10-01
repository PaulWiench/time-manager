// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$DayEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $JobsTable get jobs => attachedDatabase.jobs;
  $DayEntriesTable get dayEntries => attachedDatabase.dayEntries;
  DayEntryDaoManager get managers => DayEntryDaoManager(this);
}

class DayEntryDaoManager {
  final _$DayEntryDaoMixin _db;
  DayEntryDaoManager(this._db);
  $$JobsTableTableManager get jobs =>
      $$JobsTableTableManager(_db.attachedDatabase, _db.jobs);
  $$DayEntriesTableTableManager get dayEntries =>
      $$DayEntriesTableTableManager(_db.attachedDatabase, _db.dayEntries);
}
