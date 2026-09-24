/// Retroactive edit UI for a completed [WorkSession] — the UI for the
/// already-implemented `WorkSessionRepository.editSession`/`deleteSession`.
///
/// It also records manual breaks within the session's span. A manual break is
/// a pure annotation: per `domain/recalculation_engine.dart` it does not reduce
/// net worked hours the way the auto-break deduction does. The design's §4.3.6
/// shows only start, end and a note, but the sheet already did more than that
/// before the redesign, so this restyles rather than removes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import '../data/database/database.dart';
import '../data/database/enums.dart';
import '../providers/day_providers.dart';
import '../providers/repository_providers.dart';
import 'app_bottom_sheet.dart';
import 'buttons.dart';

class EditSessionSheet extends ConsumerStatefulWidget {
  const EditSessionSheet({super.key, required this.session});

  final WorkSession session;

  static Future<void> show(BuildContext context, WorkSession session) {
    return showAppSheet(
      context: context,
      builder: (_) => EditSessionSheet(session: session),
    );
  }

  @override
  ConsumerState<EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends ConsumerState<EditSessionSheet> {
  late DateTime _start;
  late DateTime _end;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _start = widget.session.startTime;
    _end = widget.session.endTime ?? widget.session.startTime;
    _notes = TextEditingController(text: widget.session.notes ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  /// Time pickers only edit the time of day, keeping the session's original
  /// calendar date — moving a session across midnight is not exposed here,
  /// even though `editSession` supports it.
  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    setState(() {
      final updated = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
      if (isStart) {
        _start = updated;
      } else {
        _end = updated;
      }
    });
  }

  Future<void> _save() async {
    final notes = _notes.text.trim();
    await ref.read(workSessionRepositoryProvider).editSession(
          sessionId: widget.session.id,
          start: _start,
          end: _end,
          notes: notes.isEmpty ? null : notes,
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(workSessionRepositoryProvider).deleteSession(widget.session.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dayEntry = ref.watch(dayEntryForDateProvider(widget.session.date)).valueOrNull;
    final allBreaks =
        ref.watch(breaksForDateProvider(widget.session.date)).valueOrNull ?? const [];
    final manualBreaks = allBreaks
        .where((b) =>
            b.type == BreakType.manual &&
            !b.startTime.isBefore(_start) &&
            !b.endTime.isAfter(_end))
        .toList();

    return AppSheet(
      title: 'Edit session',
      subtitle: [
        AppFormat.dayRow(widget.session.date),
        if (dayEntry != null) '${AppFormat.hm(dayEntry.netWorkedHours)} net after breaks',
      ].join(' · '),
      actions: [
        SecondaryPill(label: 'Delete', onPressed: _delete),
        PrimaryPill(label: 'Save', onPressed: _save),
      ],
      children: [
        Row(
          children: [
            Expanded(
              child: SheetField(
                label: 'START',
                value: AppFormat.time(_start),
                onTap: () => _pickTime(isStart: true),
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: SheetField(
                label: 'END',
                value: AppFormat.time(_end),
                onTap: () => _pickTime(isStart: false),
              ),
            ),
          ],
        ),
        _NoteField(controller: _notes),
        _ManualBreaks(
          breaks: manualBreaks,
          onAdd: _addBreak,
          onRemove: (id) => ref.read(workSessionRepositoryProvider).deleteManualBreak(id),
        ),
      ],
    );
  }

  Future<void> _addBreak() async {
    var breakStart = _start;
    var breakEnd = _end.difference(_start) > const Duration(minutes: 30)
        ? _start.add(const Duration(minutes: 30))
        : _end;

    DateTime withTime(TimeOfDay time) =>
        DateTime(_start.year, _start.month, _start.day, time.hour, time.minute);

    await showDialog<void>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Add break',
              style: AppTextStyles.headline.copyWith(color: dialogContext.colors.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetField(
                label: 'START',
                value: AppFormat.time(breakStart),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: dialogContext,
                    initialTime: TimeOfDay.fromDateTime(breakStart),
                  );
                  if (picked != null) {
                    setDialogState(() => breakStart = withTime(picked));
                  }
                },
              ),
              const SizedBox(height: AppSpace.s3),
              SheetField(
                label: 'END',
                value: AppFormat.time(breakEnd),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: dialogContext,
                    initialTime: TimeOfDay.fromDateTime(breakEnd),
                  );
                  if (picked != null) {
                    setDialogState(() => breakEnd = withTime(picked));
                  }
                },
              ),
            ],
          ),
          actions: [
            AppTextButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(dialogContext),
            ),
            PrimaryPill(
              label: 'Add',
              expand: false,
              height: AppSize.touch,
              onPressed: breakEnd.isAfter(breakStart) &&
                      !breakStart.isBefore(_start) &&
                      !breakEnd.isAfter(_end)
                  ? () {
                      ref.read(workSessionRepositoryProvider).addManualBreak(
                            date: widget.session.date,
                            start: breakStart,
                            end: breakEnd,
                          );
                      Navigator.pop(dialogContext);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The note, editable in place. A [SheetField] that opens yet another dialog
/// to type one line would be a dialog too many.
class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s4,
        vertical: AppSpace.s3,
      ),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('NOTE', style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
          TextField(
            controller: controller,
            style: AppTextStyles.body.copyWith(color: colors.text),
            cursorColor: colors.accentStrong,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'What was this session?',
              hintStyle: AppTextStyles.body.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualBreaks extends StatelessWidget {
  const _ManualBreaks({
    required this.breaks,
    required this.onAdd,
    required this.onRemove,
  });

  final List<BreakEntry> breaks;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('BREAKS',
                  style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
            ),
            AppTextButton(label: 'Add break', onPressed: onAdd),
          ],
        ),
        if (breaks.isEmpty)
          Text('None recorded',
              style: AppTextStyles.caption.copyWith(color: colors.textMuted))
        else
          for (final entry in breaks)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppFormat.time(entry.startTime)}–${AppFormat.time(entry.endTime)}',
                    style: AppTextStyles.body.copyWith(color: colors.text),
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.x,
                  semanticLabel: 'Remove break',
                  size: AppIconSize.md,
                  color: colors.textMuted,
                  onPressed: () => onRemove(entry.id),
                ),
              ],
            ),
      ],
    );
  }
}
