// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'break_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$BreakEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $JobsTable get jobs => attachedDatabase.jobs;
  $BreakEntriesTable get breakEntries => attachedDatabase.breakEntries;
  BreakEntryDaoManager get managers => BreakEntryDaoManager(this);
}

class BreakEntryDaoManager {
  final _$BreakEntryDaoMixin _db;
  BreakEntryDaoManager(this._db);
  $$JobsTableTableManager get jobs =>
      $$JobsTableTableManager(_db.attachedDatabase, _db.jobs);
  $$BreakEntriesTableTableManager get breakEntries =>
      $$BreakEntriesTableTableManager(_db.attachedDatabase, _db.breakEntries);
}
