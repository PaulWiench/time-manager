/// The form field (additions handoff §3.6): a kicker label over a value, on a
/// `surface2` block that takes a focus ring while typing and the warning
/// treatment when invalid. Used for a vacation's name and a job's name.
library;

import 'package:flutter/material.dart' show InputDecoration, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.hint,
    this.error,
    this.autofocus = false,
    this.maxLength,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;

  /// Caption under the field, e.g. "Renames all 11 days".
  final String? hint;

  /// Replaces [hint] and turns the field to the warning treatment.
  final String? error;
  final bool autofocus;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final invalid = widget.error != null;
    final ink = invalid ? colors.warningText : colors.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _focus.requestFocus,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: invalid ? colors.warningTint : colors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _focus.hasFocus && !invalid ? colors.focus : const Color(0x00000000),
                width: AppStroke.focus,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label,
                    style: AppTextStyles.kicker
                        .copyWith(color: invalid ? colors.warningText : colors.textMuted)),
                const SizedBox(height: 2),
                TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  onChanged: widget.onChanged,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    if (widget.maxLength != null)
                      LengthLimitingTextInputFormatter(widget.maxLength),
                  ],
                  cursorColor: colors.text,
                  style: AppTextStyles.bodyLg.copyWith(color: ink),
                  decoration: InputDecoration.collapsed(
                    hintText: widget.placeholder,
                    hintStyle: AppTextStyles.bodyLg.copyWith(color: colors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.error != null || widget.hint != null) ...[
          const SizedBox(height: AppSpace.s1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
            child: Text(
              widget.error ?? widget.hint!,
              style: AppTextStyles.caption
                  .copyWith(color: invalid ? colors.warningText : colors.textMuted),
            ),
          ),
        ],
      ],
    );
  }
}
