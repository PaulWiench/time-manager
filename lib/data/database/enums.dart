/// Enum columns per the Data Model doc. `AuditAction` is deliberately a plain
/// string column instead (see AuditLogEntries in tables.dart) since the doc
/// lists it with a trailing "…" — open-ended, not a closed set.
library;

enum SessionStatus { active, completed, discarded, autoStopped }

enum BreakType { real, synthetic, manual }

enum LeaveType { vacation, sick, flexDay }

/// `removed` is a tombstone, not a source: seeding skips dates that already
/// have a row, so a deleted auto holiday would otherwise come back on the
/// next launch. Queries filter it out; the row exists only to be seen by
/// [PublicHolidayRepository.seedYear].
enum HolidaySource { auto, manual, removed }
