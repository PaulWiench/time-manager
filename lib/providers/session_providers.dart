import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/database.dart';
import '../data/database/enums.dart';
import '../domain/date_only.dart';
import 'database_providers.dart';

part 'session_providers.g.dart';

/// The currently active session (if any), derived from today's sessions.
/// A session that crosses midnight is still "today's" until the midnight
/// cutoff logic resolves it — see `domain/midnight_cutoff.dart`.
@riverpod
Stream<WorkSession?> activeSession(Ref ref) {
  final today = dateOnly(DateTime.now());
  final db = ref.watch(appDatabaseProvider);
  return db.workSessionDao.watchForDate(today).map((sessions) {
    for (final s in sessions) {
      if (s.status == SessionStatus.active) return s;
    }
    return null;
  });
}
