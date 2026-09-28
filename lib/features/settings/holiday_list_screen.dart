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
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../domain/date_only.dart';
import '../../providers/holiday_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/buttons.dart';
import '../../widgets/press_scale.dart';
import 'holiday_list_body.dart';

class HolidayListScreen extends ConsumerWidget {
  const HolidayListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final year = now.year;
    final holidays = ref.watch(publicHolidaysForYearProvider(year)).valueOrNull ?? const [];
    final sorted = [...holidays]..sort((a, b) => a.date.compareTo(b.date));

    return HolidayListBody(
      year: year,
      holidays: sorted,
      now: now,
      onAdd: () => _edit(context, ref, year: year),
      onEdit: (holiday) => _edit(context, ref, year: year, existing: holiday),
      onRemove: (holiday) =>
          ref.read(publicHolidayRepositoryProvider).removeHoliday(holiday.date),
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


