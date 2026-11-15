import 'package:flutter/material.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/button.dart';
import '../../../design/widgets/surfaces.dart';
import '../domain/ledger.dart';
import 'transaction_table.dart';

class LedgerPanel extends StatefulWidget {
  final Currency currency;
  final LedgerSnapshot snapshot;
  final List<LedgerEntry> entries;
  final String filterKey;
  final VoidCallback onAdd, onOpening;
  final Future<void> Function(LedgerEntry) onEdit, onDelete;
  const LedgerPanel({
    super.key,
    required this.currency,
    required this.snapshot,
    required this.entries,
    required this.filterKey,
    required this.onAdd,
    required this.onOpening,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  State<LedgerPanel> createState() => _LedgerPanelState();
}

class _LedgerPanelState extends State<LedgerPanel> {
  int page = 0;
  static const pageSize = 10;
  @override
  void didUpdateWidget(covariant LedgerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterKey != oldWidget.filterKey ||
        page * pageSize >= widget.entries.length) {
      page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rpm;
    final c = widget.currency;
    final summary = widget.snapshot.summary(c);
    final visible = widget.entries
        .skip(page * pageSize)
        .take(pageSize)
        .toList();
    final exists = widget.snapshot.entries.any((e) => e.currency == c);
    return RpmSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: p.card,
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c.code} Ledger',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.title,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: p.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RpmButton(
                      icon: Icons.add,
                      tooltip: 'Add ${c.code} transaction',
                      variant: RpmButtonVariant.ghost,
                      onPressed: widget.onAdd,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'CLOSING BALANCE',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: p.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Money.format(summary.closing),
                          style: RpmTokens.moneyStyle.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: c == Currency.usd ? p.success : p.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      c.code,
                      style: TextStyle(color: p.accent, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Opening balance',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: p.secondary,
                    ),
                  ),
                ),
                Text(
                  Money.format(summary.opening),
                  style: RpmTokens.moneyStyle.copyWith(fontSize: 13),
                ),
                RpmButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit ${c.code} opening balance',
                  variant: RpmButtonVariant.ghost,
                  onPressed: widget.onOpening,
                ),
              ],
            ),
          ),
          if (visible.isEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 172),
              child: RpmEmptyState(
                title: exists
                    ? 'No matching transactions'
                    : 'A fresh start for ${c.code}',
                message: exists
                    ? 'Clear search or filters to see your records.'
                    : 'Add your first receipt or payment to begin.',
                actionLabel: 'Add transaction',
                onAction: exists ? null : widget.onAdd,
              ),
            )
          else ...[
            RpmTransactionTable(
              entries: visible,
              balances: widget.snapshot.runningBalances(c),
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
            ),
            RpmPagination(
              page: page,
              pageSize: pageSize,
              count: widget.entries.length,
              onPage: (value) => setState(() => page = value),
            ),
          ],
        ],
      ),
    );
  }
}
