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
import 'dart:math';

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

/// Generates transactions from Jan 1 of [year] through [today] (inclusive).
List<TransactionModel> generateYearToDate({
  required int year,
  required DateTime today,
  int seed = 42,
}) {
  final random = Random(seed);
  final end = DateTime(today.year, today.month, today.day, 23, 59);
  var day = DateTime(year, 1, 1);
  final out = <TransactionModel>[];

  while (!day.isAfter(end)) {
    _addMonthlyRecurring(day, random, out);
    _addWeekly(day, random, out);
    _addDailyNoise(day, random, out);
    if (_isLastDayOfMonth(day)) {
      _maybeAddFreelance(day, random, out);
    }
    day = day.add(const Duration(days: 1));
  }

  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

// ---- Recurring building blocks ----

void _addMonthlyRecurring(
  DateTime day,
  Random random,
  List<TransactionModel> out,
) {
  // Salary on the 1st: mostly USD, sometimes SYP.
  if (day.day == 1) {
    if (random.nextDouble() < 0.7) {
      out.add(
        _tx(
          day,
          random,
          type: TransactionType.income,
          currency: 'USD',
          amount: 800 + random.nextDouble() * 700,
          payee: 'Salary - Company',
        ),
      );
    } else {
      out.add(
        _tx(
          day,
          random,
          type: TransactionType.income,
          currency: 'SYP',
          amount: 3000000 + random.nextDouble() * 5000000,
          payee: 'Salary - Company',
        ),
      );
    }
  }
  // Rent in the first few days.
  if (day.day == 3) {
    out.add(
      _tx(
        day,
        random,
        type: TransactionType.expense,
        currency: 'SYP',
        amount: 1500000 + random.nextDouble() * 2000000,
        payee: 'Rent',
      ),
    );
  }
  // Utilities mid-month.
  if (day.day == 12) {
    out.add(
      _tx(
        day,
        random,
        type: TransactionType.expense,
        currency: 'SYP',
        amount: 40000 + random.nextDouble() * 210000,
        payee: 'Electricity bill',
      ),
    );
  }
  if (day.day == 15) {
    out.add(
      _tx(
        day,
        random,
        type: TransactionType.expense,
        currency: 'SYP',
        amount: 75000 + random.nextDouble() * 200000,
        payee: random.nextBool() ? 'MTN bill' : 'Syriatel bill',
      ),
    );
    if (random.nextDouble() < 0.5) {
      out.add(
        _tx(
          day,
          random,
          type: TransactionType.expense,
          currency: 'USD',
          amount: 10 + random.nextDouble() * 10,
          payee: random.nextBool() ? 'Netflix' : 'Spotify',
        ),
      );
    }
  }
}

void _addWeekly(DateTime day, Random random, List<TransactionModel> out) {
  // Big grocery + fuel run on Saturdays.
  if (day.weekday != DateTime.saturday) return;
  out.add(
    _tx(
      day,
      random,
      type: TransactionType.expense,
      currency: _pickCurrency(random),
      amountSyp: 150000 + random.nextDouble() * 550000,
      amountUsd: 15 + random.nextDouble() * 65,
      payee: random.nextBool() ? 'Spinneys' : 'Carrefour',
    ),
  );
  if (random.nextDouble() < 0.6) {
    out.add(
      _tx(
        day,
        random,
        type: TransactionType.expense,
        currency: _pickCurrency(random),
        amountSyp: 100000 + random.nextDouble() * 300000,
        amountUsd: 10 + random.nextDouble() * 30,
        payee: 'Fuel',
      ),
    );
  }
}

void _addDailyNoise(DateTime day, Random random, List<TransactionModel> out) {
  final roll = random.nextDouble();
  final count = roll < 0.15
      ? 0
      : roll < 0.50
      ? 1
      : roll < 0.85
      ? 2
      : 3;
  for (var i = 0; i < count; i++) {
    final template = _weightedExpense(random);
    final currency = template.sypOnly ? 'SYP' : _pickCurrency(random);
    out.add(
      _tx(
        day,
        random,
        type: TransactionType.expense,
        currency: currency,
        amountSyp:
            template.minSyp +
            random.nextDouble() * (template.maxSyp - template.minSyp),
        amountUsd:
            template.minUsd +
            random.nextDouble() * (template.maxUsd - template.minUsd),
        payee: template.payee,
      ),
    );
  }
}

void _maybeAddFreelance(
  DateTime day,
  Random random,
  List<TransactionModel> out,
) {
  if (random.nextDouble() >= 0.25) return;
  out.add(
    _tx(
      day,
      random,
      type: TransactionType.income,
      currency: _pickCurrency(random),
      amountSyp: 500000 + random.nextDouble() * 2500000,
      amountUsd: 50 + random.nextDouble() * 250,
      payee: 'Freelance',
    ),
  );
}

// ---- Helpers ----

class _ExpenseTemplate {
  final String payee;
  final double minSyp;
  final double maxSyp;
  final double minUsd;
  final double maxUsd;
  final double weight;
  final bool sypOnly;

  const _ExpenseTemplate({
    required this.payee,
    required this.minSyp,
    required this.maxSyp,
    required this.minUsd,
    required this.maxUsd,
    required this.weight,
    this.sypOnly = false,
  });
}

const _expenses = <_ExpenseTemplate>[
  _ExpenseTemplate(
    payee: 'Mini market',
    minSyp: 25000,
    maxSyp: 150000,
    minUsd: 3,
    maxUsd: 15,
    weight: 20,
  ),
  _ExpenseTemplate(
    payee: 'Bakery الفرن',
    minSyp: 10000,
    maxSyp: 50000,
    minUsd: 1,
    maxUsd: 5,
    weight: 14,
  ),
  _ExpenseTemplate(
    payee: 'Coffee shop',
    minSyp: 30000,
    maxSyp: 90000,
    minUsd: 3,
    maxUsd: 8,
    weight: 12,
  ),
  _ExpenseTemplate(
    payee: 'Restaurant',
    minSyp: 150000,
    maxSyp: 600000,
    minUsd: 15,
    maxUsd: 60,
    weight: 10,
  ),
  _ExpenseTemplate(
    payee: 'Taxi',
    minSyp: 20000,
    maxSyp: 80000,
    minUsd: 2,
    maxUsd: 8,
    weight: 12,
  ),
  _ExpenseTemplate(
    payee: 'Pharmacy',
    minSyp: 50000,
    maxSyp: 350000,
    minUsd: 5,
    maxUsd: 30,
    weight: 7,
  ),
  _ExpenseTemplate(
    payee: 'Internet bill',
    minSyp: 50000,
    maxSyp: 180000,
    minUsd: 5,
    maxUsd: 15,
    weight: 2,
    sypOnly: true,
  ),
  _ExpenseTemplate(
    payee: 'Clothes',
    minSyp: 300000,
    maxSyp: 1200000,
    minUsd: 30,
    maxUsd: 120,
    weight: 2,
  ),
  _ExpenseTemplate(
    payee: 'Barber',
    minSyp: 50000,
    maxSyp: 120000,
    minUsd: 5,
    maxUsd: 10,
    weight: 3,
  ),
];

_ExpenseTemplate _weightedExpense(Random random) {
  var total = 0.0;
  for (final t in _expenses) {
    total += t.weight;
  }
  var roll = random.nextDouble() * total;
  for (final t in _expenses) {
    roll -= t.weight;
    if (roll <= 0) return t;
  }
  return _expenses.last;
}

/// 90% SYP / 10% USD, per request.
String _pickCurrency(Random random) =>
    random.nextDouble() < 0.9 ? 'SYP' : 'USD';

TransactionModel _tx(
  DateTime day,
  Random random, {
  required TransactionType type,
  required String currency,
  double? amount,
  double? amountSyp,
  double? amountUsd,
  required String payee,
}) {
  double raw;
  if (amount != null) {
    raw = amount;
  } else if (currency == 'SYP') {
    raw = amountSyp ?? 50000;
  } else {
    raw = amountUsd ?? 10;
  }
  // SYP: round to nearest 500 (cash-like). USD: cents.
  final rounded = currency == 'SYP'
      ? (raw / 500).round() * 500.0
      : (raw * 100).round() / 100.0;
  final hour = 8 + random.nextInt(15); // 8:00-22:xx
  final minute = random.nextInt(60);
  final date = DateTime(day.year, day.month, day.day, hour, minute);
  return TransactionModel(
    type: type,
    amount: rounded,
    currency: currency,
    payee: payee,
    date: date,
    createdAt: date.add(Duration(minutes: random.nextInt(30))),
  );
}

bool _isLastDayOfMonth(DateTime day) {
  final next = day.add(const Duration(days: 1));
  return next.month != day.month;
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
