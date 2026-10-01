// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$LeaveEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $JobsTable get jobs => attachedDatabase.jobs;
  $VacationsTable get vacations => attachedDatabase.vacations;
  $LeaveEntriesTable get leaveEntries => attachedDatabase.leaveEntries;
  LeaveEntryDaoManager get managers => LeaveEntryDaoManager(this);
}

class LeaveEntryDaoManager {
  final _$LeaveEntryDaoMixin _db;
  LeaveEntryDaoManager(this._db);
  $$JobsTableTableManager get jobs =>
      $$JobsTableTableManager(_db.attachedDatabase, _db.jobs);
  $$VacationsTableTableManager get vacations =>
      $$VacationsTableTableManager(_db.attachedDatabase, _db.vacations);
  $$LeaveEntriesTableTableManager get leaveEntries =>
      $$LeaveEntriesTableTableManager(_db.attachedDatabase, _db.leaveEntries);
}
