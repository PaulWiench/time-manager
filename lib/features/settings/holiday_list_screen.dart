import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../domain/date_only.dart';
import '../../providers/holiday_providers.dart';
import '../../providers/repository_providers.dart';

/// Lists the current year's public holidays (auto-seeded nationwide +
/// Baden-Württemberg ones, plus any the user has added) and lets the user
/// add, edit, or remove entries — the escape hatch Requirements § 4 assumes
/// exists for any other region's or company's holidays that aren't
/// auto-seeded (see `domain/holiday_calculator.dart`).
class HolidayListScreen extends ConsumerWidget {
  const HolidayListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final year = DateTime.now().year;
    final holidays = ref.watch(publicHolidaysForYearProvider(year)).valueOrNull ?? const [];
    final sorted = [...holidays]..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: Text('Public holidays', style: AppTextStyles.screenTitle.copyWith(color: colors.text)),
        actions: [
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.plus),
            onPressed: () => _editHoliday(context, ref, year: year),
          ),
        ],
      ),
      body: sorted.isEmpty
          ? Center(child: Text('No holidays for $year yet', style: AppTextStyles.body.copyWith(color: colors.textMuted)))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpace.screenPadding),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => Divider(color: colors.divider, height: 1),
              itemBuilder: (context, i) {
                final h = sorted[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(h.name, style: AppTextStyles.body.copyWith(color: colors.text)),
                  subtitle: Text(
                    h.fraction < 1.0 ? '${AppFormat.dayRow(h.date)} · half day' : AppFormat.dayRow(h.date),
                    style: AppTextStyles.meta.copyWith(color: colors.textMuted),
                  ),
                  onTap: () => _editHoliday(context, ref, year: year, existing: h),
                  trailing: IconButton(
                    icon: PhosphorIcon(PhosphorIconsRegular.trash, color: colors.textMuted, size: 18),
                    onPressed: () => ref.read(publicHolidayRepositoryProvider).removeHoliday(h.date),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _editHoliday(BuildContext context, WidgetRef ref, {required int year, PublicHoliday? existing}) async {
    var date = existing?.date ?? dateOnly(DateTime.now());
    var name = existing?.name ?? '';
    var halfDay = (existing?.fraction ?? 1.0) < 1.0;
    final nameController = TextEditingController(text: name);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add holiday' : 'Edit holiday'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(year - 1),
                    lastDate: DateTime(year + 1, 12, 31),
                  );
                  if (picked != null) setState(() => date = dateOnly(picked));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(AppFormat.dayRow(date)),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Half day'),
                  Checkbox(value: halfDay, onChanged: (v) => setState(() => halfDay = v ?? false)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: name.trim().isEmpty
                  ? null
                  : () {
                      final repo = ref.read(publicHolidayRepositoryProvider);
                      // Date is the PK, so moving an existing holiday to a
                      // new date would otherwise leave a stale row behind at
                      // the old date instead of replacing it.
                      if (existing != null && !dateOnly(existing.date).isAtSameMomentAs(date)) {
                        repo.removeHoliday(existing.date);
                      }
                      repo.setHoliday(date: date, name: name.trim(), fraction: halfDay ? 0.5 : 1.0);
                      Navigator.pop(context);
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
