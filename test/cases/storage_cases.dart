import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:rpm/core/storage.dart';
import 'package:rpm/features/ledger/domain/ledger.dart';
import 'ledger_cases.dart' show entry;

void main() {
  late Directory dir;
  late AppStorage storage;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('rpm-storage-');
    storage = AppStorage(
      root: Directory(p.join(dir.path, 'Documents', 'RPM')),
      support: Directory(p.join(dir.path, 'Support')),
    );
    await storage.acquireLock();
  });
  tearDown(() async {
    await storage.close();
    await dir.delete(recursive: true);
  });
  test(
    'first launch creates directories only after explicit initialization',
    () async {
      expect((await storage.inspect()).status, StorageStatus.firstLaunch);
      expect(await storage.databaseFile.exists(), false);
      await storage.create();
      expect(await storage.databaseFile.exists(), true);
      expect(await storage.backups.exists(), true);
      expect(await storage.exports.exists(), true);
      expect(await storage.marker.exists(), true);
      await expectLater(storage.create(), throwsStateError);
    },
  );
  test(
    'missing database after restart enters recovery without recreating it',
    () async {
      await storage.create();
      await storage.close();
      await storage.databaseFile.delete();
      final next = AppStorage(root: storage.root, support: storage.support);
      expect((await next.inspect()).status, StorageStatus.recovery);
      expect(await next.databaseFile.exists(), false);
      await expectLater(next.create(), throwsStateError);
      expect(await next.databaseFile.exists(), false);
    },
  );
  test(
    'deleting the entire RPM folder still triggers recovery via support marker',
    () async {
      await storage.create();
      await storage.close();
      await storage.root.delete(recursive: true);
      expect((await storage.inspect()).status, StorageStatus.recovery);
      expect(await storage.root.exists(), false);
    },
  );
  test(
    'unrecognized existing directory does not silently initialize',
    () async {
      await storage.root.create(recursive: true);
      expect((await storage.inspect()).status, StorageStatus.recovery);
    },
  );
  test('corrupt file is kept and recovery preserves original bytes', () async {
    await storage.databases.create(recursive: true);
    await storage.databaseFile.writeAsString('damaged financial database');
    expect((await storage.inspect()).status, StorageStatus.recovery);
    expect(
      await storage.databaseFile.readAsString(),
      'damaged financial database',
    );
    final data = LedgerSnapshot(
      openings: {Currency.mwk: 12, Currency.usd: 34},
      entries: [entry()],
    );
    final repo = await storage.recover(data);
    expect((await repo.load()).entries.length, 1);
    final preserved = await storage.backups
        .list()
        .where((f) => f.path.contains('preserved-'))
        .toList();
    expect(preserved.length, 1);
    expect(
      await File(preserved.single.path).readAsString(),
      'damaged financial database',
    );
  });
  test('in-session missing file blocks further writes', () async {
    final repo = await storage.create();
    await storage.databaseFile.rename('${storage.databaseFile.path}.moved');
    await expectLater(repo.save(entry()), throwsStateError);
  });
  test('refresh recreates a deleted database after restart', () async {
    final original = await storage.create();
    await original.save(entry());
    await storage.close();
    await storage.databaseFile.delete();
    await storage.acquireLock();
    expect((await storage.inspect()).databaseMissing, true);
    final fresh = await storage.recreateMissing();
    expect((await fresh.load()).entries, isEmpty);
    expect((await fresh.load()).summary(Currency.mwk).closing, 0);
    expect((await fresh.load()).summary(Currency.usd).closing, 0);
    await fresh.save(entry(description: 'After refresh'));
    await storage.close();
    final reopened = await storage.open();
    expect((await reopened.load()).entries.single.description, 'After refresh');
  });
  test(
    'refresh recreates the whole folder while its database is open',
    () async {
      final original = await storage.create();
      await original.save(entry());
      await storage.root.delete(recursive: true);
      expect((await storage.inspect()).databaseMissing, true);
      final fresh = await storage.recreateMissing();
      expect(await storage.databaseFile.exists(), true);
      expect(await storage.backups.exists(), true);
      expect(await storage.exports.exists(), true);
      expect((await fresh.load()).entries, isEmpty);
      await fresh.save(entry(description: 'New session'));
      expect((await fresh.load()).entries.single.description, 'New session');
    },
  );
  test('recreation refuses existing valid and damaged databases', () async {
    final original = await storage.create();
    await original.save(entry());
    await expectLater(storage.recreateMissing(), throwsStateError);
    expect((await original.load()).entries.length, 1);
    await storage.close();
    await storage.databaseFile.writeAsString('damaged financial database');
    await expectLater(storage.recreateMissing(), throwsStateError);
    expect(
      await storage.databaseFile.readAsString(),
      'damaged financial database',
    );
  });
  test('missing database refresh preserves orphaned SQLite journals', () async {
    await storage.create();
    await storage.close();
    await storage.databaseFile.delete();
    for (final suffix in ['-wal', '-shm', '-journal']) {
      await File('${storage.databaseFile.path}$suffix').writeAsString(suffix);
    }
    final fresh = await storage.recreateMissing();
    expect((await fresh.load()).entries, isEmpty);
    final preserved = await storage.backups
        .list()
        .where((file) => file.path.contains('missing-database-'))
        .toList();
    expect(preserved.length, 3);
    for (final file in preserved) {
      final suffix = file.path.substring(file.path.lastIndexOf('.sqlite') + 7);
      expect(await File(file.path).readAsString(), suffix);
    }
  });
  test('v1 gets a consistent safety snapshot before migration', () async {
    final repo = await storage.create();
    final e = entry(amount: 1245);
    await repo.save(e);
    await storage.close();
    final raw = sqlite3.open(storage.databaseFile.path);
    raw.execute('DROP INDEX entries_chronology');
    raw.execute('ALTER TABLE entries DROP COLUMN created_at');
    raw.execute('PRAGMA user_version = 1');
    raw.close();
    await storage.acquireLock();
    final migrated = await storage.open();
    expect((await migrated.load()).entries.single.amount, 1245);
    final snapshots = await storage.backups
        .list()
        .where((f) => f.path.contains('pre-migration-'))
        .toList();
    expect(snapshots.length, 1);
    final old = sqlite3.open(snapshots.single.path, mode: OpenMode.readOnly);
    try {
      expect(old.select('PRAGMA user_version').single.values.single, 1);
      expect(
        old.select('SELECT amount_minor FROM entries').single.values.single,
        1245,
      );
    } finally {
      old.close();
    }
  });
  test(
    'unsupported future database version is preserved without downgrade',
    () async {
      await storage.create();
      await storage.close();
      final raw = sqlite3.open(storage.databaseFile.path);
      raw.execute('PRAGMA user_version = 999');
      raw.close();
      final before = await storage.databaseFile.readAsBytes();
      expect((await storage.inspect()).status, StorageStatus.recovery);
      expect(await storage.databaseFile.readAsBytes(), before);
    },
  );
  test('a second process cannot acquire the active application lock', () async {
    final path = p.join(storage.support.path, 'rpm.lock');
    final blocked = await Process.run('dart', [
      'test/cases/lock_probe.dart',
      path,
    ]);
    expect(blocked.exitCode, 0);
    expect(blocked.stdout, 'locked');
    await storage.close();
    final released = await Process.run('dart', [
      'test/cases/lock_probe.dart',
      path,
    ]);
    expect(released.exitCode, 0);
    expect(released.stdout, 'available');
  });
}
