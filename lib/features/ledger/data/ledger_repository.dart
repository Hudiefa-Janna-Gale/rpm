import 'package:drift/drift.dart';
import '../../../core/database.dart';
import '../domain/ledger.dart';

class LedgerRepository {
  final RpmDatabase database;
  final Future<void> Function()? checkStorage;
  LedgerRepository(this.database, {this.checkStorage});

  Future<LedgerSnapshot> load() async {
    await checkStorage?.call();
    return database.transaction(() async {
      final openings = await database.select(database.openingBalances).get();
      final rows = await database.select(database.entries).get();
      final snapshot = LedgerSnapshot(
        openings: {
          for (final r in openings) Currency.parse(r.currency): r.amountMinor,
        },
        entries: [
          for (final r in rows)
            LedgerEntry(
              id: r.id,
              currency: Currency.parse(r.currency),
              kind: switch (r.kind) {
                'cashIn' => EntryKind.cashIn,
                'cashOut' => EntryKind.cashOut,
                _ => throw const FormatException(
                  'Invalid cash direction in the database. Recovery is required.',
                ),
              },
              amount: r.amountMinor,
              date: r.date,
              category: r.category,
              description: r.description,
              createdAt: r.createdAt,
            ),
        ],
      );
      snapshot.validate();
      return snapshot;
    });
  }

  Future<void> save(LedgerEntry entry, {bool edit = false}) async {
    entry.validate();
    await checkStorage?.call();
    await database.transaction(() async {
      final before = await load();
      if (edit && !before.entries.any((e) => e.id == entry.id)) {
        throw StateError('This transaction no longer exists.');
      }
      if (!edit && before.entries.any((e) => e.id == entry.id)) {
        throw StateError('This transaction already exists.');
      }
      LedgerSnapshot(
        openings: before.openings,
        entries: [...before.entries.where((e) => e.id != entry.id), entry],
      ).validate();
      final row = EntriesCompanion.insert(
        id: entry.id,
        currency: entry.currency.code,
        kind: entry.kind.name,
        amountMinor: entry.amount,
        date: entry.date,
        category: entry.category.trim(),
        description: entry.description.trim(),
        duplicateKey: entry.duplicateKey,
        createdAt: Value(entry.createdAt),
      );
      if (edit) {
        await (database.update(
          database.entries,
        )..where((t) => t.id.equals(entry.id))).write(row);
      } else {
        await database.into(database.entries).insert(row);
      }
    });
  }

  Future<void> delete(String id) async {
    await checkStorage?.call();
    await database.transaction(() async {
      final before = await load();
      LedgerSnapshot(
        openings: before.openings,
        entries: before.entries.where((e) => e.id != id).toList(),
      ).validate();
      final count = await (database.delete(
        database.entries,
      )..where((t) => t.id.equals(id))).go();
      if (count != 1) throw StateError('This transaction no longer exists.');
    });
  }

  Future<void> setOpening(Currency currency, int amount) async {
    await checkStorage?.call();
    await database.transaction(() async {
      final before = await load();
      LedgerSnapshot(
        openings: {...before.openings, currency: amount},
        entries: before.entries,
      ).validate();
      await (database.update(database.openingBalances)
            ..where((t) => t.currency.equals(currency.code)))
          .write(OpeningBalancesCompanion(amountMinor: Value(amount)));
    });
  }

  /// Caller must finish a durable safety backup before using replacement.
  Future<void> replace(LedgerSnapshot snapshot) async {
    snapshot.validate();
    await checkStorage?.call();
    await database.transaction(() async {
      await database.delete(database.entries).go();
      await database.delete(database.openingBalances).go();
      for (final c in Currency.values) {
        await database
            .into(database.openingBalances)
            .insert(
              OpeningBalancesCompanion.insert(
                currency: c.code,
                amountMinor: Value(snapshot.openings[c]!),
              ),
            );
      }
      await database.batch((batch) {
        batch.insertAll(database.entries, [
          for (final e in snapshot.entries)
            EntriesCompanion.insert(
              id: e.id,
              currency: e.currency.code,
              kind: e.kind.name,
              amountMinor: e.amount,
              date: e.date,
              category: e.category,
              description: e.description,
              duplicateKey: e.duplicateKey,
              createdAt: Value(e.createdAt),
            ),
        ]);
      });
    });
  }
}
