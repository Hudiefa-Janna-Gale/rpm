import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import '../features/ledger/data/ledger_repository.dart';
import '../features/ledger/domain/ledger.dart';
import 'database.dart';

enum StorageStatus { firstLaunch, ready, recovery }

class StorageInspection {
  final StorageStatus status;
  final String message;
  final bool databaseMissing;
  const StorageInspection(
    this.status,
    this.message, {
    this.databaseMissing = false,
  });
}

class AppStorage {
  final Directory root;
  final Directory support;
  RandomAccessFile? _lock;
  RpmDatabase? _database;
  AppStorage({required this.root, required this.support});
  Directory get databases => Directory(p.join(root.path, 'Database'));
  Directory get backups => Directory(p.join(root.path, 'Backups'));
  Directory get exports => Directory(p.join(root.path, 'Exports'));
  File get databaseFile => File(p.join(databases.path, 'rpm_database.sqlite'));
  File get marker => File(p.join(support.path, 'storage.json'));

  Future<void> acquireLock() async {
    await support.create(recursive: true);
    final lock = await File(
      p.join(support.path, 'rpm.lock'),
    ).open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
      _lock = lock;
    } catch (_) {
      await lock.close();
      throw StateError(
        'RPM is already open in another window. Close it before opening another copy.',
      );
    }
  }

  Future<StorageInspection> inspect() async {
    if (!await databaseFile.exists()) {
      if (await marker.exists() || await root.exists()) {
        return const StorageInspection(
          StorageStatus.recovery,
          'Your RPM database is missing. Choose Refresh to recreate the local folders and start with empty ledgers, or restore a JSON backup to recover your saved records.',
          databaseMissing: true,
        );
      }
      return const StorageInspection(
        StorageStatus.firstLaunch,
        'Create your local ledgers, or restore an existing RPM JSON backup. No account or internet connection is needed.',
      );
    }
    if (_database != null) {
      return const StorageInspection(StorageStatus.ready, '');
    }
    try {
      await _preflight();
      return const StorageInspection(StorageStatus.ready, '');
    } catch (_) {
      return const StorageInspection(
        StorageStatus.recovery,
        'The local database could not be verified. It may be damaged, inaccessible, or from an unsupported version. Your files have been left in place. Restore a validated JSON backup or recover the original files, then retry.',
      );
    }
  }

  Future<void> _preflight({bool backupMigration = false}) async {
    if (await databaseFile.length() < 100) {
      throw StateError('Incomplete database.');
    }
    final handle = await databaseFile.open();
    try {
      final header = await handle.read(16);
      if (latin1.decode(header) != 'SQLite format 3\u0000') {
        throw StateError('Invalid SQLite header.');
      }
    } finally {
      await handle.close();
    }
    final db = sqlite3.open(databaseFile.path, mode: OpenMode.readOnly);
    try {
      final version =
          db.select('PRAGMA user_version').single.values.single as int;
      if (version < 1 || version > 2) throw StateError('Unsupported schema.');
      if (db.select('PRAGMA quick_check').single.values.single != 'ok') {
        throw StateError('Integrity check failed.');
      }
      final names = db
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((r) => r['name'])
          .toSet();
      if (!names.containsAll(['entries', 'opening_balances'])) {
        throw StateError('Not an RPM database.');
      }
      // A consistent SQLite snapshot before any schema migration, including WAL.
      if (version < 2 && backupMigration) {
        await backups.create(recursive: true);
        db.execute('VACUUM INTO ?', [
          p.join(backups.path, 'pre-migration-${const Uuid().v4()}.sqlite'),
        ]);
      }
    } finally {
      db.close();
    }
  }

  Future<void> assertPresent() async {
    if (!await databaseFile.exists() || await databaseFile.length() < 100) {
      throw StateError(
        'The database file is missing or incomplete. Use Refresh to recreate a missing database, or restore a JSON backup to recover your records.',
      );
    }
  }

  Future<void> _mark() async {
    final next = File('${marker.path}.next');
    await next.writeAsString(
      jsonEncode({'version': 1, 'database': databaseFile.path}),
      flush: true,
    );
    await next.rename(marker.path);
  }

  Future<void> _directories() async {
    for (final dir in [databases, backups, exports]) {
      await dir.create(recursive: true);
    }
  }

  Future<LedgerRepository> open() async {
    if (_database != null) throw StateError('The database is already open.');
    await _preflight(backupMigration: true);
    await _directories();
    final db = RpmDatabase.file(databaseFile);
    try {
      final repository = LedgerRepository(db, checkStorage: assertPresent);
      await repository.load();
      await _mark();
      _database = db;
      return repository;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Future<LedgerRepository> create() async {
    if ((await inspect()).status != StorageStatus.firstLaunch) {
      throw StateError(
        'Existing RPM storage detected. Use the recovery workflow.',
      );
    }
    return _createDatabase();
  }

  /// Recreate only an absent database, keeping the application lock and schema.
  /// Existing databases, including damaged files, must never be replaced here.
  Future<LedgerRepository> recreateMissing() async {
    if (await databaseFile.exists()) {
      throw StateError(
        'The database still exists. Refresh will not replace it.',
      );
    }
    await _database?.close();
    _database = null;
    // A file restored while the previous connection closed must be reopened.
    if (await databaseFile.exists()) return open();
    await _directories();
    final id = const Uuid().v4();
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final orphan = File('${databaseFile.path}$suffix');
      if (await orphan.exists()) {
        await orphan.rename(
          p.join(backups.path, 'missing-database-$id.sqlite$suffix'),
        );
      }
    }
    return _createDatabase();
  }

  Future<LedgerRepository> _createDatabase() async {
    await _directories();
    // Write intent before database creation; an interrupted setup is recoverable.
    await _mark();
    await databaseFile.create(exclusive: true);
    final db = RpmDatabase.file(databaseFile);
    try {
      final repository = LedgerRepository(db);
      await repository.load();
      await db.close();
      return await open();
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  /// Used only before opening an active database. The caller confirms recovery.
  Future<LedgerRepository> recover(LedgerSnapshot data) async {
    if (_database != null) {
      throw StateError('Close the active database before recovery.');
    }
    data.validate();
    await _directories();
    final id = const Uuid().v4();
    final staged = File(p.join(databases.path, 'recovery-$id.sqlite'));
    await staged.create(exclusive: true);
    final db = RpmDatabase.file(staged);
    try {
      final repo = LedgerRepository(db);
      await repo.replace(data);
      await repo.load();
      // Make the staged database self-contained before publishing its name.
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      await db.customStatement('PRAGMA journal_mode = DELETE');
    } finally {
      await db.close();
    }
    // Keep every existing SQLite file, including journals, under Backups.
    // Rename within Documents/RPM preserves the bytes without overwriting.
    final preserved = <String, String>{};
    var published = false;
    try {
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        final original = File('${databaseFile.path}$suffix');
        if (await original.exists()) {
          final target = p.join(backups.path, 'preserved-$id.sqlite$suffix');
          await original.rename(target);
          preserved[original.path] = target;
        }
      }
      await staged.rename(databaseFile.path);
      published = true;
      await _mark();
      return await open();
    } catch (_) {
      // Preserve a completed candidate and put original files back on failure.
      if (published) {
        for (final suffix in ['', '-wal', '-shm', '-journal']) {
          final candidate = File('${databaseFile.path}$suffix');
          if (await candidate.exists()) {
            await candidate.rename(
              p.join(backups.path, 'candidate-$id.sqlite$suffix'),
            );
          }
        }
      }
      for (final item in preserved.entries) {
        await File(item.value).rename(item.key);
      }
      rethrow;
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    if (_lock != null) {
      await _lock!.unlock();
      await _lock!.close();
      _lock = null;
    }
  }
}
