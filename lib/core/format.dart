import 'package:intl/intl.dart';

/// Formatting helpers shared across screens — hours-as-double (the unit used
/// throughout the domain/data layers) rendered as clock-style H:MM or H:MM:SS
/// strings, matching the design's number treatment (`5:42 of 7:54`, `+12:45`,
/// `2:34:12`).
///
/// Clock times are 24-hour on purpose: they are read in lists next to each
/// other, and `08:05` aligns with `18:41` where `8:05 AM` does not.
class AppFormat {
  AppFormat._();

  static String hm(double hours, {bool signed = false}) {
    final sign = hours < 0 ? '−' : (signed ? '+' : '');
    final totalMinutes = (hours.abs() * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '$sign$h:${m.toString().padLeft(2, '0')}';
  }

  /// Renders a target-hours figure (e.g. weekly hours) without a false
  /// trailing ".0" for whole numbers, but keeping halves like "39.5h".
  static String hoursLabel(double hours) {
    final isWhole = hours == hours.roundToDouble();
    return isWhole ? '${hours.round()} h' : '${hours.toStringAsFixed(1)} h';
  }

  static String hms(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static final _headerDate = DateFormat('EEE d MMM');
  static final _dayRow = DateFormat('EEE d MMM');
  static final _time = DateFormat('HH:mm');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _monthName = DateFormat('MMMM');
  static final _monthAbbrev = DateFormat('MMM');

  static String headerDate(DateTime d) => _headerDate.format(d);
  static String dayRow(DateTime d) => _dayRow.format(d);
  static String time(DateTime d) => _time.format(d);

  /// `08:00`, from minutes since midnight — the shape the work window is
  /// stored in, so it never has to be turned into a DateTime just to be read.
  static String minutesOfDay(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static String monthYear(DateTime d) => _monthYear.format(d);
  static String monthName(DateTime d) => _monthName.format(d);

  /// `Sep`, for a date block that already sits under its year.
  static String monthAbbrev(DateTime d) => _monthAbbrev.format(d);

  /// `14 Sep`, for a button that says where you are about to land.
  static String dayAndMonth(DateTime d) => _dayAndMonth.format(d);

  static final _dayAndMonth = DateFormat('d MMM');

  /// `21–27 Sep 2026`, or `28 Sep – 4 Oct 2026` when the week straddles two
  /// months. En dash, no spaces around it unless both sides carry a month.
  static String weekRange(DateTime start, DateTime end) {
    final endFmt = DateFormat('d MMM yyyy');
    if (start.month == end.month && start.year == end.year) {
      return '${start.day}–${endFmt.format(end)}';
    }
    return '${DateFormat('d MMM').format(start)} – ${endFmt.format(end)}';
  }

  /// `21–27 Sep`, for a row that sits under a header already naming the year.
  static String weekRangeShort(DateTime start, DateTime end) {
    final endFmt = DateFormat('d MMM');
    if (start.month == end.month) return '${start.day}–${endFmt.format(end)}';
    return '${endFmt.format(start)} – ${endFmt.format(end)}';
  }
}
