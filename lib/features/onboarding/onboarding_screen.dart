import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/date_only.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/outlined_primary_button.dart';

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// 4-step cancelable onboarding wizard (design handoff §4). Cancelling via
/// the X at any step keeps steps already confirmed via Continue and
/// silently defaults the rest — no confirmation dialog, per the UX doc.
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _defaultWeeklyHours = 40.0;
  static final _defaultWorkDays = {1, 2, 3, 4, 5};
  static const _defaultStartingBalance = 0.0;
  static const _defaultAutoBreak = true;

  int _step = 0;

  // Committed once "Continue" is pressed for that step; null = not yet
  // confirmed, so cancelling now falls back to the default.
  double? _committedWeeklyHours;
  Set<int>? _committedWorkDays;
  double? _committedStartingBalance;
  bool? _committedAutoBreak;

  // Live, editable draft for the current step.
  double _weeklyHours = _defaultWeeklyHours;
  final Set<int> _workDays = {..._defaultWorkDays};
  double _startingBalance = _defaultStartingBalance;
  bool _autoBreak = _defaultAutoBreak;

  bool _submitting = false;

  Future<void> _finish({required bool cancelled}) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final weeklyHours = cancelled ? (_committedWeeklyHours ?? _defaultWeeklyHours) : _weeklyHours;
    final workDays = cancelled ? (_committedWorkDays ?? _defaultWorkDays) : _workDays;
    final startingBalance = cancelled ? (_committedStartingBalance ?? _defaultStartingBalance) : _startingBalance;
    final autoBreak = cancelled ? (_committedAutoBreak ?? _defaultAutoBreak) : _autoBreak;

    final today = dateOnly(DateTime.now());
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.seedStartingBalance(balance: startingBalance, effectiveFrom: today);
    await settingsRepo.save(
      effectiveFrom: today,
      weeklyHours: weeklyHours,
      workDays: (workDays.toList()..sort()),
      minSessionMinutes: 5,
      autoBreakEnabled: autoBreak,
      restrictCheckin: false,
    );

    widget.onDone();
  }

  void _continue() {
    switch (_step) {
      case 0:
        _committedWeeklyHours = _weeklyHours;
      case 1:
        _committedWorkDays = {..._workDays};
      case 2:
        _committedStartingBalance = _startingBalance;
      case 3:
        _committedAutoBreak = _autoBreak;
        _finish(cancelled: false);
        return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _submitting ? null : () => _finish(cancelled: true),
                    child: PhosphorIcon(PhosphorIconsRegular.x, size: 18, color: colors.textMuted),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Container(
                          width: 20,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i <= _step ? colors.accentFill : colors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 18),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [_buildStep(colors)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                children: [
                  OutlinedPrimaryButton(label: 'Continue', onPressed: _submitting ? null : _continue),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: (_submitting || _step == 0) ? null : _back,
                    child: Text(
                      'Back',
                      style: AppTextStyles.body.copyWith(color: _step == 0 ? colors.divider : colors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(AppColors colors) {
    switch (_step) {
      case 0:
        return _StepShell(
          step: 1,
          icon: PhosphorIconsRegular.clock,
          title: 'How many hours a week do you work?',
          helper: 'You can change this anytime in Settings.',
          defaultCaption: 'Default: 40h',
          colors: colors,
          child: _Stepper(
            label: AppFormat.hoursLabel(_weeklyHours),
            onDecrement: () => setState(() => _weeklyHours = (_weeklyHours - 0.5).clamp(0, 80)),
            onIncrement: () => setState(() => _weeklyHours = (_weeklyHours + 0.5).clamp(0, 80)),
            colors: colors,
          ),
        );
      case 1:
        return _StepShell(
          step: 2,
          icon: PhosphorIconsRegular.calendarCheck,
          title: 'Which days do you work?',
          helper: 'You can change this anytime in Settings.',
          defaultCaption: 'Default: Mon – Fri',
          colors: colors,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _WeekdayPill(
                  label: _weekdayLabels[i],
                  selected: _workDays.contains(i + 1),
                  colors: colors,
                  onTap: () => setState(() {
                    final weekday = i + 1;
                    if (_workDays.contains(weekday)) {
                      _workDays.remove(weekday);
                    } else {
                      _workDays.add(weekday);
                    }
                  }),
                ),
              ],
            ],
          ),
        );
      case 2:
        return _StepShell(
          step: 3,
          icon: PhosphorIconsRegular.scales,
          title: 'Any existing hour balance to carry over?',
          helper: 'Positive if you\'re owed hours, negative if you owe them.',
          defaultCaption: 'Default: 0:00',
          colors: colors,
          child: _Stepper(
            label: AppFormat.hm(_startingBalance, signed: true),
            onDecrement: () => setState(() => _startingBalance -= 1),
            onIncrement: () => setState(() => _startingBalance += 1),
            colors: colors,
          ),
        );
      case 3:
        return _StepShell(
          step: 4,
          icon: PhosphorIconsRegular.coffee,
          title: 'Automatically deduct legal breaks?',
          helper: 'German labor law requires a break after 6h and 9h of work — TimeManager can apply it for you.',
          defaultCaption: 'Default: On',
          colors: colors,
          child: GestureDetector(
            onTap: () => setState(() => _autoBreak = !_autoBreak),
            child: Container(
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _autoBreak ? colors.accentFill : colors.divider,
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: _autoBreak ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StepShell extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String helper;
  final String defaultCaption;
  final AppColors colors;
  final Widget child;

  const _StepShell({
    required this.step,
    required this.icon,
    required this.title,
    required this.helper,
    required this.defaultCaption,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'STEP $step OF 4',
          style: AppTextStyles.metaMedium.copyWith(color: colors.textMuted, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        PhosphorIcon(icon, size: 40, color: colors.accentFill),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: AppTextStyles.onboardingTitle.copyWith(color: colors.text)),
        const SizedBox(height: 8),
        Text(helper, textAlign: TextAlign.center, style: AppTextStyles.bodyRegular.copyWith(color: colors.textMuted)),
        const SizedBox(height: 26),
        child,
        const SizedBox(height: 14),
        Text(defaultCaption, style: AppTextStyles.meta.copyWith(color: colors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _WeekdayPill extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  const _WeekdayPill({required this.label, required this.selected, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? colors.accentTint : Colors.transparent,
          border: Border.all(color: selected ? colors.accentFill : colors.divider, width: 1.5),
        ),
        child: Text(label, style: AppTextStyles.heroNumber(12).copyWith(color: selected ? colors.accentText : colors.textMuted)),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final AppColors colors;

  const _Stepper({required this.label, required this.onDecrement, required this.onIncrement, required this.colors});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.divider)),
            child: PhosphorIcon(icon, size: 16, color: colors.text),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(PhosphorIconsRegular.minus, onDecrement),
        SizedBox(width: 90, child: Text(label, textAlign: TextAlign.center, style: AppTextStyles.heroNumber(22).copyWith(color: colors.text))),
        button(PhosphorIconsRegular.plus, onIncrement),
      ],
    );
  }
}
