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
    final netColor = totals.net >= 0 ? pal.income : pal.expense;

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
          // Hero: the one number that matters most.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${totals.net >= 0 ? '+' : '−'}${formatMoney(totals.net.abs(), currency)}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: netColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currencySymbol(currency),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: pal.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Secondary: income / expense, scannable at a glance.
          Row(
            children: [
              _flow(
                pal,
                Icons.arrow_upward_rounded,
                l10n.income,
                totals.income,
                pal.income,
              ),
              const SizedBox(width: 20),
              _flow(
                pal,
                Icons.arrow_downward_rounded,
                l10n.expense,
                totals.expense,
                pal.expense,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flow(
    AppPalette pal,
    IconData icon,
    String label,
    double amount,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: pal.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          formatMoney(amount, currency),
          style: TextStyle(
            fontSize: 13,
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
            _payeeBarSection(
              pal,
              l10n.expense,
              topExpense,
              pal.expense,
              isExpense: true,
            ),
          ],
          if (topIncome.isNotEmpty) ...[
            const SizedBox(height: 16),
            _payeeBarSection(
              pal,
              l10n.income,
              topIncome,
              pal.income,
              isExpense: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _payeeBarSection(
    AppPalette pal,
    String title,
    List<_PayeeTotal> items,
    Color accentColor, {
    required bool isExpense,
  }) {
    double amountOf(_PayeeTotal p) => isExpense ? p.expenseSum : p.incomeSum;
    Map<String, double> byCurrencyOf(_PayeeTotal p) =>
        isExpense ? p.expenseByCurrency : p.incomeByCurrency;

    final maxAmount = amountOf(items.first);

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
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: pal.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      () {
                        final cur = _dominantCurrency(byCurrencyOf(item));
                        return '${formatMoney(amountOf(item), cur)} ${currencySymbol(cur)}';
                      }(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: pal.text,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: maxAmount > 0 ? amountOf(item) / maxAmount : 0.0,
                    minHeight: 4,
                    backgroundColor: pal.border.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ],
            ),
          ),
      ],
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
