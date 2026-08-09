import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/data/repositories/leave_repository.dart';
import 'package:time_manager/data/repositories/public_holiday_repository.dart';
import 'package:time_manager/data/repositories/recalculation_service.dart';
import 'package:time_manager/data/repositories/settings_repository.dart';
import 'package:time_manager/data/repositories/work_session_repository.dart';

void main() {
  // Fixed "today" (a Wednesday) so cascade-to-today behavior is
  // deterministic instead of depending on the real wall clock. All test
  // dates below (Mon 8/10 - Wed 8/12) fall on or before it.
  final fixedNow = DateTime(2026, 8, 12);

  late AppDatabase db;
  late RecalculationService recalc;
  late WorkSessionRepository sessions;
  late SettingsRepository settings;
  late LeaveRepository leave;
  late PublicHolidayRepository holidays;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    recalc = RecalculationService(db, now: () => fixedNow);
    sessions = WorkSessionRepository(db, recalc);
    settings = SettingsRepository(db, recalc);
    leave = LeaveRepository(db, recalc);
    holidays = PublicHolidayRepository(db, recalc);

    // effectiveFrom matches the earliest date any test uses (Monday), so
    // settings are actually effective for every test date, while still
    // keeping setUp's own cascade short (Mon-Wed only, not a long backlog).
    await settings.save(
      effectiveFrom: DateTime(2026, 8, 10),
      weeklyHours: 40,
      workDays: const [1, 2, 3, 4, 5],
      minSessionMinutes: 5,
      autoBreakEnabled: true,
      restrictCheckin: false,
    );
  });

  tearDown(() => db.close());

  test('check-in/check-out over 6h triggers break deduction end to end', () async {
    final day = DateTime(2026, 8, 10); // Monday

    await sessions.checkIn(day.add(const Duration(hours: 8)));
    var active = await sessions.activeSession();
    expect(active, isNotNull);

    await sessions.checkOut(
      sessionId: active!.id,
      at: day.add(const Duration(hours: 14, minutes: 30)),
    );

    final dayEntry = await db.dayEntryDao.forDate(day);
    expect(dayEntry, isNotNull);
    // 6.5h gross, single session, no gap -> over 6h -> 30 min synthetic
    // break -> 6.0h net.
    expect(dayEntry!.netWorkedHours, 6.0);
    expect(dayEntry.targetHours, 8.0);
    expect(dayEntry.balanceDelta, 6.0 - 8.0);

    // Nothing precedes Monday in this test, so the snapshot should equal
    // the day's own delta exactly.
    final snapshot = await db.balanceSnapshotDao.forDate(day);
    expect(snapshot?.balance, dayEntry.balanceDelta);

    final synthetic = (await db.breakEntryDao.forDate(day))
        .where((b) => b.type == BreakType.synthetic);
    expect(synthetic, hasLength(1));
  });

  test('too-short sessions are discarded and do not affect DayEntry', () async {
    final day = DateTime(2026, 8, 10);

    await sessions.checkIn(day.add(const Duration(hours: 8)));
    final active = await sessions.activeSession();
    await sessions.checkOut(
      sessionId: active!.id,
      at: day.add(const Duration(hours: 8, minutes: 2)), // 2 min, under the 5 min minimum
    );

    final stored = await db.workSessionDao.forDate(day);
    expect(stored.single.status, SessionStatus.discarded);

    // DayEntry was created at check-in time (empty placeholder) but should
    // reflect zero worked hours since the only session was discarded.
    final dayEntry = await db.dayEntryDao.forDate(day);
    expect(dayEntry?.netWorkedHours, 0);

    final auditEntries = await db.auditLogDao.forEntity('WorkSession', active.id);
    expect(auditEntries.any((e) => e.action == 'discard'), isTrue);
  });

  test('a vacation leave day sets balance delta to leave minus target', () async {
    final day = DateTime(2026, 8, 11); // Tuesday, work day

    await leave.addLeave(date: day, type: LeaveType.vacation, hours: 8);

    final dayEntry = await db.dayEntryDao.forDate(day);
    expect(dayEntry?.leaveHours, 8);
    expect(dayEntry?.targetHours, 8);
    expect(dayEntry?.balanceDelta, 0);
  });

  test('a settings change retroactively updates existing days\' targets', () async {
    // Wednesday -- after the original (Monday-effective) settings row, so a
    // second, more-recent row can cleanly supersede it for this date
    // without tying on `effectiveFrom`.
    final day = DateTime(2026, 8, 12);
    await sessions.checkIn(day.add(const Duration(hours: 8)));
    final active = await sessions.activeSession();
    await sessions.checkOut(
      sessionId: active!.id,
      at: day.add(const Duration(hours: 16)), // 8h gross
    );

    final before = await db.dayEntryDao.forDate(day);
    // 8h gross, single session, no gap -> 30 min synthetic break -> 7.5h net.
    expect(before?.netWorkedHours, 7.5);
    expect(before?.targetHours, 8.0);
    expect(before?.balanceDelta, -0.5);

    // A new settings version, effective from Tuesday -- more recent than
    // the original (Monday) row, so it wins for Wednesday and retroactively
    // changes that already-recorded day's target.
    await settings.save(
      effectiveFrom: DateTime(2026, 8, 11),
      weeklyHours: 20,
      workDays: const [1, 2, 3, 4, 5],
      minSessionMinutes: 5,
      autoBreakEnabled: true,
      restrictCheckin: false,
    );

    final after = await db.dayEntryDao.forDate(day);
    // Net worked hours is unaffected by the target change -- only the
    // target (and so the delta) should move.
    expect(after?.netWorkedHours, 7.5);
    expect(after?.targetHours, 4.0);
    expect(after?.balanceDelta, 3.5);
  });

  test('seeding a holiday creates a DayEntry with zero target on a work day', () async {
    final christmas = DateTime(2026, 12, 25); // a Friday in 2026, a work day
    await holidays.setHoliday(date: christmas, name: '1. Weihnachtstag');

    final dayEntry = await db.dayEntryDao.forDate(christmas);
    expect(dayEntry, isNotNull);
    expect(dayEntry!.targetHours, 0);
    expect(dayEntry.balanceDelta, 0);
  });

  test('balance carries forward across multiple days including a missed workday', () async {
    final monday = DateTime(2026, 8, 10);
    final tuesday = DateTime(2026, 8, 11);
    final wednesday = DateTime(2026, 8, 12);

    // Monday: worked exactly the target, no deficit.
    await sessions.checkIn(monday.add(const Duration(hours: 8)));
    var active = await sessions.activeSession();
    await sessions.checkOut(
      sessionId: active!.id,
      at: monday.add(const Duration(hours: 16)),
    );

    // Tuesday: nothing recorded at all (missed workday).
    // Wednesday: an explicit vacation day.
    await leave.addLeave(date: wednesday, type: LeaveType.vacation, hours: 8);

    final mondaySnapshot = await db.balanceSnapshotDao.forDate(monday);
    final tuesdaySnapshot = await db.balanceSnapshotDao.forDate(tuesday);
    final wednesdaySnapshot = await db.balanceSnapshotDao.forDate(wednesday);

    expect(mondaySnapshot, isNotNull);
    expect(tuesdaySnapshot?.balance, mondaySnapshot!.balance - 8.0); // missed workday
    expect(wednesdaySnapshot?.balance, tuesdaySnapshot!.balance); // vacation exactly covers target
  });
}
