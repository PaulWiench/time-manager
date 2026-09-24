/// Which colour every chart mark is, decided once.
///
/// Before this, each chart reached for `accentFill` inline — which is the
/// *block* fill, pale by design, and reads as thin when it is a 2 dp line or a
/// 6 dp bar on a white card. Marks want `accentStrong`; blocks want
/// `accentFill`. Keeping that distinction in one place is the difference
/// between the charts looking deliberate and looking approximate.
library;

import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';

class ChartPalette {
  const ChartPalette._(this._colors);

  factory ChartPalette.of(BuildContext context) => ChartPalette._(context.colors);

  final AppColors _colors;

  /// Lines and bars. In dark this equals `accentFill`; in light it is a
  /// deeper burnt orange, because a pale fill cannot carry a hairline.
  Color get mark => _colors.accentStrong;

  /// The area under a line, and any wash behind a mark.
  Color get wash => _colors.accentTint;

  /// One mark singled out: today's bar, the current week, the modal bucket,
  /// the last point of a trend.
  Color get highlight => _colors.selected;

  /// A mark that exists but stands for nothing: a missed week, a weekend, a
  /// weekday with no data.
  Color get inactive => _colors.track;

  /// Dashed background gridlines.
  Color get grid => _colors.divider;

  /// The zero line and the target line, which are statements rather than
  /// scaffolding and so sit above the grid.
  Color get baseline => _colors.textMuted;

  Color get axisLabel => _colors.textMuted;

  /// The card behind the chart, for knocking a hole in a mark.
  Color get ground => _colors.surface;

  /// Leave, punched through the heatmap.
  Color get leave => _colors.vacationFill;

  /// The heatmap's six steps, least to most.
  List<Color> get heat => [
        _colors.heat0,
        _colors.heat1,
        _colors.heat2,
        _colors.heat3,
        _colors.heat4,
        _colors.heat5,
      ];

  /// The legend under the heatmap, in step order.
  static const heatLabels = ['0 h', '<4 h', '4–6', '6–tgt', '±15m', 'over'];

  /// Which step a day lands on. The steps are absolute hours rather than a
  /// ratio, except at the top: hitting the target within a quarter of an hour
  /// is its own step, and going past it is the darkest. That way a short day
  /// and a long one look different even when both missed.
  Color heatFor(double worked, double target) {
    if (worked <= 0) return heat[0];
    if (target > 0) {
      if (worked > target + 0.25) return heat[5];
      if (worked >= target - 0.25) return heat[4];
    }
    if (worked < 4) return heat[1];
    if (worked < 6) return heat[2];
    return heat[3];
  }
}
