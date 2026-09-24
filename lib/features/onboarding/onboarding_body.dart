/// The four onboarding steps, drawn (handoff §4.1).
///
/// Left-aligned questions with a step kicker above them, one input card each,
/// and a caption naming the default so it is obvious that skipping is safe.
/// Back is hidden on the first step rather than disabled — a control that
/// cannot be used is noise, and a disabled one here failed contrast as well.
library;

import 'package:flutter/material.dart' show Switch;
import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/buttons.dart';
import '../../widgets/stepper_field.dart';

const int kOnboardingSteps = 4;

class OnboardingBody extends StatelessWidget {
  const OnboardingBody({
    super.key,
    required this.step,
    required this.weeklyHours,
    required this.workDays,
    required this.startingBalance,
    required this.autoBreak,
    this.onCancel,
    this.onContinue,
    this.onBack,
    this.onWeeklyHours,
    this.onToggleWorkDay,
    this.onStartingBalance,
    this.onAutoBreak,
    this.busy = false,
  });

  /// Zero-based.
  final int step;

  final double weeklyHours;
  final Set<int> workDays;
  final double startingBalance;
  final bool autoBreak;

  final VoidCallback? onCancel;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final ValueChanged<double>? onWeeklyHours;
  final ValueChanged<int>? onToggleWorkDay;
  final ValueChanged<double>? onStartingBalance;
  final ValueChanged<bool>? onAutoBreak;

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutterSparse,
          0,
          AppSpace.gutterSparse,
          AppSpace.s6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: AppSize.touch,
              child: Row(
                children: [
                  // The button's own 44 dp box carries its padding, so it
                  // bleeds back into the gutter to sit optically on the margin.
                  Transform.translate(
                    offset: const Offset(-AppSpace.s3, 0),
                    child: AppIconButton(
                      icon: AppIcons.x,
                      semanticLabel: 'Cancel setup',
                      onPressed: busy ? null : onCancel,
                    ),
                  ),
                  Expanded(child: Center(child: _StepIndicator(step: step))),
                  const SizedBox(width: AppSize.touch),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s10),
            Text('STEP ${step + 1} OF $kOnboardingSteps',
                style: AppTextStyles.kicker.copyWith(color: colors.accentText)),
            const SizedBox(height: AppSpace.s3),
            Text(_question, style: AppTextStyles.title.copyWith(color: colors.text)),
            const SizedBox(height: AppSpace.s3),
            Text(_helper, style: AppTextStyles.body.copyWith(color: colors.textMuted)),
            const SizedBox(height: AppSpace.s8),
            _InputCard(child: _input(context)),
            const SizedBox(height: AppSpace.s3),
            Padding(
              padding: const EdgeInsets.only(left: AppSpace.s1),
              child: Text(_defaultCaption,
                  style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
            ),
            const Spacer(),
            PrimaryPill(
              label: step == kOnboardingSteps - 1 ? 'Finish' : 'Continue',
              onPressed: busy ? null : onContinue,
            ),
            const SizedBox(height: AppSpace.s2),
            // The space is kept on step 1 so Continue does not jump when Back
            // appears.
            SizedBox(
              height: AppSize.touch,
              child: step == 0
                  ? null
                  : Center(
                      child: AppTextButton(
                        label: 'Back',
                        onPressed: busy ? null : onBack,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String get _question => switch (step) {
        0 => 'How many hours a week do you work?',
        1 => 'Which days do you work?',
        2 => 'Any existing hour balance to carry over?',
        _ => 'Automatically deduct legal breaks?',
      };

  String get _helper => switch (step) {
        0 => 'You can change this anytime in Settings.',
        1 => 'You can change this anytime in Settings.',
        2 => "Positive if you're owed hours, negative if you owe them.",
        _ => 'German labour law requires a break after 6 h and 9 h of work — '
            'TimeManager can apply it for you.',
      };

  String get _defaultCaption => switch (step) {
        0 => 'Default: 40 h',
        1 => 'Default: Mon–Fri',
        2 => 'Default: 0:00',
        _ => 'Default: On',
      };

  Widget _input(BuildContext context) {
    final colors = context.colors;

    return switch (step) {
      0 => StepperField(
          label: AppFormat.hoursLabel(weeklyHours).replaceAll(' h', ''),
          unit: 'h',
          onDecrease: () => onWeeklyHours?.call((weeklyHours - 0.5).clamp(0, 80)),
          onIncrease: () => onWeeklyHours?.call((weeklyHours + 0.5).clamp(0, 80)),
        ),
      1 => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeekdayToggles(
              selected: workDays,
              onToggle: (day) => onToggleWorkDay?.call(day),
            ),
            const SizedBox(height: AppSpace.s3),
            Text(
              '${workDays.length} day${workDays.length == 1 ? '' : 's'} selected',
              style: AppTextStyles.caption.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      2 => StepperField(
          label: AppFormat.hm(startingBalance, signed: true),
          unit: 'h',
          onDecrease: () => onStartingBalance?.call(startingBalance - 1),
          onIncrease: () => onStartingBalance?.call(startingBalance + 1),
        ),
      _ => Row(
          children: [
            Container(
              width: AppSize.iconTile,
              height: AppSize.iconTile,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.breakTint,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(AppIcons.coffee,
                  size: AppIconSize.lg, color: colors.breakText),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Auto-break',
                      style: AppTextStyles.bodyLg.copyWith(color: colors.text)),
                  Text('30 min after 6 h, 45 min after 9 h',
                      style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
                ],
              ),
            ),
            Switch(value: autoBreak, onChanged: (on) => onAutoBreak?.call(on)),
          ],
        ),
    };
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider, width: AppStroke.hair),
        boxShadow: colors.shadowSm,
      ),
      child: child,
    );
  }
}

/// Four pills, the current one wider. A progress bar would imply the steps
/// take different amounts of work; they do not.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      label: 'Step ${step + 1} of $kOnboardingSteps',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < kOnboardingSteps; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.s2),
            Container(
              width: i == step ? 40 : 24,
              height: 6,
              decoration: BoxDecoration(
                color: i <= step ? colors.accentFill : colors.track,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                // Apricot on paper is pale enough to disappear; a hairline
                // keeps the finished steps legible in light mode.
                border: i <= step && colors.shadowSm.isNotEmpty
                    ? Border.all(color: colors.accentStrong, width: 1)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
