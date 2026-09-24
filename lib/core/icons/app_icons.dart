/// Phosphor icons, self-hosted.
///
/// The `phosphor_flutter` package cannot be used any more: it declares
/// `class PhosphorIconData extends IconData`, and Flutter made `IconData` a
/// final class, so the package stopped compiling and has no newer release.
/// Since the design only ever asks for two weights (Bold everywhere, Fill for
/// the active nav item), the two font files are bundled directly and the
/// codepoints below were extracted once from phosphor_flutter 2.1.0's
/// generated `phosphor_icons_{bold,fill}.dart`.
///
/// Self-hosting also removes the `package:` argument every icon font otherwise
/// needs when painted by hand — the ring's knob glyph is drawn with a
/// TextPainter, which is easy to get silently wrong through a package font.
library;

import 'package:flutter/widgets.dart';

const String _bold = 'PhosphorBold';
const String _fill = 'PhosphorFill';

/// Bold weight — every icon in the app except the active nav item.
class AppIcons {
  static const IconData houseSimple = IconData(0xe2c6, fontFamily: _bold);
  static const IconData clockCounterClockwise = IconData(0xe1a0, fontFamily: _bold);
  static const IconData chartLineUp = IconData(0xe156, fontFamily: _bold);
  static const IconData gearSix = IconData(0xe272, fontFamily: _bold);
  static const IconData sun = IconData(0xe472, fontFamily: _bold);
  static const IconData coffee = IconData(0xe1c2, fontFamily: _bold);
  static const IconData moon = IconData(0xe330, fontFamily: _bold);
  static const IconData power = IconData(0xe3da, fontFamily: _bold);
  static const IconData clock = IconData(0xe19a, fontFamily: _bold);
  static const IconData playCircle = IconData(0xe3d2, fontFamily: _bold);
  static const IconData timer = IconData(0xe492, fontFamily: _bold);
  static const IconData airplaneTilt = IconData(0xe5d6, fontFamily: _bold);
  static const IconData confetti = IconData(0xe81a, fontFamily: _bold);
  static const IconData thermometerSimple = IconData(0xe5cc, fontFamily: _bold);
  static const IconData arrowsLeftRight = IconData(0xe0a0, fontFamily: _bold);
  static const IconData calendarDots = IconData(0xe7b4, fontFamily: _bold);
  static const IconData calendarBlank = IconData(0xe10a, fontFamily: _bold);
  static const IconData calendarCheck = IconData(0xe712, fontFamily: _bold);
  static const IconData hourglassMedium = IconData(0xe2b8, fontFamily: _bold);
  static const IconData plusMinus = IconData(0xe3d8, fontFamily: _bold);
  static const IconData clockUser = IconData(0xedec, fontFamily: _bold);
  static const IconData scales = IconData(0xe750, fontFamily: _bold);
  static const IconData umbrellaSimple = IconData(0xe686, fontFamily: _bold);
  static const IconData bellSimple = IconData(0xe0d0, fontFamily: _bold);
  static const IconData code = IconData(0xe1bc, fontFamily: _bold);
  static const IconData floppyDisk = IconData(0xe248, fontFamily: _bold);
  static const IconData plus = IconData(0xe3d4, fontFamily: _bold);
  static const IconData minus = IconData(0xe32a, fontFamily: _bold);
  static const IconData x = IconData(0xe4f6, fontFamily: _bold);
  static const IconData caretLeft = IconData(0xe138, fontFamily: _bold);
  static const IconData caretRight = IconData(0xe13a, fontFamily: _bold);
  static const IconData caretUp = IconData(0xe13c, fontFamily: _bold);
  static const IconData caretDown = IconData(0xe136, fontFamily: _bold);
  static const IconData pencilSimple = IconData(0xe3b4, fontFamily: _bold);
  static const IconData pencilSimpleLine = IconData(0xebc6, fontFamily: _bold);
  static const IconData note = IconData(0xe348, fontFamily: _bold);
  static const IconData trash = IconData(0xe4a6, fontFamily: _bold);
}

/// Fill weight — the active bottom-nav item only.
class AppIconsFill {
  static const IconData houseSimple = IconData(0xe2c6, fontFamily: _fill);
  static const IconData clockCounterClockwise = IconData(0xe1a0, fontFamily: _fill);
  static const IconData chartLineUp = IconData(0xe156, fontFamily: _fill);
  static const IconData gearSix = IconData(0xe272, fontFamily: _fill);
}
