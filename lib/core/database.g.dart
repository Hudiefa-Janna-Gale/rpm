// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    check: () => currency.isIn(['MWK', 'USD']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(['cashIn', 'cashOut']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    check: () =>
        ComparableExpr(amountMinor).isBiggerThanValue(0) &
        ComparableExpr(amountMinor).isSmallerOrEqualValue(99999999999999),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _duplicateKeyMeta = const VerificationMeta(
    'duplicateKey',
  );
  @override
  late final GeneratedColumn<String> duplicateKey = GeneratedColumn<String>(
    'duplicate_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('2000-01-01T00:00:00.000Z'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currency,
    kind,
    amountMinor,
    date,
    category,
    description,
    duplicateKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('duplicate_key')) {
      context.handle(
        _duplicateKeyMeta,
        duplicateKey.isAcceptableOrUnknown(
          data['duplicate_key']!,
          _duplicateKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_duplicateKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      duplicateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duplicate_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  final String id;
  final String currency;
  final String kind;
  final int amountMinor;
  final String date;
  final String category;
  final String description;
  final String duplicateKey;
  final String createdAt;
  const Entry({
    required this.id,
    required this.currency,
    required this.kind,
    required this.amountMinor,
    required this.date,
    required this.category,
    required this.description,
    required this.duplicateKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['currency'] = Variable<String>(currency);
    map['kind'] = Variable<String>(kind);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['date'] = Variable<String>(date);
    map['category'] = Variable<String>(category);
    map['description'] = Variable<String>(description);
    map['duplicate_key'] = Variable<String>(duplicateKey);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      currency: Value(currency),
      kind: Value(kind),
      amountMinor: Value(amountMinor),
      date: Value(date),
      category: Value(category),
      description: Value(description),
      duplicateKey: Value(duplicateKey),
      createdAt: Value(createdAt),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<String>(json['id']),
      currency: serializer.fromJson<String>(json['currency']),
      kind: serializer.fromJson<String>(json['kind']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      date: serializer.fromJson<String>(json['date']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String>(json['description']),
      duplicateKey: serializer.fromJson<String>(json['duplicateKey']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'currency': serializer.toJson<String>(currency),
      'kind': serializer.toJson<String>(kind),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'date': serializer.toJson<String>(date),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String>(description),
      'duplicateKey': serializer.toJson<String>(duplicateKey),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Entry copyWith({
    String? id,
    String? currency,
    String? kind,
    int? amountMinor,
    String? date,
    String? category,
    String? description,
    String? duplicateKey,
    String? createdAt,
  }) => Entry(
    id: id ?? this.id,
    currency: currency ?? this.currency,
    kind: kind ?? this.kind,
    amountMinor: amountMinor ?? this.amountMinor,
    date: date ?? this.date,
    category: category ?? this.category,
    description: description ?? this.description,
    duplicateKey: duplicateKey ?? this.duplicateKey,
    createdAt: createdAt ?? this.createdAt,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      currency: data.currency.present ? data.currency.value : this.currency,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      duplicateKey: data.duplicateKey.present
          ? data.duplicateKey.value
          : this.duplicateKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('currency: $currency, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('duplicateKey: $duplicateKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    currency,
    kind,
    amountMinor,
    date,
    category,
    description,
    duplicateKey,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.currency == this.currency &&
          other.kind == this.kind &&
          other.amountMinor == this.amountMinor &&
          other.date == this.date &&
          other.category == this.category &&
          other.description == this.description &&
          other.duplicateKey == this.duplicateKey &&
          other.createdAt == this.createdAt);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<String> id;
  final Value<String> currency;
  final Value<String> kind;
  final Value<int> amountMinor;
  final Value<String> date;
  final Value<String> category;
  final Value<String> description;
  final Value<String> duplicateKey;
  final Value<String> createdAt;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.currency = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.duplicateKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    required String id,
    required String currency,
    required String kind,
    required int amountMinor,
    required String date,
    required String category,
    required String description,
    required String duplicateKey,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       currency = Value(currency),
       kind = Value(kind),
       amountMinor = Value(amountMinor),
       date = Value(date),
       category = Value(category),
       description = Value(description),
       duplicateKey = Value(duplicateKey);
  static Insertable<Entry> custom({
    Expression<String>? id,
    Expression<String>? currency,
    Expression<String>? kind,
    Expression<int>? amountMinor,
    Expression<String>? date,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? duplicateKey,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currency != null) 'currency': currency,
      if (kind != null) 'kind': kind,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (duplicateKey != null) 'duplicate_key': duplicateKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? currency,
    Value<String>? kind,
    Value<int>? amountMinor,
    Value<String>? date,
    Value<String>? category,
    Value<String>? description,
    Value<String>? duplicateKey,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      currency: currency ?? this.currency,
      kind: kind ?? this.kind,
      amountMinor: amountMinor ?? this.amountMinor,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      duplicateKey: duplicateKey ?? this.duplicateKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (duplicateKey.present) {
      map['duplicate_key'] = Variable<String>(duplicateKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('currency: $currency, ')
          ..write('kind: $kind, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('duplicateKey: $duplicateKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OpeningBalancesTable extends OpeningBalances
    with TableInfo<$OpeningBalancesTable, OpeningBalance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OpeningBalancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    check: () => currency.isIn(['MWK', 'USD']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [currency, amountMinor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'opening_balances';
  @override
  VerificationContext validateIntegrity(
    Insertable<OpeningBalance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {currency};
  @override
  OpeningBalance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OpeningBalance(
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
    );
  }

  @override
  $OpeningBalancesTable createAlias(String alias) {
    return $OpeningBalancesTable(attachedDatabase, alias);
  }
}

class OpeningBalance extends DataClass implements Insertable<OpeningBalance> {
  final String currency;
  final int amountMinor;
  const OpeningBalance({required this.currency, required this.amountMinor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['currency'] = Variable<String>(currency);
    map['amount_minor'] = Variable<int>(amountMinor);
    return map;
  }

  OpeningBalancesCompanion toCompanion(bool nullToAbsent) {
    return OpeningBalancesCompanion(
      currency: Value(currency),
      amountMinor: Value(amountMinor),
    );
  }

  factory OpeningBalance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OpeningBalance(
      currency: serializer.fromJson<String>(json['currency']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'currency': serializer.toJson<String>(currency),
      'amountMinor': serializer.toJson<int>(amountMinor),
    };
  }

  OpeningBalance copyWith({String? currency, int? amountMinor}) =>
      OpeningBalance(
        currency: currency ?? this.currency,
        amountMinor: amountMinor ?? this.amountMinor,
      );
  OpeningBalance copyWithCompanion(OpeningBalancesCompanion data) {
    return OpeningBalance(
      currency: data.currency.present ? data.currency.value : this.currency,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OpeningBalance(')
          ..write('currency: $currency, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(currency, amountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OpeningBalance &&
          other.currency == this.currency &&
          other.amountMinor == this.amountMinor);
}

class OpeningBalancesCompanion extends UpdateCompanion<OpeningBalance> {
  final Value<String> currency;
  final Value<int> amountMinor;
  final Value<int> rowid;
  const OpeningBalancesCompanion({
    this.currency = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OpeningBalancesCompanion.insert({
    required String currency,
    this.amountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : currency = Value(currency);
  static Insertable<OpeningBalance> custom({
    Expression<String>? currency,
    Expression<int>? amountMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (currency != null) 'currency': currency,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OpeningBalancesCompanion copyWith({
    Value<String>? currency,
    Value<int>? amountMinor,
    Value<int>? rowid,
  }) {
    return OpeningBalancesCompanion(
      currency: currency ?? this.currency,
      amountMinor: amountMinor ?? this.amountMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OpeningBalancesCompanion(')
          ..write('currency: $currency, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RpmDatabase extends GeneratedDatabase {
  _$RpmDatabase(QueryExecutor e) : super(e);
  $RpmDatabaseManager get managers => $RpmDatabaseManager(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $OpeningBalancesTable openingBalances = $OpeningBalancesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    entries,
    openingBalances,
  ];
}

typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      required String id,
      required String currency,
      required String kind,
      required int amountMinor,
      required String date,
      required String category,
      required String description,
      required String duplicateKey,
      Value<String> createdAt,
      Value<int> rowid,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<String> id,
      Value<String> currency,
      Value<String> kind,
      Value<int> amountMinor,
      Value<String> date,
      Value<String> category,
      Value<String> description,
      Value<String> duplicateKey,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$EntriesTableFilterComposer
    extends Composer<_$RpmDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get duplicateKey => $composableBuilder(
    column: $table.duplicateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntriesTableOrderingComposer
    extends Composer<_$RpmDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get duplicateKey => $composableBuilder(
    column: $table.duplicateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$RpmDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get duplicateKey => $composableBuilder(
    column: $table.duplicateKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$RpmDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, BaseReferences<_$RpmDatabase, $EntriesTable, Entry>),
          Entry,
          PrefetchHooks Function()
        > {
  $$EntriesTableTableManager(_$RpmDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> duplicateKey = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                currency: currency,
                kind: kind,
                amountMinor: amountMinor,
                date: date,
                category: category,
                description: description,
                duplicateKey: duplicateKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String currency,
                required String kind,
                required int amountMinor,
                required String date,
                required String category,
                required String description,
                required String duplicateKey,
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                currency: currency,
                kind: kind,
                amountMinor: amountMinor,
                date: date,
                category: category,
                description: description,
                duplicateKey: duplicateKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$RpmDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, BaseReferences<_$RpmDatabase, $EntriesTable, Entry>),
      Entry,
      PrefetchHooks Function()
    >;
typedef $$OpeningBalancesTableCreateCompanionBuilder =
    OpeningBalancesCompanion Function({
      required String currency,
      Value<int> amountMinor,
      Value<int> rowid,
    });
typedef $$OpeningBalancesTableUpdateCompanionBuilder =
    OpeningBalancesCompanion Function({
      Value<String> currency,
      Value<int> amountMinor,
      Value<int> rowid,
    });

class $$OpeningBalancesTableFilterComposer
    extends Composer<_$RpmDatabase, $OpeningBalancesTable> {
  $$OpeningBalancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OpeningBalancesTableOrderingComposer
    extends Composer<_$RpmDatabase, $OpeningBalancesTable> {
  $$OpeningBalancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OpeningBalancesTableAnnotationComposer
    extends Composer<_$RpmDatabase, $OpeningBalancesTable> {
  $$OpeningBalancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );
}

class $$OpeningBalancesTableTableManager
    extends
        RootTableManager<
          _$RpmDatabase,
          $OpeningBalancesTable,
          OpeningBalance,
          $$OpeningBalancesTableFilterComposer,
          $$OpeningBalancesTableOrderingComposer,
          $$OpeningBalancesTableAnnotationComposer,
          $$OpeningBalancesTableCreateCompanionBuilder,
          $$OpeningBalancesTableUpdateCompanionBuilder,
          (
            OpeningBalance,
            BaseReferences<
              _$RpmDatabase,
              $OpeningBalancesTable,
              OpeningBalance
            >,
          ),
          OpeningBalance,
          PrefetchHooks Function()
        > {
  $$OpeningBalancesTableTableManager(
    _$RpmDatabase db,
    $OpeningBalancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OpeningBalancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OpeningBalancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OpeningBalancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> currency = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OpeningBalancesCompanion(
                currency: currency,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String currency,
                Value<int> amountMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OpeningBalancesCompanion.insert(
                currency: currency,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OpeningBalancesTableProcessedTableManager =
    ProcessedTableManager<
      _$RpmDatabase,
      $OpeningBalancesTable,
      OpeningBalance,
      $$OpeningBalancesTableFilterComposer,
      $$OpeningBalancesTableOrderingComposer,
      $$OpeningBalancesTableAnnotationComposer,
      $$OpeningBalancesTableCreateCompanionBuilder,
      $$OpeningBalancesTableUpdateCompanionBuilder,
      (
        OpeningBalance,
        BaseReferences<_$RpmDatabase, $OpeningBalancesTable, OpeningBalance>,
      ),
      OpeningBalance,
      PrefetchHooks Function()
    >;

class $RpmDatabaseManager {
  final _$RpmDatabase _db;
  $RpmDatabaseManager(this._db);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$OpeningBalancesTableTableManager get openingBalances =>
      $$OpeningBalancesTableTableManager(_db, _db.openingBalances);
}
