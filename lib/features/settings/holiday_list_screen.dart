/// The year's public holidays: the nationwide and Baden-Württemberg ones the
/// app seeds, plus anything added by hand.
///
/// The escape hatch for another region's or a company's holidays, which
/// `domain/holiday_calculator.dart` deliberately does not try to know about.
/// Removing an auto-seeded one leaves a tombstone rather than deleting the row,
/// so next year's seed does not bring it back.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../data/database/enums.dart';
import '../../domain/date_only.dart';
import '../../providers/holiday_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/buttons.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/screen_scaffold.dart';

class HolidayListScreen extends ConsumerWidget {
  const HolidayListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final year = DateTime.now().year;
    final holidays = ref.watch(publicHolidaysForYearProvider(year)).valueOrNull ?? const [];
    final sorted = [...holidays]..sort((a, b) => a.date.compareTo(b.date));

    return SubScreen(
      title: 'Public holidays',
      subtitle: 'Baden-Württemberg · $year · tap a day to edit',
      action: _AddPill(onTap: () => _edit(context, ref, year: year)),
      child: sorted.isEmpty
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
                      for (final (i, holiday) in sorted.indexed) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 64, right: AppSpace.s4),
                            child: Container(height: AppStroke.hair, color: colors.divider),
                          ),
                        _HolidayRow(
                          holiday: holiday,
                          onTap: () => _edit(context, ref, year: year, existing: holiday),
                          onRemove: () => ref
                              .read(publicHolidayRepositoryProvider)
                              .removeHoliday(holiday.date),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    required int year,
    PublicHoliday? existing,
  }) async {
    var date = existing?.date ?? dateOnly(DateTime.now());
    var halfDay = (existing?.fraction ?? 1.0) < 1.0;
    final name = TextEditingController(text: existing?.name ?? '');

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final colors = context.colors;

          return AppDialog(
            title: existing == null ? 'Add holiday' : 'Edit holiday',
            actions: [
              AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
              PrimaryPill(
                label: 'Save',
                expand: false,
                height: AppSize.touch,
                onPressed: name.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s4,
                    vertical: AppSpace.s3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('NAME',
                          style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
                      TextField(
                        controller: name,
                        autofocus: existing == null,
                        style: AppTextStyles.body.copyWith(color: colors.text),
                        cursorColor: colors.accentStrong,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s3),
                PressScale(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(year - 1),
                      lastDate: DateTime(year + 1, 12, 31),
                    );
                    if (picked != null) setState(() => date = dateOnly(picked));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s4,
                      vertical: AppSpace.s3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('DATE',
                            style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
                        Text(AppFormat.dayRow(date),
                            style: AppTextStyles.statSm.copyWith(color: colors.text)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s3),
                Row(
                  children: [
                    Expanded(
                      child: Text('Half day',
                          style: AppTextStyles.bodyLg.copyWith(color: colors.text)),
                    ),
                    Switch(
                      value: halfDay,
                      onChanged: (on) => setState(() => halfDay = on),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (saved != true) return;
    final repo = ref.read(publicHolidayRepositoryProvider);
    // Date is the primary key, so moving an existing holiday would otherwise
    // leave a stale row behind at the old date instead of replacing it.
    if (existing != null && !dateOnly(existing.date).isAtSameMomentAs(date)) {
      await repo.removeHoliday(existing.date);
    }
    await repo.setHoliday(
      date: date,
      name: name.text.trim(),
      fraction: halfDay ? 0.5 : 1.0,
    );
  }
}

class _AddPill extends StatelessWidget {
  const _AddPill({required this.onTap});

  final VoidCallback onTap;

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
    required this.onTap,
    required this.onRemove,
  });

  final PublicHoliday holiday;
  final VoidCallback onTap;
  final VoidCallback onRemove;

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
    final isPast = holiday.date.isBefore(dateOnly(DateTime.now()));

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
