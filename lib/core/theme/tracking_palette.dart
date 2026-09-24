/// Which colour and glyph the day's current state wears.
///
/// The ring, the rail's now knob, the timeline's active row, the state kicker
/// and the widget all answer the same question, and they must never answer it
/// differently — "on break" being lilac in one place and apricot in another is
/// the kind of drift that makes a design look approximate.
library;

import 'package:flutter/widgets.dart';

import '../../domain/tracking_state.dart';
import '../icons/app_icons.dart';
import 'app_colors.dart';

extension TrackingPalette on AppColors {
  /// The ring arc, the rail knob, the active timeline dot.
  Color stateFill(TrackingState state) => switch (state) {
        TrackingState.tracking => accentFill,
        TrackingState.onBreak => breakFill,
        TrackingState.checkedOut => idle,
        TrackingState.notStarted => slabTrack,
      };

  /// The kicker beside the ring: the two live states carry their hue, the two
  /// resting ones stay muted so only one thing on the slab is ever loud.
  Color stateLabel(TrackingState state) => switch (state) {
        TrackingState.tracking => accentFill,
        TrackingState.onBreak => breakFill,
        TrackingState.checkedOut => onSlabMuted,
        TrackingState.notStarted => onSlabMuted,
      };
}

IconData stateIcon(TrackingState state) => switch (state) {
      TrackingState.tracking => AppIcons.sun,
      TrackingState.onBreak => AppIcons.coffee,
      TrackingState.checkedOut => AppIcons.moon,
      TrackingState.notStarted => AppIcons.power,
    };

String stateKicker(TrackingState state) => switch (state) {
      TrackingState.tracking => 'TRACKING',
      TrackingState.onBreak => 'ON BREAK',
      TrackingState.checkedOut => 'CHECKED OUT',
      TrackingState.notStarted => 'NOT STARTED',
    };
