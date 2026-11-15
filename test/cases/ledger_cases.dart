import 'package:test/test.dart';
import 'package:rpm/features/ledger/domain/ledger.dart';
import 'package:uuid/uuid.dart';

LedgerEntry entry({
  Currency currency = Currency.mwk,
  EntryKind kind = EntryKind.cashIn,
  int amount = 10000,
  String date = '2026-01-02',
  String description = 'Receipt',
  String? id,
}) => LedgerEntry(
  id: id ?? const Uuid().v4(),
  currency: currency,
  kind: kind,
  amount: amount,
  date: date,
  category: 'General',
  description: description,
  createdAt: '2026-01-01T12:00:00.000Z',
);

void main() {
  test('minor units parse exactly without floating point', () {
    expect(Money.parse('0.10') + Money.parse('0.20'), 30);
    expect(Money.parse('123456789012.34'), 12345678901234);
    expect(Money.parse('-1.25', signed: true), -125);
    expect(Money.parse('0', signed: true), 0);
    expect(Money.format(-123456), '−1,234.56');
    for (final invalid in [
      '-1',
      '0',
      'NaN',
      '1e2',
      '1,000',
      '0.001',
      '.5',
      '9999999999999',
    ]) {
      expect(
        () => Money.parse(invalid),
        throwsFormatException,
        reason: invalid,
      );
    }
  });
  for (final currency in Currency.values) {
    test(
      '${currency.code} opening, debit, credit and chronological running balance',
      () {
        final first = entry(
          currency: currency,
          amount: 150,
          date: '2026-01-01',
        );
        final second = entry(
          currency: currency,
          kind: EntryKind.cashOut,
          amount: 75,
          date: '2026-01-02',
        );
        final data = LedgerSnapshot(
          openings: {Currency.mwk: 1000, Currency.usd: -250},
          entries: [second, first],
        );
        final start = data.openings[currency]!;
        expect(data.entries.first.id, first.id);
        expect(data.summary(currency).cashIn, 150);
        expect(data.summary(currency).cashOut, 75);
        expect(data.summary(currency).net, 75);
        expect(data.summary(currency).closing, start + 75);
        expect(data.runningBalances(currency), {
          first.id: start + 150,
          second.id: start + 75,
        });
        final other = currency == Currency.mwk ? Currency.usd : Currency.mwk;
        expect(data.summary(other).closing, data.openings[other]);
      },
    );
  }
  test('duplicate content is rejected even with different identifiers', () {
    final data = LedgerSnapshot(
      openings: LedgerSnapshot.empty().openings,
      entries: [
        entry(),
        entry(description: ' receipt '),
      ],
    );
    expect(data.validate, throwsFormatException);
  });
  test('invalid calendar dates and invalid fields are rejected', () {
    for (final date in [
      '2026-02-30',
      '1899-01-01',
      '2201-01-01',
      '2026-1-01',
    ]) {
      expect(() => parseDate(date), throwsFormatException);
    }
    expect(() => entry(amount: -1).validate(), throwsFormatException);
    expect(() => entry(description: '').validate(), throwsFormatException);
  });
  test(
    'same-day ordering compares timestamps at full microsecond precision',
    () {
      final early = LedgerEntry.fromJson({
        ...entry(description: 'Earlier').toJson(),
        'createdAt': '2026-01-01T12:00:00.000Z',
      });
      final late = LedgerEntry.fromJson({
        ...entry(description: 'Later').toJson(),
        'createdAt': '2026-01-01T12:00:00.000001Z',
      });
      final snapshot = LedgerSnapshot(
        openings: LedgerSnapshot.empty().openings,
        entries: [late, early],
      );
      expect(snapshot.entries.map((e) => e.id), [early.id, late.id]);
      expect(snapshot.runningBalances(Currency.mwk)[early.id], early.amount);
    },
  );
}
