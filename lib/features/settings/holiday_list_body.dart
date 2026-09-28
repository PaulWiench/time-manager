/// The presentational half of [HolidayListScreen].
///
/// Takes its holidays, its year and its idea of "now" as arguments so the
/// screen can be rendered to a golden without a database. `now` matters more
/// than it looks: a past holiday is tinted differently from an upcoming one,
/// so a body that read the clock itself would produce a render that changed
/// under it — the same defect the date picker had.
library;

import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../data/database/enums.dart';
import '../../domain/date_only.dart';
import '../../widgets/buttons.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/screen_scaffold.dart';

class HolidayListBody extends StatelessWidget {
  const HolidayListBody({
    super.key,
    required this.year,
    required this.holidays,
    required this.now,
    this.onAdd,
    this.onEdit,
    this.onRemove,
  });

  final int year;

  /// Sorted by date by the caller.
  final List<PublicHoliday> holidays;

  final DateTime now;

  final VoidCallback? onAdd;
  final ValueChanged<PublicHoliday>? onEdit;
  final ValueChanged<PublicHoliday>? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = dateOnly(now);

    return SubScreen(
      title: 'Public holidays',
      subtitle: 'Baden-Württemberg · $year · tap a day to edit',
      action: _AddPill(onTap: onAdd),
      child: holidays.isEmpty
          ? Center(
              child: Text('No holidays for $year yet',
                  style: AppTextStyles.body.copyWith(color: colors.textMuted)),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpace.gutterDense,
                0,
                AppSpace.gutterDense,
                AppSpace.s6 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
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
                      for (final (i, holiday) in holidays.indexed) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 64, right: AppSpace.s4),
                            child: Container(height: AppStroke.hair, color: colors.divider),
                          ),
                        _HolidayRow(
                          holiday: holiday,
                          isPast: holiday.date.isBefore(today),
                          onTap: onEdit == null ? null : () => onEdit!(holiday),
                          onRemove: onRemove == null ? null : () => onRemove!(holiday),
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
        label: 'Add holiday',
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

class _HolidayRow extends StatelessWidget {
  const _HolidayRow({
    required this.holiday,
    required this.isPast,
    required this.onTap,
    required this.onRemove,
  });

  final PublicHoliday holiday;

  /// Decided by the caller from an injectable `now` — see [HolidayListBody].
  final bool isPast;

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
                // A holiday that has already happened is history; one still to
                // come is something to plan around.
                color: isPast ? colors.surface2 : colors.holidayTint,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppFormat.monthAbbrev(holiday.date).toUpperCase(),
                    style: AppTextStyles.microStrong.copyWith(
                      color: isPast ? colors.textMuted : colors.holidayText,
                    ),
                  ),
                  Text(
                    '${holiday.date.day}',
                    style: AppTextStyles.statSm.copyWith(
                      color: isPast ? colors.textMuted : colors.holidayText,
                    ),
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
                  Text(holiday.name,
                      style: AppTextStyles.bodyLg.copyWith(color: colors.text)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      _weekdays[holiday.date.weekday - 1],
                      if (holiday.fraction < 1) 'half day',
                      holiday.source == HolidaySource.manual ? 'added by you' : 'auto',
                    ].join(' · '),
                    style: AppTextStyles.caption.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: AppIcons.x,
              semanticLabel: 'Remove ${holiday.name}',
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
