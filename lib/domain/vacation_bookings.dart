/// Vacation days grouped back into the bookings they were made as, for the
/// leave list (additions handoff §4.2) and History's "day 6 of 11" labels.
library;

import 'date_only.dart';

/// One leave day as far as grouping cares.
class VacationDay {
  const VacationDay({required this.date, required this.vacationId, required this.days});

  final DateTime date;

  /// The booking it belongs to; null for a day written before bookings
  /// existed and never grouped (each such day is its own row).
  final String? vacationId;

  /// What the day is worth against the quota (1, ½, …).
  final double days;
}

class VacationBooking {
  const VacationBooking({
    required this.id,
    required this.name,
    required this.first,
    required this.last,
    required this.days,
    required this.dates,
    required this.planned,
  });

  /// The booking's id, or `day:<iso date>` for an ungrouped day.
  final String id;
  final String? name;
  final DateTime first;
  final DateTime last;
  final double days;
  final List<DateTime> dates;

  /// Starts after today — booked, not yet taken.
  final bool planned;

  bool get isUngrouped => id.startsWith('day:');

  /// 1-based position of [date] among the booking's days, for "day 6 of 11".
  int dayNumber(DateTime date) => dates.indexOf(dateOnly(date)) + 1;
}

/// Groups [days] by booking. Planned ones first, soonest first; then taken
/// ones, newest first — what is coming up matters more than what is done.
List<VacationBooking> groupVacations(
  List<VacationDay> days, {
  required Map<String, String?> names,
  required DateTime today,
}) {
  final byId = <String, List<VacationDay>>{};
  for (final day in days) {
    final key = day.vacationId ?? 'day:${dateOnly(day.date).toIso8601String()}';
    byId.putIfAbsent(key, () => []).add(day);
  }

  final todayDate = dateOnly(today);
  final bookings = [
    for (final MapEntry(key: id, value: group) in byId.entries)
      () {
        final dates = [for (final d in group) dateOnly(d.date)]..sort();
        return VacationBooking(
          id: id,
          name: names[id],
          first: dates.first,
          last: dates.last,
          days: group.fold(0.0, (sum, d) => sum + d.days),
          dates: dates,
          planned: dates.first.isAfter(todayDate),
        );
      }(),
  ];

  bookings.sort((a, b) {
    if (a.planned != b.planned) return a.planned ? -1 : 1;
    return a.planned ? a.first.compareTo(b.first) : b.first.compareTo(a.first);
  });
  return bookings;
}
