import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../data/database/enums.dart';
import '../domain/date_only.dart';
import '../domain/day_settlement.dart';
import '../domain/midnight_cutoff.dart';
import '../domain/recalculation_engine.dart';
import 'database_providers.dart';
import 'day_providers.dart';
import 'settings_providers.dart';

final latestBalanceProvider = StreamProvider<BalanceSnapshot?>((ref) {
  return ref.watch(appDatabaseProvider).balanceSnapshotDao.watchLatest();
});

/// The balance carried into [date] — i.e. everything already settled.
///
/// Screens compose this with today's live contribution rather than reading
/// [latestBalanceProvider], which includes a today row whose stored delta is a
/// full-day shortfall until the day has been worked. See
/// `lib/domain/day_settlement.dart` for why.
final settledBalanceProvider =
    StreamProvider.autoDispose.family<BalanceSnapshot?, DateTime>((ref, date) {
  return ref.watch(appDatabaseProvider).balanceSnapshotDao.watchLatestBefore(date);
});

/// The balance as every screen should print it, and whether today is still
/// being held back.
///
/// Home does not use this — it recomputes the same thing once a second so the
/// figure can respond to the session running right now. Everywhere else reads
/// it, so Stats and History cannot drift away from what Home says.
class DisplayedBalance {
  const DisplayedBalance({required this.hours, required this.provisional});

  final double hours;

  /// Today is open and behind target, so [hours] is deliberately withholding a
  /// shortfall that lands when the day ends.
  final bool provisional;
}

final displayedBalanceProvider =
    Provider.autoDispose.family<DisplayedBalance, DateTime>((ref, now) {
  final today = dateOnly(now);

  final settled = ref.watch(settledBalanceProvider(today)).valueOrNull;
  final entry = ref.watch(dayEntryForDateProvider(today)).valueOrNull;
  final sessions = ref.watch(sessionsForDateProvider(today)).valueOrNull ?? const [];
  final settings = ref.watch(effectiveSettingsForProvider(today)).valueOrNull;

  if (settings == null) {
    return DisplayedBalance(hours: settled?.balance ?? 0, provisional: false);
  }

  WorkSession? active;
  final completed = <WorkSession>[];
  for (final session in sessions) {
    if (session.status == SessionStatus.active) {
      active = session;
    } else if (session.status == SessionStatus.completed && session.endTime != null) {
      completed.add(session);
    }
  }
  completed.sort((a, b) => a.startTime.compareTo(b.startTime));

  final targetHours = entry?.targetHours ??
      computeTargetHours(
        date: today,
        workDays: settings.workDays,
        weeklyHours: settings.weeklyHours,
      );
  // Unlike Home's, this net does not include the second-by-second running
  // session — nothing here re-reads the clock. It moves at each check-out,
  // which is when a committed figure exists to move it.
  final todayDelta =
      (entry?.netWorkedHours ?? 0) + (entry?.leaveHours ?? 0) - targetHours;

  final finished = dayIsFinished(
    now: now,
    day: today,
    hasActiveSession: active != null,
    lastCheckOut: completed.isEmpty ? null : completed.last.endTime,
    workWindow: TimeOfDayWindow(
      startMinutes: settings.workWindowStartMinutes,
      endMinutes: settings.workWindowEndMinutes,
    ),
  );

  return DisplayedBalance(
    hours: (settled?.balance ?? 0) + todayContribution(delta: todayDelta, finished: finished),
    provisional: !finished && todayDelta < 0,
  );
});
