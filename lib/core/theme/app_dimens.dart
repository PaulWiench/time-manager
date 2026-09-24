/// Golden Hour's geometry scales.
///
/// Every number a screen draws should come from here. The old 0.7x scale this
/// replaces was mostly unused — spacing was hardcoded at ~160 call sites — so
/// the rule for the redesign is that a screen is not done until its file
/// contains no bare spacing literals.
library;

/// 4 dp grid.
class AppSpace {
  AppSpace._();

  static const double s1 = 4; // icon-to-label, rail segment gap
  static const double s2 = 8; // chip padding, number-cluster gap
  static const double s3 = 12; // gap between day rows
  static const double s4 = 16; // row horizontal padding, dense gutter
  static const double s5 = 20; // sparse gutter, card padding
  static const double s6 = 24; // gap between cards / settings groups
  static const double s8 = 32; // block gap on sparse screens
  static const double s10 = 40; // top of an onboarding question
  static const double s14 = 56; // primary pill height

  /// Home and Onboarding breathe; the list screens are denser.
  static const double gutterSparse = s5;
  static const double gutterDense = s4;

  /// Bottom padding for scroll views, so the floating nav never covers the
  /// last item: nav height 64 + its 16 dp inset + 24 dp of air.
  static const double navClearance = 104;

  @Deprecated('Use gutterSparse or gutterDense; kept so untouched screens still compile.')
  static const double screenPadding = gutterSparse;
}

class AppRadius {
  AppRadius._();

  static const double cell = 5; // heatmap legend cells, swatches
  static const double cellLg = 8; // heatmap cells >= 36 dp
  static const double sm = 10; // date blocks, chips, note boxes, icon tiles
  static const double md = 16; // day rows, inputs, settings rows
  static const double lg = 24; // cards, settings groups, sheets, dialogs
  static const double xl = 32; // the Dusk Slab, the expanded widget
  static const double pill = 999; // buttons, segmented, nav, chips, bars
}

class AppStroke {
  AppStroke._();

  static const double hair = 1; // light-mode card/row outline
  static const double dash = 1.5; // synthetic break, missed day, audit row
  static const double dashOn = 4, dashOff = 3;
  static const double focus = 2; // focus ring and "today" outlines, offset 2
  static const double ring = 22; // the in-app progress ring
  static const double ringTick = 2; // engraved hour ticks, length 8 (r-4 .. r+4)
  static const double knobCut = 3; // slab-coloured stroke around a knob
  static const double ringWidget1x1 = 7;
  static const double ringWidget4x2 = 12;
  static const double vacationRing = 14;
  static const double timelineRail = 2;
  static const double chartLine = 2.5;
  static const double chartGrid = 1;
}

class AppSize {
  AppSize._();

  static const double touch = 44; // minimum hit area, everywhere

  /// Ring box includes the knob's 17 dp margin, so the track radius is
  /// 216 / 2 - 17 = 91.
  static const double ringInApp = 216;
  static const double knob = 30;
  static const double railHeight = 12;
  static const double railKnob = 22;

  static const double dateBlock = 44;
  static const double iconTile = 36;
  static const double timelineDot = 10;
  static const double timelineActiveDot = 16;
  static const double chipHeight = 32;
  static const double swatch = 12;

  static const double navHeight = 64;
  static const double pillButton = 56;
  static const double segmented = 44;
  static const double rangeChip = 36;
  static const double toggleW = 52, toggleH = 32;
  static const double toggleThumbOn = 24, toggleThumbOff = 16;

  static const double widget1x1 = 72;
  static const double widget4x2W = 321, widget4x2H = 148;
}

class AppIconSize {
  AppIconSize._();

  static const double xs = 14; // state glyph beside the ring kicker
  static const double sm = 16; // chip leading icon, note icons
  static const double md = 18; // chevrons, small in-row actions
  static const double lg = 20; // settings tiles, day-row leave icons
  static const double nav = 22;
  static const double xl = 24; // icon buttons, onboarding stepper
}
