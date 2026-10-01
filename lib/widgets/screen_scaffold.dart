/// The two page shapes the app has (handoff §3.1, §3.3).
///
/// [TabScreen] is a root tab: no Scaffold of its own — the shell owns the only
/// one — no app bar, and a title that scrolls away with the content, because a
/// pinned bar would compete with Home's slab for the top of the screen.
///
/// [SubScreen] is a pushed page: its own Scaffold, a back button, and a
/// subtitle that says what the page is for.
library;

import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'buttons.dart';

class TabScreen extends StatelessWidget {
  const TabScreen({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.action,
    this.gutter = AppSpace.gutterSparse,
    this.controller,
    this.header,
  });

  final String title;

  /// Home's date line. The other tabs have nothing to say under their title.
  final String? subtitle;

  final List<Widget> children;

  /// A single control on the title row, e.g. Home's gear.
  final Widget? action;

  /// Sparse screens (Home) breathe at 20; the list screens are denser at 16.
  final double gutter;

  final ScrollController? controller;

  /// Under the title row — the job pill, when there is more than one job.
  /// Its spacing comes with it, so a hidden pill leaves no gap.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: true,
      bottom: false,
      child: ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
          gutter,
          AppSpace.s3,
          gutter,
          // The floating nav sits over the content, so the last item needs
          // room to clear it as well as the system gesture inset.
          AppSpace.navClearance + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.title.copyWith(color: colors.text),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.body.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s3),
              child: header!,
            ),
          ...children,
        ],
      ),
    );
  }
}

class SubScreen extends StatelessWidget {
  const SubScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.gutter = AppSpace.gutterDense,
  });

  final String title;
  final String? subtitle;

  /// An action on the back row, e.g. the holidays screen's Add pill.
  final Widget? action;

  final Widget child;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              // The back button's own 44 dp box already carries padding, so it
              // bleeds 8 into the gutter to sit optically on the margin.
              padding: EdgeInsets.fromLTRB(
                gutter - AppSpace.s2,
                AppSpace.s1,
                gutter,
                0,
              ),
              child: Row(
                children: [
                  AppIconButton(
                    icon: AppIcons.caretLeft,
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (action != null) action!,
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, AppSpace.s2, gutter, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.title.copyWith(color: colors.text),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpace.s2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s5),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
