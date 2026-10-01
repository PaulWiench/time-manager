import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/vacation_bookings.dart';

void main() {
  VacationDay d(int month, int day, String? id, [double days = 1]) =>
      VacationDay(date: DateTime(2026, month, day), vacationId: id, days: days);

  final bookings = groupVacations(
    [
      d(6, 5, 'a'),
      d(7, 17, 'b'),
      d(7, 20, 'b'),
      d(10, 26, 'c'),
      d(10, 27, 'c', 0.5),
      d(4, 7, null),
      d(1, 2, null),
    ],
    names: {'b': 'Sommer', 'c': 'Herbstferien'},
    today: DateTime(2026, 10, 1, 19),
  );

  test('planned first, then taken newest first, ungrouped days on their own', () {
    expect(bookings.map((b) => b.name ?? b.first.toIso8601String().substring(5, 10)),
        ['Herbstferien', 'Sommer', '06-05', '04-07', '01-02']);
    expect(bookings.first.planned, isTrue);
    expect(bookings[1].planned, isFalse);
    expect(bookings[3].isUngrouped, isTrue);
  });

  test('a booking adds up its days and knows each day\'s place in it', () {
    final autumn = bookings.first;
    expect(autumn.days, 1.5);
    expect(autumn.first, DateTime(2026, 10, 26));
    expect(autumn.last, DateTime(2026, 10, 27));
    expect(bookings[1].dayNumber(DateTime(2026, 7, 20)), 2);
  });
}
