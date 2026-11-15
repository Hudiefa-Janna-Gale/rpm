import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../design/tokens.dart';
import '../../../design/widgets/button.dart';
import '../../../design/widgets/fields.dart';
import '../domain/ledger.dart';

class RpmTransactionTable extends StatefulWidget {
  final List<LedgerEntry> entries;
  final Map<String, int>? balances;
  final Future<void> Function(LedgerEntry) onEdit, onDelete;
  const RpmTransactionTable({
    super.key,
    required this.entries,
    this.balances,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  State<RpmTransactionTable> createState() => _RpmTransactionTableState();
}

class _RpmTransactionTableState extends State<RpmTransactionTable> {
  final horizontal = ScrollController(), vertical = ScrollController();
  @override
  void dispose() {
    horizontal.dispose();
    vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = widget.balances != null;
    final p = context.rpm;
    double measure(String value) {
      final text = TextPainter(
        text: TextSpan(
          text: value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = text.width + 8;
      text.dispose();
      return width;
    }

    var amountWidth = ledger ? 72.0 : 112.0, balanceWidth = 84.0;
    for (final entry in widget.entries) {
      amountWidth = math.max(amountWidth, measure(Money.format(entry.amount)));
      if (widget.balances != null) {
        balanceWidth = math.max(
          balanceWidth,
          measure(Money.format(widget.balances![entry.id]!)),
        );
      }
    }
    final minimumWidth = ledger
        ? 520 + 2 * (amountWidth - 72) + (balanceWidth - 84)
        : 920 + (amountWidth - 112);
    return LayoutBuilder(
      builder: (context, c) => Scrollbar(
        controller: horizontal,
        notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
        child: SingleChildScrollView(
          controller: horizontal,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(c.maxWidth, minimumWidth),
            child: Column(
              children: [
                Container(
                  height: 48,
                  color: p.card,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TableLine(
                    ledger: ledger,
                    amountWidth: amountWidth,
                    balanceWidth: balanceWidth,
                    header: true,
                    values: ledger
                        ? ['DATE', 'DESCRIPTION', 'IN', 'OUT', 'BALANCE']
                        : [
                            'DATE',
                            'DESCRIPTION',
                            'CATEGORY',
                            'CURRENCY',
                            'TYPE',
                            'AMOUNT',
                          ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: RpmTokens.rowHeight * 6,
                  ),
                  child: Scrollbar(
                    controller: vertical,
                    child: SingleChildScrollView(
                      controller: vertical,
                      child: Column(
                        children: [
                          for (final e in widget.entries)
                            _TransactionRow(
                              entry: e,
                              amountWidth: amountWidth,
                              balanceWidth: balanceWidth,
                              balance: widget.balances?[e.id],
                              onEdit: () => widget.onEdit(e),
                              onDelete: () => widget.onDelete(e),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableLine extends StatelessWidget {
  final bool ledger, header;
  final List<String> values;
  final Widget? description, actions;
  final EntryKind? kind;
  final double amountWidth, balanceWidth;
  const _TableLine({
    required this.ledger,
    required this.header,
    required this.values,
    this.description,
    this.actions,
    this.kind,
    required this.amountWidth,
    required this.balanceWidth,
  });
  @override
  Widget build(BuildContext context) {
    final p = context.rpm;
    Widget cell(int index, {bool money = false}) => Align(
      alignment: money ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        values[index],
        maxLines: 1,
        overflow: money ? TextOverflow.visible : TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: header ? 11 : 12,
          fontWeight: header ? FontWeight.w500 : FontWeight.w400,
          color:
              !header &&
                  money &&
                  ((ledger && index == 2 && kind == EntryKind.cashIn) ||
                      (!ledger && kind == EntryKind.cashIn))
              ? p.success
              : !header &&
                    money &&
                    ((ledger && index == 3 && kind == EntryKind.cashOut) ||
                        (!ledger && kind == EntryKind.cashOut))
              ? p.danger
              : p.secondary,
          fontFeatures: money ? const [FontFeature.tabularFigures()] : null,
        ),
      ),
    );
    return Row(
      children: ledger
          ? [
              SizedBox(width: 78, child: cell(0)),
              Expanded(child: description ?? cell(1)),
              SizedBox(width: amountWidth, child: cell(2, money: true)),
              const SizedBox(width: 8),
              SizedBox(width: amountWidth, child: cell(3, money: true)),
              const SizedBox(width: 8),
              SizedBox(width: balanceWidth, child: cell(4, money: true)),
              const SizedBox(width: 8),
              SizedBox(width: 24, child: actions),
            ]
          : [
              SizedBox(width: 144, child: cell(0)),
              Expanded(child: description ?? cell(1)),
              const SizedBox(width: 16),
              SizedBox(width: 136, child: cell(2)),
              SizedBox(width: 96, child: cell(3)),
              SizedBox(width: 128, child: cell(4)),
              SizedBox(width: amountWidth, child: cell(5, money: true)),
              const SizedBox(width: 16),
              SizedBox(width: 40, child: actions),
            ],
    );
  }
}

class _TransactionRow extends StatefulWidget {
  final LedgerEntry entry;
  final int? balance;
  final VoidCallback onEdit, onDelete;
  final double amountWidth, balanceWidth;
  const _TransactionRow({
    required this.entry,
    this.balance,
    required this.onEdit,
    required this.onDelete,
    required this.amountWidth,
    required this.balanceWidth,
  });
  @override
  State<_TransactionRow> createState() => _TransactionRowState();
}

class _TransactionRowState extends State<_TransactionRow> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final p = context.rpm;
    final ledger = widget.balance != null;
    return AnimatedContainer(
      duration: RpmTokens.hoverDuration,
      height: RpmTokens.rowHeight,
      color: hovered ? p.hover : p.sidebar,
      child: InkWell(
        onTap: widget.onEdit,
        onHover: (v) => setState(() => hovered = v),
        focusColor: p.selected,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _TableLine(
            ledger: ledger,
            amountWidth: widget.amountWidth,
            balanceWidth: widget.balanceWidth,
            header: false,
            kind: e.kind,
            values: ledger
                ? [
                    DateFormat('dd MMM yy').format(parseDate(e.date)),
                    e.description,
                    e.kind == EntryKind.cashIn ? Money.format(e.amount) : '—',
                    e.kind == EntryKind.cashOut ? Money.format(e.amount) : '—',
                    Money.format(widget.balance!),
                  ]
                : [
                    DateFormat('dd MMM yyyy').format(parseDate(e.date)),
                    e.description,
                    e.category,
                    e.currency.code,
                    e.kind == EntryKind.cashIn ? 'Cash in' : 'Cash out',
                    Money.format(e.amount),
                  ],
            description: Tooltip(
              message: e.description,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: ledger ? p.text : p.secondary,
                    ),
                  ),
                  if (ledger) ...[
                    const SizedBox(height: 4),
                    Text(
                      e.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: p.secondary),
                    ),
                  ],
                ],
              ),
            ),
            actions: PopupMenuButton<String>(
              tooltip: 'Transaction actions',
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_horiz, size: 20, color: p.secondary),
              onSelected: (value) =>
                  value == 'edit' ? widget.onEdit() : widget.onDelete(),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit transaction'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete transaction',
                    style: TextStyle(color: p.danger),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RpmPagination extends StatelessWidget {
  final int page, pageSize, count;
  final ValueChanged<int> onPage;
  final ValueChanged<int>? onPageSize;
  const RpmPagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.count,
    required this.onPage,
    this.onPageSize,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: onPageSize == null ? 8 : 22,
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      spacing: 12,
      children: [
        Text(
          count == 0
              ? '0 transactions'
              : '${page * pageSize + 1}–${math.min((page + 1) * pageSize, count)} of $count ${count == 1 ? 'transaction' : 'transactions'}',
          style: TextStyle(fontSize: 12, color: context.rpm.secondary),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPageSize != null) ...[
              Text(
                'Rows per page',
                style: TextStyle(fontSize: 12, color: context.rpm.secondary),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 80,
                child: RpmSelect<int>(
                  value: pageSize,
                  options: const {10: '10', 25: '25', 50: '50'},
                  borderless: true,
                  onChanged: onPageSize,
                ),
              ),
            ] else
              Text(
                'Oldest first',
                style: TextStyle(fontSize: 12, color: context.rpm.secondary),
              ),
            RpmButton(
              icon: Icons.chevron_left,
              tooltip: 'Previous page',
              variant: RpmButtonVariant.ghost,
              onPressed: page > 0 ? () => onPage(page - 1) : null,
            ),
            RpmButton(
              icon: Icons.chevron_right,
              tooltip: 'Next page',
              variant: RpmButtonVariant.ghost,
              onPressed: (page + 1) * pageSize < count
                  ? () => onPage(page + 1)
                  : null,
            ),
          ],
        ),
      ],
    ),
  );
}
