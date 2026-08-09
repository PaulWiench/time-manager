import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../data/database/enums.dart';
import '../../domain/stats_aggregation.dart';
import '../../providers/day_providers.dart';
import '../../providers/stats_providers.dart';
import '../../widgets/stat_card.dart';
import 'charts/balance_trend_chart.dart';
import 'charts/checkin_distribution_chart.dart';
import 'charts/chart_empty_state.dart';
import 'charts/daily_hours_chart.dart';
import 'charts/leave_breakdown.dart';
import 'charts/monthly_heatmap.dart';
import 'charts/overtime_rate_chart.dart';
import 'charts/weekday_hours_chart.dart';
import 'charts/weekly_hit_rate_chart.dart';

enum StatsTab { overview, patterns, leave }

/// Header, in-screen tab bar, range selector, and the real chart bodies per
/// the design handoff and § 5.4 of the design spec (Milestone 8).
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsTab _tab = StatsTab.overview;
  String _range = 'Month';
  DateRange? _customRange;
  int _leaveYear = DateTime.now().year;

  DateRange _resolveRange() {
    final today = DateTime.now();
    switch (_range) {
      case '6 Months':
        return trailingRange(182, today: today);
      case 'Year':
        return trailingRange(365, today: today);
      case 'Custom':
        return _customRange ?? trailingRange(30, today: today);
      case 'Month':
      default:
        return trailingRange(30, today: today);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange;
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initial?.start ?? now.subtract(const Duration(days: 29)),
        end: initial != null ? initial.endExclusive.subtract(const Duration(days: 1)) : now,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _range = 'Custom';
      _customRange = DateRange(
        start: DateTime(result.start.year, result.start.month, result.start.day),
        endExclusive: DateTime(result.end.year, result.end.month, result.end.day).add(const Duration(days: 1)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 14, AppSpace.screenPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stats', style: AppTextStyles.screenTitle.copyWith(color: colors.text)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final t in StatsTab.values) ...[
                        _TabLabel(tab: t, active: _tab == t, colors: colors, onTap: () => setState(() => _tab = t)),
                        const SizedBox(width: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_tab == StatsTab.leave)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _leaveYear -= 1),
                          child: PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 15, color: colors.textMuted),
                        ),
                        const SizedBox(width: 10),
                        Text(_leaveYear.toString(), style: AppTextStyles.heroNumber(13).copyWith(color: colors.text)),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => setState(() => _leaveYear += 1),
                          child: PhosphorIcon(PhosphorIconsRegular.caretRight, size: 15, color: colors.textMuted),
                        ),
                      ],
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final r in const ['Month', '6 Months', 'Year', 'Custom']) ...[
                            _RangeChip(
                              label: r,
                              selected: _range == r,
                              colors: colors,
                              onTap: r == 'Custom' ? _pickCustomRange : () => setState(() => _range = r),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 14, AppSpace.screenPadding, 20),
                children: _cardsFor(_tab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String kicker, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ChartCard(kicker: kicker, child: child),
      );

  List<DayStat> _toDayStats(List<DayEntry> entries) => [
        for (final e in entries)
          DayStat(date: e.date, netWorkedHours: e.netWorkedHours, targetHours: e.targetHours, balanceDelta: e.balanceDelta),
      ];

  List<Widget> _cardsFor(StatsTab tab) {
    switch (tab) {
      case StatsTab.overview:
        return _overviewCards(_resolveRange());
      case StatsTab.patterns:
        return _patternsCards(_resolveRange());
      case StatsTab.leave:
        return _leaveCards();
    }
  }

  List<Widget> _overviewCards(DateRange range) {
    final balanceAsync = ref.watch(balanceSnapshotsInRangeProvider(range.start, range.endExclusive));
    final daysAsync = ref.watch(dayEntriesInRangeProvider(range.start, range.endExclusive));

    return [
      _card(
        'Balance trend',
        balanceAsync.when(
          data: (snapshots) => BalanceTrendChart(snapshots: snapshots),
          loading: () => const ChartLoading(height: 140),
          error: (_, __) => const ChartEmptyState(height: 140),
        ),
      ),
      _card(
        'Weekly target hit rate',
        daysAsync.when(
          data: (entries) => WeeklyHitRateChart(weeks: weeklyAggregates(_toDayStats(entries))),
          loading: () => const ChartLoading(),
          error: (_, __) => const ChartEmptyState(),
        ),
      ),
      _card(
        'Overtime accumulation rate',
        daysAsync.when(
          data: (entries) => OvertimeRateChart(weeks: weeklyAggregates(_toDayStats(entries))),
          loading: () => const ChartLoading(),
          error: (_, __) => const ChartEmptyState(),
        ),
      ),
    ];
  }

  List<Widget> _patternsCards(DateRange range) {
    final daysAsync = ref.watch(dayEntriesInRangeProvider(range.start, range.endExclusive));
    final sessionsAsync = ref.watch(workSessionsInRangeProvider(range.start, range.endExclusive));

    return [
      _card('Monthly overview', const MonthlyHeatmap()),
      _card(
        'Daily hours',
        daysAsync.when(
          data: (entries) => DailyHoursChart(days: _toDayStats(entries)),
          loading: () => const ChartLoading(),
          error: (_, __) => const ChartEmptyState(),
        ),
      ),
      _card(
        'By day of week',
        daysAsync.when(
          data: (entries) => WeekdayHoursChart(averages: averageHoursByWeekday(_toDayStats(entries))),
          loading: () => const ChartLoading(),
          error: (_, __) => const ChartEmptyState(),
        ),
      ),
      _card(
        'Check-in times',
        sessionsAsync.when(
          data: (sessions) => CheckinDistributionChart(
            histogram: checkinHourHistogram([
              for (final s in sessions)
                if (s.status != SessionStatus.discarded) s.startTime,
            ]),
          ),
          loading: () => const ChartLoading(),
          error: (_, __) => const ChartEmptyState(),
        ),
      ),
    ];
  }

  List<Widget> _leaveCards() {
    final quotaAsync = ref.watch(vacationQuotaForYearProvider(_leaveYear));
    final entriesAsync = ref.watch(leaveForYearProvider(_leaveYear));

    return [
      _card(
        'Leave breakdown',
        quotaAsync.when(
          data: (quota) => entriesAsync.when(
            data: (entries) => LeaveBreakdown(quota: quota, entries: entries),
            loading: () => const ChartLoading(height: 90),
            error: (_, __) => const ChartEmptyState(height: 90),
          ),
          loading: () => const ChartLoading(height: 90),
          error: (_, __) => const ChartEmptyState(height: 90),
        ),
      ),
    ];
  }
}

class _TabLabel extends StatelessWidget {
  final StatsTab tab;
  final bool active;
  final AppColors colors;
  final VoidCallback onTap;

  const _TabLabel({required this.tab, required this.active, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = switch (tab) {
      StatsTab.overview => 'Overview',
      StatsTab.patterns => 'Patterns',
      StatsTab.leave => 'Leave',
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? colors.accentFill : Colors.transparent, width: 2))),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(color: active ? colors.accentText : colors.textMuted, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  const _RangeChip({required this.label, required this.selected, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: selected ? colors.accentTint : null, borderRadius: BorderRadius.circular(100)),
        child: Text(
          label,
          style: AppTextStyles.metaMedium.copyWith(color: selected ? colors.accentText : colors.textMuted, fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
        ),
      ),
    );
  }
}
