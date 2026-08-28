import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:io/core/theme/app_theme.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/motion.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';
import '../../models/transaction_model.dart';
import '../../state/reports_controller.dart';
import 'transaction_tile.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, this.controller});
  final ReportsController? controller;

  ReportsController get _c => controller ?? di.reportsController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      body: SignalBuilder(
        builder: (context) {
          final totals = _c.totalsByCurrency.value;
          final list = _c.filtered.value;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildRangeSelector(context)),
              SliverToBoxAdapter(child: _buildTotals(context, totals)),
              if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(label: l10n.noTransactions),
                )
              else
                _buildList(context, list),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRangeSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SignalBuilder(
        builder: (context) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<ReportRangeType>(
            segments: [
              ButtonSegment(
                value: ReportRangeType.today,
                label: Text(l10n.today),
              ),
              ButtonSegment(
                value: ReportRangeType.thisWeek,
                label: Text(l10n.thisWeek),
              ),
              ButtonSegment(
                value: ReportRangeType.thisMonth,
                label: Text(l10n.thisMonth),
              ),
              ButtonSegment(value: ReportRangeType.all, label: Text(l10n.all)),
            ],
            selected: {_c.rangeType.value},
            onSelectionChanged: (s) => _c.rangeType.value = s.first,
          ),
        ),
      ),
    );
  }

  // ── Totals: balance is the headline, income/expense secondary ────────
  Widget _buildTotals(
    BuildContext context,
    Map<String, CurrencyTotals> totals,
  ) {
    final l10n = AppLocalizations.of(context);
    if (totals.isEmpty) return const SizedBox.shrink();
    return Column(
      children: totals.entries.map((e) {
        final t = e.value;
        return Entrance(
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: kInkSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.balance,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kInkSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CountUpText(
                    value: t.balance,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: t.balance >= 0 ? kInk : kExpense,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(thickness: 1, height: 1, color: kBorder),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _stat(l10n.totalIncome, t.income, kIncome),
                      ),
                      Expanded(
                        child: _stat(l10n.totalExpense, t.expense, kExpense),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _stat(String label, double value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kInkSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      CountUpText(
        value: value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );

  // ── Grouped list: day headers + boxed tiles ───────────────────────────
  Widget _buildList(BuildContext context, List<TransactionModel> list) {
    // Assumes the controller returns newest-first; groups stay in order.
    final groups = <_DayGroup>[];
    for (final t in list) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (groups.isNotEmpty && groups.last.day == day) {
        groups.last.transactions.add(t);
      } else {
        groups.add(_DayGroup(day)..transactions.add(t));
      }
    }

    final items = <_ListItem>[];
    for (final g in groups) {
      items.add(
        _ListItem(
          ValueKey('day-${g.day.toIso8601String()}'),
          _DayHeader(day: g.day),
        ),
      );
      for (final t in g.transactions) {
        items.add(
          _ListItem(
            ValueKey(t.id),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TransactionTile(
                transaction: t,
                onDelete: () => di.transactionsController.remove(t.id!),
              ),
            ),
          ),
        );
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => Entrance(
            key: items[i].key,
            // Stagger roughly the first screenful only.
            delay: i < 8 ? kMotionStagger * i : Duration.zero,
            child: items[i].child,
          ),
          childCount: items.length,
          // Key-based matching keeps entrance states across rebuilds:
          // single delete = no replay; range switch = full replay.
          findChildIndexCallback: (key) {
            final i = items.indexWhere((e) => e.key == key);
            return i < 0 ? null : i;
          },
        ),
      ),
    );
  }
}

class _DayGroup {
  _DayGroup(this.day);

  final DateTime day;
  final List<TransactionModel> transactions = [];
}

class _ListItem {
  const _ListItem(this.key, this.child);

  final Key key;
  final Widget child;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final label = isToday
        ? l10n.today
        : DateFormat.yMMMd(
            Localizations.localeOf(context).languageCode,
          ).format(day);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kInkSecondary,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(thickness: 1, height: 1, color: kBorder),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: kBorder),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 26,
                color: kInkMuted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: kInkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
