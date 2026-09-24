/// The colours the home-screen widget needs, as Android colour resources.
///
/// The widget cannot read Dart's [AppColors] — it runs in the launcher's
/// process, not the app's — so those values have to exist twice. Until now the
/// second copy was hand-maintained Kotlin constants, which had drifted: the
/// widget was still painting the pre-redesign lavender.
///
/// Generating `res/values/tm_tokens.xml` and `res/values-night/tm_tokens.xml`
/// from this one source fixes the drift, and moving the values into resources
/// fixes something else — a resource-backed colour is re-resolved by the
/// launcher on a configuration change, so flipping the system theme no longer
/// leaves the widget in the old palette until the next half-hourly refresh.
///
/// Regenerate with:
///
///     UPDATE_WIDGET_TOKENS=1 flutter test test/core/theme/widget_tokens_test.dart
library;

import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Resource name to the role it mirrors. Only what the widget draws: it has
/// no cards, no chips and no charts.
const widgetTokenRoles = <String, Color Function(AppColors)>{
  'tm_slab': _slab,
  'tm_on_slab': _onSlab,
  'tm_on_slab_muted': _onSlabMuted,
  'tm_slab_track': _slabTrack,
  'tm_accent_fill': _accentFill,
  'tm_break_fill': _breakFill,
  'tm_idle': _idle,
  'tm_ring_lap': _ringLap,
};

Color _slab(AppColors c) => c.slab;
Color _onSlab(AppColors c) => c.onSlab;
Color _onSlabMuted(AppColors c) => c.onSlabMuted;
Color _slabTrack(AppColors c) => c.slabTrack;
Color _accentFill(AppColors c) => c.accentFill;
Color _breakFill(AppColors c) => c.breakFill;
Color _idle(AppColors c) => c.idle;
Color _ringLap(AppColors c) => c.ringLap;

/// The contents of one `tm_tokens.xml`.
String widgetTokensXml(AppColors colors, {required bool night}) {
  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="utf-8"?>')
    ..writeln('<!-- Generated from lib/core/theme/app_colors.dart. Do not edit by hand:')
    ..writeln('     run UPDATE_WIDGET_TOKENS=1 flutter test'
        ' test/core/theme/widget_tokens_test.dart -->')
    ..writeln('<resources>');

  for (final entry in widgetTokenRoles.entries) {
    buffer.writeln(
      '    <color name="${entry.key}">${_argb(entry.value(colors))}</color>',
    );
  }

  buffer.writeln('</resources>');
  return buffer.toString();
}

String _argb(Color color) {
  String hex(double channel) =>
      (channel * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${hex(color.a)}${hex(color.r)}${hex(color.g)}${hex(color.b)}';
}
