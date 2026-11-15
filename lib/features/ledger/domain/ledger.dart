import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

enum Currency {
  mwk,
  usd;

  String get code => name.toUpperCase();
  String get title => this == mwk ? 'Malawian Kwacha' : 'US Dollar';
  static Currency parse(Object? value) => switch (value) {
    'MWK' => mwk,
    'USD' => usd,
    _ => throw const FormatException('Unsupported currency.'),
  };
}

enum EntryKind { cashIn, cashOut }

/// All persisted money uses integer hundredths. No binary floating point.
abstract final class Money {
  static const maxAmount = 99999999999999;
  static const maxBalance = 9000000000000000;
  static int parse(String input, {bool signed = false}) {
    final text = input.trim();
    if (!RegExp(
      signed ? r'^-?\d{1,12}(\.\d{1,2})?$' : r'^\d{1,12}(\.\d{1,2})?$',
    ).hasMatch(text)) {
      throw const FormatException(
        'Enter an amount with up to 2 decimal places (no commas).',
      );
    }
    final negative = text.startsWith('-');
    final parts = text.replaceFirst('-', '').split('.');
    final amount =
        int.parse(parts[0]) * 100 +
        int.parse(parts.length == 2 ? parts[1].padRight(2, '0') : '0');
    if (amount > maxAmount || (!signed && amount == 0)) {
      throw const FormatException(
        'Amount must be greater than zero and within the supported limit.',
      );
    }
    return negative ? -amount : amount;
  }

  static String input(int amount) =>
      '${amount < 0 ? '-' : ''}${amount.abs() ~/ 100}.${(amount.abs() % 100).toString().padLeft(2, '0')}';
  static String format(int amount) {
    final whole = NumberFormat('#,##0', 'en_US').format(amount.abs() ~/ 100);
    return '${amount < 0 ? '−' : ''}$whole.${(amount.abs() % 100).toString().padLeft(2, '0')}';
  }
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime parseDate(Object? input) {
  if (input is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) {
    throw const FormatException('Invalid transaction date.');
  }
  final date = DateTime.tryParse(input);
  if (date == null ||
      dateKey(date) != input ||
      date.year < 1900 ||
      date.year > 2200) {
    throw const FormatException('Date must be between 1900 and 2200.');
  }
  return date;
}

class LedgerEntry {
  final String id;
  final Currency currency;
  final EntryKind kind;
  final int amount;
  final String date;
  final String category;
  final String description;
  final String createdAt;
  const LedgerEntry({
    required this.id,
    required this.currency,
    required this.kind,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
    required this.createdAt,
  });

  int get signedAmount => kind == EntryKind.cashIn ? amount : -amount;
  String get duplicateKey => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            currency.code,
            kind.name,
            amount,
            date,
            category.trim().toLowerCase(),
            description.trim().toLowerCase(),
          ]),
        ),
      )
      .toString();

  void validate() {
    if (!RegExp(
      r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
    ).hasMatch(id)) {
      throw const FormatException('Invalid transaction identifier.');
    }
    if (amount <= 0 || amount > Money.maxAmount) {
      throw const FormatException('Invalid transaction amount.');
    }
    parseDate(date);
    if (category.trim().isEmpty ||
        category.length > 80 ||
        description.trim().isEmpty ||
        description.length > 500 ||
        RegExp(r'[\x00-\x1f]').hasMatch(category) ||
        RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(description)) {
      throw const FormatException(
        'Enter a category (up to 80 characters) and description (up to 500).',
      );
    }
    if (DateTime.tryParse(createdAt)?.toUtc().toIso8601String() != createdAt) {
      throw const FormatException('Invalid creation timestamp.');
    }
  }

  Map<String, Object> toJson() => {
    'id': id,
    'currency': currency.code,
    'kind': kind.name,
    'amountMinor': amount,
    'date': date,
    'category': category,
    'description': description,
    'createdAt': createdAt,
  };

  factory LedgerEntry.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid transaction record.');
    }
    if (value['id'] is! String ||
        value['amountMinor'] is! int ||
        value['date'] is! String ||
        value['category'] is! String ||
        value['description'] is! String ||
        value['createdAt'] is! String) {
      throw const FormatException(
        'A transaction has missing or invalid fields.',
      );
    }
    final entry = LedgerEntry(
      id: value['id'] as String,
      currency: Currency.parse(value['currency']),
      kind: switch (value['kind']) {
        'cashIn' => EntryKind.cashIn,
        'cashOut' => EntryKind.cashOut,
        _ => throw const FormatException('Invalid cash direction.'),
      },
      amount: value['amountMinor'] as int,
      date: value['date'] as String,
      category: value['category'] as String,
      description: value['description'] as String,
      createdAt: value['createdAt'] as String,
    );
    entry.validate();
    return entry;
  }
}

class LedgerSnapshot {
  final Map<Currency, int> openings;
  final List<LedgerEntry> entries;
  LedgerSnapshot({
    required Map<Currency, int> openings,
    required List<LedgerEntry> entries,
  }) : openings = Map.unmodifiable(openings),
       entries = List.unmodifiable(
         <LedgerEntry>[...entries]..sort(compareEntries),
       );
  factory LedgerSnapshot.empty() => LedgerSnapshot(
    openings: {for (final c in Currency.values) c: 0},
    entries: [],
  );
  static int compareEntries(LedgerEntry a, LedgerEntry b) {
    final date = a.date.compareTo(b.date);
    if (date != 0) return date;
    final created = DateTime.parse(
      a.createdAt,
    ).compareTo(DateTime.parse(b.createdAt));
    return created != 0 ? created : a.id.compareTo(b.id);
  }

  LedgerSummary summary(Currency currency) {
    var cashIn = 0, cashOut = 0;
    for (final e in entries.where((e) => e.currency == currency)) {
      if (e.kind == EntryKind.cashIn) {
        cashIn += e.amount;
      } else {
        cashOut += e.amount;
      }
    }
    return LedgerSummary(openings[currency]!, cashIn, cashOut);
  }

  Map<String, int> runningBalances(Currency currency) {
    var balance = openings[currency]!;
    return {
      for (final e in entries.where((e) => e.currency == currency))
        e.id: (balance += e.signedAmount),
    };
  }

  void validate() {
    if (entries.length > 100000) {
      throw const FormatException(
        'The supported limit is 100,000 transactions.',
      );
    }
    if (openings.length != 2 ||
        Currency.values.any(
          (c) =>
              !openings.containsKey(c) || openings[c]!.abs() > Money.maxAmount,
        )) {
      throw const FormatException(
        'Both currency opening balances are required and must be within the supported limit.',
      );
    }
    final ids = <String>{}, keys = <String>{};
    for (final e in entries) {
      e.validate();
      if (!ids.add(e.id) || !keys.add(e.duplicateKey)) {
        throw const FormatException('Duplicate transaction in this data.');
      }
    }
    final incoming = {for (final c in Currency.values) c: 0};
    final outgoing = {for (final c in Currency.values) c: 0};
    final balances = {...openings};
    for (final e in entries) {
      final totals = e.kind == EntryKind.cashIn ? incoming : outgoing;
      totals[e.currency] = totals[e.currency]! + e.amount;
      balances[e.currency] = balances[e.currency]! + e.signedAmount;
      if (totals[e.currency]! > Money.maxBalance ||
          balances[e.currency]!.abs() > Money.maxBalance) {
        throw const FormatException(
          'Ledger total exceeds the supported financial limit.',
        );
      }
    }
  }
}

class LedgerSummary {
  final int opening, cashIn, cashOut;
  const LedgerSummary(this.opening, this.cashIn, this.cashOut);
  int get net => cashIn - cashOut;
  int get closing => opening + net;
}
