/// The floating pill nav (handoff §3.2).
///
/// It replaces a full-width Material [NavigationBar]: the nav is cut from the
/// same Dusk Slab as Home's hero block, floats clear of the content, and the
/// active item is an apricot pill that slides between positions rather than
/// four items that each recolour in place.
///
/// In light mode the bar is the slab, which is the design's signature move. In
/// dark mode the slab would be invisible against the background, so it steps up
/// to `surface2` instead — the same reason the slab is the one surface that
/// does not invert.
library;

import 'package:flutter/widgets.dart';

import '../core/icons/app_icons.dart';
import '../core/motion.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'press_scale.dart';

enum AppTab { home, history, stats, settings }

class _TabDef {
  const _TabDef(this.tab, this.bold, this.fill, this.label);
  final AppTab tab;
  final IconData bold;
  final IconData fill;
  final String label;
}

const _tabs = [
  _TabDef(AppTab.home, AppIcons.houseSimple, AppIconsFill.houseSimple, 'Home'),
  _TabDef(AppTab.history, AppIcons.clockCounterClockwise,
      AppIconsFill.clockCounterClockwise, 'History'),
  _TabDef(AppTab.stats, AppIcons.chartLineUp, AppIconsFill.chartLineUp, 'Stats'),
  _TabDef(AppTab.settings, AppIcons.gearSix, AppIconsFill.gearSix, 'Settings'),
];

/// Inset from the screen edges, and the height of the active pill inside the
/// 64 dp bar.
const double kNavInset = AppSpace.s4;
const double _padding = AppSpace.s2;
const double _gap = AppSpace.s1;
const double _activeHeight = 48;

class PillNav extends StatelessWidget {
  const PillNav({super.key, required this.active, required this.onSelect});

  final AppTab active;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = AppMotion.of(context);
    final dark = colors.background.computeLuminance() < 0.5;
    final ground = dark ? colors.surface2 : colors.slab;
    final inactive = dark ? colors.textMuted : colors.onSlabMuted;

    return Container(
      height: AppSize.navHeight,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: colors.shadowFloat,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth =
              (constraints.maxWidth - _gap * (_tabs.length - 1)) / _tabs.length;
          final activeIndex = _tabs.indexWhere((t) => t.tab == active);

          return Stack(
            children: [
              AnimatedPositioned(
                duration: motion.navPill,
                curve: AppCurves.control,
                left: activeIndex * (itemWidth + _gap),
                top: 0,
                width: itemWidth,
                height: _activeHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.accentFill,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (i, def) in _tabs.indexed) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: itemWidth,
                      child: _NavItem(
                        def: def,
                        selected: def.tab == active,
                        inactiveColor: inactive,
                        onTap: () => onSelect(def.tab),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.def,
    required this.selected,
    required this.inactiveColor,
    required this.onTap,
  });

  final _TabDef def;
  final bool selected;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.onAccent : inactiveColor;

    return PressScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: def.label,
        child: SizedBox(
          height: _activeHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? def.fill : def.bold,
                size: AppIconSize.nav,
                color: foreground,
              ),
              const SizedBox(height: AppSpace.s1),
              Text(
                def.label,
                style: (selected ? AppTextStyles.captionStrong : AppTextStyles.caption)
                    .copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
