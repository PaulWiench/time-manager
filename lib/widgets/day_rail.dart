/// The Day Rail (handoff §5.2): what today was made of, on a time axis.
///
/// Not a progress bar — the ring is the only thing that says how far through
/// the day you are. The rail says how the day was *composed*: where the work
/// sat, where the breaks fell, which stretch was leave. Its axis runs from the
/// first check-in to now (or to the last check-out), so an early start and a
/// late one look different rather than both filling from the left.
library;

import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/painting/hatch.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../domain/tracking_state.dart';

enum RailSegmentType { work, realBreak, syntheticBreak, vacation, sick, holiday, flex }

class RailSegment {
  const RailSegment({required this.type, required this.start, required this.end});

  final RailSegmentType type;
  final DateTime start;
  final DateTime end;
}

class DayRail extends StatelessWidget {
  const DayRail({
    super.key,
    required this.segments,
    required this.axisStart,
    required this.axisEnd,
    required this.state,
  });

  final List<RailSegment> segments;

  /// First check-in and now (or the last check-out). Equal or inverted bounds
  /// mean there is nothing to place, and the rail draws as an empty track.
  final DateTime axisStart;
  final DateTime axisEnd;

  final TrackingState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final span = axisEnd.difference(axisStart).inSeconds;
    final live = state == TrackingState.tracking || state == TrackingState.onBreak;

    return SizedBox(
      height: AppSize.railHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.slabTrack,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              if (span > 0)
                for (final segment in segments)
                  ..._positioned(segment, span, width, colors),
              if (live)
                Positioned(
                  left: width - AppSize.railKnob / 2,
                  top: (AppSize.railHeight - AppSize.railKnob) / 2,
                  child: _NowKnob(
                    color: state == TrackingState.onBreak ? colors.breakFill : colors.accentFill,
                    rim: colors.slab,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// One segment, inset 2 dp each side so adjacent blocks read as separate
  /// pills rather than one striped bar, and never narrower than 4 dp — a
  /// six-minute break still has to be visible.
  List<Widget> _positioned(RailSegment segment, int span, double width, AppColors colors) {
    const inset = AppSpace.s1 / 2;
    final from = segment.start.difference(axisStart).inSeconds / span;
    final to = segment.end.difference(axisStart).inSeconds / span;
    if (to <= 0 || from >= 1) return const [];

    final left = (from.clamp(0.0, 1.0) * width) + inset;
    final right = (to.clamp(0.0, 1.0) * width) - inset;
    final drawn = (right - left).clamp(4.0, width);

    return [
      Positioned(
        left: left.clamp(0.0, width - drawn),
        top: 0,
        bottom: 0,
        width: drawn,
        child: _SegmentBlock(type: segment.type, colors: colors),
      ),
    ];
  }
}

class _SegmentBlock extends StatelessWidget {
  const _SegmentBlock({required this.type, required this.colors});

  final RailSegmentType type;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);

    // Leave is hatched rather than merely tinted: it is the one block on the
    // rail that did not happen at a desk, and texture says that in greyscale.
    final (fill, stripe) = switch (type) {
      RailSegmentType.vacation => (colors.vacationTint, colors.vacationFill),
      RailSegmentType.sick => (colors.sickTint, colors.sickFill),
      RailSegmentType.holiday => (colors.holidayTint, colors.holidayFill),
      RailSegmentType.flex => (colors.accentTint, colors.accentFill),
      _ => (null, null),
    };
    if (fill != null && stripe != null) {
      return DecoratedBox(
        decoration: HatchDecoration(background: fill, stripe: stripe, borderRadius: radius),
      );
    }

    if (type == RailSegmentType.syntheticBreak) {
      // Hollow: a break the app inferred, not one that was logged.
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: colors.onSlabMuted, width: AppStroke.dash),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: type == RailSegmentType.work ? colors.accentFill : colors.breakFill,
        borderRadius: radius,
      ),
    );
  }
}

/// The right end of the axis while something is running: a disc cut out of the
/// slab, pulsing so "now" reads as moving even though the rail is still.
class _NowKnob extends StatefulWidget {
  const _NowKnob({required this.color, required this.rim});

  final Color color;
  final Color rim;

  @override
  State<_NowKnob> createState() => _NowKnobState();
}

class _NowKnobState extends State<_NowKnob> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = AppMotion.of(context);
    if (motion.loops && _controller == null) {
      _controller = AnimationController(vsync: this, duration: motion.pulse)
        ..repeat(reverse: true);
    } else if (!motion.loops && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final knob = Container(
      width: AppSize.railKnob,
      height: AppSize.railKnob,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        border: Border.all(color: widget.rim, width: AppStroke.knobCut),
      ),
    );

    final controller = _controller;
    if (controller == null) return knob;

    return FadeTransition(
      opacity: Tween(begin: 1.0, end: kPulseMinOpacity)
          .animate(CurvedAnimation(parent: controller, curve: AppCurves.pulse)),
      child: knob,
    );
  }
}
