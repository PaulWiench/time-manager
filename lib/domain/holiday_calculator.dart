/// German public holidays, computed deterministically instead of pulled
/// from a package — see Tech Stack § notable technical decisions. Movable
/// feasts are derived from Easter Sunday via the corrected Gauss algorithm
/// (including the 1954/1981 exception-day correction terms it's known for
/// needing). Only the 9 holidays observed nationwide in every German state
/// are included; state-specific holidays (e.g. Bavaria's Fronleichnam) are
/// out of scope for v1 per Requirements § Out of Scope, and holidays are
/// "fully editable by the user" regardless (Requirements § 4).
library;

class HolidaySeed {
  final DateTime date;
  final String name;

  const HolidaySeed({required this.date, required this.name});
}

/// Easter Sunday for [year] via the corrected Gauss algorithm. Valid for
/// the Gregorian calendar (1583 onward).
DateTime gaussEasterSunday(int year) {
  final a = year % 19;
  final b = year % 4;
  final c = year % 7;
  final k = year ~/ 100;
  final p = (13 + 8 * k) ~/ 25;
  final q = k ~/ 4;
  final m = (15 - p + k - q) % 30;
  final n = (4 + k - q) % 7;
  final d = (19 * a + m) % 30;
  final e = (2 * b + 4 * c + 6 * d + n) % 7;

  var day = 22 + d + e;
  var month = 3;
  if (day > 31) {
    month = 4;
    day -= 31;
  }

  // Known exceptions to the base formula.
  if (month == 4 && day == 26) {
    day = 19;
  } else if (month == 4 && day == 25 && d == 28 && e == 6 && a > 10) {
    day = 18;
  }

  return DateTime(year, month, day);
}

/// The 9 German public holidays observed nationwide, for [year].
List<HolidaySeed> germanNationalHolidays(int year) {
  final easter = gaussEasterSunday(year);

  return [
    HolidaySeed(date: DateTime(year, 1, 1), name: 'Neujahr'),
    HolidaySeed(
      date: easter.subtract(const Duration(days: 2)),
      name: 'Karfreitag',
    ),
    HolidaySeed(
      date: easter.add(const Duration(days: 1)),
      name: 'Ostermontag',
    ),
    HolidaySeed(date: DateTime(year, 5, 1), name: 'Tag der Arbeit'),
    HolidaySeed(
      date: easter.add(const Duration(days: 39)),
      name: 'Christi Himmelfahrt',
    ),
    HolidaySeed(
      date: easter.add(const Duration(days: 50)),
      name: 'Pfingstmontag',
    ),
    HolidaySeed(
      date: DateTime(year, 10, 3),
      name: 'Tag der Deutschen Einheit',
    ),
    HolidaySeed(date: DateTime(year, 12, 25), name: '1. Weihnachtstag'),
    HolidaySeed(date: DateTime(year, 12, 26), name: '2. Weihnachtstag'),
  ];
}
