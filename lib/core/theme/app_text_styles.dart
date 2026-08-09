import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale from the design handoff: Inter, weights 400/500/600,
/// heading weight (600) reserved for the ring timer, stat numbers, and
/// screen titles. Colors are intentionally omitted here — callers apply
/// [AppColors] roles via `copyWith`, matching how the design tokens
/// separate type scale from color role.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter(double size, FontWeight weight, {double? height, double? letterSpacing}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, height: height, letterSpacing: letterSpacing);

  /// Ring timer (30/600) and stat-card hero numbers (20/600) share this
  /// family; pass [size] explicitly.
  static TextStyle heroNumber(double size) => _inter(size, FontWeight.w600, letterSpacing: -0.2, height: 1.0);

  static TextStyle screenTitle = _inter(15, FontWeight.w600, height: 1.2, letterSpacing: -0.1);

  static TextStyle sectionTitle = _inter(20, FontWeight.w600, height: 1.2);

  static TextStyle body = _inter(13, FontWeight.w500, height: 1.3);
  static TextStyle bodyLarge = _inter(14, FontWeight.w500, height: 1.3);
  static TextStyle bodyRegular = _inter(13, FontWeight.w400, height: 1.4);

  static TextStyle meta = _inter(12, FontWeight.w400, height: 1.2);
  static TextStyle metaMedium = _inter(11, FontWeight.w500, height: 1.2);

  static TextStyle kicker = _inter(11, FontWeight.w600, height: 1.2, letterSpacing: 0.9);
  static TextStyle kickerSm = _inter(12, FontWeight.w600, height: 1.2, letterSpacing: 0.8);

  static TextStyle onboardingTitle = _inter(22, FontWeight.w600, height: 1.3);
}
