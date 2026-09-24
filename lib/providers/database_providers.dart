import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';

/// Providers in this package are written by hand rather than generated:
/// `riverpod_generator` pins an analyzer too old to parse the current SDK's
/// own sources, so `build_runner` cannot run at all. The names match what the
/// generator produced, so no call site changed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
