import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'database_providers.dart';

final latestBalanceProvider = StreamProvider<BalanceSnapshot?>((ref) {
  return ref.watch(appDatabaseProvider).balanceSnapshotDao.watchLatest();
});
