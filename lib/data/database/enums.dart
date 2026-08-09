/// Enum columns per the Data Model doc. `AuditAction` is deliberately a plain
/// string column instead (see AuditLogEntries in tables.dart) since the doc
/// lists it with a trailing "…" — open-ended, not a closed set.
library;

enum SessionStatus { active, completed, discarded, autoStopped }

enum BreakType { real, synthetic, manual }

enum LeaveType { vacation, sick, flexDay }

enum HolidaySource { auto, manual }
