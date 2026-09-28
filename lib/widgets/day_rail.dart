/// The Day Rail (handoff §5.2, revised): how much of today is done, and what
/// it was made of.
///
/// It used to be a composition bar on a wall-clock axis running from the first
/// check-in to now, with leave appended on the end — and the handoff said in so
/// many words that it was "not a progress bar". But it sits directly under
/// `5:49 of 7:54 · 2:05 left`, full width, rounded like every progress bar ever
/// drawn, and the first thing anyone said about it was "I guess that's the time
/// left". It was not: because the axis was `daySpan + leave`, a stale full-day
/// vacation entry took 54 % of the bar and a day that was 73 % worked read as
/// about a third.
///
/// So it means what the line above it says. Work and leave stack by duration
/// against the target, the uncovered remainder is the track and equals "X left"
/// exactly, and a day that overshoots scales to its own total with a tick left
/// at the target.
///
/// Breaks are the one thing that cannot be proportional. A break earns no
/// target, so giving it width would take width from the work either side and
/// reintroduce the same lie in miniature — it is drawn as a fixed marker where
/// it fell instead.
library;

import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/painting/hatch.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../domain/tracking_state.dart';

enum RailSegmentType { work, realBreak, syntheticBreak, vacation, sick, holiday, flex }

extension on RailSegmentType {
  /// Whether the segment earns against the day's target, and so takes width in
  /// proportion to its length.
  bool get counts => switch (this) {
        RailSegmentType.realBreak || RailSegmentType.syntheticBreak => false,
        _ => true,
      };
}

class RailSegment {
  const RailSegment({required this.type, required this.hours});

  final RailSegmentType type;

  /// Ignored for break types, which are drawn at a fixed width.
  final double hours;
}

/// Wide enough to see, narrow enough not to distort the day around it.
const double _breakMarker = 10;

class DayRail extends StatelessWidget {
  const DayRail({
    super.key,
    required this.segments,
    required this.targetHours,
    required this.state,
  });

  /// In the order they happened.
  final List<RailSegment> segments;

  /// A full bar. Zero on a rest day, where the rail is all track.
  final double targetHours;

  final TrackingState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final live = state == TrackingState.tracking || state == TrackingState.onBreak;

    var counted = 0.0;
    var breaks = 0;
    for (final segment in segments) {
      if (segment.type.counts) {
        counted += segment.hours;
      } else {
        breaks++;
      }
    }
    // Over target the bar rescales to the day rather than clipping, so the
    // overshoot stays visible instead of silently sitting at 100 %.
    final axis = counted > targetHours ? counted : targetHours;

    return SizedBox(
      height: AppSize.railHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final usable = (width - breaks * _breakMarker).clamp(0.0, width);

          final blocks = <Widget>[];
          var cursor = 0.0;
          for (final segment in segments) {
            final span = segment.type.counts
                ? (axis > 0 ? segment.hours / axis * usable : 0.0)
                : _breakMarker;
            if (span > 0) {
              blocks.add(_block(segment.type, cursor, span, width, colors));
            }
            cursor += span;
          }

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
              ...blocks,
              // Where the target sat, on a day that went past it.
              if (counted > targetHours && targetHours > 0)
                Positioned(
                  left: targetHours / axis * usable,
                  top: 0,
                  bottom: 0,
                  width: AppStroke.focus,
                  child: DecoratedBox(decoration: BoxDecoration(color: colors.slab)),
                ),
              if (live)
                Positioned(
                  left: (cursor - AppSize.railKnob / 2).clamp(
                    -AppSize.railKnob / 2,
                    width - AppSize.railKnob / 2,
                  ),
                  top: (AppSize.railHeight - AppSize.railKnob) / 2,
                  child: _NowKnob(
                    color: state == TrackingState.onBreak
                        ? colors.breakFill
                        : colors.accentFill,
                    rim: colors.slab,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Inset 2 dp each side so adjacent blocks read as separate pills rather than
  /// one striped bar, and never narrower than 4 dp — a six-minute session still
  /// has to be visible.
  Widget _block(
    RailSegmentType type,
    double left,
    double span,
    double width,
    AppColors colors,
  ) {
    const inset = AppSpace.s1 / 2;
    final drawn = (span - inset * 2).clamp(4.0, width);

    return Positioned(
      left: (left + inset).clamp(0.0, width - drawn),
      top: 0,
      bottom: 0,
      width: drawn,
      child: _SegmentBlock(type: type, colors: colors),
    );
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

/// The leading edge of the filled bar while something is running: a disc cut
/// out of the slab, pulsing so "now" reads as moving even though the rail is
/// still.
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
