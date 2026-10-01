/// The "about this setting" sheet (additions handoff §1.3, variant B), with
/// a control, with only a link, and with the break law's table.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/core/icons/app_icons.dart';
import 'package:time_manager/core/theme/app_colors.dart';
import 'package:time_manager/core/theme/app_dimens.dart';
import 'package:time_manager/features/settings/setting_info_sheet.dart';

import 'harness.dart';

Future<void> _noop(Object? _) async {}

void main() {
  setUpAll(loadAppFonts);

  final sheets = <String, SettingInfo>{
    'settings-info-autobreak': SettingInfo(
      name: 'Auto-break',
      group: 'Breaks · all jobs',
      value: 'on',
      icon: AppIcons.coffee,
      tone: SettingTone.breaks,
      body: "Deducts the legally required break (30 min after 6 h, 45 min after 9 h) when "
          "you didn't check out for one.",
      rules: const [('After 6 h of work', '30 min'), ('After 9 h of work', '45 min')],
      footnote: 'Time between your sessions counts toward it first; only what is still '
          'missing is deducted.',
      control: ToggleControl(label: 'Deduct missing breaks', value: true, onSave: _noop),
    ),
    'settings-info-quota': SettingInfo(
      name: 'Vacation quota',
      group: 'Leave',
      value: '30 days/yr',
      icon: AppIcons.airplaneTilt,
      tone: SettingTone.vacation,
      body: 'Vacation days per full year. This year the job covers 9 full months, so it is '
          'pro-rated: 30 × 9/12 = 22.5, which makes 23 days in 2026.',
      control: NumberControl(
        value: 30,
        min: 0,
        max: 60,
        step: 1,
        unit: 'days',
        format: (v) => '${v.round()}',
        onSave: _noop,
      ),
    ),
    'settings-info-workdays': SettingInfo(
      name: 'Work days',
      group: 'Schedule',
      value: 'Mon–Fri',
      icon: AppIcons.calendarDots,
      body: 'Days with a target. Other days are rest days and never count as missed; work '
          'on them still counts in full.',
      control: WorkDaysControl(value: const [1, 2, 3, 4, 5], onSave: _noop),
    ),
    'settings-info-holidays': SettingInfo(
      name: 'Public holidays',
      group: 'Holidays · all jobs',
      value: 'DE · 12',
      icon: AppIcons.confetti,
      tone: SettingTone.holiday,
      body: 'Days off with no target, loaded for Baden-Württemberg. You can add or remove '
          'days, including half days.',
      openLabel: 'Open list',
      onOpen: () {},
    ),
  };

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final MapEntry(key: name, value: info) in sheets.entries) {
      testWidgets('$name (${brightness.name})', (tester) async {
        await renderGolden(
          tester,
          name: name,
          brightness: brightness,
          size: const Size(1080, 1900),
          child: Builder(
            builder: (context) => ColoredBox(
              color: context.colors.scrim,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  ),
                  child: SettingInfoSheet(info: info),
                ),
              ),
            ),
          ),
        );
      });
    }
  }
}
