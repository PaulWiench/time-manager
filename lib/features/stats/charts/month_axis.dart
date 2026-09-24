/// Month labels under a chart whose x axis is time.
///
/// Shared by the balance trend and the hit-rate pills, which both run over the
/// same range and must agree about where July starts. Labels that would sit on
/// top of each other are dropped rather than overlapped — a range beginning
/// six days before the end of a month should not print that month's name.
library;

import 'package:flutter/widgets.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const double _labelWidth = 32;
const double _minSeparation = 0.09;

class MonthAxis extends StatelessWidget {
  const MonthAxis({super.key, required this.dates});

  /// One date per plotted position, in order.
  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (dates.length < 2) return const SizedBox(height: 14);

    final marks = <(double, String)>[];
    var lastMonth = -1;
    var lastFraction = -1.0;

    for (final (i, date) in dates.indexed) {
      if (date.month == lastMonth) continue;
      lastMonth = date.month;
      final fraction = i / (dates.length - 1);
      if (lastFraction >= 0 && fraction - lastFraction < _minSeparation) continue;
      lastFraction = fraction;
      marks.add((fraction, AppFormat.monthAbbrev(date)));
    }

    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            for (final (fraction, label) in marks)
              Positioned(
                // Centred on the tick, but never hanging off either end.
                left: (fraction * constraints.maxWidth - _labelWidth / 2)
                    .clamp(0.0, constraints.maxWidth - _labelWidth),
                width: _labelWidth,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.micro.copyWith(color: colors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
