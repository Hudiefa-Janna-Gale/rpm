import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:rpm/core/database.dart';
import 'package:rpm/features/backup/backup_service.dart';
import 'package:rpm/features/ledger/data/ledger_repository.dart';
import 'package:rpm/features/ledger/domain/ledger.dart';
import 'ledger_cases.dart' show entry;

void main() {
  late Directory dir;
  late RpmDatabase db;
  late LedgerRepository repo;
  late BackupService service;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('rpm-backup-');
    db = RpmDatabase(NativeDatabase.memory());
    repo = LedgerRepository(db);
    service = BackupService(repo, dir);
    await repo.setOpening(Currency.usd, -123);
    await repo.save(entry());
    await repo.save(entry(currency: Currency.usd, amount: 50));
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  test(
    'JSON backup round trip preserves every field and independent balances',
    () async {
      final before = await repo.load();
      final file = await service.backup();
      final restored = await BackupCodec.read(file);
      expect(restored.openings, before.openings);
      expect(
        restored.entries.map((e) => e.toJson()).toList(),
        before.entries.map((e) => e.toJson()).toList(),
      );
    },
  );
  test(
    'restore replaces records, preserves safety backup, and does not duplicate on repeat',
    () async {
      final original = await repo.load();
      final replacement = LedgerSnapshot(
        openings: {Currency.mwk: 456, Currency.usd: 789},
        entries: [entry(amount: 70)],
      );
      final safety = await service.restore(replacement);
      expect(
        (await BackupCodec.read(safety)).entries.length,
        original.entries.length,
      );
      await service.restore(replacement);
      expect((await repo.load()).entries.length, 1);
      expect((await repo.load()).openings, replacement.openings);
    },
  );
  test(
    'reset requires a verified backup and clears both opening balances',
    () async {
      final backup = await service.reset();
      expect((await BackupCodec.read(backup)).entries.length, 2);
      final cleared = await repo.load();
      expect(cleared.entries, isEmpty);
      expect(cleared.openings, {Currency.mwk: 0, Currency.usd: 0});
    },
  );
  test('failed safety backup prevents both reset and restore', () async {
    final blocker = File(p.join(dir.path, 'not-a-directory'));
    await blocker.writeAsString('block');
    final failing = BackupService(
      repo,
      Directory(p.join(blocker.path, 'Backups')),
    );
    await expectLater(failing.reset(), throwsA(isA<FileSystemException>()));
    expect((await repo.load()).entries.length, 2);
    await expectLater(
      failing.restore(LedgerSnapshot.empty()),
      throwsA(isA<FileSystemException>()),
    );
    expect((await repo.load()).entries.length, 2);
  });
  test('existing export is never overwritten', () async {
    final target = File(p.join(dir.path, 'existing.json'));
    await target.writeAsString('original');
    await expectLater(
      service.backup(destination: target.path),
      throwsA(isA<FileSystemException>()),
    );
    expect(await target.readAsString(), 'original');
  });
  test(
    'malformed, wrong version, fractional and duplicate backup records are rejected',
    () async {
      final encoded =
          jsonDecode(BackupCodec.encode(await repo.load()))
              as Map<String, dynamic>;
      expect(() => BackupCodec.decode('{'), throwsFormatException);
      expect(
        () => BackupCodec.decode(jsonEncode({...encoded, 'version': 99})),
        throwsFormatException,
      );
      final records = encoded['transactions'] as List;
      expect(
        () => BackupCodec.decode(
          jsonEncode({
            ...encoded,
            'transactions': [...records, records.first],
          }),
        ),
        throwsFormatException,
      );
      final bad = Map<String, dynamic>.from(records.first as Map)
        ..['amountMinor'] = 1.5;
      expect(
        () => BackupCodec.decode(
          jsonEncode({
            ...encoded,
            'transactions': [bad],
          }),
        ),
        throwsFormatException,
      );
      expect(
        () => BackupCodec.decode(
          jsonEncode({
            ...encoded,
            'openingBalances': {'USD': 1},
          }),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'CSV separates currencies, includes opening and running balances, escapes formulas',
    () {
      final data = LedgerSnapshot(
        openings: {Currency.mwk: 0, Currency.usd: -100},
        entries: [
          entry(description: '=SUM(A1:A2), "test"'),
          entry(currency: Currency.usd, amount: 50),
        ],
      );
      final csv = BackupService.csv(data);
      expect(csv, contains('"MWK"'));
      expect(csv, contains('"USD"'));
      expect(csv, contains('"\'=SUM(A1:A2), ""test"""'));
      expect(csv, contains('"\'-0.50"'));
    },
  );
}
