import 'dart:io';
import 'dart:ui' show AppExitResponse;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/storage.dart';
import '../../../core/storage_locations.dart';
import '../../backup/backup_service.dart';
import '../data/ledger_repository.dart';
import '../domain/ledger.dart';
import 'desktop_screen.dart';
import 'dialogs.dart';

class StartupScreen extends StatefulWidget {
  final Future<AppStorage> Function()? storageFactory;
  const StartupScreen({super.key, this.storageFactory});
  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  AppStorage? storage;
  StorageInspection? inspection;
  LedgerRepository? repository;
  bool busy = true;
  String? error;
  late final AppLifecycleListener lifecycle;
  @override
  void initState() {
    super.initState();
    lifecycle = AppLifecycleListener(
      onExitRequested: () async {
        await storage?.close();
        return AppExitResponse.exit;
      },
    );
    initialize();
  }

  @override
  void dispose() {
    lifecycle.dispose();
    storage?.close();
    super.dispose();
  }

  Future<void> initialize({bool recreateMissing = false}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (storage == null) {
        final candidate = await (widget.storageFactory ?? defaultStorage)();
        await candidate.acquireLock();
        storage = candidate;
      }
      final result = await storage!.inspect();
      if (recreateMissing && result.databaseMissing) {
        repository = await storage!.recreateMissing();
      } else if (result.status == StorageStatus.ready) {
        try {
          repository = await storage!.open();
        } catch (_) {
          inspection = const StorageInspection(
            StorageStatus.recovery,
            'The database could not be opened safely. Your existing files have been kept. Restore a validated JSON backup, or check permissions and retry.',
          );
        }
      } else {
        inspection = result;
      }
    } catch (e) {
      error = friendlyError(e);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> refresh() async {
    if (busy) return;
    await initialize(recreateMissing: true);
  }

  Future<void> create() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      repository = await storage!.create();
    } catch (e) {
      error = friendlyError(e);
      inspection = await storage!.inspect();
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> restore() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'RPM JSON backup', extensions: ['json']),
      ],
    );
    if (file == null || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await BackupCodec.read(File(file.path));
      if (!mounted) return;
      final accepted = await confirmAction(
        context,
        title: 'Recover from this backup?',
        message:
            'This backup contains ${data.entries.length} transactions.\n\nMWK closing: ${Money.format(data.summary(Currency.mwk).closing)}\nUSD closing: ${Money.format(data.summary(Currency.usd).closing)}\n\nRPM will use these records as your active ledgers. Existing database files, if any, will be preserved in Documents/RPM/Backups. We recommend keeping another copy of your original backup.',
        confirm: 'Restore backup',
      );
      if (accepted) repository = await storage!.recover(data);
    } catch (e) {
      error = friendlyError(e);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> reopen({bool recreateMissing = false}) async {
    setState(() {
      repository = null;
      busy = true;
    });
    await storage?.close();
    storage = null;
    await initialize(recreateMissing: recreateMissing);
  }

  @override
  Widget build(BuildContext context) {
    if (repository != null && storage != null) {
      return ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(storage!),
          repositoryProvider.overrideWithValue(repository!),
        ],
        child: DesktopScreen(
          onRecover: reopen,
          onRefreshStorage: () => reopen(recreateMissing: true),
        ),
      );
    }
    final recovery = inspection?.status == StorageStatus.recovery;
    return CallbackShortcuts(
      bindings: {
        SingleActivator(
          LogicalKeyboardKey.keyR,
          meta: Platform.isMacOS,
          control: !Platform.isMacOS,
        ): refresh,
        const SingleActivator(LogicalKeyboardKey.f5): refresh,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: 660,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: navy,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'RECEIPTS & PAYMENTS MANAGER',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.7,
                            color: purple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          recovery
                              ? 'Let’s recover your ledgers.'
                              : 'Your books. On your desktop.',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (busy)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          Text(
                            inspection?.message ??
                                'RPM could not access local storage.',
                            style: const TextStyle(height: 1.7),
                          ),
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          if (storage != null)
                            SelectableText(
                              storage!.root.path,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (inspection?.status ==
                                  StorageStatus.firstLaunch)
                                FilledButton.icon(
                                  onPressed: create,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create local ledgers'),
                                ),
                              if (storage != null)
                                OutlinedButton.icon(
                                  onPressed: restore,
                                  icon: const Icon(Icons.restore),
                                  label: const Text('Restore JSON backup'),
                                ),
                              if (recovery || error != null)
                                TextButton.icon(
                                  onPressed: refresh,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            children: [
                              Icon(Icons.lock_outline, size: 15, color: green),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Offline · Single user · Stored on this computer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
