import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../ledger/data/ledger_repository.dart';
import '../ledger/domain/ledger.dart';

abstract final class BackupCodec {
  static const maxFileBytes = 256 * 1024 * 1024;
  static String encode(LedgerSnapshot data) {
    data.validate();
    final content = const JsonEncoder.withIndent('  ').convert({
      'format': 'rpm-backup',
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'openingBalances': {
        for (final c in Currency.values) c.code: data.openings[c],
      },
      'transactions': data.entries.map((e) => e.toJson()).toList(),
    });
    if (utf8.encode(content).length > maxFileBytes) {
      throw const FormatException(
        'Backup exceeds the supported 256 MB limit. No data was changed.',
      );
    }
    return content;
  }

  static LedgerSnapshot decode(String content) {
    if (utf8.encode(content).length > maxFileBytes) {
      throw const FormatException('Backup is larger than 256 MB.');
    }
    final value = jsonDecode(content);
    if (value is! Map<String, dynamic> ||
        value['format'] != 'rpm-backup' ||
        value['version'] != 1 ||
        value['version'] is! int) {
      throw const FormatException(
        'This is not a supported RPM backup (version 1).',
      );
    }
    final openings = value['openingBalances'], records = value['transactions'];
    if (openings is! Map<String, dynamic> ||
        openings.length != 2 ||
        openings['MWK'] is! int ||
        openings['USD'] is! int ||
        records is! List ||
        records.length > 100000) {
      throw const FormatException(
        'Backup must contain both opening balances and up to 100,000 transactions.',
      );
    }
    final data = LedgerSnapshot(
      openings: {for (final c in Currency.values) c: openings[c.code] as int},
      entries: records.map(LedgerEntry.fromJson).toList(),
    );
    data.validate();
    return data;
  }

  static Future<LedgerSnapshot> read(File file) async {
    if (await file.length() > maxFileBytes) {
      throw const FormatException('Backup is larger than 256 MB.');
    }
    return decode(await file.readAsString());
  }
}

/// Create exclusively and flush all bytes before reporting success.
Future<File> writeNewFile(String target, String content) async {
  final file = File(target);
  if (await file.exists()) {
    throw const FileSystemException(
      'A file already exists at this destination. Choose a new name.',
    );
  }
  await file.create(exclusive: true);
  try {
    await file.writeAsString(content, flush: true);
    return file;
  } catch (_) {
    // A failed partial export must never be mistaken for a valid backup.
    if (await file.exists()) await file.delete();
    rethrow;
  }
}

class BackupService {
  final LedgerRepository repository;
  final Directory backupDirectory;
  BackupService(this.repository, this.backupDirectory);
  Future<File> backup({String? destination, String reason = 'manual'}) async {
    final content = BackupCodec.encode(await repository.load());
    final target =
        destination ??
        p.join(
          backupDirectory.path,
          'rpm-$reason-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}-${const Uuid().v4().substring(0, 8)}.json',
        );
    final file = await writeNewFile(target, content);
    // Verify the durable file before authorizing a destructive operation.
    final restored = await BackupCodec.read(file);
    final original = BackupCodec.decode(content);
    if (jsonEncode(restored.entries.map((e) => e.toJson()).toList()) !=
            jsonEncode(original.entries.map((e) => e.toJson()).toList()) ||
        Currency.values.any(
          (c) => restored.openings[c] != original.openings[c],
        )) {
      throw const FileSystemException(
        'Backup verification failed. No data was changed.',
      );
    }
    return file;
  }

  Future<File> restore(LedgerSnapshot data) async {
    data.validate();
    final safety = await backup(reason: 'before-restore');
    await repository.replace(data);
    return safety;
  }

  Future<File> reset() async {
    final safety = await backup(reason: 'before-reset');
    await repository.replace(LedgerSnapshot.empty());
    return safety;
  }

  static String csv(LedgerSnapshot snapshot) {
    String cell(Object value) {
      var text = value.toString();
      // Neutralize spreadsheet formulas, including leading whitespace/control.
      if (RegExp(r'^\s*[=+\-@\t\r\n]').hasMatch(text)) text = "'$text";
      return '"${text.replaceAll('"', '""')}"';
    }

    final rows = <List<Object>>[
      [
        'Currency',
        'Date',
        'Type',
        'Category',
        'Description',
        'Cash In',
        'Cash Out',
        'Running Balance',
        'ID',
      ],
    ];
    for (final c in Currency.values) {
      rows.add([
        c.code,
        '',
        'Opening balance',
        '',
        '',
        '',
        '',
        Money.input(snapshot.openings[c]!),
        '',
      ]);
      final balances = snapshot.runningBalances(c);
      for (final e in snapshot.entries.where((e) => e.currency == c)) {
        rows.add([
          c.code,
          e.date,
          e.kind == EntryKind.cashIn ? 'Cash In' : 'Cash Out',
          e.category,
          e.description,
          e.kind == EntryKind.cashIn ? Money.input(e.amount) : '',
          e.kind == EntryKind.cashOut ? Money.input(e.amount) : '',
          Money.input(balances[e.id]!),
          e.id,
        ]);
      }
    }
    return '\uFEFF${rows.map((r) => r.map(cell).join(',')).join('\r\n')}\r\n';
  }
}
