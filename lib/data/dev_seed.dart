/// Dev-only demo data generator: somewhat real-world transactions for the
/// current year, from Jan 1 through today.
///
/// Pure Dart (no Flutter, no DB) so it can run both from `tool/seed.dart`
/// (desktop CLI) and from inside the app (e.g. Android device DB via the
/// repository). Not referenced by release UI.
library;

import 'dart:math';

import '../models/transaction_model.dart';

/// Generates transactions from Jan 1 of [year] through [today] (inclusive).
/// Deterministic for a given [seed].
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

/// 90% SYP / 10% USD.
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
