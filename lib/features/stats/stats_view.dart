/// What Stats says above each chart.
///
/// Every card leads with a sentence and a number; the plot is the evidence.
/// Those sentences are decided here, from the same aggregates the charts draw,
/// so a card can never headline one thing and plot another.
library;

import '../../core/format.dart';
import '../../domain/stats_aggregation.dart';

enum StatsTab { overview, patterns, leave }

enum StatsRange { week, month, sixMonths, year, custom }

extension StatsRangeLabels on StatsRange {
  /// The chip, which has a fifth of a 361 dp row to live in.
  String get short => switch (this) {
        StatsRange.week => '1W',
        StatsRange.month => '1M',
        StatsRange.sixMonths => '6M',
        StatsRange.year => '1Y',
        StatsRange.custom => 'Custom',
      };

  /// What a screen reader says instead.
  String get spoken => switch (this) {
        StatsRange.week => 'Week',
        StatsRange.month => 'Month',
        StatsRange.sixMonths => '6 months',
        StatsRange.year => 'Year',
        StatsRange.custom => 'Custom',
      };

  int? get trailingDays => switch (this) {
        StatsRange.week => 7,
        StatsRange.month => 30,
        StatsRange.sixMonths => 182,
        StatsRange.year => 365,
        StatsRange.custom => null,
      };
}

/// A card's three-line header. A null [value] means there is not enough data
/// in this range, and the card shows its empty block instead.
class CardHeader {
  const CardHeader({this.value, this.unit, this.caption});

  final String? value;
  final String? unit;
  final String? caption;

  static const empty = CardHeader();
}

/// One point on the balance trend.
class BalancePoint {
  const BalancePoint({required this.date, required this.balance});
  final DateTime date;
  final double balance;
}

// ---------------------------------------------------------------------------
// Overview.
// ---------------------------------------------------------------------------

class OverviewData {
  const OverviewData({
    required this.balance,
    required this.weeks,
    required this.today,
  });

  final List<BalancePoint> balance;
  final List<WeekStat> weeks;
  final DateTime today;

  /// The balance as it stands, and how far it moved inside this range.
  CardHeader get balanceHeader {
    if (balance.length < 2) return CardHeader.empty;
    final change = balance.last.balance - balance.first.balance;
    return CardHeader(
      value: AppFormat.hm(balance.last.balance, signed: true),
      unit: 'h',
      caption: '${AppFormat.hm(change, signed: true)} over this range',
    );
  }

  CardHeader get hitRateHeader {
    if (weeks.isEmpty) return CardHeader.empty;
    final hit = weeks.where((w) => w.hitTarget).length;
    return CardHeader(
      value: '${(hit / weeks.length * 100).round()}',
      unit: '%',
      caption: '$hit of ${weeks.length} weeks hit target',
    );
  }

  /// How fast the balance is moving, per week — which is the number that says
  /// whether the trend above is a blip or a habit.
  CardHeader get overtimeRateHeader {
    if (weeks.isEmpty) return CardHeader.empty;
    final average =
        weeks.fold<double>(0, (sum, w) => sum + w.balanceDelta) / weeks.length;
    return CardHeader(
      value: AppFormat.hm(average, signed: true),
      unit: 'h / wk',
      caption: 'Average weekly balance change',
    );
  }
}

// ---------------------------------------------------------------------------
// Patterns.
// ---------------------------------------------------------------------------

class PatternsData {
  const PatternsData({
    required this.month,
    required this.monthDays,
    required this.leaveDays,
    required this.days,
    required this.weekdayAverages,
    required this.checkinHistogram,
    required this.checkins,
    required this.today,
  });

  /// The heatmap steps through calendar months on its own, independent of the
  /// range chips: a flattened six-month window does not lay out as a calendar.
  final DateTime month;
  final List<DayStat> monthDays;
  final Set<DateTime> leaveDays;

  final List<DayStat> days;
  final List<double> weekdayAverages;

  /// Length 24, counting each day's *first* check-in only.
  final List<int> checkinHistogram;

  final CheckinSummary checkins;
  final DateTime today;

  CardHeader get heatmapHeader {
    final worked = monthDays.where((d) => d.netWorkedHours > 0).toList();
    if (worked.isEmpty) return CardHeader.empty;
    final total = worked.fold<double>(0, (sum, d) => sum + d.netWorkedHours);
    final isCurrentMonth = month.year == today.year && month.month == today.month;
    return CardHeader(
      value: AppFormat.hm(total),
      unit: 'h',
      caption: '${AppFormat.monthName(month)}${isCurrentMonth ? ' so far' : ''} · '
          '${worked.length} workdays',
    );
  }

  CardHeader get dailyHoursHeader {
    final worked = days.where((d) => d.netWorkedHours > 0).toList();
    if (worked.length < 2) return CardHeader.empty;
    final average =
        worked.fold<double>(0, (sum, d) => sum + d.netWorkedHours) / worked.length;
    return CardHeader(
      value: AppFormat.hm(average),
      unit: 'h / day',
      caption: 'Average on workdays',
    );
  }

  /// Which weekday is the long one. Naming it is the whole point of the chart.
  CardHeader get weekdayHeader {
    var best = -1;
    for (var i = 0; i < weekdayAverages.length; i++) {
      if (weekdayAverages[i] > 0 && (best < 0 || weekdayAverages[i] > weekdayAverages[best])) {
        best = i;
      }
    }
    if (best < 0) return CardHeader.empty;
    return CardHeader(
      value: AppFormat.hm(weekdayAverages[best]),
      unit: 'h',
      caption: '${_weekdayNames[best]} average, the longest',
    );
  }

  CardHeader get checkinHeader {
    if (checkins.modalHour < 0 || checkins.dayCount < 2) return CardHeader.empty;
    final from = checkins.modalHour.toString().padLeft(2, '0');
    final to = (checkins.modalHour + 1).toString().padLeft(2, '0');
    return CardHeader(
      value: '$from:00–$to:00',
      caption: 'Most first check-ins · ${checkins.modalCount} of ${checkins.dayCount} days',
    );
  }
}

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

// ---------------------------------------------------------------------------
// Leave.
// ---------------------------------------------------------------------------

/// Leave is always shown per year: a quota is a calendar-year thing, and a
/// trailing six-month window would report a number nobody is entitled to.
class LeaveData {
  const LeaveData({
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.plannedDays,
    required this.sickDays,
    required this.flexDays,
  });

  final int year;
  final double totalDays;

  /// Vacation dated on or before today.
  final double usedDays;

  /// Vacation dated after today: booked, not yet taken. It used to be folded
  /// into [usedDays] with nothing saying so, which made "Remaining" quietly
  /// mean "after everything you have already booked" while reading as "days
  /// you have left to take".
  final double plannedDays;

  final double sickDays;
  final double flexDays;

  /// Days that can still be booked. Not clamped: over-booking the quota is a
  /// thing worth seeing, and a floor at zero hid it.
  double get remainingDays => totalDays - usedDays - plannedDays;

  double get usedProgress => totalDays > 0 ? (usedDays / totalDays).clamp(0.0, 1.0) : 0;

  /// The planned arc sits on top of the used one, so it is the pair that is
  /// clamped rather than each separately.
  double get bookedProgress =>
      totalDays > 0 ? ((usedDays + plannedDays) / totalDays).clamp(0.0, 1.0) : 0;

  bool get hasData => totalDays > 0;
}

/// Days, as a number someone would say out loud: `13` rather than `13.0`, and
/// `2.5` when it really is a half.
String formatLeaveDays(double days) {
  final rounded = (days * 4).round() / 4;
  if (rounded == rounded.roundToDouble()) return '${rounded.round()}';
  return rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
}
