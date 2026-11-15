import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../tokens.dart';
import 'button.dart';

class RpmFieldLabel extends StatelessWidget {
  final String label;
  final Widget child;
  const RpmFieldLabel({super.key, required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: context.rpm.text,
        ),
      ),
      const SizedBox(height: 12),
      child,
    ],
  );
}

class RpmInput extends StatelessWidget {
  final TextEditingController controller;
  final String? label, hint, errorText;
  final String? Function(String?)? validator;
  final bool enabled, autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged, onSubmitted;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  const RpmInput({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
  });
  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(fontSize: 14, color: context.rpm.text, height: 1.2),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        counterText: '',
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 20, color: context.rpm.secondary),
        suffixIcon: suffix,
        constraints: maxLines == 1 ? const BoxConstraints(minHeight: 40) : null,
      ),
    );
    return label == null ? field : RpmFieldLabel(label: label!, child: field);
  }
}

class RpmSelect<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T>? onChanged;
  final String? label;
  final bool borderless;
  const RpmSelect({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label,
    this.borderless = false,
  });
  @override
  Widget build(BuildContext context) {
    final p = context.rpm;
    final field = SizedBox(
      height: 40,
      child: DropdownButtonFormField<T>(
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        dropdownColor: p.card,
        borderRadius: BorderRadius.circular(8),
        menuMaxHeight: 320,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: label == null ? 13 : 14,
          height: 1.2,
          color: p.secondary,
        ),
        icon: Icon(Icons.arrow_drop_down, size: 18, color: p.secondary),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          filled: !borderless,
          enabledBorder: borderless
              ? const OutlineInputBorder(borderSide: BorderSide.none)
              : null,
        ),
        selectedItemBuilder: (_) => options.entries
            .map(
              (e) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  e.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        items: options.entries
            .map(
              (e) => DropdownMenuItem<T>(
                value: e.key,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.value, overflow: TextOverflow.ellipsis),
                    ),
                    if (e.key == value)
                      Icon(Icons.check, color: p.accent, size: 16),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: onChanged == null
            ? null
            : (v) {
                if (v != null) onChanged!(v);
              },
      ),
    );
    return label == null ? field : RpmFieldLabel(label: label!, child: field);
  }
}

Future<DateTime?> showRpmDatePicker(
  BuildContext context,
  DateTime selected,
) => showDialog<DateTime>(
  context: context,
  builder: (context) => Dialog(
    child: SizedBox(
      width: 336,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CalendarDatePicker(
            initialDate: selected,
            firstDate: DateTime(1900),
            lastDate: DateTime(2200, 12, 31),
            onDateChanged: (date) => Navigator.pop(context, date),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected: ${DateFormat('dd MMM yyyy').format(selected)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                RpmButton(
                  label: 'Cancel',
                  variant: RpmButtonVariant.ghost,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
