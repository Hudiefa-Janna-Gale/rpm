import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../app/identity.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/button.dart';
import '../../../design/widgets/fields.dart';
import '../../../design/widgets/sidebar.dart';
import '../../../design/widgets/surfaces.dart';
import '../domain/ledger.dart';
import 'desktop_actions.dart';
import 'dialogs.dart';
import 'ledger_panel.dart';
import 'transaction_table.dart';

class DesktopScreen extends ConsumerStatefulWidget {
  final Future<void> Function() onRecover;
  final Future<void> Function()? onRefreshStorage;
  const DesktopScreen({
    super.key,
    required this.onRecover,
    this.onRefreshStorage,
  });
  @override
  ConsumerState<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends ConsumerState<DesktopScreen> {
  final search = TextEditingController();
  final searchFocus = FocusNode();
  late final DesktopActions actions;
  RpmDestination destination = RpmDestination.overview;
  bool? collapsed;
  bool refreshing = false;
  String category = '', currency = '', kind = '';
  bool newest = true;
  DateTimeRange? range;
  int page = 0, pageSize = 10;
  @override
  void initState() {
    super.initState();
    actions = DesktopActions(ref, () => context);
  }

  @override
  void dispose() {
    actions.dispose();
    search.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  void select(RpmDestination value) {
    setState(() {
      destination = value;
      page = 0;
    });
  }

  void changeFilters(VoidCallback update) {
    setState(() {
      update();
      page = 0;
    });
  }

  void clearFilters() => changeFilters(() {
    search.clear();
    category = '';
    currency = '';
    kind = '';
    range = null;
  });
  Future<void> reloadData() async {
    if (refreshing || actions.busy) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => refreshing = true);
    try {
      if (widget.onRefreshStorage != null &&
          !await ref.read(storageProvider).databaseFile.exists()) {
        await widget.onRefreshStorage!();
        return;
      }
      ref.invalidate(ledgerProvider);
      await ref.read(ledgerProvider.future);
      if (mounted) {
        notify(
          context,
          'Saved records and balances have been reloaded.',
          title: 'Data refreshed',
        );
      }
    } catch (error) {
      if (mounted) notify(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> pickRange() async {
    final value = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      initialDateRange: range,
      builder: (context, child) =>
          Center(child: SizedBox(width: 600, height: 620, child: child)),
    );
    if (mounted && value != null) changeFilters(() => range = value);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ledgerProvider);
    final mac = Platform.isMacOS;
    return ListenableBuilder(
      listenable: actions,
      builder: (context, _) => CallbackShortcuts(
        bindings: {
          SingleActivator(LogicalKeyboardKey.keyR, meta: mac, control: !mac):
              reloadData,
          const SingleActivator(LogicalKeyboardKey.f5): reloadData,
          SingleActivator(
            LogicalKeyboardKey.keyN,
            meta: mac,
            control: !mac,
          ): () {
            if (!actions.busy) actions.add();
          },
          SingleActivator(
            LogicalKeyboardKey.keyF,
            meta: mac,
            control: !mac,
          ): () {
            if (!actions.busy) {
              if (destination != RpmDestination.overview &&
                  destination != RpmDestination.transactions) {
                select(RpmDestination.transactions);
              }
              searchFocus.requestFocus();
            }
          },
          SingleActivator(
            LogicalKeyboardKey.keyB,
            meta: mac,
            control: !mac,
          ): () {
            if (!actions.busy) actions.backup();
          },
          SingleActivator(
            LogicalKeyboardKey.keyE,
            meta: mac,
            control: !mac,
          ): () {
            if (!actions.busy) actions.exportCsv();
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final compact = collapsed ?? constraints.maxWidth < 1100;
                return Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RpmSidebar(
                          selected: destination,
                          collapsed: compact,
                          onSelected: select,
                          onToggle: () => setState(() => collapsed = !compact),
                        ),
                        Expanded(
                          child: data.when(
                            loading: () => const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text('Loading transactions…'),
                                  SizedBox(height: 8),
                                  Text('Reading local records.'),
                                ],
                              ),
                            ),
                            error: (error, _) => Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 540,
                                ),
                                child: RpmSurface(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Could not load transactions',
                                        style: TextStyle(
                                          color: context.rpm.danger,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(friendlyError(error)),
                                      const SizedBox(height: 20),
                                      Wrap(
                                        spacing: 12,
                                        children: [
                                          RpmButton(
                                            label: 'Try again',
                                            onPressed: reloadData,
                                          ),
                                          RpmButton(
                                            label: 'Open recovery',
                                            variant: RpmButtonVariant.primary,
                                            onPressed: widget.onRecover,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            data: (snapshot) => SingleChildScrollView(
                              key: const Key('workspace-scroll'),
                              padding: EdgeInsets.all(
                                RpmTokens.pageInset(constraints.maxWidth),
                              ),
                              child: _page(snapshot),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (actions.busy)
                      Positioned.fill(
                        child: AbsorbPointer(
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: .28),
                            child: Center(
                              child: RpmSurface(
                                filled: true,
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.rpm.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text('Working with local files…'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<LedgerEntry> filtered(
    LedgerSnapshot data, {
    bool management = false,
    Currency? ledger,
  }) {
    final query = search.text.trim().toLowerCase();
    final result = data.entries
        .where(
          (e) =>
              (ledger == null || e.currency == ledger) &&
              (query.isEmpty ||
                  '${e.description} ${e.category} ${Money.input(e.amount)} ${e.date} ${e.currency.code}'
                      .toLowerCase()
                      .contains(query)) &&
              (category.isEmpty || e.category == category) &&
              (!management ||
                  currency.isEmpty ||
                  e.currency.code == currency) &&
              (!management || kind.isEmpty || e.kind.name == kind) &&
              (range == null ||
                  (e.date.compareTo(dateKey(range!.start)) >= 0 &&
                      e.date.compareTo(dateKey(range!.end)) <= 0)),
        )
        .toList();
    return management && newest ? result.reversed.toList() : result;
  }

  List<Widget> headerActions({bool backup = false, Currency? ledger}) => [
    RpmButton(label: 'Export CSV', onPressed: actions.exportCsv),
    if (backup) RpmButton(label: 'Backup', onPressed: actions.backup),
    RpmButton(
      label: 'New transaction',
      icon: Icons.add,
      variant: RpmButtonVariant.primary,
      onPressed: () => actions.add(currency: ledger),
    ),
  ];
  Widget _page(LedgerSnapshot snapshot) => switch (destination) {
    RpmDestination.overview => overview(snapshot),
    RpmDestination.transactions => transactions(snapshot),
    RpmDestination.mwk => overview(snapshot, ledger: Currency.mwk),
    RpmDestination.usd => overview(snapshot, ledger: Currency.usd),
    RpmDestination.settings => settings(snapshot),
    RpmDestination.backup => settings(snapshot, backupOnly: true),
    RpmDestination.categories => categories(snapshot),
    RpmDestination.reports => reports(snapshot),
  };
  Widget overview(LedgerSnapshot snapshot, {Currency? ledger}) {
    final entries = filtered(snapshot, ledger: ledger);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RpmPageHeader(
          onRefresh: reloadData,
          refreshing: refreshing,
          title: ledger == null
              ? 'Financial overview'
              : '${ledger.code} Ledger',
          subtitle: ledger == null
              ? 'A clear view of every receipt and payment.'
              : '${ledger.title} · Every receipt and payment in chronological order.',
          actions: headerActions(backup: ledger == null, ledger: ledger),
        ),
        const SizedBox(height: 24),
        if (ledger == null) ...[
          summaryCards(snapshot),
          const SizedBox(height: 28),
        ],
        Row(
          children: [
            Text(
              'Currency ledgers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            Text(
              '${snapshot.entries.length} ${snapshot.entries.length == 1 ? 'record' : 'records'} · All time',
              style: TextStyle(color: context.rpm.secondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 24),
        filters(snapshot),
        const SizedBox(height: 24),
        if (search.text.isNotEmpty || category.isNotEmpty || range != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Showing ${entries.length} matching records. Summaries and running balances include the complete ledgers.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        LayoutBuilder(
          builder: (context, c) => ledger != null
              ? ledgerPanel(ledger, snapshot, entries)
              : c.maxWidth >= 940
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ledgerPanel(Currency.mwk, snapshot, entries),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ledgerPanel(Currency.usd, snapshot, entries),
                    ),
                  ],
                )
              : Column(
                  children: [
                    ledgerPanel(Currency.mwk, snapshot, entries),
                    const SizedBox(height: 20),
                    ledgerPanel(Currency.usd, snapshot, entries),
                  ],
                ),
        ),
        for (final c in Currency.values.where(
          (c) =>
              (ledger == null || ledger == c) &&
              snapshot.summary(c).closing < 0,
        )) ...[
          const SizedBox(height: 24),
          RpmBanner(
            message:
                '${c.code} closing balance is below zero. Review receipts, payments and opening balance.',
          ),
        ],
      ],
    );
  }

  Widget ledgerPanel(
    Currency c,
    LedgerSnapshot snapshot,
    List<LedgerEntry> entries,
  ) => LedgerPanel(
    currency: c,
    snapshot: snapshot,
    entries: entries.where((e) => e.currency == c).toList(),
    filterKey: '${search.text}|$category|$range',
    onAdd: () => actions.add(currency: c),
    onOpening: () => actions.opening(c, snapshot.openings[c]!),
    onEdit: (entry) => actions.add(entry: entry),
    onDelete: actions.delete,
  );
  Widget summaryCards(LedgerSnapshot snapshot) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 900 ? 4 : 2;
      final width = (c.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: width,
            child: FinancialSummaryCard(
              title: 'Total cash in',
              helper: 'Receipts across both ledgers',
              snapshot: snapshot,
              value: (s) => s.cashIn,
            ),
          ),
          SizedBox(
            width: width,
            child: FinancialSummaryCard(
              title: 'Total cash out',
              helper: 'Payments across both ledgers',
              snapshot: snapshot,
              value: (s) => s.cashOut,
            ),
          ),
          SizedBox(
            width: width,
            child: FinancialSummaryCard(
              title: 'Net movement',
              helper: 'Cash in minus cash out',
              snapshot: snapshot,
              value: (s) => s.net,
            ),
          ),
          SizedBox(
            width: width,
            child: FinancialSummaryCard(
              title: 'Closing cash balance',
              helper: 'Opening + net movement',
              snapshot: snapshot,
              value: (s) => s.closing,
              highlighted: true,
            ),
          ),
        ],
      );
    },
  );
  Widget filters(LedgerSnapshot snapshot, {bool management = false}) {
    final names = snapshot.entries.map((e) => e.category).toSet().toList()
      ..sort();
    final active = names.contains(category) ? category : '';
    return LayoutBuilder(
      builder: (context, c) {
        final controls = [
          SizedBox(
            width: 144,
            child: RpmSelect<String>(
              value: active,
              options: {
                '': 'All categories',
                for (final name in names) name: name,
              },
              onChanged: (v) => changeFilters(() => category = v),
            ),
          ),
          SizedBox(
            width: range == null ? 120 : 250,
            child: RpmButton(
              label: range == null
                  ? 'All dates'
                  : '${dateKey(range!.start)} — ${dateKey(range!.end)}',
              trailingIcon: Icons.arrow_drop_down,
              onPressed: pickRange,
            ),
          ),
        ];
        final searchBox = RpmInput(
          key: const Key('transaction-search'),
          controller: search,
          focusNode: searchFocus,
          hint: management
              ? 'Search description or category…'
              : 'Search transactions…',
          prefixIcon: Icons.search,
          suffix: search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () => changeFilters(search.clear),
                  icon: const Icon(Icons.close, size: 16),
                ),
          onChanged: (_) => changeFilters(() {}),
        );
        final currencyBox = SizedBox(
          width: 144,
          child: RpmSelect<String>(
            value: currency,
            options: const {'': 'All currencies', 'MWK': 'MWK', 'USD': 'USD'},
            onChanged: (v) => changeFilters(() => currency = v),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.maxWidth >= (management ? 900 : (range == null ? 700 : 760)))
              Row(
                children: [
                  if (management)
                    Expanded(child: searchBox)
                  else
                    SizedBox(width: 300, child: searchBox),
                  const SizedBox(width: 12),
                  if (management) ...[currencyBox, const SizedBox(width: 12)],
                  ...controls.expand((w) => [w, const SizedBox(width: 12)]),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchBox,
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [if (management) currencyBox, ...controls],
                  ),
                ],
              ),
            if (search.text.isNotEmpty ||
                active.isNotEmpty ||
                range != null ||
                (management && (currency.isNotEmpty || kind.isNotEmpty)))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: RpmButton(
                  label: 'Clear filters',
                  icon: Icons.close,
                  variant: RpmButtonVariant.ghost,
                  onPressed: clearFilters,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget transactions(LedgerSnapshot snapshot) {
    final entries = filtered(snapshot, management: true);
    final currentPage = entries.isEmpty
        ? 0
        : page.clamp(0, (entries.length - 1) ~/ pageSize);
    final visible = entries
        .skip(currentPage * pageSize)
        .take(pageSize)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RpmPageHeader(
          onRefresh: reloadData,
          refreshing: refreshing,
          title: 'Transactions',
          subtitle: 'Every receipt and payment, in one place.',
          actions: headerActions(),
        ),
        const SizedBox(height: 24),
        RpmSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Column(
                  children: [
                    filters(snapshot, management: true),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Text(
                            '${entries.length} ${entries.length == 1 ? 'transaction' : 'transactions'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 128,
                                child: RpmSelect<String>(
                                  value: kind,
                                  options: const {
                                    '': 'All types',
                                    'cashIn': 'Cash in',
                                    'cashOut': 'Cash out',
                                  },
                                  borderless: true,
                                  onChanged: (v) =>
                                      changeFilters(() => kind = v),
                                ),
                              ),
                              SizedBox(
                                width: 144,
                                child: RpmSelect<bool>(
                                  value: newest,
                                  options: const {
                                    true: 'Newest first',
                                    false: 'Oldest first',
                                  },
                                  borderless: true,
                                  onChanged: (v) =>
                                      changeFilters(() => newest = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (visible.isEmpty)
                SizedBox(
                  height: 180,
                  child: RpmEmptyState(
                    title: snapshot.entries.isEmpty
                        ? 'No transactions yet'
                        : 'No matching transactions',
                    message: snapshot.entries.isEmpty
                        ? 'Add your first receipt or payment to begin.'
                        : 'Clear search or filters to see your records.',
                    onAction: snapshot.entries.isEmpty
                        ? () => actions.add()
                        : clearFilters,
                    actionLabel: snapshot.entries.isEmpty
                        ? 'Add transaction'
                        : 'Clear filters',
                  ),
                )
              else
                RpmTransactionTable(
                  entries: visible,
                  onEdit: (e) => actions.add(entry: e),
                  onDelete: actions.delete,
                ),
              Divider(height: 1, color: context.rpm.border),
              RpmPagination(
                page: currentPage,
                pageSize: pageSize,
                count: entries.length,
                onPage: (v) => setState(() => page = v),
                onPageSize: (v) => setState(() {
                  pageSize = v;
                  page = 0;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        currencySummaries(snapshot),
        const SizedBox(height: 32),
        Text(
          'Amounts remain in their original currency. MWK and USD are never added together.',
          style: TextStyle(fontSize: 12, color: context.rpm.secondary),
        ),
      ],
    );
  }

  Widget currencySummaries(LedgerSnapshot snapshot) => LayoutBuilder(
    builder: (context, c) {
      final cards = [
        for (final currency in Currency.values)
          RpmSurface(
            filled: true,
            outlined: false,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currency.code} ledger',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    color: context.rpm.accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cash in  ${Money.format(snapshot.summary(currency).cashIn)}     /     Cash out  ${Money.format(snapshot.summary(currency).cashOut)}',
                  style: RpmTokens.moneyStyle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Text(
                  '${snapshot.entries.where((e) => e.currency == currency).length} transactions · Closing balance ${Money.format(snapshot.summary(currency).closing)}',
                  style: TextStyle(fontSize: 12, color: context.rpm.secondary),
                ),
              ],
            ),
          ),
      ];
      return c.maxWidth >= 850
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 20),
                Expanded(child: cards[1]),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [cards[0], const SizedBox(height: 16), cards[1]],
            );
    },
  );
  Widget settings(LedgerSnapshot snapshot, {bool backupOnly = false}) {
    final p = context.rpm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RpmPageHeader(
          onRefresh: reloadData,
          refreshing: refreshing,
          title: backupOnly ? 'Backup & Restore' : 'Settings',
          subtitle:
              'Your data stays on this device. Keep a backup before making changes.',
          actions: backupOnly
              ? []
              : [
                  RpmButton(
                    icon: Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    tooltip: 'Change appearance',
                    variant: RpmButtonVariant.ghost,
                    onPressed: () => ref
                        .read(themeProvider.notifier)
                        .toggle(
                          Theme.of(context).brightness == Brightness.dark,
                        ),
                  ),
                ],
        ),
        const SizedBox(height: 24),
        RpmSurface(
          filled: true,
          outlined: false,
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local storage',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.entries.length} ${snapshot.entries.length == 1 ? 'transaction' : 'transactions'} · 2 currency ledgers · Available offline',
                      style: TextStyle(fontSize: 14, color: p.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '●  Local only',
                style: TextStyle(fontSize: 14, color: p.success),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        RpmSurface(
          child: Column(
            children: [
              settingsRow(
                'Backup data',
                'Save receipts, payments, categories and opening balances to a backup.',
                'Create backup',
                actions.backup,
              ),
              Divider(height: 1, color: p.border),
              settingsRow(
                'Restore backup',
                'Replace current local data from a previously saved RPM backup.',
                'Restore backup',
                actions.restore,
              ),
              Divider(height: 1, color: p.border),
              settingsRow(
                'Export transactions',
                'Export transaction records as CSV. This is not a full backup.',
                'Export CSV',
                actions.exportCsv,
              ),
            ],
          ),
        ),
        if (!backupOnly) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: p.dangerSurface,
              borderRadius: BorderRadius.circular(12),
            ),
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
                            'Reset local data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: p.danger,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Permanently remove RPM data from this device.',
                            style: TextStyle(fontSize: 14, color: p.secondary),
                          ),
                        ],
                      ),
                    ),
                    RpmButton(
                      label: 'Reset data',
                      variant: RpmButtonVariant.danger,
                      onPressed: actions.reset,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'This cannot be undone. Create a backup before continuing.',
                  style: TextStyle(fontSize: 12, color: p.danger),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Backup and restore use local files. No account or cloud connection is required.',
          style: TextStyle(fontSize: 12, color: p.secondary),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: RpmButton(
            label: 'Storage location & keyboard shortcuts',
            icon: Icons.info_outline,
            variant: RpmButtonVariant.ghost,
            onPressed: () => actions.guarded(actions.dataInfo),
          ),
        ),
        const SizedBox(height: 24),
        Text(rpmCopyright, style: TextStyle(fontSize: 12, color: p.secondary)),
      ],
    );
  }

  Widget settingsRow(
    String title,
    String message,
    String label,
    VoidCallback action,
  ) => Padding(
    padding: const EdgeInsets.all(24),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: context.rpm.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        RpmButton(label: label, onPressed: action),
      ],
    ),
  );
  Widget categories(LedgerSnapshot snapshot) {
    final names = snapshot.entries.map((e) => e.category).toSet().toList()
      ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RpmPageHeader(
          onRefresh: reloadData,
          refreshing: refreshing,
          title: 'Categories',
          subtitle: 'Categories used by your saved transactions.',
        ),
        const SizedBox(height: 24),
        RpmSurface(
          child: names.isEmpty
              ? const RpmEmptyState(
                  title: 'No categories in use',
                  message:
                      'Choose a category when recording your first transaction.',
                )
              : Column(
                  children: [
                    for (final name in names)
                      ListTile(
                        title: Text(name),
                        subtitle: Text(
                          '${snapshot.entries.where((e) => e.category == name).length} transactions',
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () {
                          clearFilters();
                          setState(() {
                            category = name;
                            destination = RpmDestination.transactions;
                          });
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget reports(LedgerSnapshot snapshot) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RpmPageHeader(
        onRefresh: reloadData,
        refreshing: refreshing,
        title: 'Reports',
        subtitle: 'All-time cash movement, kept separate by currency.',
        actions: [RpmButton(label: 'Export CSV', onPressed: actions.exportCsv)],
      ),
      const SizedBox(height: 24),
      summaryCards(snapshot),
      const SizedBox(height: 24),
      currencySummaries(snapshot),
    ],
  );
}

class FinancialSummaryCard extends StatelessWidget {
  final String title, helper;
  final LedgerSnapshot snapshot;
  final int Function(LedgerSummary) value;
  final bool highlighted;
  const FinancialSummaryCard({
    super.key,
    required this.title,
    required this.helper,
    required this.snapshot,
    required this.value,
    this.highlighted = false,
  });
  @override
  Widget build(BuildContext context) {
    final p = context.rpm;
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlighted ? p.selected : p.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlighted ? RpmTokens.primary : p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_forward, size: 18, color: p.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 13, color: p.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'MWK  ${Money.format(value(snapshot.summary(Currency.mwk)))}',
              style: RpmTokens.moneyStyle.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: p.text,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'USD  ${Money.format(value(snapshot.summary(Currency.usd)))}',
            style: RpmTokens.moneyStyle.copyWith(
              fontSize: 13,
              color: p.secondary,
            ),
          ),
          const Spacer(),
          Text(
            helper,
            maxLines: 2,
            style: TextStyle(fontSize: 12, color: p.secondary),
          ),
        ],
      ),
    );
  }
}
