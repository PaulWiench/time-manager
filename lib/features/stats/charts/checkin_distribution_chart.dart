/// When the day usually starts (handoff §5.6.7).
///
/// One bar per hour, over the hours that actually contain check-ins — a
/// twenty-four-hour axis for a range that never starts before seven is mostly
/// a picture of nothing. The modal bucket is highlighted because it is what
/// the header names.
library;

import 'package:flutter/widgets.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/stats_aggregation.dart';
import 'chart_palette.dart';

const double _plotHeight = 110;

class CheckinDistributionChart extends StatelessWidget {
  const CheckinDistributionChart({
    super.key,
    required this.histogram,
    required this.summary,
  });

  /// Length 24, index = hour of day.
  final List<int> histogram;

  final CheckinSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final colors = context.colors;

    var lo = 23, hi = 0;
    for (var hour = 0; hour < 24; hour++) {
      if (histogram[hour] > 0) {
        if (hour < lo) lo = hour;
        if (hour > hi) hi = hour;
      }
    }
    // An hour of air either side, so the earliest bar is not flush against
    // the card's edge.
    lo = (lo - 1).clamp(0, 23);
    hi = (hi + 1).clamp(0, 23);
    final hours = [for (var hour = lo; hour <= hi; hour++) hour];

    var maxCount = 1;
    for (final hour in hours) {
      if (histogram[hour] > maxCount) maxCount = histogram[hour];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _plotHeight + 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, hour) in hours.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpace.s1),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: histogram[hour] == 0
                            ? 2
                            : (histogram[hour] / maxCount * _plotHeight)
                                .clamp(4.0, _plotHeight),
                        decoration: BoxDecoration(
                          color: histogram[hour] == 0
                              ? palette.inactive
                              : (hour == summary.modalHour
                                  ? palette.highlight
                                  : palette.mark),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: AppSpace.s1),
                      Text(hour.toString().padLeft(2, '0'),
                          style: AppTextStyles.micro.copyWith(color: colors.textMuted)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (summary.earliest != null && summary.latest != null) ...[
          const SizedBox(height: AppSpace.s3),
          Row(
            children: [
              _Extreme(label: 'Earliest', time: summary.earliest!),
              const SizedBox(width: AppSpace.s4),
              _Extreme(label: 'Latest', time: summary.latest!),
            ],
          ),
        ],
      ],
    );
  }
}

class _Extreme extends StatelessWidget {
  const _Extreme({required this.label, required this.time});

  final String label;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
        Text(AppFormat.time(time),
            style: AppTextStyles.captionStrong.copyWith(color: colors.text)),
      ],
    );
  }
}
