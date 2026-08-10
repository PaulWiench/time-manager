import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import '../data/database/database.dart';
import '../data/database/enums.dart';
import '../providers/day_providers.dart';
import '../providers/repository_providers.dart';

/// Retroactive edit UI for a completed [WorkSession] — the UI that was
/// missing for the already-implemented `WorkSessionRepository.editSession`/
/// `deleteSession` (Requirements § 6). Also lets the user record a manual
/// break within the session's span; per the domain doc
/// (`domain/recalculation_engine.dart`), a manual break is a pure
/// annotation and doesn't reduce net worked hours the way the auto-break
/// deduction does.
class EditSessionSheet extends ConsumerStatefulWidget {
  final WorkSession session;
  const EditSessionSheet({super.key, required this.session});

  static Future<void> show(BuildContext context, WorkSession session) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditSessionSheet(session: session),
    );
  }

  @override
  ConsumerState<EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends ConsumerState<EditSessionSheet> {
  late DateTime _start;
  late DateTime _end;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _start = widget.session.startTime;
    _end = widget.session.endTime ?? widget.session.startTime;
    _notesController = TextEditingController(text: widget.session.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Time pickers only edit the time-of-day, keeping the session's original
  // calendar date — moving a session across midnight isn't exposed here,
  // even though editSession() itself supports it.
  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (picked == null) return;
    setState(() {
      final updated = DateTime(current.year, current.month, current.day, picked.hour, picked.minute);
      if (isStart) {
        _start = updated;
      } else {
        _end = updated;
      }
    });
  }

  Future<void> _save() async {
    final notes = _notesController.text.trim();
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

  Future<void> _addBreak() async {
    var breakStart = _start;
    var breakEnd = _end.difference(_start) > const Duration(minutes: 30) ? _start.add(const Duration(minutes: 30)) : _end;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add break'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeField(
                label: 'Start',
                time: breakStart,
                onTap: () async {
                  final picked = await showTimePicker(context: dialogContext, initialTime: TimeOfDay.fromDateTime(breakStart));
                  if (picked != null) {
                    setDialogState(() => breakStart = DateTime(_start.year, _start.month, _start.day, picked.hour, picked.minute));
                  }
                },
              ),
              _TimeField(
                label: 'End',
                time: breakEnd,
                onTap: () async {
                  final picked = await showTimePicker(context: dialogContext, initialTime: TimeOfDay.fromDateTime(breakEnd));
                  if (picked != null) {
                    setDialogState(() => breakEnd = DateTime(_start.year, _start.month, _start.day, picked.hour, picked.minute));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            TextButton(
              onPressed: breakEnd.isAfter(breakStart) && !breakStart.isBefore(_start) && !breakEnd.isAfter(_end)
                  ? () {
                      ref.read(workSessionRepositoryProvider).addManualBreak(date: widget.session.date, start: breakStart, end: breakEnd);
                      Navigator.pop(dialogContext);
                    }
                  : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allBreaks = ref.watch(breaksForDateProvider(widget.session.date)).valueOrNull ?? const [];
    final manualBreaks = allBreaks
        .where((b) => b.type == BreakType.manual && !b.startTime.isBefore(_start) && !b.endTime.isAfter(_end))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, AppSpace.screenPadding, AppSpace.screenPadding, 28),
        decoration: BoxDecoration(color: colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit session', style: AppTextStyles.screenTitle.copyWith(color: colors.text)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _TimeField(label: 'Start', time: _start, onTap: () => _pickTime(isStart: true))),
                const SizedBox(width: 12),
                Expanded(child: _TimeField(label: 'End', time: _end, onTap: () => _pickTime(isStart: false))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('BREAKS', style: AppTextStyles.kickerSm.copyWith(color: colors.textMuted)),
                TextButton(onPressed: _addBreak, child: const Text('Add break')),
              ],
            ),
            if (manualBreaks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('No manual breaks', style: AppTextStyles.meta.copyWith(color: colors.textMuted)),
              ),
            for (final b in manualBreaks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${AppFormat.time(b.startTime)} – ${AppFormat.time(b.endTime)}', style: AppTextStyles.body.copyWith(color: colors.text)),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: colors.textMuted),
                      onPressed: () => ref.read(workSessionRepositoryProvider).deleteManualBreak(b.id),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(foregroundColor: colors.warningText, side: BorderSide(color: colors.warningText)),
                    child: const Text('Delete session'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: _save, child: const Text('Save'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final DateTime time;
  final VoidCallback onTap;

  const _TimeField({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: colors.divider), borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.meta.copyWith(color: colors.textMuted, fontSize: 11)),
            const SizedBox(height: 2),
            Text(AppFormat.time(time), style: AppTextStyles.body.copyWith(color: colors.text)),
          ],
        ),
      ),
    );
  }
}
