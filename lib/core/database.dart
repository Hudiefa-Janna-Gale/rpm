// Drift generated table overrides resolve column references in checks.
// ignore_for_file: recursive_getters

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get currency => text().check(currency.isIn(['MWK', 'USD']))();
  TextColumn get kind => text().check(kind.isIn(['cashIn', 'cashOut']))();
  IntColumn get amountMinor => integer().check(
    amountMinor.isBiggerThanValue(0) &
        amountMinor.isSmallerOrEqualValue(99999999999999),
  )();
  TextColumn get date => text()();
  TextColumn get category => text()();
  TextColumn get description => text()();
  TextColumn get duplicateKey => text().unique()();
  // Added in v2; a stable timestamp orders entries on the same day.
  TextColumn get createdAt =>
      text().withDefault(const Constant('2000-01-01T00:00:00.000Z'))();
  @override
  Set<Column> get primaryKey => {id};
}

class OpeningBalances extends Table {
  TextColumn get currency => text().check(currency.isIn(['MWK', 'USD']))();
  IntColumn get amountMinor => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {currency};
}

@DriftDatabase(tables: [Entries, OpeningBalances])
class RpmDatabase extends _$RpmDatabase {
  RpmDatabase(super.executor);
  factory RpmDatabase.file(File file) => RpmDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode = WAL');
        db.execute('PRAGMA synchronous = FULL');
        db.execute('PRAGMA foreign_keys = ON');
        db.execute('PRAGMA busy_timeout = 5000');
      },
    ),
  );
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(
        openingBalances,
      ).insert(OpeningBalancesCompanion.insert(currency: 'MWK'));
      await into(
        openingBalances,
      ).insert(OpeningBalancesCompanion.insert(currency: 'USD'));
      await customStatement(
        'CREATE INDEX entries_chronology ON entries(currency, date, created_at, id)',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await transaction(() async {
          await m.addColumn(entries, entries.createdAt);
          await customStatement(
            'CREATE INDEX entries_chronology ON entries(currency, date, created_at, id)',
          );
        });
      } else {
        throw StateError(
          'Unsupported database version. Restore a compatible backup.',
        );
      }
    },
    beforeOpen: (details) async {
      final check = await customSelect('PRAGMA quick_check').get();
      if (check.length != 1 || check.single.data.values.single != 'ok') {
        throw StateError(
          'Database integrity check failed. Recovery is required.',
        );
      }
    },
  );
}
