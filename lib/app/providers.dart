import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage.dart';
import '../features/backup/backup_service.dart';
import '../features/ledger/data/ledger_repository.dart';
import '../features/ledger/domain/ledger.dart';

final storageProvider = Provider<AppStorage>(
  (ref) => throw StateError('Storage not initialized.'),
  dependencies: [],
);
final repositoryProvider = Provider<LedgerRepository>(
  (ref) => throw StateError('Repository not initialized.'),
  dependencies: [],
);
final backupProvider = Provider(
  (ref) => BackupService(
    ref.watch(repositoryProvider),
    ref.watch(storageProvider).backups,
  ),
  dependencies: [repositoryProvider, storageProvider],
);
final ledgerProvider = FutureProvider<LedgerSnapshot>(
  (ref) => ref.watch(repositoryProvider).load(),
  dependencies: [repositoryProvider],
);
final themeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;
  void toggle(bool currentlyDark) {
    state = currentlyDark ? ThemeMode.light : ThemeMode.dark;
  }
}
