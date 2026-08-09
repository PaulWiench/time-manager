import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/stat_card.dart';

enum StatsTab { overview, patterns, leave }

/// Header, in-screen tab bar, and range selector per the design handoff —
/// the shell every chart eventually lives inside. Chart bodies themselves
/// (balance trend, heatmap, donut, etc.) are Milestone 8 scope; each is a
/// placeholder here so the nav destination is complete and the shell can
/// be reviewed against the handoff now rather than twice.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsTab _tab = StatsTab.overview;
  String _range = 'Month';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 14, AppSpace.screenPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stats', style: AppTextStyles.screenTitle.copyWith(color: colors.text)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final t in StatsTab.values) ...[
                        _TabLabel(tab: t, active: _tab == t, colors: colors, onTap: () => setState(() => _tab = t)),
                        const SizedBox(width: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_tab == StatsTab.leave)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 15, color: colors.textMuted),
                        const SizedBox(width: 10),
                        Text(DateTime.now().year.toString(), style: AppTextStyles.heroNumber(13).copyWith(color: colors.text)),
                        const SizedBox(width: 10),
                        PhosphorIcon(PhosphorIconsRegular.caretRight, size: 15, color: colors.textMuted),
                      ],
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final r in const ['Month', '6 Months', 'Year', 'Custom']) ...[
                            _RangeChip(label: r, selected: _range == r, colors: colors, onTap: () => setState(() => _range = r)),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 14, AppSpace.screenPadding, 20),
                children: _cardsFor(_tab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _cardsFor(StatsTab tab) {
    Widget placeholder(String kicker) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ChartCard(
            kicker: kicker,
            child: SizedBox(
              height: 70,
              child: Center(
                child: Text(
                  'Coming in Milestone 8',
                  style: AppTextStyles.meta.copyWith(color: Theme.of(context).extension<AppColors>()!.textMuted),
                ),
              ),
            ),
          ),
        );

    switch (tab) {
      case StatsTab.overview:
        return [placeholder('Balance trend'), placeholder('Weekly target hit rate'), placeholder('Overtime accumulation rate')];
      case StatsTab.patterns:
        return [placeholder('Monthly overview'), placeholder('Daily hours'), placeholder('By day of week'), placeholder('Check-in times')];
      case StatsTab.leave:
        return [placeholder('Vacation used vs. quota'), placeholder('Sick days taken')];
    }
  }
}

class _TabLabel extends StatelessWidget {
  final StatsTab tab;
  final bool active;
  final AppColors colors;
  final VoidCallback onTap;

  const _TabLabel({required this.tab, required this.active, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = switch (tab) {
      StatsTab.overview => 'Overview',
      StatsTab.patterns => 'Patterns',
      StatsTab.leave => 'Leave',
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? colors.accentFill : Colors.transparent, width: 2))),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(color: active ? colors.accentText : colors.textMuted, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  const _RangeChip({required this.label, required this.selected, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: selected ? colors.accentTint : null, borderRadius: BorderRadius.circular(100)),
        child: Text(
          label,
          style: AppTextStyles.metaMedium.copyWith(color: selected ? colors.accentText : colors.textMuted, fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
        ),
      ),
    );
  }
}
