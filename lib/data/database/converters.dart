import 'package:drift/drift.dart';

/// Stores a list of ISO-8601 weekday numbers (1 = Monday .. 7 = Sunday) as a
/// comma-separated string. Used for `AppSettings.workDays`.
class WeekdayListConverter extends TypeConverter<List<int>, String> {
  const WeekdayListConverter();

  @override
  List<int> fromSql(String fromDb) =>
      fromDb.isEmpty ? const [] : fromDb.split(',').map(int.parse).toList();

  @override
  String toSql(List<int> value) => value.join(',');
}
