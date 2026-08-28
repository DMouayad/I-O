import 'package:signals_flutter/signals_flutter.dart';
import '../models/transaction_model.dart';
import 'transactions_controller.dart';

enum ReportRangeType { today, thisWeek, thisMonth, all }

class CurrencyTotals {
  final double income;
  final double expense;
  const CurrencyTotals({this.income = 0, this.expense = 0});
  double get balance => income - expense;
  CurrencyTotals copyWith({double? income, double? expense}) => CurrencyTotals(
    income: income ?? this.income,
    expense: expense ?? this.expense,
  );
}

class ReportsController {
  ReportsController(this._transactionsController);
  final TransactionsController _transactionsController;

  final Signal<ReportRangeType> rangeType = signal(ReportRangeType.thisMonth);

  late final Computed<List<TransactionModel>> filtered = computed(() {
    final all = _transactionsController.transactions.value;
    final range = rangeType.value;
    if (range == ReportRangeType.all) return all;

    final now = DateTime.now();
    late DateTime start;
    switch (range) {
      case ReportRangeType.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case ReportRangeType.thisWeek:
        final d = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(d.year, d.month, d.day);
        break;
      case ReportRangeType.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case ReportRangeType.all:
        start = DateTime(0);
        break;
    }
    return all.where((t) => !t.date.isBefore(start)).toList();
  });

  late final Computed<Map<String, CurrencyTotals>> totalsByCurrency = computed(
    () {
      final map = <String, CurrencyTotals>{};
      for (final t in filtered.value) {
        final current = map[t.currency] ?? const CurrencyTotals();
        map[t.currency] = t.type == TransactionType.income
            ? current.copyWith(income: current.income + t.amount)
            : current.copyWith(expense: current.expense + t.amount);
      }
      return map;
    },
  );

  late final Computed<Map<String, double>> incomeByCategory = computed(() {
    return _sumByCategory(TransactionType.income);
  });

  late final Computed<Map<String, double>> expenseByCategory = computed(() {
    return _sumByCategory(TransactionType.expense);
  });

  Map<String, double> _sumByCategory(TransactionType type) {
    final map = <String, double>{};
    for (final t in filtered.value.where((t) => t.type == type)) {
      final key = t.category;
      if (key == null) continue;
      map[key] = (map[key] ?? 0) + t.amount;
    }
    return map;
  }
}
