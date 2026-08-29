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

  // ---- Day grouping helpers (for DayListScreen / DayScreen) ----

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  late final Computed<Map<DateTime, List<TransactionModel>>> groupedByDay =
      computed(() {
        final map = <DateTime, List<TransactionModel>>{};
        for (final t in _transactionsController.transactions.value) {
          final day = dateOnly(t.date);
          (map[day] ??= []).add(t);
        }
        return map;
      });

  /// Days that have transactions, sorted desc (newest first).
  late final Computed<List<DateTime>> txDays = computed(() {
    final days = groupedByDay.value.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return days;
  });

  List<TransactionModel> transactionsForDay(DateTime day) {
    return groupedByDay.value[dateOnly(day)] ?? const [];
  }

  List<TransactionModel> transactionsForDayAndType(
    DateTime day,
    TransactionType type,
  ) {
    return transactionsForDay(day).where((t) => t.type == type).toList();
  }

  /// Per-currency sums for a day. If [type] is null → whole-day, else filtered by tab.
  Map<String, double> totalsForDay(DateTime day, {TransactionType? type}) {
    final list = type == null
        ? transactionsForDay(day)
        : transactionsForDayAndType(day, type);
    final map = <String, double>{};
    for (final t in list) {
      map[t.currency] =
          (map[t.currency] ?? 0) +
          (t.type == TransactionType.income ? t.amount : -t.amount);
    }
    return map;
  }
}
