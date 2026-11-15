import 'dart:io';
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:rpm/core/database.dart';
import 'package:rpm/features/ledger/data/ledger_repository.dart';
import 'package:rpm/features/ledger/domain/ledger.dart';
import 'package:sqlite3/sqlite3.dart';
import 'ledger_cases.dart' show entry;

void main() {
  late RpmDatabase db;
  late LedgerRepository repo;
  setUp(() {
    db = RpmDatabase(NativeDatabase.memory());
    repo = LedgerRepository(db);
  });
  tearDown(() => db.close());
  for (final currency in Currency.values) {
    test(
      '${currency.code} add/edit/delete recalculates subsequent balances',
      () async {
        await repo.setOpening(currency, 10000);
        final a = entry(currency: currency, amount: 2000, date: '2026-01-01');
        final b = entry(
          currency: currency,
          kind: EntryKind.cashOut,
          amount: 500,
          date: '2026-01-02',
        );
        await repo.save(b);
        await repo.save(a);
        expect((await repo.load()).summary(currency).closing, 11500);
        final edited = entry(
          id: a.id,
          currency: currency,
          amount: 3000,
          date: '2026-01-03',
        );
        await repo.save(edited, edit: true);
        var data = await repo.load();
        expect(data.runningBalances(currency)[b.id], 9500);
        expect(data.runningBalances(currency)[a.id], 12500);
        await repo.delete(b.id);
        data = await repo.load();
        expect(data.summary(currency).closing, 13000);
        final other = currency == Currency.mwk ? Currency.usd : Currency.mwk;
        expect(data.summary(other).closing, 0);
      },
    );
  }
  test(
    'duplicate insert and edit are rejected without changing records',
    () async {
      final a = entry();
      final b = entry(description: 'Other');
      await repo.save(a);
      await repo.save(b);
      await expectLater(repo.save(entry()), throwsFormatException);
      await expectLater(
        repo.save(entry(id: b.id), edit: true),
        throwsFormatException,
      );
      expect((await repo.load()).entries.length, 2);
    },
  );
  test(
    'invalid replacement rolls back without erasing original data',
    () async {
      await repo.save(entry());
      final invalid = LedgerSnapshot(
        openings: LedgerSnapshot.empty().openings,
        entries: [entry(), entry()],
      );
      await expectLater(repo.replace(invalid), throwsFormatException);
      expect((await repo.load()).entries.length, 1);
    },
  );
  test(
    'SQLite failure during replacement rolls back deletions and openings',
    () async {
      final original = entry();
      await repo.save(original);
      await repo.setOpening(Currency.usd, 777);
      await db.customStatement(
        "CREATE TRIGGER simulate_failure BEFORE INSERT ON entries WHEN NEW.description = 'BLOCK' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      final candidate = LedgerSnapshot(
        openings: {Currency.mwk: 12, Currency.usd: 34},
        entries: [entry(description: 'BLOCK')],
      );
      await expectLater(
        repo.replace(candidate),
        throwsA(isA<SqliteException>()),
      );
      final actual = await repo.load();
      expect(actual.entries.single.id, original.id);
      expect(actual.openings[Currency.usd], 777);
    },
  );
  test('data persists after closing and reopening the database', () async {
    final dir = await Directory.systemTemp.createTemp('rpm-persistence-');
    final file = File(p.join(dir.path, 'ledger.sqlite'));
    final first = RpmDatabase.file(file);
    final e = entry(currency: Currency.usd, amount: 12345);
    await LedgerRepository(first).setOpening(Currency.mwk, 789);
    await LedgerRepository(first).save(e);
    await first.close();
    final second = RpmDatabase.file(file);
    try {
      final loaded = await LedgerRepository(second).load();
      expect(loaded.entries.single.toJson(), e.toJson());
      expect(loaded.summary(Currency.usd).closing, 12345);
      expect(loaded.openings[Currency.mwk], 789);
    } finally {
      await second.close();
      await dir.delete(recursive: true);
    }
  });
  test(
    'v1 migrates to v2 with data preserved and deterministic ordering',
    () async {
      final dir = await Directory.systemTemp.createTemp('rpm-migration-');
      final file = File(p.join(dir.path, 'v1.sqlite'));
      final raw = sqlite3.open(file.path);
      final e = entry();
      raw.execute(
        '''CREATE TABLE entries (id TEXT NOT NULL PRIMARY KEY, currency TEXT NOT NULL,
      kind TEXT NOT NULL, amount_minor INTEGER NOT NULL, date TEXT NOT NULL, category TEXT NOT NULL,
      description TEXT NOT NULL, duplicate_key TEXT NOT NULL UNIQUE)''',
      );
      raw.execute(
        'CREATE TABLE opening_balances (currency TEXT NOT NULL PRIMARY KEY, amount_minor INTEGER NOT NULL DEFAULT 0)',
      );
      raw.execute(
        "INSERT INTO opening_balances VALUES ('MWK', 100), ('USD', 200)",
      );
      raw.execute('INSERT INTO entries VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [
        e.id,
        e.currency.code,
        e.kind.name,
        e.amount,
        e.date,
        e.category,
        e.description,
        e.duplicateKey,
      ]);
      raw.execute('PRAGMA user_version = 1');
      raw.close();
      final migrated = RpmDatabase.file(file);
      try {
        final data = await LedgerRepository(migrated).load();
        expect(data.entries.single.id, e.id);
        expect(data.entries.single.createdAt, '2000-01-01T00:00:00.000Z');
        expect(data.summary(Currency.mwk).closing, e.amount + 100);
        final version = await migrated
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data.values.single, 2);
      } finally {
        await migrated.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
