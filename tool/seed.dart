/// Dev seed script: generates somewhat real-world transactions for the
/// current year, from Jan 1 through today.
///
/// Usage:
///   dart run tool/seed.dart [--seed 42] [--year 2026] [--no-wipe] [--dry-run]
///
/// Defaults to wiping `transactions` first. Pass --dry-run to only print
/// what would be inserted without touching the DB.
library;

import 'dart:io';

import 'package:io/data/dev_seed.dart';
import 'package:io/models/transaction_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _dbFileName = 'i_and_o.db';

const _createTableSql = '''
  CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    amount REAL NOT NULL,
    currency TEXT NOT NULL,
    payee TEXT,
    date INTEGER NOT NULL,
    created_at INTEGER NOT NULL
  )
  ''';

void main(List<String> args) async {
  var seed = 42;
  var year = DateTime.now().year;
  var wipe = true;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String? valueFor(String name) {
      const prefixEq = '--';
      if (arg.startsWith('$prefixEq$name=')) {
        return arg.substring('$prefixEq$name='.length);
      }
      if (arg == '--$name' && i + 1 < args.length) {
        i++;
        return args[i];
      }
      return null;
    }

    if (arg == '--help' || arg == '-h') {
      _printHelp();
      return;
    } else if (arg == '--no-wipe') {
      wipe = false;
    } else if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg.startsWith('--seed')) {
      final v = valueFor('seed');
      final parsed = int.tryParse(v ?? '');
      if (parsed == null) {
        stderr.writeln('Invalid --seed value: $v');
        exit(64);
      }
      seed = parsed;
    } else if (arg.startsWith('--year')) {
      final v = valueFor('year');
      final parsed = int.tryParse(v ?? '');
      if (parsed == null) {
        stderr.writeln('Invalid --year value: $v');
        exit(64);
      }
      year = parsed;
    } else {
      stderr.writeln('Unknown argument: $arg\n');
      _printHelp();
      exit(64);
    }
  }

  final now = DateTime.now();
  if (year > now.year) {
    stderr.writeln('Year $year is in the future. Nothing to seed.');
    exit(64);
  }

  final transactions = generateYearToDate(year: year, today: now, seed: seed);

  stdout.writeln(
    'Planned ${transactions.length} transactions '
    'for $year-01-01..${now.year == year ? _fmtDay(now) : '$year-12-31'} '
    '(seed=$seed).',
  );
  _printSummary(transactions);

  if (dryRun) {
    stdout.writeln('Dry run — DB untouched.');
    return;
  }

  sqfliteFfiInit();
  final dir = await databaseFactoryFfi.getDatabasesPath();
  final dbPath = p.join(dir, _dbFileName);
  final db = await databaseFactoryFfi.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, version) async {
        await db.execute(_createTableSql);
        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_payee ON transactions(payee)',
        );
      },
    ),
  );

  try {
    // Ensure table exists even if the DB predates this script.
    await db.execute(
      'CREATE TABLE IF NOT EXISTS transactions ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'type TEXT NOT NULL, '
      'amount REAL NOT NULL, '
      'currency TEXT NOT NULL, '
      'payee TEXT, '
      'date INTEGER NOT NULL, '
      'created_at INTEGER NOT NULL)',
    );
    if (wipe) {
      final deleted = await db.delete('transactions');
      stdout.writeln('Wiped $deleted existing row(s).');
    }
    final batch = db.batch();
    for (final t in transactions) {
      batch.insert('transactions', t.toMap());
    }
    await batch.commit(noResult: true);
    stdout.writeln('Inserted ${transactions.length} row(s) into $dbPath.');
  } finally {
    await db.close();
  }
}

void _printHelp() {
  stdout.writeln('''Seed dev transactions for the current year (Jan 1 -> today).

Usage: dart run tool/seed.dart [options]

Options:
  --seed <int>   Random seed for reproducible output (default: 42)
  --year <int>   Year to seed (default: current year)
  --no-wipe      Keep existing rows (default: delete all first)
  --dry-run      Print summary without writing to the DB
  -h, --help     Show this help''');
}

String _fmtDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void _printSummary(List<TransactionModel> transactions) {
  var incomeSyp = 0.0;
  var expenseSyp = 0.0;
  var incomeUsd = 0.0;
  var expenseUsd = 0.0;
  for (final t in transactions) {
    if (t.currency == 'SYP') {
      if (t.type == TransactionType.income) {
        incomeSyp += t.amount;
      } else {
        expenseSyp += t.amount;
      }
    } else {
      if (t.type == TransactionType.income) {
        incomeUsd += t.amount;
      } else {
        expenseUsd += t.amount;
      }
    }
  }
  stdout.writeln(
    '  income SYP: ${_compact(incomeSyp)} | '
    'expense SYP: ${_compact(expenseSyp)}',
  );
  stdout.writeln(
    '  income USD: ${incomeUsd.toStringAsFixed(2)} | '
    'expense USD: ${expenseUsd.toStringAsFixed(2)}',
  );
}

String _compact(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
  return v.toStringAsFixed(0);
}
