/// One pill per week, filled if the week hit its target (handoff §5.6.2).
///
/// Not a bar chart: the question is binary, and twenty-five bars of varying
/// height answer "how much" when what was asked is "how often". Pills of equal
/// height make the pattern of misses readable at a glance.
library;

import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/date_only.dart';
import '../../../domain/stats_aggregation.dart';
import 'chart_palette.dart';
import 'month_axis.dart';

class WeeklyHitRateChart extends StatelessWidget {
  const WeeklyHitRateChart({super.key, required this.weeks, required this.today});

  final List<WeekStat> weeks;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final colors = context.colors;
    final currentWeek = startOfWeek(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36 + AppStroke.focus * 2 + 2,
          child: Row(
            children: [
              for (final (i, week) in weeks.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpace.s1),
                Expanded(
                  child: _Pill(
                    hit: week.hitTarget,
                    current: week.weekStart == currentWeek,
                    palette: palette,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        MonthAxis(dates: [for (final week in weeks) week.weekStart]),
        const SizedBox(height: AppSpace.s3),
        Row(
          children: [
            _LegendDot(color: palette.mark, label: 'Hit', ink: colors.text),
            const SizedBox(width: AppSpace.s4),
            _LegendDot(color: palette.inactive, label: 'Missed', ink: colors.text),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.hit, required this.current, required this.palette});

  final bool hit;
  final bool current;
  final ChartPalette palette;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      height: 36,
      decoration: BoxDecoration(
        color: hit ? palette.mark : palette.inactive,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );

    if (!current) return Center(child: pill);

    // The current week is outlined rather than recoloured: it has not
    // finished yet, so saying whether it hit would be premature.
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: palette.highlight, width: AppStroke.focus),
      ),
      child: pill,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, required this.ink});

  final Color color;
  final String label;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSize.swatch,
          height: AppSize.swatch,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpace.s2),
        Text(label, style: AppTextStyles.caption.copyWith(color: ink)),
      ],
    );
  }
}
