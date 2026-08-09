import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'converters.dart';
import 'enums.dart';

/// A single clock-in/clock-out event. See Data Model § WorkSession.
///
/// `date` FKs to [DayEntries.date] — callers must upsert the DayEntry for
/// that date in the same transaction before inserting a session, since
/// DayEntry rows are created lazily (Data Model § Design Principles).
class WorkSessions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  DateTimeColumn get date => dateTime().references(DayEntries, #date)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get status => textEnum<SessionStatus>()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// A break within a day — real (derived from a session gap), synthetic
/// (auto-inserted by the ArbZG break logic), or manual. See Data Model §
/// BreakEntry.
class BreakEntries extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  DateTimeColumn get date => dateTime().references(DayEntries, #date)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get type => textEnum<BreakType>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Leave on a specific day (a day can have both sessions and leave — partial
/// days). See Data Model § LeaveEntry.
class LeaveEntries extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  DateTimeColumn get date => dateTime().references(DayEntries, #date)();
  TextColumn get type => textEnum<LeaveType>()();
  RealColumn get hours => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Known public holidays, auto-loaded for Germany and user-editable. Not FK'd
/// to DayEntries — holidays exist independently and only cause a DayEntry to
/// be created via the recalculation trigger rules, not a hard DB constraint.
/// See Data Model § PublicHoliday.
class PublicHolidays extends Table {
  DateTimeColumn get date => dateTime()();
  TextColumn get name => text()();
  RealColumn get fraction => real().withDefault(const Constant(1.0))();
  TextColumn get source => textEnum<HolidaySource>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {date};
}

/// Aggregate cache for a single calendar date, recalculated whenever any
/// child entity changes. See Data Model § DayEntry.
class DayEntries extends Table {
  DateTimeColumn get date => dateTime()();
  RealColumn get netWorkedHours => real().withDefault(const Constant(0))();
  RealColumn get leaveHours => real().withDefault(const Constant(0))();
  RealColumn get targetHours => real().withDefault(const Constant(0))();
  RealColumn get balanceDelta => real().withDefault(const Constant(0))();
  BoolColumn get autoBreakOverridden =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {date};
}

/// Running hour balance up to and including each date. See Data Model §
/// BalanceSnapshot.
class BalanceSnapshots extends Table {
  DateTimeColumn get date => dateTime()();
  RealColumn get balance => real()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {date};
}

/// One row per calendar year of vacation entitlement/rollover. See Data
/// Model § VacationQuota.
class VacationQuotas extends Table {
  IntColumn get year => integer()();
  RealColumn get totalDays => real().withDefault(const Constant(30))();
  RealColumn get rolloverDays => real().withDefault(const Constant(0))();
  DateTimeColumn get rolloverDeadline => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {year};
}

/// Versioned settings — a new row per change, with an `effectiveFrom` date.
/// The active row for any given date is the one with the highest
/// `effectiveFrom` that is <= that date. Named `AppSettings` (not
/// `Settings`) to avoid clashing with framework-level naming. See Data
/// Model § Settings.
class AppSettings extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  DateTimeColumn get effectiveFrom =>
      dateTime().withDefault(currentDateAndTime)();
  RealColumn get weeklyHours => real().withDefault(const Constant(40))();

  /// ISO-8601 weekday numbers (1=Mon..7=Sun), default Mon-Fri.
  TextColumn get workDays => text()
      .withDefault(const Constant('1,2,3,4,5'))
      .map(const WeekdayListConverter())();
  IntColumn get minSessionMinutes =>
      integer().withDefault(const Constant(5))();
  BoolColumn get autoBreakEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get restrictCheckin =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Immutable record of every user and system action. `action` is a plain
/// string (not a Dart enum) since the Data Model lists it as open-ended
/// ("create, update, delete, ... , balance_edit, …"). See Data Model §
/// AuditLogEntry.
class AuditLogEntries extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();

  /// JSON-encoded snapshot of the entity before/after the change.
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
