/// Vacation used against the year's quota (handoff §4.4, Leave).
///
/// A plain ring — no ticks, no knob, no lap — which is why the Sun Dial and
/// [ProgressRing] stayed separate widgets rather than one with six flags.
library;

import 'package:flutter/widgets.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/progress_ring.dart';
import '../stats_view.dart';

class LeaveBreakdown extends StatelessWidget {
  const LeaveBreakdown({super.key, required this.data});

  final LeaveData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Two arcs on one track: what has been taken, and what is booked on top of
    // it. Planned days used to be counted as used with nothing saying so, so
    // "Remaining" read as days left to take while meaning days left to book.
    final planned = ProgressRing(
      size: 132,
      strokeWidth: AppStroke.vacationRing,
      progress: data.bookedProgress,
      color: colors.vacationFill.withValues(alpha: 0.4),
      trackColor: colors.track,
    );

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            planned,
            ProgressRing(
              size: 132,
              strokeWidth: AppStroke.vacationRing,
              progress: data.usedProgress,
              color: colors.vacationFill,
              trackColor: const Color(0x00000000),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(formatLeaveDays(data.usedDays + data.plannedDays),
                          style: AppTextStyles.stat.copyWith(color: colors.text)),
                      const SizedBox(width: 2),
                      Text('d',
                          style: AppTextStyles.statSm.copyWith(color: colors.textMuted)),
                    ],
                  ),
                  Text('of ${formatLeaveDays(data.totalDays)} booked',
                      style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpace.s5),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendRow(
                icon: AppIcons.airplaneTilt,
                iconColor: colors.vacationText,
                label: 'Used',
                value: '${formatLeaveDays(data.usedDays)} d',
                valueColor: colors.vacationText,
              ),
              _LegendRow(
                swatch: colors.vacationFill.withValues(alpha: 0.4),
                label: 'Planned',
                value: '${formatLeaveDays(data.plannedDays)} d',
                valueColor: colors.text,
              ),
              _LegendRow(
                swatch: colors.track,
                label: 'Remaining',
                value: '${formatLeaveDays(data.remainingDays)} d',
                valueColor: data.remainingDays < 0 ? colors.warningText : colors.text,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    this.icon,
    this.iconColor,
    this.swatch,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData? icon;
  final Color? iconColor;
  final Color? swatch;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: AppSize.iconTile,
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, size: AppIconSize.md, color: iconColor)
          else
            Container(
              width: AppSize.swatch,
              height: AppSize.swatch,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: colors.divider, width: AppStroke.hair),
              ),
            ),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Text(label, style: AppTextStyles.body.copyWith(color: colors.text)),
          ),
          Text(value, style: AppTextStyles.statSm.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
