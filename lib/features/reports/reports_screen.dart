import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/currency.dart';
import '../../core/money_format.dart';
import '../../core/motion.dart';
import '../../core/theme/palette.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';
import '../../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static final DateTime _earliest = DateTime(2020, 1);
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      body: SafeArea(
        child: Column(
          children: [
            // Month Switcher Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _month.isAfter(_earliest)
                        ? () => _shift(-1)
                        : null,
                    icon: Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        intl.DateFormat.yMMMM(locale).format(_month),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: pal.text,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _month.isBefore(DateTime(now.year, now.month))
                        ? () => _shift(1)
                        : null,
                    icon: Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: pal.border),

            Expanded(
              child: SignalBuilder(
                builder: (context) {
                  di.reportsController.txDays.value;
                  di.reportsController.groupedByDay.value;

                  final daysInMonth = di.reportsController.txDays.value
                      .where(
                        (d) => d.year == _month.year && d.month == _month.month,
                      )
                      .toList();

                  if (daysInMonth.isEmpty) {
                    return Center(
                      child: Entrance(
                        key: ValueKey(_month),
                        child: Text(
                          l10n.noTransactions,
                          style: TextStyle(color: pal.textMuted),
                        ),
                      ),
                    );
                  }

                  final totals = <String, _CurTotals>{};
                  final payees = <String, _PayeeTotal>{};

                  for (final day in daysInMonth) {
                    for (final e
                        in di.reportsController
                            .totalsForDay(day, type: TransactionType.income)
                            .entries) {
                      totals.putIfAbsent(e.key, _CurTotals.new).income +=
                          e.value;
                    }
                    for (final e
                        in di.reportsController
                            .totalsForDay(day, type: TransactionType.expense)
                            .entries) {
                      totals.putIfAbsent(e.key, _CurTotals.new).expense +=
                          -e.value;
                    }
                    for (final t in di.reportsController.transactionsForDay(
                      day,
                    )) {
                      final name = t.payee?.trim();
                      if (name == null || name.isEmpty) continue;
                      final p = payees.putIfAbsent(
                        name,
                        () => _PayeeTotal(name),
                      );
                      if (t.type == TransactionType.income) {
                        p.incomeByCurrency[t.currency] =
                            (p.incomeByCurrency[t.currency] ?? 0) + t.amount;
                      } else {
                        p.expenseByCurrency[t.currency] =
                            (p.expenseByCurrency[t.currency] ?? 0) + t.amount;
                      }
                    }
                  }

                  final currencies = totals.keys.toList()..sort();
                  final monthLen = DateTime(
                    _month.year,
                    _month.month + 1,
                    0,
                  ).day;

                  List<({double income, double expense})> funBars(String cur) {
                    return [
                      for (var d = 1; d <= monthLen; d++)
                        (
                          income:
                              di.reportsController.totalsForDay(
                                DateTime(_month.year, _month.month, d),
                                type: TransactionType.income,
                              )[cur] ??
                              0,
                          expense:
                              -(di.reportsController.totalsForDay(
                                    DateTime(_month.year, _month.month, d),
                                    type: TransactionType.expense,
                                  )[cur] ??
                                  0),
                        ),
                    ];
                  }

                  final topIncome =
                      payees.values.where((p) => p.incomeSum > 0).toList()
                        ..sort((a, b) => b.incomeSum.compareTo(a.incomeSum));
                  final topExpense =
                      payees.values.where((p) => p.expenseSum > 0).toList()
                        ..sort((a, b) => b.expenseSum.compareTo(a.expenseSum));

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      for (final cur in currencies)
                        Entrance(
                          key: ValueKey('totals-$cur'),
                          child: _ModernTotalsCard(
                            currency: cur,
                            totals: totals[cur]!,
                            bars: funBars(cur),
                          ),
                        ),
                      if (topExpense.isNotEmpty || topIncome.isNotEmpty)
                        Entrance(
                          key: const ValueKey('payees'),
                          delay: kMotionStagger * 2,
                          child: _VisualPayeesCard(
                            topIncome: topIncome.take(4).toList(),
                            topExpense: topExpense.take(4).toList(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Currency Totals & Trend Card ─────────────────────────────────────────────

class _ModernTotalsCard extends StatelessWidget {
  const _ModernTotalsCard({
    required this.currency,
    required this.totals,
    required this.bars,
  });

  final String currency;
  final _CurTotals totals;
  final List<({double income, double expense})> bars;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);
    final totalTurnover = totals.income + totals.expense;
    final incomeRatio = totalTurnover > 0
        ? (totals.income / totalTurnover)
        : 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.surfaceHigh,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currency,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: pal.text,
                ),
              ),
              Text(
                '${totals.net >= 0 ? '+' : ''}${formatMoney(totals.net, currency)} ${currencySymbol(currency)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: totals.net >= 0 ? pal.income : pal.expense,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Savings / Flow Distribution Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (incomeRatio * 100).toInt(),
                    child: Container(color: pal.income),
                  ),
                  Expanded(
                    flex: ((1 - incomeRatio) * 100).toInt(),
                    child: Container(color: pal.expense),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric(
                l10n.income,
                '+${formatMoney(totals.income, currency)}',
                pal.income,
              ),
              _metric(
                l10n.expense,
                '-${formatMoney(totals.expense, currency)}',
                pal.expense,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Bars
          _DailyBars(
            bars: bars,
            semanticsLabel: '${l10n.income} / ${l10n.expense} $currency',
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ── Payees with Visual Progress Bars ─────────────────────────────────────────

class _VisualPayeesCard extends StatelessWidget {
  const _VisualPayeesCard({required this.topIncome, required this.topExpense});

  final List<_PayeeTotal> topIncome;
  final List<_PayeeTotal> topExpense;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.surfaceHigh,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.topPayees,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: pal.text,
            ),
          ),
          if (topExpense.isNotEmpty) ...[
            const SizedBox(height: 12),
            _payeeBarSection(context, l10n.expense, topExpense, pal.expense),
          ],
          if (topIncome.isNotEmpty) ...[
            const SizedBox(height: 16),
            _payeeBarSection(context, l10n.income, topIncome, pal.income),
          ],
        ],
      ),
    );
  }

  Widget _payeeBarSection(
    BuildContext context,
    String title,
    List<_PayeeTotal> items,
    Color accentColor,
  ) {
    final pal = context.pal;
    final maxAmount = items.first.expenseSum > 0
        ? items.first.expenseSum
        : items.first.incomeSum;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 6),
        for (final item in items) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: pal.text,
                      ),
                    ),
                    Text(
                      item.expenseSum > 0
                          ? formatMoney(
                              item.expenseSum,
                              _dominantCurrency(item.expenseByCurrency),
                            )
                          : formatMoney(
                              item.incomeSum,
                              _dominantCurrency(item.incomeByCurrency),
                            ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: maxAmount > 0
                        ? ((item.expenseSum > 0
                                  ? item.expenseSum
                                  : item.incomeSum) /
                              maxAmount)
                        : 0.0,
                    minHeight: 4,
                    backgroundColor: pal.border.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Daily Trend Bars ─────────────────────────────────────────────────────────

class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.bars, required this.semanticsLabel});

  final List<({double income, double expense})> bars;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    var max = 0.0;
    for (final b in bars) {
      if (b.income > max) max = b.income;
      if (b.expense > max) max = b.expense;
    }
    if (max <= 0) return const SizedBox.shrink();
    const sideH = 28.0;

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: sideH * 2 + 2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final b in bars)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    children: [
                      SizedBox(
                        height: sideH,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: (b.income / max) * sideH,
                            decoration: BoxDecoration(
                              color: pal.income,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(height: 1.5, color: pal.border),
                      SizedBox(
                        height: sideH,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: (b.expense / max) * sideH,
                            decoration: BoxDecoration(
                              color: pal.expense,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CurTotals {
  double income = 0;
  double expense = 0;
  double get net => income - expense;
}

class _PayeeTotal {
  _PayeeTotal(this.name);

  final String name;
  final Map<String, double> incomeByCurrency = {};
  final Map<String, double> expenseByCurrency = {};

  double get incomeSum => incomeByCurrency.values.fold(0.0, (a, v) => a + v);
  double get expenseSum => expenseByCurrency.values.fold(0.0, (a, v) => a + v);
}

/// The payee sums above fold across currencies; format them by whichever
/// currency contributes the most (exact in the common single-currency case).
String _dominantCurrency(Map<String, double> byCurrency) {
  var best = '';
  var bestAbs = -1.0;
  byCurrency.forEach((currency, value) {
    if (value.abs() > bestAbs) {
      bestAbs = value.abs();
      best = currency;
    }
  });
  return best;
}
