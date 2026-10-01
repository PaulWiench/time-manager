import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'converters.dart';
import 'enums.dart';

/// An employment the hours belong to. Jobs may overlap in time, and each keeps
/// its own schedule (versioned [AppSettings] rows), balance (its own
/// [BalanceSnapshots]) and vacation quota. Everything per-day — sessions,
/// breaks, leave, day entries — carries the job it belongs to.
///
/// Schema v4. The database the phone had before then becomes job 1, whose
/// start is the first settings row's `effectiveFrom`.
class Jobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Date-only. Days before it are not this job's: no target, no shortfall.
  DateTimeColumn get startDate => dateTime()();

  /// Date-only, inclusive — the last working day. Null while the job runs.
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// One booking of vacation: the leave days written together, under an
/// optional name ("Sommer an der Ostsee"). Renaming a vacation renames every
/// day in it at once, because the name lives here and not on the days.
class Vacations extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  IntColumn get jobId => integer().references(Jobs, #id)();
  TextColumn get name => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Small app-wide choices that are not settings history — which job Home,
/// History and Stats are showing. Key/value, so the next one needs no
/// migration.
class AppPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// Every per-job table's `jobId` defaults to 1 on purpose: the home-screen
// widget writes to this database directly from Kotlin, and a widget build
// that does not know about jobs must still land its check-in somewhere valid
// (job 1, the job every pre-v4 row belongs to) rather than fail NOT NULL.

/// A single clock-in/clock-out event. See Data Model § WorkSession.
///
/// `date` FKs to [DayEntries.date] — callers must upsert the DayEntry for
/// that date in the same transaction before inserting a session, since
/// DayEntry rows are created lazily (Data Model § Design Principles).
class WorkSessions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  IntColumn get jobId =>
      integer().withDefault(const Constant(1)).references(Jobs, #id)();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get status => textEnum<SessionStatus>()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [_dayEntryForeignKey];
}

/// A day is now (job, date), so the children point at both halves of it.
const _dayEntryForeignKey =
    'FOREIGN KEY (job_id, date) REFERENCES day_entries (job_id, date)';

/// A break within a day — real (derived from a session gap), synthetic
/// (auto-inserted by the ArbZG break logic), or manual. See Data Model §
/// BreakEntry.
class BreakEntries extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  IntColumn get jobId =>
      integer().withDefault(const Constant(1)).references(Jobs, #id)();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get type => textEnum<BreakType>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [_dayEntryForeignKey];
}

/// Leave on a specific day (a day can have both sessions and leave — partial
/// days). See Data Model § LeaveEntry.
class LeaveEntries extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  IntColumn get jobId =>
      integer().withDefault(const Constant(1)).references(Jobs, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => textEnum<LeaveType>()();
  RealColumn get hours => real()();
  TextColumn get notes => text().nullable()();

  /// The booking this day belongs to. Vacation only; null for sick and flex
  /// days, which are not named.
  TextColumn get vacationId => text().nullable().references(Vacations, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [_dayEntryForeignKey];
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
  IntColumn get jobId =>
      integer().withDefault(const Constant(1)).references(Jobs, #id)();
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
  Set<Column> get primaryKey => {jobId, date};
}

/// Running hour balance up to and including each date. See Data Model §
/// BalanceSnapshot.
class BalanceSnapshots extends Table {
  IntColumn get jobId =>
      integer().withDefault(const Constant(1)).references(Jobs, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get balance => real()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {jobId, date};
}

/// One row per calendar year of vacation entitlement/rollover. See Data
/// Model § VacationQuota.
class VacationQuotas extends Table {
  IntColumn get jobId =>
      integer().withDefault(const Constant(1)).references(Jobs, #id)();
  IntColumn get year => integer()();
  RealColumn get totalDays => real().withDefault(const Constant(30))();
  RealColumn get rolloverDays => real().withDefault(const Constant(0))();
  DateTimeColumn get rolloverDeadline => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {jobId, year};
}

/// Versioned settings — a new row per change, with an `effectiveFrom` date.
/// The active row for any given date is the one with the highest
/// `effectiveFrom` that is <= that date. Named `AppSettings` (not
/// `Settings`) to avoid clashing with framework-level naming. See Data
/// Model § Settings.
class AppSettings extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Settings are versioned per job. The handful that apply to every job
  /// (auto-break, minimum session, restrict check-in) are written to each
  /// job's next row together, so every job's history stays complete.
  IntColumn get jobId =>
      integer().withDefault(const Constant(1)).references(Jobs, #id)();
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

  /// Normal working hours, as minutes since midnight, so they compare directly
  /// against `TimeOfDayWindow` (lib/domain/midnight_cutoff.dart) without a
  /// Flutter `TimeOfDay` reaching the data layer.
  ///
  /// This is not the same question as [restrictCheckin], which is about
  /// refusing a check-in and is still deliberately unarmed. This window answers
  /// "is it still the working day?", and the balance uses it to tell an idle
  /// gap that means *finished for the day* from one that means *stepped out*.
  /// 08:00–18:00 by default — wide enough that an ordinary long lunch is never
  /// mistaken for the end of the day.
  IntColumn get workWindowStartMinutes =>
      integer().withDefault(const Constant(8 * 60))();
  IntColumn get workWindowEndMinutes =>
      integer().withDefault(const Constant(18 * 60))();

  /// Null means "not configured" — which has to stay representable, because
  /// the warning treatment must not fire for a bound the user never set.
  RealColumn get balanceFloorHours => real().nullable()();
  RealColumn get balanceCapHours => real().nullable()();
  BoolColumn get balanceAnnualReset =>
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
