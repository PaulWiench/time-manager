import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'balance_snapshot_dao.g.dart';

@DriftAccessor(tables: [BalanceSnapshots])
class BalanceSnapshotDao extends DatabaseAccessor<AppDatabase>
    with _$BalanceSnapshotDaoMixin {
  BalanceSnapshotDao(super.db);

  Future<BalanceSnapshot?> forDate(DateTime date) =>
      (select(balanceSnapshots)..where((t) => t.date.equals(date)))
          .getSingleOrNull();

  /// The most recent snapshot strictly before [date] — the recalculation
  /// engine's starting point when cascading forward from an edit.
  Future<BalanceSnapshot?> latestBefore(DateTime date) =>
      (select(balanceSnapshots)
            ..where((t) => t.date.isSmallerThanValue(date))
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<BalanceSnapshot>> forRange(DateTime start, DateTime endExclusive) =>
      (select(balanceSnapshots)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(endExclusive))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  Stream<BalanceSnapshot?> watchLatest() => (select(balanceSnapshots)
        ..orderBy([(t) => OrderingTerm.desc(t.date)])
        ..limit(1))
      .watchSingleOrNull();

  Future<int> upsert(BalanceSnapshotsCompanion entry) =>
      into(balanceSnapshots).insertOnConflictUpdate(entry);

  Future<int> deleteFromDate(DateTime date) =>
      (delete(balanceSnapshots)..where((t) => t.date.isBiggerOrEqualValue(date)))
          .go();
}
