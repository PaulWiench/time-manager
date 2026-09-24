/// The dialog shell every editor in Settings uses.
///
/// Material's [AlertDialog] gets close with theming, but not to the title
/// weight, the action shapes or the padding this design asks for — and each
/// call site that patched it patched it slightly differently. One shell, one
/// set of decisions.
library;

import 'package:flutter/material.dart' show showDialog;
import 'package:flutter/widgets.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: builder,
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Laid out right-aligned, in order — a text button and then a pill.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s5),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s5),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: colors.shadowFloat,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(),
                  style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpace.s2),
                Text(subtitle!,
                    style: AppTextStyles.body.copyWith(color: colors.textMuted)),
              ],
              const SizedBox(height: AppSpace.s4),
              child,
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpace.s5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final (i, action) in actions.indexed) ...[
                      if (i > 0) const SizedBox(width: AppSpace.s2),
                      action,
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
