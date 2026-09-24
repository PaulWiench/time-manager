/// The component state matrix (handoff §5), drawn.
///
/// Every state a shared component can be in appears here, in both themes. That
/// is deliberate: these are the pieces the screens are assembled from, so a
/// mistake caught on this sheet is a mistake caught once instead of on five
/// screens. The three sheets mirror the design's own boards
/// (`components-ring-timeline`, `components-rows-charts`, `components-controls`)
/// so the two can be held side by side.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/core/icons/app_icons.dart';
import 'package:time_manager/core/theme/app_colors.dart';
import 'package:time_manager/core/theme/app_dimens.dart';
import 'package:time_manager/core/theme/app_text_styles.dart';
import 'package:time_manager/core/theme/tracking_palette.dart';
import 'package:time_manager/domain/tracking_state.dart';
import 'package:time_manager/widgets/app_bottom_sheet.dart';
import 'package:time_manager/widgets/banded_number.dart';
import 'package:time_manager/widgets/buttons.dart';
import 'package:time_manager/widgets/chart_card.dart';
import 'package:time_manager/widgets/day_rail.dart';
import 'package:time_manager/widgets/day_row.dart';
import 'package:time_manager/widgets/event_timeline.dart';
import 'package:time_manager/widgets/pill_nav.dart';
import 'package:time_manager/widgets/range_chip.dart';
import 'package:time_manager/widgets/segmented_control.dart';
import 'package:time_manager/widgets/settings_row.dart';
import 'package:time_manager/widgets/sun_dial.dart';

import 'harness.dart';

/// The day the design's renders were drawn for, so the sheets and the renders
/// carry the same numbers.
final _day = DateTime(2026, 9, 22);
DateTime _at(int hour, int minute) => DateTime(2026, 9, 22, hour, minute);

void main() {
  setUpAll(loadAppFonts);

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('components: ring and timeline (${brightness.name})', (tester) async {
      await renderGolden(
        tester,
        name: 'components-ring-timeline',
        brightness: brightness,
        size: const Size(1600, 2100),
        dpr: 1,
        child: const SingleChildScrollView(child: _RingSheet()),
      );
    });

    testWidgets('components: rows and charts (${brightness.name})', (tester) async {
      await renderGolden(
        tester,
        name: 'components-rows-charts',
        brightness: brightness,
        size: const Size(1600, 2200),
        dpr: 1,
        child: const SingleChildScrollView(child: _RowSheet()),
      );
    });

    testWidgets('components: controls (${brightness.name})', (tester) async {
      await renderGolden(
        tester,
        name: 'components-controls',
        brightness: brightness,
        size: const Size(1600, 2100),
        dpr: 1,
        child: const SingleChildScrollView(child: _ControlSheet()),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Ring, rail and timeline.
// ---------------------------------------------------------------------------

class _RingSheet extends StatelessWidget {
  const _RingSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget onSlab(Widget child, {double pad = AppSpace.s5}) => Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: colors.slab,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: colors.slabRim == null ? null : Border.all(color: colors.slabRim!),
            boxShadow: colors.shadowSlab,
          ),
          child: child,
        );

    Widget dial(TrackingState state, double progress, String timer) => onSlab(
          SunDial(
            progress: progress,
            state: state,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(stateIcon(state), size: AppIconSize.xs, color: colors.stateLabel(state)),
                    const SizedBox(width: AppSpace.s1),
                    Text(stateKicker(state),
                        style: AppTextStyles.kicker.copyWith(color: colors.stateLabel(state))),
                  ],
                ),
                const SizedBox(height: AppSpace.s1),
                Text(timer, style: AppTextStyles.timer.copyWith(color: colors.onSlab)),
              ],
            ),
          ),
        );

    return ComponentSheet(
      title: 'Ring, rail and timeline',
      subtitle: 'Sun Dial states, Day Rail, timeline dot + chip matrix',
      sections: [
        SheetSection(
          title: 'Sun Dial · in-app, on slab',
          children: [
            Specimen(
              label: 'Idle · not started',
              child: dial(TrackingState.notStarted, 0, '0:00'),
            ),
            Specimen(
              label: 'Tracking · 0.717',
              child: dial(TrackingState.tracking, 0.717, '1:46:12'),
            ),
            Specimen(
              label: 'Break · 0.494',
              child: dial(TrackingState.onBreak, 0.494, '0:28:10'),
            ),
            Specimen(
              label: 'Checked out · 1.0',
              child: dial(TrackingState.checkedOut, 1.0, '7:54'),
            ),
            Specimen(
              label: 'Lapped overtime · 1.165',
              child: dial(TrackingState.tracking, 1.165, '5:18:09'),
            ),
          ],
        ),
        SheetSection(
          title: 'Day Rail',
          children: [
            Specimen(
              label: 'Work, break, synthetic, leave (hatched), now knob',
              width: 560,
              child: onSlab(
                DayRail(
                  segments: [
                    RailSegment(type: RailSegmentType.work, start: _at(8, 5), end: _at(10, 30)),
                    RailSegment(type: RailSegmentType.realBreak, start: _at(10, 30), end: _at(11, 0)),
                    RailSegment(
                        type: RailSegmentType.syntheticBreak,
                        start: _at(12, 0),
                        end: _at(12, 30)),
                    RailSegment(type: RailSegmentType.work, start: _at(12, 30), end: _at(14, 30)),
                    RailSegment(
                        type: RailSegmentType.vacation, start: _at(14, 30), end: _at(16, 0)),
                  ],
                  axisStart: _at(8, 5),
                  axisEnd: _at(16, 37),
                  state: TrackingState.tracking,
                ),
              ),
            ),
            Specimen(
              label: 'Nothing logged yet',
              width: 400,
              child: onSlab(
                DayRail(
                  segments: const [],
                  axisStart: _day,
                  axisEnd: _day,
                  state: TrackingState.notStarted,
                ),
              ),
            ),
          ],
        ),
        SheetSection(
          title: 'Timeline chips',
          children: [
            for (final (role, label) in const [
              (EventChipRole.work, 'Work session · 3:54'),
              (EventChipRole.realBreak, 'Break · 2:14'),
              (EventChipRole.vacation, 'Vacation · 7:54'),
              (EventChipRole.sick, 'Sick · 7:54'),
              (EventChipRole.flex, 'Flex day · 7:54'),
              (EventChipRole.activeWork, 'Work session · 1:46 so far'),
              (EventChipRole.activeBreak, 'Break · 0:28 so far'),
            ])
              Specimen(
                label: role.name,
                child: EventChip(item: TimelineChipItem(role: role, label: label)),
              ),
            Specimen(
              label: 'syntheticBreak',
              child: const EventChip(
                item: TimelineChipItem(
                  role: EventChipRole.syntheticBreak,
                  label: 'Synthetic break · 0:30',
                ),
              ),
            ),
            Specimen(
              label: 'syntheticBreak · selected, deletable',
              child: EventChip(
                item: TimelineChipItem(
                  role: EventChipRole.syntheticBreak,
                  label: 'Synthetic break · 0:30',
                  selected: true,
                  onDelete: () {},
                ),
              ),
            ),
          ],
        ),
        SheetSection(
          title: 'Timeline',
          children: [
            Specimen(
              label: 'Events, chips and the active tail',
              width: 520,
              child: EventTimeline(
                ground: colors.background,
                items: const [
                  TimelineEvent(label: 'Check in', time: '14:51', isCheckIn: true),
                  TimelineChipItem(role: EventChipRole.realBreak, label: 'Break · 2:14'),
                  TimelineChipItem(
                      role: EventChipRole.syntheticBreak, label: 'Synthetic break · 0:30'),
                  TimelineChipItem(role: EventChipRole.vacation, label: 'Vacation · 3:57'),
                  TimelineActiveItem(
                    state: TrackingState.tracking,
                    label: 'Tracking since 14:51',
                    chipLabel: 'Work session · 1:46 so far',
                  ),
                ],
              ),
            ),
            Specimen(
              label: 'A closed day',
              width: 520,
              child: EventTimeline(
                ground: colors.background,
                items: const [
                  TimelineEvent(label: 'Check in', time: '08:05', isCheckIn: true),
                  TimelineChipItem(role: EventChipRole.work, label: 'Work · 08:05–12:00'),
                  TimelineChipItem(
                      role: EventChipRole.syntheticBreak,
                      label: 'Synthetic break · 12:00–12:30'),
                  TimelineChipItem(role: EventChipRole.work, label: 'Work · 12:30–16:41'),
                  TimelineEvent(label: 'Check out', time: '16:41', isCheckIn: false),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Day rows, numbers and cards.
// ---------------------------------------------------------------------------

class _RowSheet extends StatelessWidget {
  const _RowSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget balance(String text, bool warning, {bool onSlab = false}) => Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s5, vertical: AppSpace.s4),
          decoration: BoxDecoration(
            color: onSlab ? colors.slab : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: onSlab ? null : Border.all(color: colors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              BandedNumber(
                text: text,
                style: AppTextStyles.hero,
                warning: warning,
                plainColor: onSlab ? colors.onSlab : colors.text,
                warningColor: onSlab ? colors.warningFill : colors.warningText,
                bandColor: onSlab ? colors.warningFill : colors.warningTint,
                bandOpacity: onSlab ? 0.28 : 1,
              ),
              const SizedBox(width: AppSpace.s1),
              Text('h',
                  style: AppTextStyles.statSm
                      .copyWith(color: onSlab ? colors.onSlabMuted : colors.textMuted)),
            ],
          ),
        );

    return ComponentSheet(
      title: 'Rows, numbers and cards',
      subtitle: 'Day row statuses, balance treatment, stat and chart cards',
      sections: [
        SheetSection(
          title: 'Day row · collapsed',
          children: [
            const Specimen(
              label: 'Normal',
              width: 460,
              child: DayRow(
                status: DayRowStatus.normal,
                blockTop: 'MON',
                blockBottom: '21',
                line1: '8:06 worked',
                line2: '08:05–16:41',
                delta: '+0:12',
              ),
            ),
            const Specimen(
              label: 'Today',
              width: 460,
              child: DayRow(
                status: DayRowStatus.today,
                blockTop: 'TUE',
                blockBottom: '22',
                line1: '7:54 worked',
                line2: 'Today · 08:42–18:51',
                delta: '+0:00',
              ),
            ),
            const Specimen(
              label: 'Missed scheduled workday',
              width: 460,
              child: DayRow(
                status: DayRowStatus.missed,
                blockTop: 'WED',
                blockBottom: '3',
                line1: 'No entry',
                line2: 'Scheduled workday · missed',
                delta: '−7:54',
              ),
            ),
            const Specimen(
              label: 'Rest day',
              width: 460,
              child: DayRow(
                status: DayRowStatus.rest,
                blockTop: 'SAT',
                blockBottom: '26',
                line1: 'Rest day',
                delta: '—',
              ),
            ),
            const Specimen(
              label: 'Future scheduled',
              width: 460,
              child: DayRow(
                status: DayRowStatus.future,
                blockTop: 'WED',
                blockBottom: '23',
                line1: 'Scheduled',
                line2: '7:54 target',
              ),
            ),
            Specimen(
              label: 'Public holiday',
              width: 460,
              child: const DayRow(
                status: DayRowStatus.publicHoliday,
                blockTop: 'THU',
                blockBottom: '4',
                line1: 'Fronleichnam',
                line2: 'Public holiday',
                trailingIcon: AppIcons.confetti,
              ),
            ),
            const Specimen(
              label: 'Leave · vacation',
              width: 460,
              child: DayRow(
                status: DayRowStatus.vacation,
                blockTop: 'FRI',
                blockBottom: '5',
                line1: 'Vacation · 7:54',
                line2: 'Brückentag',
                trailingIcon: AppIcons.airplaneTilt,
              ),
            ),
            const Specimen(
              label: 'Leave · sick',
              width: 460,
              child: DayRow(
                status: DayRowStatus.sick,
                blockTop: 'MON',
                blockBottom: '14',
                line1: 'Sick · 7:54',
                line2: 'Leave',
                trailingIcon: AppIcons.thermometerSimple,
              ),
            ),
            const Specimen(
              label: 'Delta past the configured floor',
              width: 460,
              child: DayRow(
                status: DayRowStatus.normal,
                blockTop: 'FRI',
                blockBottom: '18',
                line1: '7:07 worked',
                line2: 'Balance −20:41 after this day',
                delta: '−0:47',
                deltaWarning: true,
              ),
            ),
            const Specimen(
              label: 'Month summary',
              width: 460,
              child: DayRow(
                status: DayRowStatus.normal,
                blockTop: '2026',
                blockBottom: 'Aug',
                line1: 'August',
                line2: '157:24 worked',
                delta: '−8:30',
                chevron: true,
              ),
            ),
          ],
        ),
        SheetSection(
          title: 'Day row · expanded',
          children: [
            Specimen(
              label: 'Timeline and notes',
              width: 520,
              child: DayRow(
                status: DayRowStatus.normal,
                blockTop: 'MON',
                blockBottom: '21',
                line1: '8:06 worked',
                line2: '08:05–16:41',
                delta: '+0:12',
                expanded: true,
                expansion: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EventTimeline(
                      ground: colors.surface,
                      items: const [
                        TimelineEvent(label: 'Check in', time: '08:05', isCheckIn: true),
                        TimelineChipItem(
                            role: EventChipRole.work, label: 'Work · 08:05–12:00'),
                        TimelineChipItem(
                            role: EventChipRole.syntheticBreak,
                            label: 'Synthetic break · 12:00–12:30'),
                        TimelineChipItem(
                            role: EventChipRole.work, label: 'Work · 12:30–16:41'),
                        TimelineEvent(label: 'Check out', time: '16:41', isCheckIn: false),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s2),
                    Container(
                      padding: const EdgeInsets.all(AppSpace.s3),
                      decoration: BoxDecoration(
                        color: colors.surface2,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(AppIcons.note,
                                  size: AppIconSize.sm, color: colors.textMuted),
                              const SizedBox(width: AppSpace.s2),
                              Expanded(
                                child: Text(
                                  'Release prep for v1.2, left at 16:41 for the train.',
                                  style: AppTextStyles.body.copyWith(color: colors.text),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.s2),
                          Row(
                            children: [
                              Icon(AppIcons.pencilSimple,
                                  size: AppIconSize.sm, color: colors.textMuted),
                              const SizedBox(width: AppSpace.s2),
                              Text('08:05 session: pairing on the export bug',
                                  style: AppTextStyles.caption
                                      .copyWith(color: colors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SheetSection(
          title: 'Balance number',
          children: [
            Specimen(label: 'Default on surface', child: balance('−15:58', false)),
            Specimen(label: 'Warning on surface', child: balance('−20:41', true)),
            Specimen(label: 'Default on slab', child: balance('−15:58', false, onSlab: true)),
            Specimen(label: 'Warning on slab', child: balance('−20:41', true, onSlab: true)),
          ],
        ),
        SheetSection(
          title: 'Stat and chart cards',
          children: [
            const Specimen(
              label: 'Stat card · default',
              width: 260,
              child: StatCard(
                kicker: 'VACATION LEFT',
                value: '12',
                unit: 'd',
                caption: 'Quota 30 d',
              ),
            ),
            const Specimen(
              label: 'Stat card · warning',
              width: 260,
              child: StatCard(
                kicker: 'VACATION LEFT',
                value: '2',
                unit: 'd',
                caption: 'Threshold 3 d',
                warning: true,
              ),
            ),
            Specimen(
              label: 'Stat card · leave tone',
              width: 260,
              child: StatCard(
                kicker: 'SICK DAYS',
                value: '4',
                unit: 'd',
                caption: '2026 so far',
                tone: colors.sickText,
              ),
            ),
            const Specimen(
              label: 'Chart card · not enough data',
              width: 460,
              child: ChartCard(kicker: 'WEEKLY TARGET HIT RATE'),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Controls.
// ---------------------------------------------------------------------------

class _ControlSheet extends StatelessWidget {
  const _ControlSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ComponentSheet(
      title: 'Controls',
      subtitle: 'Segmented control, range chips, nav, buttons, sheet, settings rows',
      sections: [
        SheetSection(
          title: 'Segmented control and range chips',
          children: [
            Specimen(
              label: 'Segmented · History',
              width: 460,
              child: SegmentedControl<int>(
                segments: const [(0, 'Month'), (1, 'Week'), (2, 'Day')],
                selected: 2,
                onSelect: (_) {},
              ),
            ),
            Specimen(
              label: 'Segmented · Stats tabs',
              width: 460,
              child: SegmentedControl<int>(
                segments: const [(0, 'Overview'), (1, 'Patterns'), (2, 'Leave')],
                selected: 0,
                onSelect: (_) {},
              ),
            ),
            Specimen(
              label: 'Range chips · selected / unselected',
              width: 460,
              child: Row(
                children: [
                  for (final (label, selected) in const [
                    ('1W', false),
                    ('1M', false),
                    ('6M', true),
                    ('1Y', false),
                    ('Custom', false),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpace.s2),
                        child: RangeChip(label: label, selected: selected, onTap: () {}),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        SheetSection(
          title: 'Bottom nav',
          children: [
            for (final tab in AppTab.values)
              Specimen(
                label: 'Active · ${tab.name}',
                width: 500,
                child: PillNav(active: tab, onSelect: (_) {}),
              ),
          ],
        ),
        SheetSection(
          title: 'Buttons',
          children: [
            Specimen(
              label: 'Primary · default',
              width: 300,
              child: PrimaryPill(label: 'Check in', icon: AppIcons.sun, onPressed: () {}),
            ),
            const Specimen(
              label: 'Primary · disabled',
              width: 300,
              child: PrimaryPill(label: 'Check in', icon: AppIcons.sun),
            ),
            Specimen(
              label: 'Secondary · default',
              width: 300,
              child: SecondaryPill(label: 'Cancel', onPressed: () {}),
            ),
            const Specimen(
              label: 'Secondary · disabled',
              width: 300,
              child: SecondaryPill(label: 'Cancel'),
            ),
            Specimen(
              label: 'Text button',
              width: 200,
              child: AppTextButton(label: 'Back', onPressed: () {}),
            ),
            Specimen(
              label: 'Icon button · plain / filled',
              width: 200,
              child: Row(
                children: [
                  AppIconButton(
                    icon: AppIcons.gearSix,
                    semanticLabel: 'Settings',
                    onPressed: () {},
                  ),
                  const SizedBox(width: AppSpace.s2),
                  AppIconButton(
                    icon: AppIcons.calendarDots,
                    semanticLabel: 'Jump to date',
                    filled: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
        SheetSection(
          title: 'Bottom sheet and settings rows',
          children: [
            Specimen(
              label: 'Edit-session sheet',
              width: 480,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  boxShadow: colors.shadowFloat,
                ),
                child: AppSheet(
                  title: 'Edit session',
                  subtitle: 'Mon 21 Sep · 8:06 net after breaks',
                  onClose: () {},
                  actions: [
                    SecondaryPill(label: 'Cancel', onPressed: () {}),
                    PrimaryPill(label: 'Save', onPressed: () {}),
                  ],
                  children: const [
                    Row(
                      children: [
                        Expanded(child: SheetField(label: 'START', value: '08:05')),
                        SizedBox(width: AppSpace.s3),
                        Expanded(child: SheetField(label: 'END', value: '16:41')),
                      ],
                    ),
                    SheetField(label: 'NOTE', value: 'Pairing on the export bug'),
                  ],
                ),
              ),
            ),
            Specimen(
              label: 'Settings rows: navigate, toggle on, toggle off, static',
              width: 520,
              child: SettingsGroup(
                title: 'SCHEDULE',
                rows: [
                  SettingsRow.navigate(
                    icon: AppIcons.hourglassMedium,
                    label: 'Weekly hours',
                    value: '39.5 h',
                    onTap: () {},
                  ),
                  SettingsRow.toggle(
                    icon: AppIcons.coffee,
                    label: 'Auto-break',
                    sub: '30 min after 6 h, 45 min after 9 h',
                    value: true,
                    onChanged: (_) {},
                  ),
                  SettingsRow.toggle(
                    icon: AppIcons.clockUser,
                    label: 'Restrict check-in',
                    value: false,
                    onChanged: (_) {},
                  ),
                  SettingsRow.static(
                    icon: AppIcons.plusMinus,
                    label: 'Starting balance',
                    sub: 'Set during onboarding',
                    value: '0:00',
                  ),
                ],
              ),
            ),
            Specimen(
              label: 'Advanced row',
              width: 480,
              child: AdvancedRow(
                icon: AppIcons.code,
                label: 'Audit log',
                sub: 'Every change, as stored',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}
