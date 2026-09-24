/// The four-step setup wizard, and the only writer of the first settings row.
///
/// Cancelling with the X at any step keeps whatever was already confirmed with
/// Continue and silently defaults the rest — no confirmation dialog. Setup is
/// four questions with sensible answers already filled in; making someone
/// confirm that they want to skip it would be worse than skipping it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/date_only.dart';
import '../../providers/repository_providers.dart';
import 'onboarding_body.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _defaultWeeklyHours = 40.0;
  static const _defaultWorkDays = {1, 2, 3, 4, 5};
  static const _defaultStartingBalance = 0.0;
  static const _defaultAutoBreak = true;

  int _step = 0;

  /// Committed once Continue is pressed for that step; null means not yet
  /// confirmed, so cancelling now falls back to the default.
  double? _committedWeeklyHours;
  Set<int>? _committedWorkDays;
  double? _committedStartingBalance;
  bool? _committedAutoBreak;

  double _weeklyHours = _defaultWeeklyHours;
  final Set<int> _workDays = {..._defaultWorkDays};
  double _startingBalance = _defaultStartingBalance;
  bool _autoBreak = _defaultAutoBreak;

  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: OnboardingBody(
        step: _step,
        weeklyHours: _weeklyHours,
        workDays: _workDays,
        startingBalance: _startingBalance,
        autoBreak: _autoBreak,
        busy: _submitting,
        onCancel: () => _finish(cancelled: true),
        onContinue: _continue,
        onBack: _back,
        onWeeklyHours: (value) => setState(() => _weeklyHours = value),
        onToggleWorkDay: (day) => setState(() {
          if (!_workDays.remove(day)) _workDays.add(day);
        }),
        onStartingBalance: (value) => setState(() => _startingBalance = value),
        onAutoBreak: (value) => setState(() => _autoBreak = value),
      ),
    );
  }

  void _continue() {
    switch (_step) {
      case 0:
        _committedWeeklyHours = _weeklyHours;
      case 1:
        _committedWorkDays = {..._workDays};
      case 2:
        _committedStartingBalance = _startingBalance;
      default:
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

  Future<void> _finish({required bool cancelled}) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final weeklyHours =
        cancelled ? (_committedWeeklyHours ?? _defaultWeeklyHours) : _weeklyHours;
    final workDays = cancelled ? (_committedWorkDays ?? _defaultWorkDays) : _workDays;
    final startingBalance =
        cancelled ? (_committedStartingBalance ?? _defaultStartingBalance) : _startingBalance;
    final autoBreak = cancelled ? (_committedAutoBreak ?? _defaultAutoBreak) : _autoBreak;

    final today = dateOnly(DateTime.now());
    final settings = ref.read(settingsRepositoryProvider);
    await settings.seedStartingBalance(balance: startingBalance, effectiveFrom: today);
    await settings.save(
      effectiveFrom: today,
      weeklyHours: weeklyHours,
      workDays: workDays.toList()..sort(),
      minSessionMinutes: 5,
      autoBreakEnabled: autoBreak,
      restrictCheckin: false,
    );

    widget.onDone();
  }
}
