/// The day's events as a rail of dots and chips (handoff §5.3).
///
/// Shared by Home's "Today" section and History's expanded day row, which is
/// the point: the same day drawn the same way whether you are looking at it
/// live or a month later.
///
/// The rail line is drawn by the rows themselves — each row paints the segment
/// that crosses it, and the first and last paint only half — rather than by one
/// line stretched behind a measured column. That is what retires the
/// `IntrinsicHeight`/`Expanded` construction Home used to need, which renders
/// correctly in debug and silently wrong in release if anything under it stops
/// reporting an intrinsic height.
library;

import 'package:flutter/widgets.dart';

import '../core/icons/app_icons.dart';
import '../core/motion.dart';
import '../core/painting/dashed_border.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import '../domain/tracking_state.dart';
import 'press_scale.dart';

const double _railWidth = 24;
const double _railCentre = 11;
const double _railGap = AppSpace.s2;
const double _eventHeight = 30;

/// Handoff §5.3: a chip row is 40 tall with a 32 chip inside it. Interactive
/// chips override this to [AppSize.touch] — see [TimelineChipItem.interactive].
const double _chipRowHeight = 40;

/// What a chip is, which decides its fill, its outline and its swatch.
enum EventChipRole {
  work,
  realBreak,
  syntheticBreak,
  activeWork,
  activeBreak,
  vacation,
  sick,
  flex,
}

sealed class TimelineItem {
  const TimelineItem();
}

/// A check-in or check-out: a dot on the rail with a time on the right.
class TimelineEvent extends TimelineItem {
  const TimelineEvent({required this.label, required this.time, required this.isCheckIn});
  final String label;
  final String time;
  final bool isCheckIn;
}

/// A block of the day: work, a break, or leave.
class TimelineChipItem extends TimelineItem {
  const TimelineChipItem({
    required this.role,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  final EventChipRole role;
  final String label;

  /// Only a synthetic break is selectable, and only to reveal its Delete pill.
  final bool selected;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  /// Whether this chip is something you press. Display-only chips keep the
  /// design's 40 dp row; an interactive one takes [AppSize.touch] instead,
  /// because a 32 dp chip in a 40 dp row is four short of the minimum target
  /// this app sets itself.
  bool get interactive => onTap != null || onLongPress != null;
}

/// The open-ended tail of a live day: a pulsing marker, a "since" line and a
/// filled chip counting up.
class TimelineActiveItem extends TimelineItem {
  const TimelineActiveItem({
    required this.state,
    required this.label,
    required this.chipLabel,
  });

  final TrackingState state;
  final String label;
  final String chipLabel;
}

class EventTimeline extends StatelessWidget {
  const EventTimeline({
    super.key,
    required this.items,
    required this.ground,
    this.stagger = false,
  });

  final List<TimelineItem> items;

  /// The colour behind the timeline — `background` on Home, `surface` inside an
  /// expanded History row. Hollow markers are filled with it so the rail line
  /// appears to pass behind them.
  final Color ground;

  /// Fade the rows in one after another (handoff §6). Set where a timeline
  /// *arrives* — an expanding History row — and left off where it is simply
  /// already there, as on Home, which would otherwise flicker on every
  /// one-second rebuild while tracking.
  final bool stagger;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, item) in items.indexed)
          _StaggeredIn(
            index: i,
            enabled: stagger,
            child: _TimelineRow(
              item: item,
              ground: ground,
              isFirst: i == 0,
              isLast: i == items.length - 1,
              index: i,
            ),
          ),
      ],
    );
  }
}

/// Fades [child] in after `index * stagger`, stopping the ramp at
/// [kStaggerMax] — past five items the delay is no longer read as sequence,
/// only as lag.
class _StaggeredIn extends StatelessWidget {
  const _StaggeredIn({
    required this.index,
    required this.enabled,
    required this.child,
  });

  final int index;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    if (!enabled || !motion.enabled) return child;

    final steps = index.clamp(0, kStaggerMax);
    final delay = motion.stagger * steps;
    final total = motion.rowExpand + delay;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppCurves.expand,
      ),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: child,
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.ground,
    required this.isFirst,
    required this.isLast,
    required this.index,
  });

  final TimelineItem item;
  final Color ground;
  final bool isFirst;
  final bool isLast;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (height, marker, content) = switch (item) {
      TimelineEvent(:final label, :final time, :final isCheckIn) => (
          _eventHeight,
          _EventMarker(isCheckIn: isCheckIn, ground: ground),
          Row(
            children: [
              Expanded(
                child: Text(label, style: AppTextStyles.body.copyWith(color: colors.text)),
              ),
              Text(time, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
            ],
          ),
        ),
      TimelineChipItem chip => (
          chip.interactive ? AppSize.touch : _chipRowHeight,
          const SizedBox.shrink(),
          Align(alignment: Alignment.centerLeft, child: EventChip(item: chip)),
        ),
      TimelineActiveItem(:final state, :final label, :final chipLabel) => (
          null,
          _ActiveMarker(state: state, ground: ground),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.body.copyWith(color: colors.text)),
              const SizedBox(height: AppSpace.s1),
              EventChip(
                item: TimelineChipItem(
                  role: state == TrackingState.onBreak
                      ? EventChipRole.activeBreak
                      : EventChipRole.activeWork,
                  label: chipLabel,
                ),
              ),
            ],
          ),
        ),
    };

    // A Stack rather than a Row with a stretched rail column: the active row
    // has no fixed height, and stretching a Row child inside an unbounded box
    // needs an intrinsic pass — which is exactly the construction this widget
    // exists to retire. Here the content sizes the row and the rail is
    // positioned to whatever that turns out to be.
    final row = Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _railWidth,
          child: CustomPaint(
            painter: _RailPainter(
              color: colors.divider,
              // A chip row has no marker, so the line runs the whole way
              // through it; a marked row stops the line at the marker.
              markerAt: item is TimelineChipItem ? null : _markerCentre(item),
              drawAbove: !isFirst,
              drawBelow: !isLast,
            ),
            child: Align(alignment: Alignment.topCenter, child: marker),
          ),
        ),
        Padding(
          // A selected synthetic break grows a Delete pill beside it, and the
          // pair does not fit inside the rail's indent at phone width. It
          // bleeds over the rail instead of truncating the times the hint
          // underneath refers to.
          padding: EdgeInsets.only(left: _bleedsOverRail ? 0 : _railWidth + _railGap),
          child: SizedBox(
            width: double.infinity,
            child: Align(alignment: Alignment.centerLeft, child: content),
          ),
        ),
      ],
    );

    return height == null
        ? ConstrainedBox(constraints: const BoxConstraints(minHeight: _chipRowHeight), child: row)
        : SizedBox(height: height, child: row);
  }

  bool get _bleedsOverRail =>
      item is TimelineChipItem &&
      (item as TimelineChipItem).selected &&
      (item as TimelineChipItem).onDelete != null;

  /// Where the marker's centre sits from the top of the row, so the line meets
  /// it instead of running under it.
  double _markerCentre(TimelineItem item) => switch (item) {
        TimelineEvent() => _eventHeight / 2,
        TimelineActiveItem() => AppSize.timelineActiveDot / 2 + 4,
        TimelineChipItem() => _chipRowHeight / 2,
      };
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.color,
    required this.markerAt,
    required this.drawAbove,
    required this.drawBelow,
  });

  final Color color;

  /// Null on rows without a marker: the line crosses them uninterrupted.
  final double? markerAt;

  final bool drawAbove;
  final bool drawBelow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AppStroke.timelineRail
      ..strokeCap = StrokeCap.butt;

    final centre = markerAt ?? size.height / 2;
    if (drawAbove) {
      canvas.drawLine(Offset(_railCentre, 0), Offset(_railCentre, centre), paint);
    }
    if (drawBelow) {
      canvas.drawLine(Offset(_railCentre, centre), Offset(_railCentre, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.color != color ||
      old.markerAt != markerAt ||
      old.drawAbove != drawAbove ||
      old.drawBelow != drawBelow;
}

class _EventMarker extends StatelessWidget {
  const _EventMarker({required this.isCheckIn, required this.ground});

  final bool isCheckIn;
  final Color ground;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const size = AppSize.timelineDot;

    return Padding(
      padding: const EdgeInsets.only(top: (_eventHeight - size) / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Checking in is a filled dot, checking out a hollow one: the day
          // opens solid and closes empty.
          color: isCheckIn ? colors.accentFill : ground,
          border: isCheckIn
              ? null
              : Border.all(color: colors.textMuted, width: AppStroke.focus),
        ),
      ),
    );
  }
}

/// The live marker: a dot cut out of the ground with a ring around it, pulsing
/// while anything is running.
class _ActiveMarker extends StatefulWidget {
  const _ActiveMarker({required this.state, required this.ground});

  final TrackingState state;
  final Color ground;

  @override
  State<_ActiveMarker> createState() => _ActiveMarkerState();
}

class _ActiveMarkerState extends State<_ActiveMarker> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = AppMotion.of(context);
    // A repeating controller with a zero duration is a busy loop, not a still
    // frame, so reduced motion means no controller at all.
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
    final colors = context.colors;
    final fill = widget.state == TrackingState.onBreak ? colors.breakFill : colors.accentFill;
    const size = AppSize.timelineActiveDot;

    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: widget.ground, width: 3),
      ),
    );

    final marker = Container(
      width: size + 6,
      height: size + 6,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: fill, width: AppStroke.focus),
      ),
      child: dot,
    );

    final controller = _controller;
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: controller == null
          ? marker
          : FadeTransition(
              opacity: Tween(begin: 1.0, end: kPulseMinOpacity)
                  .animate(CurvedAnimation(parent: controller, curve: AppCurves.pulse)),
              child: marker,
            ),
    );
  }
}

/// One block of the day. Four block types that differ by fill, outline and
/// hatch rather than by hue alone, so the timeline survives greyscale.
class EventChip extends StatelessWidget {
  const EventChip({super.key, required this.item});

  final TimelineChipItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = AppMotion.of(context);
    final style = _styleFor(colors);

    final chip = AnimatedContainer(
      duration: motion.chipSelect,
      curve: AppCurves.control,
      height: AppSize.chipHeight,
      padding: const EdgeInsets.only(left: AppSpace.s2, right: AppSpace.s3),
      decoration: ShapeDecoration(
        color: style.fill,
        shape: style.dashed
            ? DashedRoundedBorder(color: style.outline!, radius: AppRadius.sm)
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                side: style.outline == null
                    ? BorderSide.none
                    : BorderSide(color: style.outline!, width: AppStroke.focus),
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A selected synthetic break has neither a swatch nor an icon — the
          // focus ring is doing that job — so it gets no leading gap either.
          if (style.icon != null) ...[
            Icon(style.icon, size: AppIconSize.sm, color: style.ink),
            const SizedBox(width: AppSpace.s2),
          ] else if (style.dashed || style.swatch.a > 0) ...[
            _Swatch(color: style.swatch, dashed: style.dashed, outline: style.outline),
            const SizedBox(width: AppSpace.s2),
          ] else
            const SizedBox(width: AppSpace.s1),
          Text(item.label, style: AppTextStyles.bodyStrong.copyWith(color: style.ink)),
        ],
      ),
    );

    final tappable = item.onTap != null || item.onLongPress != null;
    // The chip stays 32 dp — that is what the design draws — but the thing you
    // press is the full 44 dp row around it. Tapping one of these selects a
    // synthetic break and long-pressing edits a session; neither should need
    // a careful finger.
    final body = tappable
        ? Semantics(
            button: true,
            selected: item.selected,
            label: item.label,
            child: PressScale(
              onTap: item.onTap,
              onLongPress: item.onLongPress,
              child: SizedBox(
                height: AppSize.touch,
                child: Center(child: chip),
              ),
            ),
          )
        : chip;

    if (!item.selected || item.onDelete == null) return body;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        const SizedBox(width: AppSpace.s2),
        // The pill fades in rather than appearing: it arrives in response to
        // the tap that selected the chip, and a hard cut reads as the layout
        // jumping rather than as an answer to what you just did.
        TweenAnimationBuilder<double>(
          key: ValueKey(item.label),
          tween: Tween(begin: 0, end: 1),
          duration: motion.deletePillIn,
          curve: AppCurves.control,
          builder: (context, t, child) => Opacity(opacity: t, child: child),
          child: _DeletePill(onTap: item.onDelete!),
        ),
      ],
    );
  }

  _ChipStyle _styleFor(AppColors colors) => switch (item.role) {
        EventChipRole.work =>
          _ChipStyle(fill: colors.accentTint, ink: colors.accentText, swatch: colors.accentFill),
        EventChipRole.realBreak =>
          _ChipStyle(fill: colors.breakTint, ink: colors.breakText, swatch: colors.breakFill),
        EventChipRole.syntheticBreak => item.selected
            ? _ChipStyle(
                fill: colors.surface2,
                ink: colors.text,
                swatch: const Color(0x00000000),
                outline: colors.focus,
              )
            : _ChipStyle(
                fill: null,
                ink: colors.textMuted,
                swatch: const Color(0x00000000),
                outline: colors.textMuted,
                dashed: true,
              ),
        EventChipRole.activeWork =>
          _ChipStyle(fill: colors.accentFill, ink: colors.onAccent, swatch: colors.onAccent),
        EventChipRole.activeBreak =>
          _ChipStyle(fill: colors.breakFill, ink: colors.onAccent, swatch: colors.onAccent),
        EventChipRole.vacation => _ChipStyle(
            fill: colors.vacationTint,
            ink: colors.vacationText,
            swatch: colors.vacationFill,
            icon: AppIcons.airplaneTilt,
          ),
        EventChipRole.sick => _ChipStyle(
            fill: colors.sickTint,
            ink: colors.sickText,
            swatch: colors.sickFill,
            icon: AppIcons.thermometerSimple,
          ),
        EventChipRole.flex => _ChipStyle(
            fill: colors.accentTint,
            ink: colors.accentText,
            swatch: colors.accentFill,
            icon: AppIcons.arrowsLeftRight,
          ),
      };
}

class _ChipStyle {
  const _ChipStyle({
    required this.fill,
    required this.ink,
    required this.swatch,
    this.outline,
    this.dashed = false,
    this.icon,
  });

  final Color? fill;
  final Color ink;
  final Color swatch;
  final Color? outline;
  final bool dashed;
  final IconData? icon;
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.dashed, required this.outline});

  final Color color;
  final bool dashed;
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.swatch,
      height: AppSize.swatch,
      decoration: ShapeDecoration(
        color: color,
        shape: dashed
            ? DashedRoundedBorder(
                color: outline!,
                radius: AppSize.swatch / 2,
                dashLength: 2,
                gapLength: 2,
              )
            : const CircleBorder(),
      ),
    );
  }
}

/// Appears beside a selected synthetic break. There is no confirmation
/// dialog — the extra tap to select the chip is the confirmation.
class _DeletePill extends StatelessWidget {
  const _DeletePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: 'Delete break',
      child: PressScale(
        onTap: onTap,
        // Deleting is irreversible and there is no dialog behind it, so this
        // gets the full tap target and the same press feedback as every other
        // control — a destructive action should not be the one widget in the
        // app that stays silent under the finger.
        child: SizedBox(
          height: AppSize.touch,
          child: Center(
            child: Container(
              height: AppSize.chipHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
              decoration: BoxDecoration(
                color: colors.selected,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.x, size: AppIconSize.xs, color: colors.onSelected),
                  const SizedBox(width: AppSpace.s1),
                  Text('Delete',
                      style: AppTextStyles.captionStrong.copyWith(color: colors.onSelected)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
