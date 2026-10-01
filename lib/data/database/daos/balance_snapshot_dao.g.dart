// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_snapshot_dao.dart';

// ignore_for_file: type=lint
mixin _$BalanceSnapshotDaoMixin on DatabaseAccessor<AppDatabase> {
  $JobsTable get jobs => attachedDatabase.jobs;
  $BalanceSnapshotsTable get balanceSnapshots =>
      attachedDatabase.balanceSnapshots;
  BalanceSnapshotDaoManager get managers => BalanceSnapshotDaoManager(this);
}

class BalanceSnapshotDaoManager {
  final _$BalanceSnapshotDaoMixin _db;
  BalanceSnapshotDaoManager(this._db);
  $$JobsTableTableManager get jobs =>
      $$JobsTableTableManager(_db.attachedDatabase, _db.jobs);
  $$BalanceSnapshotsTableTableManager get balanceSnapshots =>
      $$BalanceSnapshotsTableTableManager(
        _db.attachedDatabase,
        _db.balanceSnapshots,
      );
}
