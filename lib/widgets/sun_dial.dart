/// The Sun Dial: Home's progress ring, and the app's check-in button.
///
/// A new widget rather than a generalisation of [ProgressRing] — the dial has
/// engraved hour ticks, a knob that carries a glyph, a second arc for lapped
/// overtime and a glow that only exists in the dark theme, and Stats' vacation
/// ring wants none of that. Keeping them separate means neither grows flags it
/// never uses.
///
/// Geometry (handoff §5.1): a 216 dp box whose 17 dp margin holds the knob, so
/// the track radius is 91 with a 22 dp stroke. The arc starts at twelve
/// o'clock and runs clockwise.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/tracking_palette.dart';
import '../domain/lap_progress.dart';
import '../domain/tracking_state.dart';

/// Space between the track's outer edge and the widget's edge, which is what
/// gives the knob somewhere to sit without being clipped.
const double _knobMargin = 17;

class SunDial extends StatefulWidget {
  const SunDial({
    super.key,
    required this.progress,
    required this.state,
    this.size = AppSize.ringInApp,
    this.stroke = AppStroke.ring,
    this.showTicks = true,
    this.showKnob = true,
    this.child,
  });

  /// Worked over target. May exceed 1 — past 1 the ring laps rather than
  /// stopping, so a long day still reads as progress.
  final double progress;

  final TrackingState state;
  final double size;
  final double stroke;
  final bool showTicks;

  /// The knob only appears while something is running; a finished day is a
  /// plain closed ring.
  final bool showKnob;

  /// Centre content — the state kicker, the timer and its since-line.
  final Widget? child;

  @override
  State<SunDial> createState() => _SunDialState();
}

class _SunDialState extends State<SunDial> {
  /// The ring fills from empty the first time it is shown and then only
  /// steps, so opening the app is an event and a passing minute is not.
  bool _filled = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = AppMotion.of(context);
    final duration = _filled ? motion.ringTick : motion.ringFirstFill;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _filled ? widget.progress : 0, end: widget.progress),
      duration: duration,
      curve: AppCurves.expand,
      onEnd: () => _filled = true,
      builder: (context, progress, _) => TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: colors.stateFill(widget.state)),
        duration: motion.ringStateColor,
        curve: AppCurves.ringStateColor,
        builder: (context, arcColor, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: SunDialPainter(
            progress: progress,
            state: widget.state,
            arcColor: arcColor ?? colors.stateFill(widget.state),
            colors: colors,
            stroke: widget.stroke,
            showTicks: widget.showTicks,
            showKnob: widget.showKnob,
            textDirection: Directionality.of(context),
          ),
          child: SizedBox.square(
            dimension: widget.size,
            child: widget.child == null ? null : Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class SunDialPainter extends CustomPainter {
  SunDialPainter({
    required this.progress,
    required this.state,
    required this.arcColor,
    required this.colors,
    required this.stroke,
    required this.showTicks,
    required this.showKnob,
    required this.textDirection,
  });

  final double progress;
  final TrackingState state;

  /// Passed in rather than derived, so the caller can lerp it between states.
  final Color arcColor;

  final AppColors colors;
  final double stroke;
  final bool showTicks;
  final bool showKnob;
  final TextDirection textDirection;

  static const double _start = -math.pi / 2;
  static const int _tickCount = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    // The stroke straddles this radius; the margin exists for the knob, which
    // sits centred on it and reaches further out than the track does.
    final radius = size.width / 2 - _knobMargin;
    final box = Rect.fromCircle(center: centre, radius: radius);

    final lap = lapProgressFor(progress);
    final lapped = lap.lapIndex > 0;
    // Everything below draws the *current* lap's sweep; a lapped ring shows a
    // completed first lap underneath it.
    final sweep = lap.fraction * 2 * math.pi;
    final complete = progress >= 1;

    Paint arcPaint(Color color, {bool round = true}) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = round ? StrokeCap.round : StrokeCap.butt;

    // 1. Glow, dark theme only: a blurred copy of the arc under everything.
    final glow = colors.glowAccent;
    if (glow != null && sweep > 0 && state != TrackingState.checkedOut) {
      canvas.drawArc(
        box,
        _start,
        lapped ? 2 * math.pi : sweep,
        false,
        arcPaint(glow)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // 2. Track.
    canvas.drawCircle(centre, radius, arcPaint(colors.slabTrack, round: false));

    // 3. Arc(s). A lapped ring is a full accent circle plus the lap arc on top.
    if (lapped) {
      canvas.drawCircle(centre, radius, arcPaint(colors.accentFill, round: false));
      canvas.drawArc(box, _start, sweep, false, arcPaint(colors.ringLap));
    } else if (sweep > 0) {
      // A closed ring should meet itself cleanly rather than overlap two round
      // caps at twelve o'clock.
      canvas.drawArc(box, _start, sweep, false, arcPaint(arcColor, round: !complete));
    }

    // 4. Ticks, engraved in the ground colour so they read as cut into the
    // ring rather than drawn on it.
    if (showTicks) {
      final tickPaint = Paint()
        ..color = colors.slab
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.ringTick
        ..strokeCap = StrokeCap.butt;
      for (var i = 0; i < _tickCount; i++) {
        final angle = _start + i * 2 * math.pi / _tickCount;
        final unit = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(centre + unit * (radius - 4), centre + unit * (radius + 4), tickPaint);
      }
    }

    // 5. Knob at the end of the live arc, with 6. its glyph.
    if (showKnob && state != TrackingState.checkedOut && state != TrackingState.notStarted) {
      final angle = _start + sweep;
      final knobCentre = centre + Offset(math.cos(angle), math.sin(angle)) * radius;
      final knobRadius = AppSize.knob / 2;
      final knobColor = lapped ? colors.accentFill : arcColor;

      // A slab-coloured disc under the knob cuts it free of the arc it sits
      // on, so the two never merge into one blob at the arc's end.
      canvas.drawCircle(
        knobCentre,
        knobRadius + AppStroke.knobCut / 2,
        Paint()..color = colors.slab,
      );
      canvas.drawCircle(knobCentre, knobRadius, Paint()..color = knobColor);

      if (state == TrackingState.onBreak) {
        _paintPauseBars(canvas, knobCentre);
      } else {
        _paintGlyph(canvas, knobCentre, stateIcon(state));
      }
    }
  }

  void _paintGlyph(Canvas canvas, Offset centre, IconData icon) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: AppIconSize.sm,
          fontFamily: icon.fontFamily,
          color: colors.onAccent,
          height: 1,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    painter.paint(canvas, centre - painter.size.center(Offset.zero));
  }

  /// Two bars rather than an icon: the pause glyph is also what the widget
  /// draws by hand into its bitmap, and one shape in two places beats one
  /// shape and one font.
  void _paintPauseBars(Canvas canvas, Offset centre) {
    const barWidth = 3.0, barHeight = 10.0, gap = 3.0;
    final paint = Paint()..color = colors.onAccent;
    for (final dx in [-(gap / 2 + barWidth), gap / 2]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(centre.dx + dx, centre.dy - barHeight / 2, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SunDialPainter old) =>
      old.progress != progress ||
      old.state != state ||
      old.arcColor != arcColor ||
      old.colors != colors ||
      old.stroke != stroke ||
      old.showTicks != showTicks ||
      old.showKnob != showKnob;
}
