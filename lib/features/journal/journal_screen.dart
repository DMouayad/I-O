import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';

/// Journal — the entry home: pick a day from the calendar or the list,
/// the day screen holds the pinned entry bar.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.journal)),
      body: SignalBuilder(
        builder: (context) {
          final txDays = di.reportsController.txDays.value;
          di.reportsController.groupedByDay.value; // signal dependency
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final defaultCurrency =
              di.settingsController.settings.value.defaultCurrency;

          final activeDays = txDays
              .map((d) => DateTime(d.year, d.month, d.day))
              .toSet();
          // Today always listed (even empty) + days with entries, newest first.
          final days = {...activeDays, today}.toList()
            ..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              _MonthCalendar(
                month: _month,
                activeDays: activeDays,
                onMonthChanged: (m) => setState(() => _month = m),
                onDaySelected: (d) => context.push('/day/${_isoDate(d)}'),
              ),
              const Divider(),
              Expanded(
                child: _DayList(
                  days: days,
                  defaultCurrency: defaultCurrency,
                  showEmptyHint: activeDays.isEmpty,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Month calendar ────────────────────────────────────────────────────────

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.activeDays,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  final DateTime month;
  final Set<DateTime> activeDays;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Column of the 1st, given the locale's week start.
    final firstDayOfWeek = MaterialLocalizations.of(
      context,
    ).firstDayOfWeekIndex;
    final leading = (first.weekday - firstDayOfWeek + 7) % 7;
    final rows = (leading + daysInMonth + 6) ~/ 7;

    final earliest = DateTime(2020, 1);
    final latest = DateTime(now.year, now.month);
    final canGoBack = first.isAfter(earliest);
    final canGoForward = first.isBefore(latest);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: canGoBack
                    ? () =>
                          onMonthChanged(DateTime(month.year, month.month - 1))
                    : null,
                icon: Icon(ltr ? Icons.chevron_left : Icons.chevron_right),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    intl.DateFormat.yMMMM(locale).format(first),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kInk,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: canGoForward
                    ? () =>
                          onMonthChanged(DateTime(month.year, month.month + 1))
                    : null,
                icon: Icon(ltr ? Icons.chevron_right : Icons.chevron_left),
              ),
            ],
          ),
          // Weekday initials — Jan 2023 starts on a Sunday, so the 1st + N
          // maps weekday numbers to labels without locale-table fiddling.
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      intl.DateFormat.E(locale).format(
                        DateTime(2023, 1, 1 + (((i + firstDayOfWeek - 1) % 7))),
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kInkMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: rows * 7,
            itemBuilder: (context, i) {
              final dayNumber = i - leading + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }
              final date = DateTime(month.year, month.month, dayNumber);
              return _CalendarCell(
                date: date,
                isToday: date == today,
                hasEntries: activeDays.contains(date),
                isFuture: date.isAfter(today),
                onTap: () => onDaySelected(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.date,
    required this.isToday,
    required this.hasEntries,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool hasEntries;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = Text(
      '${date.day}',
      style: TextStyle(
        fontSize: 13,
        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
        color: isToday ? Colors.white : (isFuture ? kInkMuted : kInk),
      ),
    );

    // Square marker (not a dot) — the design language.
    final marker = Container(
      width: 4,
      height: 4,
      color: isToday ? Colors.white : kInk,
    );

    final cell = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        number,
        const SizedBox(height: 3),
        hasEntries ? marker : const SizedBox(height: 4),
      ],
    );

    if (isToday) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kInk,
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Center(child: cell),
      );
    }
    if (isFuture) return Center(child: cell); // not tappable
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadius),
      child: Center(child: cell),
    );
  }
}

// ── Day list ──────────────────────────────────────────────────────────────

class _DayList extends StatelessWidget {
  const _DayList({
    required this.days,
    required this.defaultCurrency,
    this.showEmptyHint = false,
  });

  final List<DateTime> days;
  final String defaultCurrency;
  final bool showEmptyHint;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: days.length + (showEmptyHint ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (showEmptyHint && index == days.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              AppLocalizations.of(context).noTransactions,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: kInkMuted),
            ),
          );
        }
        return _DayRow(day: days[index], defaultCurrency: defaultCurrency);
      },
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.defaultCurrency});

  final DateTime day;
  final String defaultCurrency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday =
        day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final label = isToday
        ? l10n.today
        : intl.DateFormat.yMMMd(
            Localizations.localeOf(context).languageCode,
          ).format(day);

    final totals = di.reportsController.totalsForDay(day);
    final balanceText = _formatBalance(totals, defaultCurrency);
    final isPositive = totals.values.fold(0.0, (a, b) => a + b) >= 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: () => context.push(
          '/day/${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}',
        ),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: kBorder, width: 1),
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kInk,
                    ),
                  ),
                ),
                Text(
                  balanceText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? kIncome : kExpense,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 18, color: kInkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatBalance(Map<String, double> totals, String fallback) {
    if (totals.isEmpty) return '+0.00 $fallback';
    final keys = totals.keys.toList()..sort();
    return [
      for (final cur in keys)
        '${totals[cur]! >= 0 ? '+' : ''}${totals[cur]!.toStringAsFixed(2)} $cur',
    ].join(' · ');
  }
}
