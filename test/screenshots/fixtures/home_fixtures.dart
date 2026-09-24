/// The six designed Home states (handoff §4.2), as real data.
///
/// Each one goes through `buildHomeView` rather than hand-writing the strings
/// the builder is supposed to produce — so if the derivation drifts, the render
/// shows it. The numbers are the design's own, which makes the renders directly
/// comparable to `home-a-tracking` and its siblings.
library;

import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/features/home/home_view.dart';

import '../../fixtures/rows.dart';

/// Tuesday 22 September 2026, the day every render was drawn for. The target
/// is 7:54 — 39.5 hours over five days.
final today = DateTime(2026, 9, 22);
DateTime at(int hour, int minute) => DateTime(2026, 9, 22, hour, minute);

const _target = 7.9; // 7:54
const _balance = -15.9667; // −15:58

/// (a) Tracking at 16:37, an hour and three quarters into the afternoon.
HomeView tracking() => buildHomeView(
      now: at(16, 37),
      settings: settingsRow(),
      dayEntry: dayEntryRow(date: today, netWorkedHours: 3.9, targetHours: _target),
      sessions: [
        sessionRow(id: 'a', start: at(9, 0), end: at(12, 52)),
        sessionRow(id: 'b', start: at(14, 51), status: SessionStatus.active),
      ],
      breaks: const [],
      leave: const [],
      balance: balanceRow(date: today, balance: _balance),
    );

/// (b) On break at 13:05, twenty-eight minutes after checking out.
HomeView onBreak() => buildHomeView(
      now: at(13, 5),
      settings: settingsRow(),
      dayEntry: dayEntryRow(date: today, netWorkedHours: 3.9, targetHours: _target),
      sessions: [sessionRow(id: 'a', start: at(8, 43), end: at(12, 37))],
      breaks: const [],
      leave: const [],
      balance: balanceRow(date: today, balance: _balance),
    );

/// (c) Checked out at 19:20, having hit the target exactly.
HomeView checkedOut() => buildHomeView(
      now: at(19, 20),
      settings: settingsRow(),
      dayEntry: dayEntryRow(date: today, netWorkedHours: _target, targetHours: _target),
      sessions: [
        sessionRow(id: 'a', start: at(8, 42), end: at(12, 0)),
        sessionRow(id: 'b', start: at(12, 30), end: at(18, 51)),
      ],
      breaks: [breakRow(start: at(12, 0), end: at(12, 30))],
      leave: const [],
      balance: balanceRow(date: today, balance: _balance),
    );

/// (d) 07:58, nothing logged. The slab still carries the real balance.
HomeView empty() => buildHomeView(
      now: at(7, 58),
      settings: settingsRow(),
      dayEntry: dayEntryRow(date: today, targetHours: _target),
      sessions: const [],
      breaks: const [],
      leave: const [],
      balance: balanceRow(date: today, balance: _balance),
    );

/// (e) 20:09 and still going: the ring has lapped past the target.
HomeView overtime() => buildHomeView(
      now: at(20, 9),
      settings: settingsRow(),
      dayEntry: dayEntryRow(date: today, netWorkedHours: 3.9, targetHours: _target),
      sessions: [
        sessionRow(id: 'a', start: at(9, 0), end: at(12, 52)),
        sessionRow(id: 'b', start: at(14, 51), status: SessionStatus.active),
      ],
      breaks: const [],
      leave: const [],
      balance: balanceRow(date: today, balance: _balance),
    );

/// (f) A closed day whose balance has fallen past a floor the user set.
HomeView warning() => buildHomeView(
      now: at(19, 20),
      settings: settingsRow(balanceFloorHours: -20),
      dayEntry: dayEntryRow(date: today, netWorkedHours: _target, targetHours: _target),
      sessions: [
        sessionRow(id: 'a', start: at(8, 42), end: at(12, 0)),
        sessionRow(id: 'b', start: at(12, 30), end: at(18, 51)),
      ],
      breaks: [breakRow(start: at(12, 0), end: at(12, 30))],
      leave: const [],
      balance: balanceRow(date: today, balance: -20.6833), // −20:41
    );

/// A day that was partly leave, to exercise the rail's hatched block and the
/// leave chip. Not one of the design's six, but the only way that pair of
/// states is ever seen.
HomeView partialLeave() => buildHomeView(
      now: at(17, 30),
      settings: settingsRow(),
      dayEntry: dayEntryRow(
        date: today,
        netWorkedHours: 3.9,
        leaveHours: 4.0,
        targetHours: _target,
      ),
      sessions: [sessionRow(id: 'a', start: at(8, 30), end: at(12, 24))],
      breaks: const [],
      leave: [leaveRow(date: today, hours: 4, type: LeaveType.vacation)],
      balance: balanceRow(date: today, balance: _balance),
    );
