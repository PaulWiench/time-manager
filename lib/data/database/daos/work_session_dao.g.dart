// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_session_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkSessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $DayEntriesTable get dayEntries => attachedDatabase.dayEntries;
  $WorkSessionsTable get workSessions => attachedDatabase.workSessions;
  WorkSessionDaoManager get managers => WorkSessionDaoManager(this);
}

class WorkSessionDaoManager {
  final _$WorkSessionDaoMixin _db;
  WorkSessionDaoManager(this._db);
  $$DayEntriesTableTableManager get dayEntries =>
      $$DayEntriesTableTableManager(_db.attachedDatabase, _db.dayEntries);
  $$WorkSessionsTableTableManager get workSessions =>
      $$WorkSessionsTableTableManager(_db.attachedDatabase, _db.workSessions);
}
