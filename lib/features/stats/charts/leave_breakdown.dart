import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/database/database.dart';
import '../../../data/database/enums.dart';
import '../../../widgets/progress_ring.dart';

/// Leave tab — vacation used vs. remaining (out of quota + rollover) and
/// sick days taken, year-scoped. A "day" is approximated as 8 hours, the
/// same heuristic `VacationQuotaRepository.usedDaysForYear` already uses.
class LeaveBreakdown extends StatelessWidget {
  final VacationQuota? quota;
  final List<LeaveEntry> entries;

  const LeaveBreakdown({super.key, required this.quota, required this.entries});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalDays = (quota?.totalDays ?? 30) + (quota?.rolloverDays ?? 0);

    var vacationHours = 0.0;
    var sickHours = 0.0;
    for (final e in entries) {
      switch (e.type) {
        case LeaveType.vacation:
          vacationHours += e.hours;
        case LeaveType.sick:
          sickHours += e.hours;
        case LeaveType.flexDay:
          break;
      }
    }
    final usedDays = vacationHours / 8.0;
    final remainingDays = (totalDays - usedDays).clamp(0.0, totalDays);
    final progress = totalDays > 0 ? (usedDays / totalDays).clamp(0.0, 1.0) : 0.0;
    final sickDays = sickHours / 8.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ProgressRing(
          size: 84,
          strokeWidth: 9,
          progress: progress,
          color: colors.accentFill,
          trackColor: colors.divider,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(usedDays.toStringAsFixed(1), style: AppTextStyles.heroNumber(18).copyWith(color: colors.text)),
              Text('of ${totalDays.toStringAsFixed(0)}d', style: AppTextStyles.meta.copyWith(color: colors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeaveRow(label: 'Used', value: '${usedDays.toStringAsFixed(1)}d', colors: colors),
              const SizedBox(height: 6),
              _LeaveRow(label: 'Remaining', value: '${remainingDays.toStringAsFixed(1)}d', colors: colors),
              const SizedBox(height: 6),
              _LeaveRow(label: 'Sick days', value: '${sickDays.toStringAsFixed(1)}d', colors: colors),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaveRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;

  const _LeaveRow({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: colors.textMuted)),
        Text(value, style: AppTextStyles.body.copyWith(color: colors.text, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
