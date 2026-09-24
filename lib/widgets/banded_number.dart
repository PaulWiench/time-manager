/// A number with Golden Hour's one warning treatment.
///
/// The design has exactly one way of saying "this has gone past a bound you
/// set": the digits change colour and a band sits behind their lower half,
/// like a highlighter. No red, no green, no icon, no badge — so when it does
/// appear it means one specific thing, and a merely negative balance (which is
/// normal for this app) stays plain.
///
/// Used by Home's hero balance, History's day deltas and Stats' headlines,
/// which is why it takes its colours rather than picking them: the same
/// treatment reads `warningFill` on the slab and `warningText` on paper.
library;

import 'package:flutter/widgets.dart';

class BandedNumber extends StatelessWidget {
  const BandedNumber({
    super.key,
    required this.text,
    required this.style,
    required this.warning,
    required this.plainColor,
    required this.warningColor,
    required this.bandColor,
    this.bandOpacity = 1.0,
  });

  final String text;
  final TextStyle style;
  final bool warning;

  final Color plainColor;
  final Color warningColor;
  final Color bandColor;

  /// The slab draws the band at 28 % so the digits stay the brighter thing;
  /// on a light surface the tint is already pale enough at full strength.
  final double bandOpacity;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: style.copyWith(color: warning ? warningColor : plainColor),
    );
    if (!warning) return label;

    final lineHeight = (style.fontSize ?? 14) * (style.height ?? 1.2);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The band covers the lower half of the line box and overhangs the
        // digits slightly, so it reads as drawn on rather than as a fill.
        Positioned(
          left: -2,
          right: -2,
          top: lineHeight * 0.55,
          bottom: lineHeight * 0.08,
          child: ColoredBox(color: bandColor.withValues(alpha: bandOpacity)),
        ),
        label,
      ],
    );
  }
}
