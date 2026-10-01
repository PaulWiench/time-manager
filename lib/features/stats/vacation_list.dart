/// "VACATIONS 2026" on Stats → Leave (additions handoff §4.2): one row per
/// booking, planned first, each opening the rename/edit sheet.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
import '../../core/painting/dashed_border.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/leave_days.dart';
import '../../domain/vacation_bookings.dart';
import '../../widgets/press_scale.dart';

class VacationList extends StatelessWidget {
  const VacationList({
    super.key,
    required this.year,
    required this.bookings,
    required this.daysLeftAfterPlanned,
    this.onOpen,
  });

  final int year;
  final List<VacationBooking> bookings;
  final double daysLeftAfterPlanned;
  final ValueChanged<VacationBooking>? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final used = bookings.where((b) => !b.planned).fold<double>(0, (s, b) => s + b.days);
    final planned = bookings.where((b) => b.planned).fold<double>(0, (s, b) => s + b.days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
          child: Row(
            children: [
              Expanded(
                child: Text('VACATIONS $year',
                    style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
              ),
              Text('${formatLeaveDays(used)} used · ${formatLeaveDays(planned)} planned',
                  style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.divider, width: AppStroke.hair),
            boxShadow: colors.shadowSm,
          ),
          child: Column(
            children: [
              for (final (i, booking) in bookings.indexed) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, right: AppSpace.s4),
                    child: Container(height: AppStroke.hair, color: colors.divider),
                  ),
                _VacationRow(
                  booking: booking,
                  onTap: onOpen == null ? null : () => onOpen!(booking),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
          child: Text(
            '${formatLeaveDays(daysLeftAfterPlanned)} days left after planned. '
            'Tap a vacation to rename or change it.',
            style: AppTextStyles.caption.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _VacationRow extends StatelessWidget {
  const _VacationRow({required this.booking, this.onTap});

  final VacationBooking booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final range = vacationRangeLabel(booking.first, booking.last);
    final name = booking.name;

    return Semantics(
      button: onTap != null,
      label: '${name ?? 'Unnamed vacation'}, $range'
          '${booking.planned ? ', planned' : ''}, ${formatLeaveDays(booking.days)} days',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
          child: Row(
            children: [
              VacationSwatch(planned: booking.planned),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name ?? 'Unnamed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLg
                          .copyWith(color: name == null ? colors.textMuted : colors.text),
                    ),
                    Text(
                      booking.planned ? '$range · planned' : range,
                      style: AppTextStyles.caption.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: formatLeaveDays(booking.days),
                    style: AppTextStyles.statSm.copyWith(color: colors.text),
                  ),
                  TextSpan(
                    text: ' d',
                    style: AppTextStyles.caption.copyWith(color: colors.textMuted),
                  ),
                ]),
              ),
              const SizedBox(width: AppSpace.s2),
              Icon(AppIcons.caretRight, size: AppIconSize.md, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// `5 Jun`, `3–17 Aug`, `28 Sep – 2 Oct`.
String vacationRangeLabel(DateTime first, DateTime last) {
  if (first == last) return AppFormat.dayAndMonth(first);
  return AppFormat.weekRangeShort(first, last);
}

/// The 12×32 pill beside a vacation: hatched when taken, a dashed outline
/// when still to come.
class VacationSwatch extends StatelessWidget {
  const VacationSwatch({super.key, required this.planned});

  final bool planned;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const size = Size(AppSize.swatch, 32);
    if (planned) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: ShapeDecoration(
          shape: DashedRoundedBorder(color: colors.vacationText, radius: AppRadius.pill),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: CustomPaint(
        size: size,
        painter: _HatchPainter(fill: colors.vacationFill, ground: colors.vacationTint),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  _HatchPainter({required this.fill, required this.ground});

  final Color fill;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final stripe = Paint()
      ..color = fill
      ..strokeWidth = 3;
    // 3 on, 3 off at 135°.
    final span = size.width + size.height;
    for (var d = -size.height; d < span; d += 6 * math.sqrt2) {
      canvas.drawLine(Offset(d, size.height), Offset(d + size.height, 0), stripe);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.fill != fill || old.ground != ground;
}
