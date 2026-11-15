import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/button.dart';
import '../../../design/widgets/fields.dart';
import '../../../design/widgets/surfaces.dart';
import '../domain/ledger.dart';

String friendlyError(Object error) {
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message;
  return 'The operation could not be completed. Check file permissions, available disk space, and whether the file is open in another application. Your existing records have been kept.';
}

void notify(
  BuildContext context,
  String message, {
  bool error = false,
  String? title,
}) {
  final p = context.rpm;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      width: math.min(560, MediaQuery.sizeOf(context).width - 48),
      backgroundColor: p.card,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 7),
      showCloseIcon: true,
      closeIconColor: p.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.warning_amber_rounded : Icons.check,
            size: 18,
            color: error ? p.danger : p.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ??
                      (error ? 'Could not complete action' : 'Saved locally'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: error ? p.danger : p.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: p.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Confirm',
  String? typedWord,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _Confirmation(
        title: title,
        message: message,
        confirm: confirm,
        typedWord: typedWord,
      ),
    ) ??
    false;

class _Confirmation extends StatefulWidget {
  final String title, message, confirm;
  final String? typedWord;
  const _Confirmation({
    required this.title,
    required this.message,
    required this.confirm,
    this.typedWord,
  });
  @override
  State<_Confirmation> createState() => _ConfirmationState();
}

class _ConfirmationState extends State<_Confirmation> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destructive =
        widget.typedWord != null ||
        widget.confirm.toLowerCase().contains('delete') ||
        widget.confirm.toLowerCase().contains('reset');
    return RpmDialogFrame(
      title: widget.title,
      actions: [
        RpmButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        RpmButton(
          label: widget.confirm,
          variant: destructive
              ? RpmButtonVariant.danger
              : RpmButtonVariant.primary,
          onPressed:
              widget.typedWord == null || controller.text == widget.typedWord
              ? () => Navigator.pop(context, true)
              : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message,
            style: TextStyle(
              fontSize: 13,
              height: 1.65,
              color: context.rpm.secondary,
            ),
          ),
          if (destructive) ...[
            const SizedBox(height: 20),
            Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: context.rpm.danger),
            ),
          ],
          if (widget.typedWord != null) ...[
            const SizedBox(height: 20),
            RpmInput(
              key: const Key('reset-confirmation'),
              controller: controller,
              label: 'Type ${widget.typedWord} to continue.',
              hint: widget.typedWord,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showEntryEditor(
  BuildContext context, {
  LedgerEntry? entry,
  Currency? currency,
  List<String> categories = const ['General'],
  required Future<void> Function(LedgerEntry) onSave,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _EntryEditor(
    entry: entry,
    currency: currency,
    categories: categories,
    onSave: onSave,
  ),
);

class _EntryEditor extends StatefulWidget {
  final LedgerEntry? entry;
  final Currency? currency;
  final List<String> categories;
  final Future<void> Function(LedgerEntry) onSave;
  const _EntryEditor({
    this.entry,
    this.currency,
    required this.categories,
    required this.onSave,
  });
  @override
  State<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<_EntryEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController amount, category, description;
  late Currency currency;
  late EntryKind kind;
  late DateTime date;
  late final Set<String> categoryOptions;
  int categoryRevision = 0;
  bool saving = false;
  String? error;
  late final String id = widget.entry?.id ?? const Uuid().v4();
  late final String createdAt =
      widget.entry?.createdAt ?? DateTime.now().toUtc().toIso8601String();
  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    currency = e?.currency ?? widget.currency ?? Currency.mwk;
    kind = e?.kind ?? EntryKind.cashIn;
    date = e == null ? DateTime.now() : parseDate(e.date);
    amount = TextEditingController(
      text: e == null ? '' : Money.input(e.amount),
    );
    category = TextEditingController(text: e?.category ?? 'General');
    description = TextEditingController(text: e?.description ?? '');
    categoryOptions = {'General', ...widget.categories, category.text};
    amount.addListener(changed);
    description.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    amount.dispose();
    category.dispose();
    description.dispose();
    super.dispose();
  }

  bool get canSave {
    try {
      Money.parse(amount.text);
      return category.text.trim().isNotEmpty &&
          description.text.trim().isNotEmpty;
    } on FormatException {
      return false;
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    if (widget.entry != null) {
      final confirmed = await confirmAction(
        context,
        title: 'Save changes to this transaction?',
        message:
            'The existing ${widget.entry!.currency.code} transaction will be replaced with your changes and all later running balances will be recalculated. We recommend creating a JSON backup before editing financial records.',
        confirm: 'Save changes',
      );
      if (!confirmed || !mounted) return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSave(
        LedgerEntry(
          id: id,
          currency: currency,
          kind: kind,
          amount: Money.parse(amount.text),
          date: dateKey(date),
          category: category.text.trim(),
          description: description.text.trim(),
          createdAt: createdAt,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = friendlyError(e);
          saving = false;
        });
      }
    }
  }

  Future<void> chooseCategory(String value) async {
    if (value != '\u0000new') {
      setState(() => category.text = value);
      return;
    }
    final newValue = await showDialog<String>(
      context: context,
      builder: (_) => const _CategoryNameDialog(),
    );
    if (mounted) {
      setState(() {
        categoryRevision++;
        if (newValue != null) { categoryOptions.add(newValue); category.text = newValue; }
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: RpmDialogFrame(
      title: widget.entry == null ? 'New transaction' : 'Edit transaction',
      subtitle: 'Record a receipt or payment.',
      onClose: saving ? null : () => Navigator.pop(context),
      actions: [
        RpmButton(
          label: 'Cancel',
          onPressed: saving ? null : () => Navigator.pop(context),
        ),
        RpmButton(
          label: widget.entry == null ? 'Save transaction' : 'Save changes',
          variant: RpmButtonVariant.primary,
          loading: saving,
          onPressed: saving || !canSave ? null : save,
        ),
      ],
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final fields = [
                  RpmSelect<Currency>(
                    label: 'Currency *',
                    value: currency,
                    options: {
                      for (final c in Currency.values)
                        c: '${c.code} · ${c.title}',
                    },
                    onChanged: saving || widget.entry != null
                        ? null
                        : (v) => setState(() => currency = v),
                  ),
                  RpmSelect<EntryKind>(
                    label: 'Type *',
                    value: kind,
                    options: const {
                      EntryKind.cashIn: 'Cash in · Receipt',
                      EntryKind.cashOut: 'Cash out · Payment',
                    },
                    onChanged: saving ? null : (v) => setState(() => kind = v),
                  ),
                ];
                return c.maxWidth >= 440
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: fields[0]),
                          const SizedBox(width: 16),
                          Expanded(child: fields[1]),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          fields[0],
                          const SizedBox(height: 20),
                          fields[1],
                        ],
                      );
              },
            ),
            const SizedBox(height: 24),
            RpmInput(
              key: const Key('entry-amount'),
              controller: amount,
              label: 'Amount *',
              hint: '0.00',
              enabled: !saving,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                try {
                  Money.parse(value ?? '');
                  return null;
                } on FormatException catch (e) {
                  return e.message;
                }
              },
            ),
            const SizedBox(height: 24),
            RpmSelect<String>(
              key: ValueKey(categoryRevision),
              label: 'Category *',
              value: category.text,
              options: {
                for (final v in categoryOptions) v: v,
                '\u0000new': 'Add category…',
              },
              onChanged: saving ? null : chooseCategory,
            ),
            const SizedBox(height: 24),
            RpmInput(
              key: const Key('entry-description'),
              controller: description,
              label: 'Description',
              hint: kind == EntryKind.cashOut
                  ? 'What was this payment for?'
                  : 'What was this receipt for?',
              enabled: !saving,
              maxLength: 500,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a description.' : null,
            ),
            const SizedBox(height: 24),
            RpmFieldLabel(
              label: 'Date *',
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: double.infinity,
                  child: RpmButton(
                    label: DateFormat('dd MMM yyyy').format(date),
                    alignStart: true,
                    width: double.infinity,
                    trailingIcon: Icons.arrow_drop_down,
                    onPressed: saving
                        ? null
                        : () async {
                            final value = await showRpmDatePicker(
                              context,
                              date,
                            );
                            if (value != null && mounted) {
                              setState(() => date = value);
                            }
                          },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              canSave
                  ? 'This transaction will be saved to the ${currency.code} ledger.'
                  : 'Enter an amount greater than 0 and a description to save to the ${currency.code} ledger.',
              style: TextStyle(fontSize: 12, color: context.rpm.secondary),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              RpmBanner(message: error!, error: true),
            ],
          ],
        ),
      ),
    ),
  );
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog();
  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  final name = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RpmDialogFrame(
    title: 'Add category',
    subtitle: 'The category is saved with this transaction.',
    actions: [
      RpmButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
      RpmButton(
        label: 'Use category',
        variant: RpmButtonVariant.primary,
        onPressed: name.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, name.text.trim()),
      ),
    ],
    child: RpmInput(
      controller: name,
      label: 'Category name',
      maxLength: 80,
      autofocus: true,
      onChanged: (_) => setState(() {}),
    ),
  );
}

Future<void> showOpeningEditor(
  BuildContext context,
  Currency currency,
  int opening,
  Future<void> Function(int) onSave,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      _OpeningEditor(currency: currency, opening: opening, onSave: onSave),
);

class _OpeningEditor extends StatefulWidget {
  final Currency currency;
  final int opening;
  final Future<void> Function(int) onSave;
  const _OpeningEditor({
    required this.currency,
    required this.opening,
    required this.onSave,
  });
  @override
  State<_OpeningEditor> createState() => _OpeningEditorState();
}

class _OpeningEditorState extends State<_OpeningEditor> {
  late final controller = TextEditingController(
    text: Money.input(widget.opening),
  );
  bool busy = false;
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    int value;
    try {
      value = Money.parse(controller.text, signed: true);
    } on FormatException catch (e) {
      setState(() => error = e.message);
      return;
    }
    if (value == widget.opening) {
      Navigator.pop(context);
      return;
    }
    if (!await confirmAction(
          context,
          title: 'Change ${widget.currency.code} opening balance?',
          message:
              'The opening balance will change from ${Money.format(widget.opening)} to ${Money.format(value)} ${widget.currency.code}. All running balances in this ledger will be recalculated. We recommend a JSON backup before making this change.',
          confirm: 'Change balance',
        ) ||
        !mounted) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onSave(value);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: RpmDialogFrame(
      title: '${widget.currency.code} opening balance',
      subtitle:
          'Cash held before the first recorded transaction. Negative opening balances are supported.',
      actions: [
        RpmButton(
          label: 'Cancel',
          onPressed: busy ? null : () => Navigator.pop(context),
        ),
        RpmButton(
          label: 'Update balance',
          variant: RpmButtonVariant.primary,
          loading: busy,
          onPressed: busy ? null : save,
        ),
      ],
      child: RpmInput(
        controller: controller,
        label: 'Opening balance (${widget.currency.code})',
        errorText: error,
        autofocus: true,
        enabled: !busy,
        onSubmitted: busy ? null : (_) => save(),
      ),
    ),
  );
}
