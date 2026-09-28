import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'database_providers.dart';

/// The currently active session, if any.
///
/// Watches the whole table rather than today's rows. It used to capture
/// `dateOnly(DateTime.now())` once, when the provider was first built — so an
/// app left open across midnight went on watching yesterday, and a session
/// started after midnight was invisible until something disposed the provider.
/// A session that crosses midnight also belongs to the day it *started* on,
/// which a query keyed to today could never return.
///
/// At most one row should ever be active (`WorkSessionRepository.checkIn`
/// enforces it); the latest-started one wins if that invariant is ever broken.
/// A session still running from a previous day is closed at launch — see
/// `providers/rollover_providers.dart`.
final activeSessionProvider = StreamProvider.autoDispose<WorkSession?>((ref) {
  return ref.watch(appDatabaseProvider).workSessionDao.watchActive();
});
