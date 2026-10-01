// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_session_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkSessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $JobsTable get jobs => attachedDatabase.jobs;
  $WorkSessionsTable get workSessions => attachedDatabase.workSessions;
  WorkSessionDaoManager get managers => WorkSessionDaoManager(this);
}

class WorkSessionDaoManager {
  final _$WorkSessionDaoMixin _db;
  WorkSessionDaoManager(this._db);
  $$JobsTableTableManager get jobs =>
      $$JobsTableTableManager(_db.attachedDatabase, _db.jobs);
  $$WorkSessionsTableTableManager get workSessions =>
      $$WorkSessionsTableTableManager(_db.attachedDatabase, _db.workSessions);
}
