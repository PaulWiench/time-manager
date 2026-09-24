/// The range chip (handoff §5.10), used by Stats' 1W / 1M / 6M / 1Y / Custom row.
///
/// Short labels with the full words carried in semantics: five spelled-out
/// ranges do not fit 361 dp at `label` size, and a chip row that scrolls
/// sideways hides options rather than offering them.
library;

import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'press_scale.dart';

class RangeChip extends StatelessWidget {
  const RangeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// The spelled-out range, e.g. "6 months" for `6M`.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = AppMotion.of(context);

    return PressScale(
      onTap: onTap,
      // The chip is 36 tall but the target is 44, so the row stays reachable
      // without the chips themselves growing.
      child: Semantics(
        button: true,
        selected: selected,
        label: semanticLabel ?? label,
        child: SizedBox(
          height: AppSize.touch,
          child: Center(
            child: AnimatedContainer(
              duration: motion.control,
              curve: AppCurves.control,
              height: AppSize.rangeChip,
              // The padding is a minimum, not a reservation: the five chips
              // share the row equally, and "Custom" has to fit in its fifth
              // without wrapping to a second line.
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2),
              constraints: const BoxConstraints(minWidth: AppSize.touch),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.selected : colors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: AppTextStyles.label.copyWith(
                  color: selected ? colors.onSelected : colors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
