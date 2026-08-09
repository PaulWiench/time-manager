import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/database.dart';
import 'database_providers.dart';

part 'balance_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<BalanceSnapshot?> latestBalance(Ref ref) {
  return ref.watch(appDatabaseProvider).balanceSnapshotDao.watchLatest();
}
