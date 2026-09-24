// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_snapshot_dao.dart';

// ignore_for_file: type=lint
mixin _$BalanceSnapshotDaoMixin on DatabaseAccessor<AppDatabase> {
  $BalanceSnapshotsTable get balanceSnapshots =>
      attachedDatabase.balanceSnapshots;
  BalanceSnapshotDaoManager get managers => BalanceSnapshotDaoManager(this);
}

class BalanceSnapshotDaoManager {
  final _$BalanceSnapshotDaoMixin _db;
  BalanceSnapshotDaoManager(this._db);
  $$BalanceSnapshotsTableTableManager get balanceSnapshots =>
      $$BalanceSnapshotsTableTableManager(
        _db.attachedDatabase,
        _db.balanceSnapshots,
      );
}
