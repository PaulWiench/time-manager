/// Golden Hour's motion table (handoff §6), in one place.
///
/// Every animated value in the app comes from here so the same gesture never
/// gets two different durations in two different files. The durations are
/// deliberately short: this is a tracker that gets opened for four seconds at
/// a time, and animation that outlasts the glance is animation in the way.
///
/// Reduced motion is honoured by asking for durations through
/// [AppMotion.of] rather than reading the constants directly — it returns a
/// table of zeros when the platform says animations are disabled, so a widget
/// never has to branch on it.
library;

import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._({required this.enabled});

  /// The real table.
  static const full = AppMotion._(enabled: true);

  /// Every duration zero, for `MediaQuery.disableAnimations`.
  static const none = AppMotion._(enabled: false);

  final bool enabled;

  /// The table in force for [context]. Widgets that animate should read this
  /// once in `build` and use it for every duration they pass downwards.
  static AppMotion of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? none : full;

  Duration _d(int ms) => enabled ? Duration(milliseconds: ms) : Duration.zero;

  // Shell.
  Duration get tabOut => _d(60);
  Duration get tabIn => _d(120);
  Duration get navPill => _d(200);

  // History.
  Duration get drillDown => _d(240);
  Duration get drillUp => _d(200);
  Duration get rowExpand => _d(200);
  Duration get rowCollapse => _d(160);

  /// Each timeline item fades in this much after the one before it, for the
  /// first [kStaggerMax] items.
  Duration get stagger => _d(20);

  Duration get chipSelect => _d(200);
  Duration get chipDelete => _d(160);
  Duration get deletePillIn => _d(120);

  // Overlays.
  Duration get sheetIn => _d(240);
  Duration get sheetOut => _d(200);
  Duration get scrimIn => _d(120);

  // Controls.
  Duration get control => _d(200);
  Duration get pressIn => _d(120);
  Duration get pressOut => _d(60);

  // The ring.
  Duration get ringFirstFill => _d(500);
  Duration get ringTick => _d(250);
  Duration get ringStateColor => _d(200);
  Duration get pulse => _d(1600);

  /// Whether a looping animation should run at all. A pulse with a zero
  /// duration is not a still frame, it is a busy loop.
  bool get loops => enabled;
}

/// Curves, which do not vary with the reduced-motion setting.
class AppCurves {
  AppCurves._();

  static const tabOut = Curves.easeIn;
  static const tabIn = Curves.easeOutCubic;

  /// Shared-axis Z, used by the History drill-down and every overlay.
  static const emphasized = Cubic(0.05, 0.7, 0.1, 1.0);

  static const expand = Curves.easeOutCubic;
  static const collapse = Curves.easeInCubic;
  static const control = Curves.easeOutCubic;
  static const pressIn = Curves.easeOutCubic;
  static const pressOut = Curves.easeIn;
  static const pulse = Curves.easeInOut;

  /// The arc lerps between state colours linearly: an eased colour change on
  /// a large area reads as a flicker.
  static const ringStateColor = Curves.linear;
}

/// Incoming tab content scales from this to 1.
const double kTabInScale = 0.98;

/// Pressed controls scale to this.
const double kPressScale = 0.98;

/// The pulse dips to this opacity and back.
const double kPulseMinOpacity = 0.55;

/// Staggered fade-ins stop after this many items — past five the stagger is
/// no longer read as sequence, only as lag.
const int kStaggerMax = 5;
