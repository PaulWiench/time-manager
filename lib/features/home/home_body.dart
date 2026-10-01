/// Home, drawn from a [HomeView] and nothing else.
///
/// No providers, no database, no clock — everything it needs is in the value it
/// is given, which is what lets every designed state be rendered offscreen in
/// about a second.
library;

import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/tracking_palette.dart';
import '../../domain/tracking_state.dart';
import '../../widgets/banded_number.dart';
import '../../widgets/buttons.dart';
import '../../widgets/day_rail.dart';
import '../../widgets/event_timeline.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/sun_dial.dart';
import 'home_view.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({
    super.key,
    this.jobPill,
    required this.view,
    this.onOpenSettings,
    this.onToggleTracking,
    this.onRemoveLeave,
    this.endedJob,
    this.onSwitchJob,
  });

  /// The job switcher pill, shown under the title when there are several
  /// jobs. Passed in so this body stays free of providers.
  final Widget? jobPill;

  final HomeView view;
  final VoidCallback? onOpenSettings;

  /// Check in or out, depending on the state — the ring is the button.
  final VoidCallback? onToggleTracking;

  /// Clears today's leave, from the notice that appears when the day carries
  /// both leave and real work.
  final VoidCallback? onRemoveLeave;

  /// The selected job has ended (additions handoff §3.3): the slab shows its
  /// final balance and end date, the ring is not a button, and the page says
  /// how to get back to tracking.
  final EndedJob? endedJob;
  final VoidCallback? onSwitchJob;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TabScreen(
      title: 'TimeManager',
      header: jobPill,
      subtitle: view.dateLabel,
      action: AppIconButton(
        icon: AppIcons.gearSix,
        semanticLabel: 'Settings',
        color: colors.textMuted,
        onPressed: onOpenSettings,
      ),
      children: endedJob != null
          ? [
              const SizedBox(height: AppSpace.s4),
              _EndedSlab(job: endedJob!),
              const SizedBox(height: AppSpace.s6),
              Text(
                'This job ended on ${endedJob!.endLabel}. Its history and stats stay '
                'available. To track time, switch to an active job.',
                style: AppTextStyles.body.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: AppSpace.s4),
              SecondaryPill(label: 'Switch job', onPressed: onSwitchJob),
            ]
          : [
              const SizedBox(height: AppSpace.s4),
              _DuskSlab(
                view: view,
                onToggleTracking: onToggleTracking,
                onRemoveLeave: onRemoveLeave,
              ),
              const SizedBox(height: AppSpace.s8),
              if (view.hasActivity)
                _TodaySection(view: view)
              else
                _EmptyToday(onCheckIn: onToggleTracking),
            ],
    );
  }
}

/// The hero block: balance, ring and today bar on one deep-violet card. The
/// three things you open the app to see, in one glance, without scrolling.
class _DuskSlab extends StatelessWidget {
  const _DuskSlab({
    required this.view,
    required this.onToggleTracking,
    required this.onRemoveLeave,
  });

  final HomeView view;
  final VoidCallback? onToggleTracking;
  final VoidCallback? onRemoveLeave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpace.s6,
        horizontal: AppSpace.s5,
      ),
      decoration: BoxDecoration(
        color: colors.slab,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: colors.slabRim == null
            ? null
            : Border.all(color: colors.slabRim!),
        boxShadow: colors.shadowSlab,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Balance(view: view),
          const SizedBox(height: AppSpace.s4),
          Center(
            child: _Ring(view: view, onToggleTracking: onToggleTracking),
          ),
          const SizedBox(height: AppSpace.s4),
          _TodayBar(view: view),
          if (view.leaveConflict != null) ...[
            const SizedBox(height: AppSpace.s4),
            _LeaveConflictNotice(
              conflict: view.leaveConflict!,
              onRemove: onRemoveLeave,
            ),
          ],
        ],
      ),
    );
  }
}

/// Both leave and real work on the same day. Says so, and offers the one fix
/// the app cannot choose for you.
class _LeaveConflictNotice extends StatelessWidget {
  const _LeaveConflictNotice({required this.conflict, required this.onRemove});

  final LeaveConflict conflict;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s3,
        AppSpace.s3,
        AppSpace.s3,
        AppSpace.s1,
      ),
      decoration: BoxDecoration(
        color: colors.slabTrack,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  AppIcons.airplaneTilt,
                  size: AppIconSize.sm,
                  color: colors.accentFill,
                ),
              ),
              const SizedBox(width: AppSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conflict.headline,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: colors.onSlab,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conflict.detail,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.onSlabMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: PressScale(
              onTap: onRemove,
              child: Semantics(
                button: true,
                label: "Remove today's leave",
                child: Container(
                  height: AppSize.touch,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(left: AppSpace.s4),
                  child: Text(
                    'Remove',
                    style: AppTextStyles.label.copyWith(
                      color: colors.accentFill,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({required this.view});

  final HomeView view;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BALANCE',
          style: AppTextStyles.kicker.copyWith(color: colors.onSlabMuted),
        ),
        const SizedBox(height: AppSpace.s1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            BandedNumber(
              text: AppFormat.hm(view.balanceHours, signed: true),
              style: AppTextStyles.hero,
              warning: view.balanceWarning,
              plainColor: colors.onSlab,
              warningColor: colors.warningFill,
              bandColor: colors.warningFill,
              // On the slab the band stays behind the digits rather than
              // competing with them; on paper the tint is already pale.
              bandOpacity: 0.28,
            ),
            const SizedBox(width: AppSpace.s1),
            Text(
              'h',
              style: AppTextStyles.statSm.copyWith(color: colors.onSlabMuted),
            ),
          ],
        ),
        // A number that declines to move needs to say so. Without this the
        // balance would simply sit still all morning and look broken.
        if (view.balanceProvisional)
          Text(
            'today counts tonight',
            style: AppTextStyles.caption.copyWith(color: colors.onSlabMuted),
          ),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.view, required this.onToggleTracking});

  final HomeView view;
  final VoidCallback? onToggleTracking;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final running =
        view.state == TrackingState.tracking ||
        view.state == TrackingState.onBreak;

    return PressScale(
      onTap: onToggleTracking,
      child: Semantics(
        button: true,
        label: view.state == TrackingState.tracking ? 'Check out' : 'Check in',
        child: SunDial(
          progress: view.ringProgress,
          state: view.state,
          showKnob: running,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stateIcon(view.state),
                    size: AppIconSize.xs,
                    color: colors.stateLabel(view.state),
                  ),
                  const SizedBox(width: AppSpace.s1),
                  Text(
                    stateKicker(view.state),
                    style: AppTextStyles.kicker.copyWith(
                      color: colors.stateLabel(view.state),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s1),
              Text(
                view.timerText,
                style: AppTextStyles.timer.copyWith(color: colors.onSlab),
              ),
              const SizedBox(height: AppSpace.s1),
              Text(
                view.sinceText,
                style: AppTextStyles.caption.copyWith(
                  color: colors.onSlabMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Worked against target, and what the day was made of. The ring says how far
/// through; this says out of what, and where the time went.
class _TodayBar extends StatelessWidget {
  const _TodayBar({required this.view});

  final HomeView view;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final over = view.isOverTarget;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    AppFormat.hm(view.netHours),
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: colors.onSlab,
                    ),
                  ),
                  Text(
                    ' of ${AppFormat.hm(view.targetHours)}',
                    style: AppTextStyles.body.copyWith(
                      color: colors.onSlabMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              over
                  ? '${AppFormat.hm(-view.remainingHours, signed: true)} over'
                  : '${AppFormat.hm(view.remainingHours)} left',
              style: AppTextStyles.bodyStrong.copyWith(
                color: over ? colors.accentFill : colors.onSlabMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s2),
        DayRail(
          segments: view.rail,
          targetHours: view.targetHours,
          state: view.state,
        ),
      ],
    );
  }
}

class _TodaySection extends StatelessWidget {
  const _TodaySection({required this.view});

  final HomeView view;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY',
          style: AppTextStyles.kicker.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpace.s3),
        EventTimeline(items: view.timeline, ground: colors.background),
      ],
    );
  }
}

/// A day with nothing on it. The slab above still shows the real balance and
/// the day's target, so the screen is informative even when empty — only the
/// timeline is missing, and the pill says what to do about it.
class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.onCheckIn});

  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Text(
          'Nothing logged yet today',
          style: AppTextStyles.bodyLg.copyWith(color: colors.text),
        ),
        const SizedBox(height: AppSpace.s1),
        Text(
          'Tap the ring or check in below',
          style: AppTextStyles.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpace.s4),
        PrimaryPill(
          label: 'Check in',
          icon: AppIcons.sun,
          onPressed: onCheckIn,
        ),
      ],
    );
  }
}

/// What Home shows for a job that has ended.
class EndedJob {
  const EndedJob({
    required this.finalBalance,
    required this.endLabel,
    required this.spanLabel,
    this.warning = false,
  });

  final double finalBalance;

  /// "31 Dec 2025".
  final String endLabel;

  /// "Oct 2023 – Dec 2025".
  final String spanLabel;

  /// Past the job's floor or cap — the warning treatment still applies.
  final bool warning;
}

class _EndedSlab extends StatelessWidget {
  const _EndedSlab({required this.job});

  final EndedJob job;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpace.s6,
        horizontal: AppSpace.s5,
      ),
      decoration: BoxDecoration(
        color: colors.slab,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: colors.slabRim == null
            ? null
            : Border.all(color: colors.slabRim!),
        boxShadow: colors.shadowSlab,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FINAL BALANCE',
            style: AppTextStyles.kicker.copyWith(color: colors.onSlabMuted),
          ),
          const SizedBox(height: AppSpace.s1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              BandedNumber(
                text: AppFormat.hm(job.finalBalance, signed: true),
                style: AppTextStyles.hero,
                warning: job.warning,
                plainColor: colors.onSlab,
                warningColor: colors.warningFill,
                bandColor: colors.warningFill,
                bandOpacity: 0.28,
              ),
              const SizedBox(width: AppSpace.s1),
              Text(
                'h',
                style: AppTextStyles.statSm.copyWith(color: colors.onSlabMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          Center(
            // Track only, and not a button: there is nothing to check in to.
            child: ExcludeSemantics(
              child: SunDial(
                progress: 0,
                state: TrackingState.checkedOut,
                showKnob: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.power,
                          size: AppIconSize.xs,
                          color: colors.onSlabMuted,
                        ),
                        const SizedBox(width: AppSpace.s1),
                        Text(
                          'JOB ENDED',
                          style: AppTextStyles.kicker.copyWith(
                            color: colors.onSlabMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s1),
                    Text(
                      job.endLabel,
                      style: AppTextStyles.headline.copyWith(
                        color: colors.onSlab,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s1),
                    Text(
                      'Check-in is off',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.onSlabMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          Row(
            children: [
              Expanded(
                child: Text(
                  job.spanLabel,
                  style: AppTextStyles.body.copyWith(color: colors.onSlabMuted),
                ),
              ),
              Text(
                'Ended',
                style: AppTextStyles.bodyStrong.copyWith(
                  color: colors.onSlabMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
