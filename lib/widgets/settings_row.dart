/// Settings rows and the groups they live in (handoff §5.14, §4.5).
///
/// Settings is the densest screen in the app, so it is the one that most needs
/// structure: a kicker names each group, a card holds it, and every row inside
/// has the same shape — icon tile, label, optional sub-line, one control on the
/// right. Nothing here invents a layout for itself.
library;

import 'package:flutter/material.dart' show Switch;
import 'package:flutter/widgets.dart';

import '../core/icons/app_icons.dart';
import '../core/painting/dashed_border.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'press_scale.dart';

/// Kicker + card. Rows are separated by dividers inset past the icon tile, so
/// the tiles read as one column rather than the dividers cutting across them.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.s1),
          child: Text(title, style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
        ),
        const SizedBox(height: AppSpace.s2),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.divider, width: AppStroke.hair),
            boxShadow: colors.shadowSm,
          ),
          child: Column(
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 64, right: AppSpace.s4),
                    child: Container(height: AppStroke.hair, color: colors.divider),
                  ),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row. The right-hand side is whatever the row is for — a value and a
/// chevron, a switch, a stepper, or nothing.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.sub,
    this.value,
    this.chevron = false,
    this.trailing,
    this.onTap,
    this.onInfo,
  });

  factory SettingsRow.navigate({
    required IconData icon,
    required String label,
    String? sub,
    String? value,
    VoidCallback? onTap,
    VoidCallback? onInfo,
  }) =>
      SettingsRow(
        icon: icon,
        label: label,
        sub: sub,
        value: value,
        chevron: true,
        onTap: onTap,
        onInfo: onInfo,
      );

  /// A value with no chevron: shown, not editable here.
  factory SettingsRow.static({
    required IconData icon,
    required String label,
    String? sub,
    required String value,
    VoidCallback? onInfo,
  }) =>
      SettingsRow(icon: icon, label: label, sub: sub, value: value, onInfo: onInfo);

  factory SettingsRow.toggle({
    required IconData icon,
    required String label,
    String? sub,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onInfo,
  }) =>
      SettingsRow(
        icon: icon,
        label: label,
        sub: sub,
        trailing: Switch(value: value, onChanged: onChanged),
        onInfo: onInfo,
      );

  final IconData icon;
  final String label;
  final String? sub;
  final String? value;
  final bool chevron;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// The icon tile is its own button (additions handoff §1.1): it opens the
  /// setting's "about" sheet, while the rest of the row keeps doing what it
  /// did. Its hit area is 44 around the 36 tile without moving anything.
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PressScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: EdgeInsets.only(
          left: AppSpace.s4 - (onInfo == null ? 0 : _infoSlack),
          right: AppSpace.s4,
          top: AppSpace.s2,
          bottom: AppSpace.s2,
        ),
        child: Row(
          children: [
            _InfoTile(icon: icon, label: label, onInfo: onInfo),
            SizedBox(width: AppSpace.s3 - (onInfo == null ? 0 : _infoSlack)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTextStyles.bodyLg.copyWith(color: colors.text)),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(sub!, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
                  ],
                ],
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpace.s2),
                child: Text(value!,
                    style: AppTextStyles.body.copyWith(color: colors.textMuted)),
              ),
            if (trailing != null)
              Padding(padding: const EdgeInsets.only(left: AppSpace.s2), child: trailing!),
            if (chevron) ...[
              const SizedBox(width: AppSpace.s1),
              Icon(AppIcons.caretRight, size: AppIconSize.md, color: colors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

/// The row's icon tile. With [onInfo] it is a button with a real 44 dp hit
/// box around the 36 dp tile; the row gives back the 4 dp each side in its
/// padding and gap (see [_infoSlack]), so nothing moves.
class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.onInfo});

  final IconData icon;
  final String label;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = Container(
      width: AppSize.iconTile,
      height: AppSize.iconTile,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: AppIconSize.lg, color: colors.text),
    );
    if (onInfo == null) return tile;

    return Semantics(
      button: true,
      label: 'About $label',
      excludeSemantics: true,
      child: PressScale(
        onTap: onInfo,
        child: SizedBox.square(dimension: AppSize.touch, child: Center(child: tile)),
      ),
    );
  }
}

const double _infoSlack = (AppSize.touch - AppSize.iconTile) / 2;

/// The audit log's row: outside every group, dashed, and muted throughout.
/// Dashed is the design's word for "raw / rarely needed", and this is the only
/// place in Settings that shows the data as stored rather than as meant.
class AdvancedRow extends StatelessWidget {
  const AdvancedRow({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PressScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4,
          vertical: AppSpace.s2,
        ),
        decoration: ShapeDecoration(
          shape: DashedRoundedBorder(color: colors.textMuted, radius: AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.lg, color: colors.textMuted),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTextStyles.bodyStrong.copyWith(color: colors.textMuted)),
                  const SizedBox(height: 2),
                  Text(sub, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
                ],
              ),
            ),
            Icon(AppIcons.caretRight, size: AppIconSize.md, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
