import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../app/providers.dart';
import '../../backup/backup_service.dart';
import '../domain/ledger.dart';
import 'dialogs.dart';

/// Coordinates the existing repository/file APIs; layout widgets receive callbacks.
class DesktopActions extends ChangeNotifier {
  final WidgetRef ref;
  final BuildContext Function() _context;
  bool busy = false;
  bool _disposed = false;
  bool get mounted => !_disposed && _context().mounted;
  BuildContext get context => _context();
  DesktopActions(this.ref, this._context);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void refresh() {
    if (mounted && context.mounted) ref.invalidate(ledgerProvider);
  }

  Future<void> guarded(Future<void> Function() action) async {
    if (busy || !mounted) return;
    busy = true;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      if (mounted && context.mounted) {
        notify(context, friendlyError(e), error: true);
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> add({Currency? currency, LedgerEntry? entry}) async {
    if (busy) return;
    await showEntryEditor(
      context,
      categories:
          ref
              .read(ledgerProvider)
              .asData
              ?.value
              .entries
              .map((e) => e.category)
              .toSet()
              .toList() ??
          const ['General'],
      currency: currency,
      entry: entry,
      onSave: (value) async {
        await ref.read(repositoryProvider).save(value, edit: entry != null);
        refresh();
        if (mounted && context.mounted) {
          notify(
            context,
            'Saved to the ${value.currency.code} ledger.',
            title: entry == null ? 'Transaction saved' : 'Transaction updated',
          );
        }
      },
    );
  }

  Future<void> delete(LedgerEntry entry) async {
    if (!await confirmAction(
          context,
          title: 'Delete this ${entry.currency.code} transaction?',
          message:
              '${entry.date} · ${entry.description}\n${entry.kind == EntryKind.cashIn ? 'Cash In' : 'Cash Out'}: ${Money.format(entry.amount)} ${entry.currency.code}\n\nThis record will be permanently removed and subsequent balances will be recalculated. We recommend creating a JSON backup first. This action cannot be undone.',
          confirm: 'Delete transaction',
        ) ||
        !mounted ||
        !context.mounted) {
      return;
    }
    await guarded(() async {
      await ref.read(repositoryProvider).delete(entry.id);
      refresh();
      if (mounted && context.mounted) {
        notify(
          context,
          'Transaction deleted. Running balances have been recalculated.',
        );
      }
    });
  }

  Future<void> opening(Currency currency, int value) async {
    await showOpeningEditor(context, currency, value, (amount) async {
      await ref.read(repositoryProvider).setOpening(currency, amount);
      refresh();
    });
  }

  String filename(String type, String extension) =>
      'rpm-$type-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.$extension';
  Future<void> backup() => guarded(() async {
    final storage = ref.read(storageProvider);
    final location = await getSaveLocation(
      initialDirectory: storage.backups.path,
      suggestedName: filename('backup', 'json'),
      acceptedTypeGroups: [
        const XTypeGroup(label: 'RPM JSON backup', extensions: ['json']),
      ],
    );
    if (location == null) return;
    final file = await ref
        .read(backupProvider)
        .backup(destination: location.path);
    if (mounted && context.mounted) {
      notify(
        context,
        'Backup saved and verified: ${file.path}',
        title: 'Backup created',
      );
    }
  });
  Future<void> exportCsv() => guarded(() async {
    final storage = ref.read(storageProvider);
    final location = await getSaveLocation(
      initialDirectory: storage.exports.path,
      suggestedName: filename('ledgers', 'csv'),
      acceptedTypeGroups: [
        const XTypeGroup(label: 'CSV spreadsheet', extensions: ['csv']),
      ],
    );
    if (location == null) return;
    final data = await ref.read(repositoryProvider).load();
    await writeNewFile(location.path, BackupService.csv(data));
    if (mounted && context.mounted) {
      notify(
        context,
        'Both complete currency ledgers exported: ${location.path}',
        title: 'CSV exported',
      );
    }
  });
  Future<void> restore() => guarded(() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'RPM JSON backup', extensions: ['json']),
      ],
      initialDirectory: ref.read(storageProvider).backups.path,
    );
    if (file == null) return;
    final data = await BackupCodec.read(File(file.path));
    if (!mounted || !context.mounted) return;
    final accepted = await confirmAction(
      context,
      title: 'Replace ledgers with this backup?',
      message:
          '${p.basename(file.path)}\n${data.entries.length} validated transactions\n\nMWK closing: ${Money.format(data.summary(Currency.mwk).closing)}\nUSD closing: ${Money.format(data.summary(Currency.usd).closing)}\n\nAll current transactions and opening balances will be replaced, not merged. We recommend keeping an independent backup. RPM will create and verify a safety backup in Documents/RPM/Backups before changing any data.',
      confirm: 'Restore and replace',
    );
    if (!accepted) return;
    final safety = await ref.read(backupProvider).restore(data);
    refresh();
    if (mounted && context.mounted) {
      notify(
        context,
        'Backup restored. Previous records saved to ${safety.path}',
        title: 'Backup restored',
      );
    }
  });
  Future<void> reset() async {
    if (!await confirmAction(
          context,
          title: 'Reset all financial data?',
          message:
              'Every MWK and USD transaction will be permanently removed. Both opening balances will be set to zero. Your existing backup and export files will be kept.\n\nWe recommend keeping an independent backup. RPM must create and verify an automatic safety backup before resetting. If that fails, your data will remain unchanged.',
          confirm: 'Reset all data',
          typedWord: 'RESET',
        ) ||
        !mounted ||
        !context.mounted) {
      return;
    }
    await guarded(() async {
      final safety = await ref.read(backupProvider).reset();
      refresh();
      if (mounted && context.mounted) {
        notify(context, 'Ledgers reset. Safety backup: ${safety.path}');
      }
    });
  }

  Future<void> dataInfo() async {
    final storage = ref.read(storageProvider);
    final backups = await storage.backups
        .list()
        .where((f) => f is File && f.path.endsWith('.json'))
        .toList();
    backups.sort((a, b) => b.path.compareTo(a.path));
    if (!mounted || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Local data & protection'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All business records stay on this computer. RPM does not use a server or send your records online.',
                  style: TextStyle(height: 1.6),
                ),
                const SizedBox(height: 20),
                const Text(
                  'DATABASE',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(storage.databaseFile.path),
                const SizedBox(height: 18),
                const Text(
                  'BACKUPS',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(storage.backups.path),
                const SizedBox(height: 12),
                Text(
                  '${backups.length} JSON backup files in the local backup folder.',
                ),
                if (backups.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SelectableText(
                      'Backup file: ${p.basename(backups.first.path)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Keep a separate backup on another drive. Files can still be deleted or damaged outside RPM. Missing database files are detected on startup; RPM then guides you through recovery.',
                  style: TextStyle(height: 1.6),
                ),
                const Divider(height: 32),
                const Text(
                  'Keyboard shortcuts',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '${Platform.isMacOS ? '⌘' : 'Ctrl'}+N  New transaction\n${Platform.isMacOS ? '⌘' : 'Ctrl'}+F  Search transactions\n${Platform.isMacOS ? '⌘' : 'Ctrl'}+B  Create JSON backup\n${Platform.isMacOS ? '⌘' : 'Ctrl'}+E  Export CSV\n${Platform.isMacOS ? '⌘' : 'Ctrl'}+R / F5  Refresh saved records',
                  style: const TextStyle(height: 1.8),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
