/// Short constructors for the database's row types.
///
/// The generated data classes want every column named, including bookkeeping
/// ones no test cares about. These fill in the boring fields so a fixture can
/// say what it means — "a session from 08:05 to 12:00" — and so the render
/// fixtures go through the real view-model builders rather than hand-writing
/// the answers those builders are supposed to produce.
library;

import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';

final _epoch = DateTime(2026);

AppSetting settingsRow({
  double weeklyHours = 39.5,
  List<int> workDays = const [1, 2, 3, 4, 5],
  bool autoBreakEnabled = true,
  bool restrictCheckin = false,
  int workWindowStartMinutes = 8 * 60,
  int workWindowEndMinutes = 18 * 60,
  double? balanceFloorHours,
  double? balanceCapHours,
  bool balanceAnnualReset = false,
}) =>
    AppSetting(
      id: 'settings',
      effectiveFrom: _epoch,
      weeklyHours: weeklyHours,
      workDays: workDays,
      minSessionMinutes: 5,
      autoBreakEnabled: autoBreakEnabled,
      restrictCheckin: restrictCheckin,
      workWindowStartMinutes: workWindowStartMinutes,
      workWindowEndMinutes: workWindowEndMinutes,
      balanceFloorHours: balanceFloorHours,
      balanceCapHours: balanceCapHours,
      balanceAnnualReset: balanceAnnualReset,
      createdAt: _epoch,
    );

DayEntry dayEntryRow({
  required DateTime date,
  double netWorkedHours = 0,
  double leaveHours = 0,
  double targetHours = 7.9,
  double balanceDelta = 0,
  bool autoBreakOverridden = false,
  String? notes,
}) =>
    DayEntry(
      date: date,
      netWorkedHours: netWorkedHours,
      leaveHours: leaveHours,
      targetHours: targetHours,
      balanceDelta: balanceDelta,
      autoBreakOverridden: autoBreakOverridden,
      notes: notes,
      updatedAt: date,
    );

WorkSession sessionRow({
  String id = 'session',
  required DateTime start,
  DateTime? end,
  SessionStatus status = SessionStatus.completed,
  String? notes,
}) =>
    WorkSession(
      id: id,
      date: DateTime(start.year, start.month, start.day),
      startTime: start,
      endTime: end,
      status: status,
      notes: notes,
      createdAt: start,
      updatedAt: start,
    );

BreakEntry breakRow({
  String id = 'break',
  required DateTime start,
  required DateTime end,
  BreakType type = BreakType.synthetic,
}) =>
    BreakEntry(
      id: id,
      date: DateTime(start.year, start.month, start.day),
      startTime: start,
      endTime: end,
      type: type,
      createdAt: start,
      updatedAt: start,
    );

LeaveEntry leaveRow({
  String id = 'leave',
  required DateTime date,
  LeaveType type = LeaveType.vacation,
  required double hours,
  String? notes,
}) =>
    LeaveEntry(
      id: id,
      date: date,
      type: type,
      hours: hours,
      notes: notes,
      createdAt: date,
      updatedAt: date,
    );

BalanceSnapshot balanceRow({required DateTime date, required double balance}) =>
    BalanceSnapshot(date: date, balance: balance, updatedAt: date);

PublicHoliday holidayRow({
  required DateTime date,
  required String name,
  double fraction = 1.0,
  HolidaySource source = HolidaySource.auto,
}) =>
    PublicHoliday(
      date: date,
      name: name,
      fraction: fraction,
      source: source,
      createdAt: _epoch,
    );

AuditLogEntry auditRow({
  required DateTime timestamp,
  required String action,
  required String entityType,
  String? entityId,
}) =>
    AuditLogEntry(
      id: '$action-$entityType-${timestamp.toIso8601String()}',
      timestamp: timestamp,
      action: action,
      entityType: entityType,
      entityId: entityId,
    );
