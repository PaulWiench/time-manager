/// Average hours by weekday (handoff §5.6.6).
///
/// Seven columns, the longest one highlighted — the header already names it,
/// and the chart's job is to show by how much.
library;

import 'package:flutter/widgets.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import 'chart_palette.dart';

/// Ten hours fills the column. Past that the bar clips rather than rescaling
/// every other day into invisibility.
const double _fullScaleHours = 10;
const double _plotHeight = 120;

class WeekdayHoursChart extends StatelessWidget {
  const WeekdayHoursChart({super.key, required this.averages});

  /// Length 7, Monday first.
  final List<double> averages;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final colors = context.colors;

    var longest = 0;
    for (var i = 1; i < averages.length; i++) {
      if (averages[i] > averages[longest]) longest = i;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, average) in averages.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  average > 0 ? AppFormat.hm(average) : '—',
                  style: AppTextStyles.micro.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: AppSpace.s1),
                Container(
                  height: average <= 0
                      ? 2
                      : (average / _fullScaleHours * _plotHeight).clamp(4.0, _plotHeight),
                  decoration: BoxDecoration(
                    color: average <= 0
                        ? palette.inactive
                        : (i == longest ? palette.highlight : palette.mark),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                const SizedBox(height: AppSpace.s1),
                Text(_labels[i],
                    style: AppTextStyles.micro.copyWith(color: colors.textMuted)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
