/// "Started earlier?" and "Check in at…" (additions handoff §5).
///
/// One sheet for both corrections: a time stepper, the rail that shows where
/// the allowed span sits, the two limits with why they are there, one line
/// that says what saving would do (or why it cannot), and the actions. The
/// rules live in `domain/session_fix.dart`; this only draws them.
library;

import 'package:flutter/material.dart'
    show MediaQuery, TimeOfDay, TimePickerEntryMode, showTimePicker;
import 'package:flutter/widgets.dart';

import '../core/format.dart';
import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import '../domain/session_fix.dart';
import 'app_bottom_sheet.dart';
import 'buttons.dart';
import 'press_scale.dart';

/// Opens the sheet for [fix]. [onSave] receives the time to save — already
/// [SessionFix.resolve]d — and the sheet closes once it completes.
///
/// [todayNetHours] is what today shows so far, for "today becomes …".
Future<void> showSessionFixSheet({
  required BuildContext context,
  required SessionFix fix,
  required double todayNetHours,
  required Future<void> Function(DateTime at) onSave,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => SessionFixSheet(fix: fix, todayNetHours: todayNetHours, onSave: onSave),
  );
}

class SessionFixSheet extends StatefulWidget {
  const SessionFixSheet({
    super.key,
    required this.fix,
    required this.todayNetHours,
    required this.onSave,
    this.initialValue,
  });

  final SessionFix fix;
  final double todayNetHours;
  final Future<void> Function(DateTime at) onSave;

  /// Starts somewhere other than [SessionFix.initial] — the render harness
  /// uses it to show each validation state.
  final DateTime? initialValue;

  @override
  State<SessionFixSheet> createState() => _SessionFixSheetState();
}

class _SessionFixSheetState extends State<SessionFixSheet> {
  late DateTime _value = widget.initialValue ?? widget.fix.initial;
  bool _saving = false;

  SessionFix get _fix => widget.fix;

  Future<void> _type() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_value),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _value = _fix.atTimeOfDay(picked.hour, picked.minute));
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_fix.resolve(_value));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validity = _fix.validity(_value);
    final invalid =
        validity == FixValidity.beforeEarliest || validity == FixValidity.afterLatest;
    final canSave = _fix.canSave(_value) && !_saving;
    final isStart = _fix.kind == SessionFixKind.startEarlier;

    return AppSheet(
      title: isStart ? 'Started earlier?' : 'Check in at…',
      subtitle: isStart
          ? 'Move the start of the running session'
          : "You've been on break since ${AppFormat.time(_fix.earliest)}",
      actions: [
        SecondaryPill(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        PrimaryPill(
          label: canSave
              ? (isStart
                  ? 'Start at ${AppFormat.time(_value)}'
                  : 'Check in at ${AppFormat.time(_value)}')
              : (isStart ? 'Save start time' : 'Check in'),
          onPressed: canSave ? _save : null,
        ),
      ],
      children: [
        _TimeStepper(
          value: _value,
          invalid: invalid,
          onMinus: _fix.canStepDown(_value) && !invalid
              ? () => setState(() => _value = _fix.stepDown(_value))
              : (invalid && _value.isAfter(_fix.latest)
                  ? () => setState(() => _value = _fix.latest)
                  : null),
          onPlus: _fix.canStepUp(_value) && !invalid
              ? () => setState(() => _value = _fix.stepUp(_value))
              : (invalid && _value.isBefore(_fix.earliest)
                  ? () => setState(() => _value = _fix.earliest)
                  : null),
          onTapValue: _type,
        ),
        Transform.translate(
          offset: const Offset(0, -AppSpace.s3),
          child: Center(
            child: Text(
              '${_fix.stepMinutes}-min steps · tap the time to type it',
              style: AppTextStyles.caption.copyWith(color: context.colors.textMuted),
            ),
          ),
        ),
        LimitRail(fix: _fix, value: _value, invalid: invalid),
        _LimitsRow(fix: _fix),
        _Message(fix: _fix, value: _value, todayNetHours: widget.todayNetHours),
      ],
    );
  }
}

/// Minus, the time, plus. The steppers clamp, so only typing reaches an
/// invalid value; from there the button pointing back into range brings the
/// value to the nearest limit.
class _TimeStepper extends StatelessWidget {
  const _TimeStepper({
    required this.value,
    required this.invalid,
    required this.onMinus,
    required this.onPlus,
    required this.onTapValue,
  });

  final DateTime value;
  final bool invalid;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback onTapValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = AppFormat.time(value);

    return Row(
      children: [
        _StepButton(icon: AppIcons.minus, label: 'Earlier', onPressed: onMinus),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Time $text. Tap to type a time',
            child: GestureDetector(
              onTap: onTapValue,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.s1),
                child: Center(
                  child: Stack(
                    children: [
                      if (invalid)
                        Positioned(
                          left: -AppSpace.s1,
                          right: -AppSpace.s1,
                          bottom: 4,
                          height: 20,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.warningTint,
                              borderRadius: BorderRadius.circular(AppRadius.cell),
                            ),
                          ),
                        ),
                      Text(
                        text,
                        style: AppTextStyles.timer.copyWith(
                          color: invalid ? colors.warningText : colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _StepButton(icon: AppIcons.plus, label: 'Later', onPressed: onPlus),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: PressScale(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: colors.surface2, shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: enabled ? colors.text : colors.textMuted),
        ),
      ),
    );
  }
}

/// The allowed span on a short time axis, and where the value sits on it.
class LimitRail extends StatelessWidget {
  const LimitRail({super.key, required this.fix, required this.value, required this.invalid});

  final SessionFix fix;
  final DateTime value;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final before = Duration(minutes: fix.kind == SessionFixKind.startEarlier ? 30 : 15);
    return SizedBox(
      height: AppSize.railKnob,
      width: double.infinity,
      child: CustomPaint(
        painter: _RailPainter(
          axisStart: fix.earliest.subtract(before),
          axisEnd: fix.latest.add(const Duration(minutes: 10)),
          spanStart: fix.earliest,
          spanEnd: fix.latest,
          value: value,
          track: colors.track,
          span: colors.accentTint,
          spanBorder: colors.accentStrong,
          knob: invalid ? colors.warningText : colors.accentFill,
          knobRing: colors.surface,
        ),
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.axisStart,
    required this.axisEnd,
    required this.spanStart,
    required this.spanEnd,
    required this.value,
    required this.track,
    required this.span,
    required this.spanBorder,
    required this.knob,
    required this.knobRing,
  });

  final DateTime axisStart, axisEnd, spanStart, spanEnd, value;
  final Color track, span, spanBorder, knob, knobRing;

  @override
  void paint(Canvas canvas, Size size) {
    const knobR = AppSize.railKnob / 2;
    const trackH = AppSize.railHeight;
    final total = axisEnd.difference(axisStart).inSeconds.toDouble();
    double x(DateTime t) {
      final f = total <= 0 ? 0.5 : t.difference(axisStart).inSeconds / total;
      return knobR + (size.width - 2 * knobR) * f.clamp(0.0, 1.0);
    }

    final cy = size.height / 2;
    final trackRect = RRect.fromLTRBR(
      0, cy - trackH / 2, size.width, cy + trackH / 2, const Radius.circular(trackH / 2));
    canvas.drawRRect(trackRect, Paint()..color = track);

    final spanRect = RRect.fromLTRBR(
      x(spanStart) - trackH / 2,
      cy - trackH / 2,
      x(spanEnd) + trackH / 2,
      cy + trackH / 2,
      const Radius.circular(trackH / 2),
    );
    canvas.drawRRect(spanRect, Paint()..color = span);
    canvas.drawRRect(
      spanRect.deflate(0.75),
      Paint()
        ..color = spanBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.dash,
    );

    final kx = x(value);
    canvas.drawCircle(Offset(kx, cy), knobR, Paint()..color = knobRing);
    canvas.drawCircle(Offset(kx, cy), knobR - 3, Paint()..color = knob);
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.value != value || old.knob != knob || old.spanStart != spanStart || old.track != track;
}

class _LimitsRow extends StatelessWidget {
  const _LimitsRow({required this.fix});

  final SessionFix fix;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Limit(
            kicker: 'EARLIEST',
            time: fix.earliest,
            reason: _reasonText(fix.earliestReason),
            end: false,
          ),
        ),
        Expanded(
          child: _Limit(
            kicker: 'LATEST',
            time: fix.latest,
            reason: _reasonText(fix.latestReason),
            end: true,
          ),
        ),
      ],
    );
  }
}

class _Limit extends StatelessWidget {
  const _Limit({required this.kicker, required this.time, required this.reason, required this.end});

  final String kicker;
  final DateTime time;
  final String reason;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(kicker, style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
        const SizedBox(height: 2),
        Text(AppFormat.time(time), style: AppTextStyles.statSm.copyWith(color: colors.text)),
        Text(reason, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
      ],
    );
  }
}

String _reasonText(FixLimitReason reason) => switch (reason) {
      FixLimitReason.workWindow => 'work window starts',
      FixLimitReason.previousSession => 'your last session ended',
      FixLimitReason.dayStart => 'day start',
      FixLimitReason.currentStart => 'current start',
      FixLimitReason.checkOut => 'your check-out',
      FixLimitReason.now => 'now',
    };

/// The one line under the limits: what saving does, or why it cannot.
class _Message extends StatelessWidget {
  const _Message({required this.fix, required this.value, required this.todayNetHours});

  final SessionFix fix;
  final DateTime value;
  final double todayNetHours;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final message = sessionFixMessage(fix, value, todayNetHours: todayNetHours);

    final Widget child = switch (message.tone) {
      FixMessageTone.effect =>
        Text(message.text, style: AppTextStyles.bodyStrong.copyWith(color: colors.text)),
      FixMessageTone.hint =>
        Text(message.text, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
      FixMessageTone.note => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.coffee, size: AppIconSize.sm, color: colors.breakText),
            const SizedBox(width: AppSpace.s2),
            Expanded(
              child: Text(message.text,
                  style: AppTextStyles.caption.copyWith(color: colors.text)),
            ),
          ],
        ),
      FixMessageTone.error => Semantics(
          liveRegion: true,
          child: Text(message.text,
              style: AppTextStyles.caption.copyWith(color: colors.warningText)),
        ),
    };

    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1), child: child);
  }
}

enum FixMessageTone { effect, hint, note, error }

class FixMessage {
  const FixMessage(this.tone, this.text);
  final FixMessageTone tone;
  final String text;
}

/// The message line's words for [value], kept apart from the widget so it can
/// be tested as text.
FixMessage sessionFixMessage(SessionFix fix, DateTime value, {required double todayNetHours}) {
  final validity = fix.validity(value);
  final earliest = AppFormat.time(fix.earliest);
  final latest = AppFormat.time(fix.latest);

  if (fix.kind == SessionFixKind.startEarlier) {
    final added = fix.latest.difference(value).inMinutes / 60.0;
    return switch (validity) {
      FixValidity.valid => FixMessage(FixMessageTone.effect,
          'Adds ${AppFormat.hm(added)} · today becomes ${AppFormat.hm(todayNetHours + added)} so far'),
      FixValidity.atEarliest => FixMessage(
          FixMessageTone.effect, 'Adds ${AppFormat.hm(added)} · earliest allowed start'),
      FixValidity.unchanged => FixMessage(
          FixMessageTone.hint, 'Pick a time before $latest to move the start earlier.'),
      FixValidity.beforeEarliest => FixMessage(FixMessageTone.error, switch (fix.earliestReason) {
          FixLimitReason.workWindow =>
            'Your work window starts at $earliest. Pick $earliest or later.',
          FixLimitReason.previousSession =>
            'Your last session ended at $earliest. Pick $earliest or later.',
          _ => "Sessions can't start before 00:00.",
        }),
      FixValidity.afterLatest => FixMessage(FixMessageTone.error,
          "That's after the current start, $latest. Only an earlier start can be set here."),
    };
  }

  final breakLength = value.difference(fix.earliest);
  final breakText = AppFormat.hm(breakLength.inMinutes / 60.0);
  return switch (validity) {
    FixValidity.atEarliest => FixMessage(FixMessageTone.effect,
        'No break · the session that ended at $earliest continues'),
    FixValidity.valid || FixValidity.unchanged =>
      breakLength < kMinimumCountingBreak && breakLength > Duration.zero
          ? FixMessage(
              FixMessageTone.note,
              "This break is $breakText. Breaks under 15 min don't count toward the legal "
              'break, so auto-break may still deduct time.')
          : FixMessage(FixMessageTone.effect,
              'Break $breakText · tracking resumes from ${AppFormat.time(value)}'),
    FixValidity.afterLatest =>
      FixMessage(FixMessageTone.error, "That's in the future. The latest is now, $latest."),
    FixValidity.beforeEarliest => FixMessage(FixMessageTone.error,
        'You checked out at $earliest. To change that, edit the earlier session in History.'),
  };
}
