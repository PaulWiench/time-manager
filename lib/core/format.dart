import 'package:intl/intl.dart';

/// Formatting helpers shared across screens — hours-as-double (the unit
/// used throughout the domain/data layers) rendered as clock-style H:MM or
/// H:MM:SS strings, matching the design handoff's number treatment
/// (`5:42 / 8:00`, `+12:45`, `2:34:12`).
class AppFormat {
  AppFormat._();

  static String hm(double hours, {bool signed = false}) {
    final sign = hours < 0 ? '−' : (signed ? '+' : '');
    final totalMinutes = (hours.abs() * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '$sign$h:${m.toString().padLeft(2, '0')}';
  }

  static String hms(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static final _headerDate = DateFormat('EEEE, MMM d');
  static final _dayRow = DateFormat('EEE, MMM d');
  static final _time = DateFormat('h:mm a');
  static final _monthYear = DateFormat('MMMM yyyy');

  static String headerDate(DateTime d) => _headerDate.format(d);
  static String dayRow(DateTime d) => _dayRow.format(d);
  static String time(DateTime d) => _time.format(d);
  static String monthYear(DateTime d) => _monthYear.format(d);

  static String weekRange(DateTime start, DateTime end) {
    final sameMonth = start.month == end.month;
    final startFmt = DateFormat(sameMonth ? 'MMM d' : 'MMM d');
    final endFmt = DateFormat('MMM d, yyyy');
    return '${startFmt.format(start)}–${endFmt.format(end)}';
  }
}
