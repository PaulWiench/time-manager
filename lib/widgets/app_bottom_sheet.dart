/// The bottom sheet (handoff §5.13).
///
/// One helper rather than a `showModalBottomSheet` call per site, because the
/// details that make a sheet feel deliberate — the scrim colour, the top-only
/// radius, the handle, where the keyboard pushes it — are exactly the ones that
/// get forgotten when each call site spells them out again.
library;

import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:flutter/widgets.dart';

import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'buttons.dart';

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final colors = context.colors;

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: colors.surface,
    barrierColor: colors.scrim,
    // The edit sheet holds two time fields and a note; the keyboard must push
    // it up rather than cover what is being typed.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: builder(context),
    ),
  );
}

/// The inside of a sheet: handle, titled header with a close button, content,
/// and a row of actions at the bottom.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.actions = const [],
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Secondary then primary, each taking equal width.
  final List<Widget> actions;

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s5,
          AppSpace.s2,
          AppSpace.s5,
          AppSpace.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.headline.copyWith(color: colors.text)),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpace.s1),
                        Text(subtitle!,
                            style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
                      ],
                    ],
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.x,
                  semanticLabel: 'Close',
                  color: colors.textMuted,
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
            for (final child in children) ...[
              const SizedBox(height: AppSpace.s4),
              child,
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s4),
              Row(
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpace.s3),
                    Expanded(child: action),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A labelled value that opens a picker — the Start / End / Note fields in the
/// edit sheet.
class SheetField extends StatelessWidget {
  const SheetField({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.onTap,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4,
          vertical: AppSpace.s3,
        ),
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
            const SizedBox(height: AppSpace.s1),
            Text(
              value,
              style: (valueStyle ?? AppTextStyles.statSm).copyWith(color: colors.text),
            ),
          ],
        ),
      ),
    );
  }
}
