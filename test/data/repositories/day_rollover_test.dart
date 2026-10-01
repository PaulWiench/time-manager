/// What happens on the first launch after the app was shut for a while.
///
/// Both halves used to be missing entirely: a session left running overnight
/// was never stopped, and a day nobody tracked never reached the balance until
/// some unrelated edit dragged it in.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/data/repositories/day_rollover.dart';
import 'package:time_manager/data/repositories/recalculation_service.dart';
import 'package:time_manager/data/repositories/settings_repository.dart';
import 'package:time_manager/data/repositories/work_session_repository.dart';

void main() {
  /// The one job every test row belongs to.
  const j = 1;

  // Monday 7 September 2026 through Friday 11 September.
  final monday = DateTime(2026, 9, 7);
  DateTime day(int n) => DateTime(2026, 9, 7 + n);

  late AppDatabase db;

  /// The whole stack, pinned to [now] so nothing consults the wall clock.
  ({DayRollover rollover, WorkSessionRepository sessions, RecalculationService recalc})
      stackAt(DateTime now) {
    final recalc = RecalculationService(db, now: () => now);
    final sessions = WorkSessionRepository(db, recalc);
    return (
      rollover: DayRollover(db, sessions, recalc, now: () => now),
      sessions: sessions,
      recalc: recalc,
    );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.jobDao.insertJob(
      JobsCompanion.insert(id: const Value(j), name: 'Test', startDate: monday),
    );
    final stack = stackAt(monday);
    await SettingsRepository(db, stack.recalc).save(
      jobId: j,
      effectiveFrom: monday,
      weeklyHours: 40,
      workDays: const [1, 2, 3, 4, 5],
      minSessionMinutes: 5,
      autoBreakEnabled: true,
      restrictCheckin: false,
    );
  });

  tearDown(() => db.close());

  test('a session left running overnight is closed at 23:59, not at launch', () async {
    // Checked in Monday morning, never checked out, app reopened Wednesday.
    await stackAt(monday).sessions.checkIn(j, monday.add(const Duration(hours: 9)));

    final wednesday = day(2).add(const Duration(hours: 10));
    await stackAt(wednesday).rollover.run();

    final stored = await db.workSessionDao.forDate(j, monday);
    expect(stored.single.status, SessionStatus.completed);
    // 23:59:59 of the day it started, not 10:00 two days later — otherwise
    // Monday would be credited with 49 hours of work.
    expect(stored.single.endTime, DateTime(2026, 9, 7, 23, 59, 59));

    expect(await db.workSessionDao.activeSessions(), isEmpty);
  });

  test("today's session is left alone", () async {
    final tuesday = day(1);
    await stackAt(tuesday).sessions.checkIn(j, tuesday.add(const Duration(hours: 9)));

    await stackAt(tuesday.add(const Duration(hours: 11))).rollover.run();

    expect(await db.workSessionDao.activeSessions(), hasLength(1));
  });

  test('days nobody tracked reach the balance the next time the app opens', () async {
    // One real day on Monday, then silence until Friday.
    final stack = stackAt(monday);
    await stack.sessions.checkIn(j, monday.add(const Duration(hours: 9)));
    await stack.sessions.checkOut(
      sessionId: (await db.workSessionDao.forDate(j, monday)).single.id,
      at: monday.add(const Duration(hours: 17)),
    );

    final mondayBalance = (await db.balanceSnapshotDao.forDate(j, monday))!.balance;
    // 8 hours gross, 30 minutes of statutory break, 8 hour target.
    expect(mondayBalance, closeTo(-0.5, 0.001));

    // Nothing has been written for Tuesday through Thursday.
    expect(await db.balanceSnapshotDao.forDate(j, day(1)), isNull);

    await stackAt(day(4).add(const Duration(hours: 8))).rollover.run();

    // Three missed workdays at 8 hours each, on top of Monday's half hour.
    final thursday = await db.balanceSnapshotDao.forDate(j, day(3));
    expect(thursday, isNotNull);
    expect(thursday!.balance, closeTo(-24.5, 0.001));
  });

  test('a weekend in the gap costs nothing', () async {
    final stack = stackAt(monday);
    await stack.sessions.checkIn(j, monday.add(const Duration(hours: 9)));
    await stack.sessions.checkOut(
      sessionId: (await db.workSessionDao.forDate(j, monday)).single.id,
      at: monday.add(const Duration(hours: 17, minutes: 30)),
    );
    // 8.5 gross - 0.5 break - 8 target = level.
    expect((await db.balanceSnapshotDao.forDate(j, monday))!.balance, closeTo(0, 0.001));

    // Reopened the following Monday: Tue-Fri are workdays, Sat and Sun are not.
    await stackAt(day(7).add(const Duration(hours: 8))).rollover.run();

    final sunday = await db.balanceSnapshotDao.forDate(j, day(6));
    expect(sunday!.balance, closeTo(-32, 0.001));
  });

  test('running twice settles nothing twice', () async {
    final stack = stackAt(monday);
    await stack.sessions.checkIn(j, monday.add(const Duration(hours: 9)));
    await stack.sessions.checkOut(
      sessionId: (await db.workSessionDao.forDate(j, monday)).single.id,
      at: monday.add(const Duration(hours: 17)),
    );

    final wednesday = day(2).add(const Duration(hours: 8));
    await stackAt(wednesday).rollover.run();
    final first = (await db.balanceSnapshotDao.forDate(j, day(1)))!.balance;

    await stackAt(wednesday).rollover.run();
    expect((await db.balanceSnapshotDao.forDate(j, day(1)))!.balance, first);
  });

  test('with no snapshot at all, the job\'s own starting balance is the floor', () async {
    // Before jobs, no snapshot meant no floor to cascade from, and the
    // rollover declined to invent a history. A job carries its starting
    // balance itself (0 here), so the missed days since its start are
    // settled from that instead: Monday and Tuesday untracked, 8 h each.
    await db.balanceSnapshotDao.deleteFromDate(DateTime(2000));

    await stackAt(day(2)).rollover.run();

    expect((await db.balanceSnapshotDao.forDate(j, monday))!.balance, -8);
    expect((await db.balanceSnapshotDao.forDate(j, day(1)))!.balance, -16);
  });
}
