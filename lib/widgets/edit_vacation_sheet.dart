/// "Edit vacation" (additions handoff §4.4): rename a booking — every day of
/// it at once — or move it to other dates. Opened from a leave-list row or an
/// expanded vacation day in History.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../domain/date_only.dart';
import '../domain/vacation_bookings.dart';
import '../providers/repository_providers.dart';
import 'app_bottom_sheet.dart';
import 'app_date_picker.dart';
import 'app_form_field.dart';
import 'buttons.dart';

Future<void> showEditVacationSheet(BuildContext context, VacationBooking booking) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => EditVacationSheet(booking: booking),
  );
}

class EditVacationSheet extends ConsumerStatefulWidget {
  const EditVacationSheet({super.key, required this.booking, this.autofocus = true});

  final VacationBooking booking;

  /// Off in the render harness, which has no keyboard to raise.
  final bool autofocus;

  @override
  ConsumerState<EditVacationSheet> createState() => _EditVacationSheetState();
}

class _EditVacationSheetState extends ConsumerState<EditVacationSheet> {
  late final _name = TextEditingController(text: widget.booking.name ?? '');
  late DateTime _first = widget.booking.first;
  late DateTime _last = widget.booking.last;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _datesChanged => _first != widget.booking.first || _last != widget.booking.last;

  Future<void> _pick({required bool first}) async {
    final picked = await showAppDatePicker(context: context, initial: first ? _first : _last);
    if (picked == null || !mounted) return;
    setState(() {
      if (first) {
        _first = dateOnly(picked);
        if (_last.isBefore(_first)) _last = _first;
      } else {
        _last = dateOnly(picked);
        if (_last.isBefore(_first)) _first = _last;
      }
    });
  }

  Future<void> _save() async {
    if (_saving || widget.booking.isUngrouped) return;
    setState(() => _saving = true);
    final repo = ref.read(leaveRepositoryProvider);
    try {
      final name = _name.text.trim();
      if (name != (widget.booking.name ?? '')) {
        await repo.renameVacation(widget.booking.id, name);
      }
      if (_datesChanged) {
        await repo.moveVacation(vacationId: widget.booking.id, first: _first, last: _last);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final count = booking.dates.length;
    final range = booking.first == booking.last
        ? AppFormat.dayAndMonth(booking.first)
        : AppFormat.weekRangeShort(booking.first, booking.last);

    return AppSheet(
      title: 'Edit vacation',
      subtitle: '$range · $count workday${count == 1 ? '' : 's'}',
      actions: [
        SecondaryPill(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        PrimaryPill(label: 'Save', onPressed: _saving ? null : _save),
      ],
      children: [
        AppTextField(
          label: 'NAME · OPTIONAL',
          controller: _name,
          autofocus: widget.autofocus,
          placeholder: 'e.g. Sommer an der Ostsee',
          hint: count == 1 ? 'Renames this day' : 'Renames all $count days',
          maxLength: 40,
        ),
        Row(
          children: [
            Expanded(
              child: SheetField(
                label: 'FROM',
                value: AppFormat.dayRow(_first),
                onTap: () => _pick(first: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SheetField(
                label: 'TO',
                value: AppFormat.dayRow(_last),
                onTap: () => _pick(first: false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
