/// Stats, drawn from aggregates and nothing else.
library;

import 'package:flutter/widgets.dart';

import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/range_chip.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/segmented_control.dart';
import 'charts/balance_trend_chart.dart';
import 'charts/checkin_distribution_chart.dart';
import 'charts/daily_hours_chart.dart';
import 'charts/leave_breakdown.dart';
import 'vacation_list.dart';
import '../../domain/vacation_bookings.dart';
import 'charts/monthly_heatmap.dart';
import 'charts/overtime_rate_chart.dart';
import 'charts/weekday_hours_chart.dart';
import 'charts/weekly_hit_rate_chart.dart';
import 'stats_view.dart';

class StatsBody extends StatelessWidget {
  const StatsBody({
    super.key,
    required this.tab,
    required this.range,
    this.customRangeLabel,
    this.overview,
    this.patterns,
    this.leave,
    this.onOpenVacation,
    this.onTabChanged,
    this.onRangeChanged,
    this.onStepMonth,
    this.onStepYear,
  });

  final StatsTab tab;
  final StatsRange range;

  /// `1 Aug – 22 Sep 2026`, shown under the chips when Custom is active.
  final String? customRangeLabel;

  final OverviewData? overview;
  final PatternsData? patterns;
  final LeaveData? leave;

  /// Opens the rename/edit sheet for a booking in the vacation list.
  final ValueChanged<VacationBooking>? onOpenVacation;

  final ValueChanged<StatsTab>? onTabChanged;
  final ValueChanged<StatsRange>? onRangeChanged;
  final ValueChanged<int>? onStepMonth;
  final ValueChanged<int>? onStepYear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TabScreen(
      title: 'Stats',
      gutter: AppSpace.gutterDense,
      children: [
        const SizedBox(height: AppSpace.s4),
        // Leave is year-scoped, so the range chips are replaced by a note
        // saying so rather than left visible and quietly ignored.
        if (tab == StatsTab.leave)
          Row(
            children: [
              Icon(AppIcons.calendarDots, size: AppIconSize.sm, color: colors.textMuted),
              const SizedBox(width: AppSpace.s2),
              Text('Leave is always shown per year',
                  style: AppTextStyles.body.copyWith(color: colors.textMuted)),
            ],
          )
        else ...[
          // The handoff asks for five equal-width chips, but "Custom" is twice
          // the width of "1W" and gets clipped at a fifth of a phone row. The
          // chips take the width they need and share the slack instead, which
          // is also what the design's own render shows.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final value in StatsRange.values)
                RangeChip(
                  label: value.short,
                  semanticLabel: value.spoken,
                  selected: range == value,
                  onTap: () => onRangeChanged?.call(value),
                ),
            ],
          ),
          if (range == StatsRange.custom && customRangeLabel != null) ...[
            const SizedBox(height: AppSpace.s2),
            Text('$customRangeLabel · tap Custom to change',
                style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
          ],
        ],
        const SizedBox(height: AppSpace.s4),
        SegmentedControl<StatsTab>(
          segments: const [
            (StatsTab.overview, 'Overview'),
            (StatsTab.patterns, 'Patterns'),
            (StatsTab.leave, 'Leave'),
          ],
          selected: tab,
          onSelect: onTabChanged ?? (_) {},
        ),
        const SizedBox(height: AppSpace.s6),
        ..._cards(context),
      ],
    );
  }

  List<Widget> _cards(BuildContext context) {
    final cards = switch (tab) {
      StatsTab.overview => _overviewCards(),
      StatsTab.patterns => _patternsCards(context),
      StatsTab.leave => _leaveCards(context),
    };

    return [
      for (final (i, card) in cards.indexed) ...[
        if (i > 0) const SizedBox(height: AppSpace.s6),
        card,
      ],
    ];
  }

  List<Widget> _overviewCards() {
    final data = overview;
    if (data == null) return const [ChartCard(kicker: 'BALANCE TREND')];

    return [
      ChartCard(
        kicker: 'BALANCE TREND',
        value: data.balanceHeader.value,
        unit: data.balanceHeader.unit,
        caption: data.balanceHeader.caption,
        child: data.balanceHeader.value == null
            ? null
            : BalanceTrendChart(points: data.balance),
      ),
      ChartCard(
        kicker: 'WEEKLY TARGET HIT RATE',
        value: data.hitRateHeader.value,
        unit: data.hitRateHeader.unit,
        caption: data.hitRateHeader.caption,
        child: data.hitRateHeader.value == null
            ? null
            : WeeklyHitRateChart(weeks: data.weeks, today: data.today),
      ),
      ChartCard(
        kicker: 'OVERTIME ACCUMULATION RATE',
        value: data.overtimeRateHeader.value,
        unit: data.overtimeRateHeader.unit,
        caption: data.overtimeRateHeader.caption,
        child: data.overtimeRateHeader.value == null
            ? null
            : OvertimeRateChart(weeks: data.weeks, today: data.today),
      ),
    ];
  }

  List<Widget> _patternsCards(BuildContext context) {
    final data = patterns;
    if (data == null) return const [ChartCard(kicker: 'MONTHLY OVERVIEW')];

    return [
      ChartCard(
        kicker: 'MONTHLY OVERVIEW',
        value: data.heatmapHeader.value,
        unit: data.heatmapHeader.unit,
        caption: data.heatmapHeader.caption,
        trailing: _MonthStepper(month: data.month, onStep: onStepMonth),
        child: data.heatmapHeader.value == null
            ? null
            : MonthlyHeatmap(
                month: data.month,
                days: data.monthDays,
                leaveDays: data.leaveDays,
                today: data.today,
              ),
      ),
      ChartCard(
        kicker: 'DAILY HOURS',
        value: data.dailyHoursHeader.value,
        unit: data.dailyHoursHeader.unit,
        caption: data.dailyHoursHeader.caption,
        child: data.dailyHoursHeader.value == null
            ? null
            : DailyHoursChart(
                days: data.dailyBars,
                bucket: data.hoursBucket,
                today: data.today,
                targetHours: _typicalTarget(data),
              ),
      ),
      ChartCard(
        kicker: 'BY DAY OF WEEK',
        value: data.weekdayHeader.value,
        unit: data.weekdayHeader.unit,
        caption: data.weekdayHeader.caption,
        child: data.weekdayHeader.value == null
            ? null
            : WeekdayHoursChart(averages: data.weekdayAverages),
      ),
      ChartCard(
        kicker: 'CHECK-IN TIMES',
        value: data.checkinHeader.value,
        caption: data.checkinHeader.caption,
        child: data.checkinHeader.value == null
            ? null
            : CheckinDistributionChart(
                histogram: data.checkinHistogram,
                summary: data.checkins,
              ),
      ),
    ];
  }

  /// The target line is a single number, so it is the most common non-zero
  /// target in range rather than an average that lands between two real ones.
  double _typicalTarget(PatternsData data) {
    final counts = <double, int>{};
    for (final day in data.days) {
      if (day.targetHours > 0) {
        counts[day.targetHours] = (counts[day.targetHours] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 0;
    var best = counts.keys.first;
    for (final entry in counts.entries) {
      if (entry.value > counts[best]!) best = entry.key;
    }
    return best;
  }

  List<Widget> _leaveCards(BuildContext context) {
    final colors = context.colors;
    final data = leave;

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconButton(
            icon: AppIcons.caretLeft,
            semanticLabel: 'Previous year',
            onPressed: onStepYear == null ? null : () => onStepYear!(-1),
          ),
          Text('${data?.year ?? ''}',
              style: AppTextStyles.headline.copyWith(color: colors.text)),
          AppIconButton(
            icon: AppIcons.caretRight,
            semanticLabel: 'Next year',
            onPressed: onStepYear == null ? null : () => onStepYear!(1),
          ),
        ],
      ),
      if (data == null || !data.hasData)
        const ChartCard(kicker: 'LEAVE BREAKDOWN')
      else ...[
        ChartCard(kicker: 'LEAVE BREAKDOWN', child: LeaveBreakdown(data: data)),
        StatCard(
          kicker: 'SICK DAYS',
          value: formatLeaveDays(data.sickDays),
          unit: 'd',
          caption: '${data.year} so far',
          tone: colors.sickText,
        ),
        // Flex days used to be dropped on the floor: counted in the balance,
        // shown nowhere. Only worth a card once there are some.
        if (data.flexDays > 0)
          StatCard(
            kicker: 'FLEX DAYS',
            value: formatLeaveDays(data.flexDays),
            unit: 'd',
            caption: '${data.year} so far',
            tone: colors.accentStrong,
          ),
        if (data.vacations.isNotEmpty)
          VacationList(
            year: data.year,
            bookings: data.vacations,
            daysLeftAfterPlanned: data.remainingDays,
            onOpen: onOpenVacation,
          ),
      ],
    ];
  }
}

class _MonthStepper extends StatelessWidget {
  const _MonthStepper({required this.month, required this.onStep});

  final DateTime month;
  final ValueChanged<int>? onStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(
          icon: AppIcons.caretLeft,
          semanticLabel: 'Previous month',
          size: AppIconSize.md,
          color: colors.textMuted,
          onPressed: onStep == null ? null : () => onStep!(-1),
        ),
        Text(_label(month),
            style: AppTextStyles.captionStrong.copyWith(color: colors.text)),
        AppIconButton(
          icon: AppIcons.caretRight,
          semanticLabel: 'Next month',
          size: AppIconSize.md,
          color: colors.textMuted,
          onPressed: onStep == null ? null : () => onStep!(1),
        ),
      ],
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _label(DateTime month) => '${_months[month.month - 1]} ${month.year}';
}
