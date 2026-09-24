/// Press feedback for everything tappable.
///
/// Golden Hour's controls do not ripple — a splash spreading across an apricot
/// pill muddies the one colour the design spends its budget on. Instead every
/// control dips to 98 % under the finger and springs back, quickly in and
/// slower out, which reads as a press without repainting the fill.
library;

import 'package:flutter/widgets.dart';

import '../core/motion.dart';

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = kPressScale,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HitTestBehavior behavior;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final enabled = widget.onTap != null || widget.onLongPress != null;

    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down ? motion.pressIn : motion.pressOut,
        curve: _down ? AppCurves.pressIn : AppCurves.pressOut,
        child: widget.child,
      ),
    );
  }
}
