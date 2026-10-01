import '../../domain/date_only.dart';
import '../../domain/midnight_cutoff.dart';
import '../database/database.dart';
import 'recalculation_service.dart';
import 'work_session_repository.dart';

/// Everything that should have happened while the app was closed.
///
/// Two things were silently never happening.
///
/// **A session left running overnight was never stopped.** `evaluateMidnightCutoff`
/// has been written, documented and unit-tested since the domain layer was
/// built, and had no production caller — so forgetting to check out turned
/// into a fourteen-hour session quietly inflating the day it started on.
///
/// **The balance never moved on its own.** Snapshots are written only when
/// something mutates, so a day nobody tracked left the headline showing a
/// stale figure until the next check-in retroactively dropped it — days late,
/// and attributed to the wrong moment. That matters more now that the balance
/// deliberately withholds today's shortfall: "it lands once the day is over"
/// is only true if something settles the day once it is over.
///
/// Both halves are no-ops on the common launch.
class DayRollover {
  DayRollover(this.db, this.sessions, this.recalc, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase db;
  final WorkSessionRepository sessions;
  final RecalculationService recalc;
  final DateTime Function() _now;

  Future<void> run() async {
    final now = _now();
    final today = dateOnly(now);

    await _closeOvernightSessions(now, today);
    await _settleMissedDays(today);
    await recalc.refreshFutureDays();
  }

  /// Stops anything still running from a previous day where the policy says it
  /// should have stopped, not where the clock happens to be now.
  Future<void> _closeOvernightSessions(DateTime now, DateTime today) async {
    for (final session in await db.workSessionDao.activeSessions()) {
      if (!dateOnly(session.startTime).isBefore(today)) continue;

      final settings = await db.settingsDao.effectiveFor(session.jobId, dateOnly(session.date));
      final cutoff = evaluateMidnightCutoff(
        sessionStart: session.startTime,
        now: now,
        // Null unless the user opted into a restricted check-in window, which
        // is the contract evaluateMidnightCutoff documents: with no window
        // configured there is nothing to be outside of, so the cutoff always
        // applies. The normal-work-hours window added for the balance answers
        // a different question and is deliberately not wired in here.
        workWindow: settings != null && settings.restrictCheckin
            ? TimeOfDayWindow(
                startMinutes: settings.workWindowStartMinutes,
                endMinutes: settings.workWindowEndMinutes,
              )
            : null,
      );
      if (!cutoff.cutoffApplied) continue;

      await sessions.checkOut(sessionId: session.id, at: cutoff.effectiveEnd);
    }
  }

  /// Settles every job's days between its last snapshot and yesterday.
  ///
  /// A missed workday has no `day_entries` row at all, so only the cascade can
  /// find it — `_deltaFor` recomputes the target and charges the shortfall.
  Future<void> _settleMissedDays(DateTime today) async {
    for (final job in await db.jobDao.all()) {
      final latest = await db.balanceSnapshotDao.latestBefore(job.id, today);
      // No snapshot yet: a job created today, or onboarding has not run.
      // The job's start is where its cascade begins.
      final from = latest == null ? dateOnly(job.startDate) : shiftDays(latest.date, 1);
      if (!from.isBefore(today)) continue;

      // One pass, one cascade — recalculateFrom would cascade once per day.
      await recalc.recalculateRangeFrom(job.id, from);
    }
  }
}
