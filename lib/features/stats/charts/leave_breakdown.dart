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

    return Row(
      children: [
        ProgressRing(
          size: 132,
          strokeWidth: AppStroke.vacationRing,
          progress: data.progress,
          color: colors.vacationFill,
          trackColor: colors.track,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(_days(data.usedDays),
                      style: AppTextStyles.stat.copyWith(color: colors.text)),
                  const SizedBox(width: 2),
                  Text('d', style: AppTextStyles.statSm.copyWith(color: colors.textMuted)),
                ],
              ),
              Text('of ${_days(data.totalDays)} used',
                  style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
            ],
          ),
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
                value: '${data.usedDays.toStringAsFixed(1)} d',
                valueColor: colors.vacationText,
              ),
              _LegendRow(
                swatch: colors.track,
                label: 'Remaining',
                value: '${data.remainingDays.toStringAsFixed(1)} d',
                valueColor: colors.text,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// A whole number of days reads better than "18.0" inside the ring, where
  /// the caption already says what it is out of.
  String _days(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
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
