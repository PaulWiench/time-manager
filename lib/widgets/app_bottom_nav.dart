import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum AppTab { home, history, stats, settings }

class _TabDef {
  final AppTab tab;
  final IconData regular;
  final IconData filled;
  final String label;
  const _TabDef(this.tab, this.regular, this.filled, this.label);
}

const _tabs = [
  _TabDef(AppTab.home, PhosphorIconsRegular.houseSimple, PhosphorIconsFill.houseSimple, 'Home'),
  _TabDef(AppTab.history, PhosphorIconsRegular.clockCounterClockwise, PhosphorIconsFill.clockCounterClockwise, 'History'),
  _TabDef(AppTab.stats, PhosphorIconsRegular.chartLineUp, PhosphorIconsFill.chartLineUp, 'Stats'),
  _TabDef(AppTab.settings, PhosphorIconsRegular.gearSix, PhosphorIconsFill.gearSix, 'Settings'),
];

/// Bottom navigation shell, matching the handoff's `BottomNav.dc.html`
/// component (4 fixed items, filled icon + bold label on the active tab).
class AppBottomNav extends StatelessWidget {
  final AppTab active;
  final ValueChanged<AppTab> onSelect;

  const AppBottomNav({super.key, required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final def in _tabs)
            _NavItem(
              def: def,
              on: def.tab == active,
              colors: colors,
              onTap: () => onSelect(def.tab),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabDef def;
  final bool on;
  final AppColors colors;
  final VoidCallback onTap;

  const _NavItem({required this.def, required this.on, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = on ? colors.accentFill : colors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 56),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(on ? def.filled : def.regular, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              def.label,
              style: (on ? AppTextStyles.metaMedium.copyWith(fontWeight: FontWeight.w600) : AppTextStyles.metaMedium)
                  .copyWith(color: color, letterSpacing: 0.1),
            ),
          ],
        ),
      ),
    );
  }
}
