import 'package:test/test.dart';
import 'package:drift/drift.dart';
// Single test entrypoint also supports low-disk development environments.
import 'cases/ledger_cases.dart' as ledger;
import 'cases/repository_cases.dart' as repository;
import 'cases/backup_cases.dart' as backup;
import 'cases/storage_cases.dart' as storage;

void main() {
  // Every database in this suite uses its own executor and isolated path.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  group('ledger', ledger.main);
  group('repository', repository.main);
  group('backup', backup.main);
  group('storage', storage.main);
}
