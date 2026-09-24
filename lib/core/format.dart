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

  static String headerDate(DateTime d) => _headerDate.format(d);
  static String dayRow(DateTime d) => _dayRow.format(d);
  static String time(DateTime d) => _time.format(d);
  static String monthYear(DateTime d) => _monthYear.format(d);

  /// `21–27 Sep 2026`, or `28 Sep – 4 Oct 2026` when the week straddles two
  /// months. En dash, no spaces around it unless both sides carry a month.
  static String weekRange(DateTime start, DateTime end) {
    final endFmt = DateFormat('d MMM yyyy');
    if (start.month == end.month && start.year == end.year) {
      return '${start.day}–${endFmt.format(end)}';
    }
    return '${DateFormat('d MMM').format(start)} – ${endFmt.format(end)}';
  }
}
