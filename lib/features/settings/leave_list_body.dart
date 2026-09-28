/// The presentational half of [LeaveListScreen] — the year's vacation, sick and
/// flex days, one row each.
///
/// Takes plain view models rather than `LeaveEntry` rows, because "full day"
/// versus "½ day" is a fraction of *that date's* target and only the screen can
/// resolve it. That also keeps the body renderable to a golden with no database,
/// and keeps the clock out of it: whether a day is already taken or still
/// planned is decided by the caller from an injectable `now`, the same defect
/// the date picker and the holiday list both had.
library;

import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/enums.dart';
import '../../widgets/buttons.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/screen_scaffold.dart';

/// One row: a single day, or a run of them.
///
/// A fortnight off used to be ten identical rows saying "Vacation · full day",
/// which is how the list looked after the very first range was booked. Days
/// that run together — same type, same amount, nothing but weekends and
/// holidays between them — are one row.
class LeaveListItem {
  const LeaveListItem({
    required this.dates,
    required this.type,
    required this.amountLabel,
    required this.planned,
  });

  /// Sorted and non-empty. Weekends and holidays inside the span are not in
  /// here — nothing was booked on them.
  final List<DateTime> dates;

  final LeaveType type;

  /// `full day`, `½ day`, or the raw hours if an imported entry does not land
  /// on a quarter.
  final String amountLabel;

  /// Dated after today — booked but not yet taken.
  final bool planned;

  DateTime get date => dates.first;
  DateTime get endDate => dates.last;
  int get dayCount => dates.length;
  bool get isRun => dates.length > 1;
}

class LeaveListBody extends StatelessWidget {
  const LeaveListBody({
    super.key,
    required this.year,
    required this.items,
    required this.usedDays,
    required this.plannedDays,
    required this.quotaDays,
    this.onAdd,
    this.onEdit,
    this.onRemove,
    this.onStepYear,
    this.canStepForward = true,
  });

  final int year;

  /// Sorted by date by the caller.
  final List<LeaveListItem> items;

  /// Vacation only — sick and flex days do not come out of the quota.
  final double usedDays;
  final double plannedDays;
  final double quotaDays;

  final VoidCallback? onAdd;
  final ValueChanged<LeaveListItem>? onEdit;
  final ValueChanged<LeaveListItem>? onRemove;
  final ValueChanged<int>? onStepYear;
  final bool canStepForward;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SubScreen(
      title: 'Leave',
      subtitle: 'Vacation, sick and flex days · tap a day to edit',
      action: _AddPill(onTap: onAdd),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.gutterDense,
          0,
          AppSpace.gutterDense,
          AppSpace.s6 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Row(
            children: [
              AppIconButton(
                icon: AppIcons.caretLeft,
                semanticLabel: 'Previous year',
                onPressed: onStepYear == null ? null : () => onStepYear!(-1),
              ),
              Expanded(
                child: Text(
                  '$year',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline.copyWith(color: colors.text),
                ),
              ),
              AppIconButton(
                icon: AppIcons.caretRight,
                semanticLabel: 'Next year',
                onPressed:
                    onStepYear == null || !canStepForward ? null : () => onStepYear!(1),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          _Summary(
            usedDays: usedDays,
            plannedDays: plannedDays,
            quotaDays: quotaDays,
          ),
          const SizedBox(height: AppSpace.s4),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s8),
              child: Center(
                child: Text('Nothing booked for $year yet',
                    style: AppTextStyles.body.copyWith(color: colors.textMuted)),
              ),
            )
          else
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.divider, width: AppStroke.hair),
                boxShadow: colors.shadowSm,
              ),
              child: Column(
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 64, right: AppSpace.s4),
                        child: Container(height: AppStroke.hair, color: colors.divider),
                      ),
                    _LeaveRow(
                      item: item,
                      onTap: onEdit == null ? null : () => onEdit!(item),
                      onRemove: onRemove == null ? null : () => onRemove!(item),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String leaveTypeLabel(LeaveType type) => switch (type) {
      LeaveType.vacation => 'Vacation',
      LeaveType.sick => 'Sick day',
      LeaveType.flexDay => 'Flex day',
    };

IconData leaveTypeIcon(LeaveType type) => switch (type) {
      LeaveType.vacation => AppIcons.airplaneTilt,
      LeaveType.sick => AppIcons.thermometerSimple,
      LeaveType.flexDay => AppIcons.arrowsLeftRight,
    };

(Color tint, Color ink) leaveTypeColors(LeaveType type, AppColors colors) =>
    switch (type) {
      LeaveType.vacation => (colors.vacationTint, colors.vacationText),
      LeaveType.sick => (colors.sickTint, colors.sickText),
      LeaveType.flexDay => (colors.accentTint, colors.accentStrong),
    };

/// Days, as a number someone would say out loud: `13` rather than `13.0`, but
/// `2.5` when it really is a half.
String formatDays(double days) {
  final rounded = (days * 4).round() / 4;
  return rounded == rounded.roundToDouble()
      ? '${rounded.round()}'
      : rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.usedDays,
    required this.plannedDays,
    required this.quotaDays,
  });

  final double usedDays;
  final double plannedDays;
  final double quotaDays;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = quotaDays - usedDays - plannedDays;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s5,
        vertical: AppSpace.s4,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider, width: AppStroke.hair),
        boxShadow: colors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VACATION QUOTA',
              style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
          const SizedBox(height: AppSpace.s3),
          Row(
            children: [
              _Figure(
                  label: 'Taken', value: formatDays(usedDays), ink: colors.vacationText),
              _Figure(
                  label: 'Planned',
                  value: formatDays(plannedDays),
                  ink: colors.textMuted),
              _Figure(
                label: 'Left',
                value: formatDays(remaining),
                ink: remaining < 0 ? colors.warningText : colors.text,
              ),
              _Figure(
                  label: 'Quota', value: formatDays(quotaDays), ink: colors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.ink});

  final String label;
  final String value;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.statSm.copyWith(color: ink)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
        ],
      ),
    );
  }
}

class _LeaveRow extends StatelessWidget {
  const _LeaveRow({required this.item, required this.onTap, required this.onRemove});

  final LeaveListItem item;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (tint, ink) = leaveTypeColors(item.type, colors);
    // A day already taken is history; one still ahead is something to plan
    // around — the same distinction the holiday list draws.
    final blockFill = item.planned ? tint : colors.surface2;
    final blockInk = item.planned ? ink : colors.textMuted;

    return PressScale(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
        child: Row(
          children: [
            Container(
              width: AppSize.dateBlock,
              height: AppSize.dateBlock,
              decoration: BoxDecoration(
                color: blockFill,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppFormat.monthAbbrev(item.date).toUpperCase(),
                    style: AppTextStyles.microStrong.copyWith(color: blockInk),
                  ),
                  Text(
                    '${item.date.day}',
                    style: AppTextStyles.statSm.copyWith(color: blockInk),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(leaveTypeIcon(item.type), size: AppIconSize.sm, color: ink),
                      const SizedBox(width: AppSpace.s2),
                      Expanded(
                        child: Text(
                          item.isRun
                              ? '${leaveTypeLabel(item.type)} · ${item.dayCount} days'
                              : leaveTypeLabel(item.type),
                          style: AppTextStyles.bodyLg.copyWith(color: colors.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      // A run names its span; a single day names its weekday,
                      // which the date block beside it cannot show. The span
                      // uses History's week-row shape — `28–30 Sep`, or
                      // `31 Aug – 4 Sep` when it straddles two months — because
                      // spelling both weekdays out overran the row.
                      if (item.isRun)
                        AppFormat.weekRangeShort(item.date, item.endDate)
                      else
                        _weekdays[item.date.weekday - 1],
                      item.amountLabel,
                      if (item.planned) 'planned',
                    ].join(' · '),
                    style: AppTextStyles.caption.copyWith(color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: AppIcons.x,
              semanticLabel: item.isRun
                  ? 'Remove ${item.dayCount} days of ${leaveTypeLabel(item.type)} '
                      'from ${AppFormat.dayRow(item.date)}'
                  : 'Remove ${leaveTypeLabel(item.type)} on '
                      '${AppFormat.dayRow(item.date)}',
              size: AppIconSize.md,
              color: colors.textMuted,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPill extends StatelessWidget {
  const _AddPill({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PressScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: 'Add leave',
        child: Container(
          height: AppSize.touch,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
          decoration: BoxDecoration(
            color: colors.selected,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.plus, size: AppIconSize.md, color: colors.onSelected),
              const SizedBox(width: AppSpace.s2),
              Text('Add', style: AppTextStyles.label.copyWith(color: colors.onSelected)),
            ],
          ),
        ),
      ),
    );
  }
}
