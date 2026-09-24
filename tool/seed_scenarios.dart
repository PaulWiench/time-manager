/// Fills an empty database with a plausible six months, so the designed
/// states can be met on a device instead of only in a render.
///
/// Eight of Home's states, three of History's day statuses and every Stats
/// chart need history that does not exist in a fresh install and cannot be
/// produced by hand in a reasonable time. This makes it, going through the
/// repositories rather than the tables so the recalculation engine computes
/// the derived rows exactly as it would in real use — a seed that wrote
/// `day_entries` directly would prove nothing about the app.
///
/// Debug builds only. See `lib/main_dev.dart` for the guard.
library;

import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/data/repositories/leave_repository.dart';
import 'package:time_manager/data/repositories/public_holiday_repository.dart';
import 'package:time_manager/data/repositories/recalculation_service.dart';
import 'package:time_manager/data/repositories/settings_repository.dart';
import 'package:time_manager/data/repositories/vacation_quota_repository.dart';
import 'package:time_manager/data/repositories/work_session_repository.dart';
import 'package:time_manager/domain/date_only.dart';

/// Deletes every row. Only ever called from the dev entrypoint.
Future<void> wipe(AppDatabase db) async {
  await db.transaction(() async {
    // Children before parents: work sessions, breaks and leave all reference
    // a day entry.
    await db.delete(db.workSessions).go();
    await db.delete(db.breakEntries).go();
    await db.delete(db.leaveEntries).go();
    await db.delete(db.balanceSnapshots).go();
    await db.delete(db.dayEntries).go();
    await db.delete(db.publicHolidays).go();
    await db.delete(db.vacationQuotas).go();
    await db.delete(db.appSettings).go();
    await db.delete(db.auditLogEntries).go();
  });
}

/// The state the app should be left in when the seed finishes.
enum SeedState {
  /// A session running since this morning.
  tracking,

  /// Checked out twenty-eight minutes ago, target not yet met.
  onBreak,

  /// A finished day.
  checkedOut,

  /// Nothing logged today.
  empty,
}

Future<void> seed(
  AppDatabase db, {
  required DateTime now,
  SeedState state = SeedState.tracking,
  int days = 190,
}) async {
  final recalc = RecalculationService(db);
  final settings = SettingsRepository(db, recalc);
  final sessions = WorkSessionRepository(db, recalc);
  final leave = LeaveRepository(db, recalc);
  final holidays = PublicHolidayRepository(db, recalc);
  final quotas = VacationQuotaRepository(db);

  final today = dateOnly(now);
  final start = shiftDays(today, -days);

  await settings.seedStartingBalance(balance: 4.75, effectiveFrom: start);
  await settings.save(
    effectiveFrom: start,
    weeklyHours: 39.5,
    workDays: const [1, 2, 3, 4, 5],
    minSessionMinutes: 5,
    autoBreakEnabled: true,
    restrictCheckin: false,
    // Set, and set where the seeded balance will cross it — otherwise the
    // warning treatment has no way to appear on a device.
    balanceFloorHours: -20,
    balanceCapHours: 40,
  );

  await holidays.seedYear(today.year - 1);
  await holidays.seedYear(today.year);
  await quotas.setQuota(year: today.year, totalDays: 30);

  final wobble = _Wobble();

  for (var i = 0; i < days; i++) {
    final date = shiftDays(start, i);
    if (date.weekday > 5) continue;

    final roll = wobble.next();
    if (roll < 0.05) continue; // a missed workday
    if (roll < 0.11) {
      await leave.addLeave(
        date: date,
        type: roll < 0.09 ? LeaveType.vacation : LeaveType.sick,
        hours: 7.9,
        notes: roll < 0.09 ? 'Brückentag' : null,
      );
      continue;
    }

    // One or two sessions, starting somewhere between half seven and half
    // nine, with a real gap in the middle on the two-session days.
    final startHour = 7 + (wobble.next() * 2).floor();
    final startMinute = (wobble.next() * 59).floor();
    final morningIn = DateTime(date.year, date.month, date.day, startHour, startMinute);
    final split = wobble.next() < 0.55;

    if (split) {
      final morningOut = morningIn.add(Duration(minutes: 180 + (wobble.next() * 90).floor()));
      final afternoonIn = morningOut.add(Duration(minutes: 30 + (wobble.next() * 60).floor()));
      final afternoonOut =
          afternoonIn.add(Duration(minutes: 180 + (wobble.next() * 120).floor()));
      await _session(sessions, morningIn, morningOut);
      await _session(sessions, afternoonIn, afternoonOut);
    } else {
      final out = morningIn.add(Duration(minutes: 420 + (wobble.next() * 180).floor()));
      await _session(sessions, morningIn, out);
    }
  }

  await _today(sessions, now: now, state: state);
}

Future<void> _today(
  WorkSessionRepository sessions, {
  required DateTime now,
  required SeedState state,
}) async {
  final today = dateOnly(now);
  DateTime at(int hour, int minute) =>
      DateTime(today.year, today.month, today.day, hour, minute);

  switch (state) {
    case SeedState.empty:
      return;
    case SeedState.tracking:
      await _session(sessions, at(9, 0), at(12, 52));
      await sessions.checkIn(at(14, 51));
    case SeedState.onBreak:
      // Half a day's work and a recent check-out, so the break window and the
      // not-yet-met target both apply.
      await _session(sessions, at(8, 43), now.subtract(const Duration(minutes: 28)));
    case SeedState.checkedOut:
      await _session(sessions, at(8, 42), at(12, 0));
      await _session(sessions, at(12, 30), at(18, 51));
  }
}

Future<void> _session(
  WorkSessionRepository sessions,
  DateTime start,
  DateTime end,
) async {
  await sessions.checkIn(start);
  final active = await sessions.activeSession();
  if (active == null) return;
  await sessions.checkOut(sessionId: active.id, at: end);
}

/// A repeatable sequence in [0, 1). Deterministic on purpose: a seed that
/// produces a different shape each run is useless for comparing two builds.
class _Wobble {
  int _state = 0x5f3a91c;

  double next() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return (_state >> 8) / 0x7fffff;
  }
}
