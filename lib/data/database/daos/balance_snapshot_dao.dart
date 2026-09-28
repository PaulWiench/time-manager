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

  /// The balance as of the last day that is genuinely over — the stream behind
  /// every displayed balance.
  ///
  /// The plain [watchLatest] returns today's row whenever anything has
  /// triggered a cascade today, and today's stored delta is a full-day
  /// shortfall until the day is actually worked. Everything on screen composes
  /// this with a live figure for today instead. See
  /// `lib/domain/day_settlement.dart`.
  Stream<BalanceSnapshot?> watchLatestBefore(DateTime date) =>
      (select(balanceSnapshots)
            ..where((t) => t.date.isSmallerThanValue(date))
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(1))
          .watchSingleOrNull();

  Future<int> upsert(BalanceSnapshotsCompanion entry) =>
      into(balanceSnapshots).insertOnConflictUpdate(entry);

  Future<int> deleteFromDate(DateTime date) =>
      (delete(balanceSnapshots)..where((t) => t.date.isBiggerOrEqualValue(date)))
          .go();
}
