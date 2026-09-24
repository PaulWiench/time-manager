/// The segmented control (handoff §5.9).
///
/// One control for both places the app switches between sibling views —
/// History's Month/Week/Day and Stats' Overview/Patterns/Leave. Golden Hour has
/// no underline tab, so the Stats [TabBar] becomes this too, which also means
/// the two screens stop looking like they were built by different people.
library;

import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'press_scale.dart';

class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelect,
  });

  /// Value and label per segment, in display order.
  final List<(T, String)> segments;

  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = AppMotion.of(context);
    final index = segments.indexWhere((s) => s.$1 == selected);

    return Container(
      height: AppSize.segmented,
      padding: const EdgeInsets.all(AppSpace.s1),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = AppSpace.s1;
          final width =
              (constraints.maxWidth - gap * (segments.length - 1)) / segments.length;

          return Stack(
            children: [
              if (index >= 0)
                AnimatedPositioned(
                  duration: motion.control,
                  curve: AppCurves.control,
                  left: index * (width + gap),
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.selected,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final (i, segment) in segments.indexed) ...[
                    if (i > 0) SizedBox(width: gap),
                    SizedBox(
                      width: width,
                      child: PressScale(
                        onTap: () => onSelect(segment.$1),
                        child: Semantics(
                          button: true,
                          selected: segment.$1 == selected,
                          label: segment.$2,
                          child: Center(
                            child: Text(
                              segment.$2,
                              style: AppTextStyles.label.copyWith(
                                color: segment.$1 == selected
                                    ? colors.onSelected
                                    : colors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
