// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$LeaveEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $DayEntriesTable get dayEntries => attachedDatabase.dayEntries;
  $LeaveEntriesTable get leaveEntries => attachedDatabase.leaveEntries;
  LeaveEntryDaoManager get managers => LeaveEntryDaoManager(this);
}

class LeaveEntryDaoManager {
  final _$LeaveEntryDaoMixin _db;
  LeaveEntryDaoManager(this._db);
  $$DayEntriesTableTableManager get dayEntries =>
      $$DayEntriesTableTableManager(_db.attachedDatabase, _db.dayEntries);
  $$LeaveEntriesTableTableManager get leaveEntries =>
      $$LeaveEntriesTableTableManager(_db.attachedDatabase, _db.leaveEntries);
}
