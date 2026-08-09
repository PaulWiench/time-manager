import 'package:drift/drift.dart';

import '../../domain/break_engine.dart';
import '../../domain/date_only.dart';
import '../../domain/recalculation_engine.dart';
import '../database/database.dart';
import '../database/enums.dart';

/// Ties the domain engines to the database: recomputes a day's DayEntry
/// (and its synthetic break, if any) and cascades the BalanceSnapshot
/// forward. This is the single place every mutation (session/leave/holiday/
/// settings change) routes through, per Data Model § Recalculation Trigger
/// Rules.
class RecalculationService {
  final AppDatabase db;
  final DateTime Function() _now;

  /// [now] is injectable so tests get deterministic "today" boundaries
  /// instead of depending on the real wall clock.
  RecalculationService(this.db, {DateTime Function() now = DateTime.now})
      : _now = now;

  /// Recalculates [date]'s DayEntry, then cascades the balance forward from
  /// [date] through today (or through [date] itself, if it's in the
  /// future). Use for a single-day change (a session/leave/holiday edit).
  Future<void> recalculateFrom(DateTime date) async {
    final day = dateOnly(date);
    await db.transaction(() async {
      await _recalculateDay(day);
      await _cascadeBalanceFrom(day);
    });
  }

  /// Recalculates every day from [date] through today, then cascades the
  /// balance once at the end. Use when a change can affect many days at
  /// once — a Settings change with a past `effectiveFrom` shifts
  /// target_hours (and so balance_delta) for every already-recorded day
  /// from that point forward, not just one. Data Model § Recalculation
  /// Trigger Rules: "Settings change with past effective_from -> All
  /// DayEntries and BalanceSnapshots from effective_from forward."
  Future<void> recalculateRangeFrom(DateTime date) async {
    final start = dateOnly(date);
    final today = dateOnly(_now());
    final end = start.isAfter(today) ? start : today;

    await db.transaction(() async {
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        await _recalculateDay(d);
      }
      await _cascadeBalanceFrom(start);
    });
  }

  /// Updates the DayEntry for [day] from its current sessions/leave/holiday,
  /// but only writes a row if one already exists or something actually
  /// touches this date (a completed session, leave, or holiday) — DayEntry
  /// rows are created lazily, never speculatively, per Data Model §
  /// Design Principles.
  Future<void> _recalculateDay(DateTime day) async {
    final settings = await db.settingsDao.effectiveFor(day);
    // No settings yet means onboarding hasn't completed — nothing to
    // compute against.
    if (settings == null) return;

    final existing = await db.dayEntryDao.forDate(day);
    final holiday = await db.publicHolidayDao.forDate(day);
    final sessions = await db.workSessionDao.forDate(day);
    final completed = sessions
        .where((s) => s.status == SessionStatus.completed && s.endTime != null)
        .map((s) => WorkPeriod(start: s.startTime, end: s.endTime!))
        .toList();
    final leave = await db.leaveEntryDao.forDate(day);

    final hasActivity = completed.isNotEmpty || leave.isNotEmpty || holiday != null;
    if (existing == null && !hasActivity) return;

    var leaveHours = 0.0;
    for (final l in leave) {
      leaveHours += l.hours;
    }

    final targetHours = computeTargetHours(
      date: day,
      workDays: settings.workDays,
      weeklyHours: settings.weeklyHours,
      holidayFraction: holiday?.fraction,
    );

    final autoBreakOverridden = existing?.autoBreakOverridden ?? false;

    final computation = recalculateDayEntry(
      completedSessions: completed,
      autoBreakEnabled: settings.autoBreakEnabled,
      autoBreakOverridden: autoBreakOverridden,
      leaveHours: leaveHours,
      targetHours: targetHours,
    );

    await db.dayEntryDao.upsert(DayEntriesCompanion(
      date: Value(day),
      netWorkedHours: Value(computation.netWorkedHours),
      leaveHours: Value(computation.leaveHours),
      targetHours: Value(computation.targetHours),
      balanceDelta: Value(computation.balanceDelta),
      autoBreakOverridden: Value(autoBreakOverridden),
    ));

    // Synthetic breaks are fully re-derived every time — clear the old one
    // (if any) before writing the new plan, rather than trying to diff it.
    final existingBreaks = await db.breakEntryDao.forDate(day);
    for (final b in existingBreaks) {
      if (b.type == BreakType.synthetic) {
        await db.breakEntryDao.deleteBreak(b.id);
      }
    }
    final plan = computation.syntheticBreak;
    if (plan != null) {
      await db.breakEntryDao.insertBreak(BreakEntriesCompanion.insert(
        date: day,
        startTime: plan.start,
        endTime: plan.end,
        type: BreakType.synthetic,
      ));
    }
  }

  Future<void> _cascadeBalanceFrom(DateTime day) async {
    final previous = await db.balanceSnapshotDao.latestBefore(day);
    final startingBalance = previous?.balance ?? 0.0;

    final today = dateOnly(_now());
    final end = day.isAfter(today) ? day : today;

    final deltas = <MapEntry<DateTime, double>>[];
    for (var d = day; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      deltas.add(MapEntry(d, await _deltaFor(d)));
    }

    final snapshots =
        cascadeBalance(startingBalance: startingBalance, dailyDeltas: deltas);
    for (final s in snapshots) {
      await db.balanceSnapshotDao.upsert(BalanceSnapshotsCompanion.insert(
        date: s.date,
        balance: s.balance,
      ));
    }
  }

  /// A date's balance_delta: its DayEntry's, if one exists; otherwise
  /// [missedWorkdayDelta] for a scheduled workday with no entry, or 0 for a
  /// non-work day. Data Model § Design Principles.
  Future<double> _deltaFor(DateTime date) async {
    final entry = await db.dayEntryDao.forDate(date);
    if (entry != null) return entry.balanceDelta;

    final settings = await db.settingsDao.effectiveFor(date);
    if (settings == null) return 0;
    if (!settings.workDays.contains(date.weekday)) return 0;

    final holiday = await db.publicHolidayDao.forDate(date);
    final target = computeTargetHours(
      date: date,
      workDays: settings.workDays,
      weeklyHours: settings.weeklyHours,
      holidayFraction: holiday?.fraction,
    );
    return missedWorkdayDelta(target);
  }
}
