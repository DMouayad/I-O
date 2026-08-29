import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';
import '../../models/transaction_model.dart';

/// Reports — monthly aggregate: totals per currency + top payees.
/// Read-only; browsing and deleting live in Journal / the day screen.
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
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      body: SafeArea(
        child: Column(
          children: [
            // Month switcher — pinned, always reachable.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _month.isAfter(_earliest)
                        ? () => _shift(-1)
                        : null,
                    icon: Icon(ltr ? Icons.chevron_left : Icons.chevron_right),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        intl.DateFormat.yMMMM(locale).format(_month),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _month.isBefore(DateTime(now.year, now.month))
                        ? () => _shift(1)
                        : null,
                    icon: Icon(ltr ? Icons.chevron_right : Icons.chevron_left),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SignalBuilder(
                builder: (context) {
                  // Signal dependencies — recompute on tx changes.
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
                        child: Text(
                          l10n.noTransactions,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: kInkMuted),
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
                          e.value;
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
                      final net = p.netByCurrency[t.currency] ?? 0;
                      p.netByCurrency[t.currency] =
                          net +
                          (t.type == TransactionType.income
                              ? t.amount
                              : -t.amount);
                    }
                  }

                  final currencies = totals.keys.toList()..sort();
                  final ranked = payees.values.toList()
                    ..sort((a, b) => b.magnitude.compareTo(a.magnitude));

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (final cur in currencies)
                        Entrance(child: _totalsCard(l10n, cur, totals[cur]!)),
                      if (ranked.isNotEmpty)
                        Entrance(
                          delay: kMotionStagger * 2,
                          child: _payeesCard(l10n, ranked.take(5).toList()),
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

  Widget _totalsCard(AppLocalizations l10n, String currency, _CurTotals t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currency,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: kInkSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _stat(l10n.income, t.income, kIncome)),
                Expanded(child: _stat(l10n.expense, t.expense, kExpense)),
                Expanded(
                  child: _stat(
                    l10n.balance,
                    t.net,
                    t.net >= 0 ? kInk : kExpense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, double value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: kInkSecondary,
        ),
      ),
      const SizedBox(height: 4),
      CountUpText(
        value: value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );

  Widget _payeesCard(AppLocalizations l10n, List<_PayeeTotal> top) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.topPayees,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: kInkSecondary,
              ),
            ),
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        top[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatNet(top[i].netByCurrency),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: top[i].netSum >= 0 ? kIncome : kExpense,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatNet(Map<String, double> net) {
    final keys = net.keys.toList()..sort();
    return [
      for (final k in keys)
        '${net[k]! >= 0 ? '+' : ''}${net[k]!.toStringAsFixed(2)} $k',
    ].join(' · ');
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
  final Map<String, double> netByCurrency = {};

  double get magnitude => netByCurrency.values.fold(0.0, (a, v) => a + v.abs());
  double get netSum => netByCurrency.values.fold(0.0, (a, v) => a + v);
}
