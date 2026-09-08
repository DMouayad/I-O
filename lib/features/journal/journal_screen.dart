import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:io/core/widgets/signed_money_text.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/date_utils.dart';
import '../../core/money_format.dart';
import '../../core/theme/palette.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';
import '../../models/transaction_model.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _calendarExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pal = context.pal;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journal),
        actions: [
          IconButton(
            tooltip: _calendarExpanded
                ? l10n.collapseCalendar
                : l10n.expandCalendar,
            icon: Icon(
              _calendarExpanded
                  ? Icons.calendar_today_outlined
                  : Icons.calendar_month_outlined,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _calendarExpanded = !_calendarExpanded),
          ),
        ],
      ),
      body: SignalBuilder(
        dependencies: [
          di.reportsController.txDays,
          di.reportsController.groupedByDay,
        ],
        builder: (_) {
          final today = dateOnly(DateTime.now());
          final activeDays = di.reportsController.txDays.value
              .map(dateOnly)
              .toSet();

          // Today is always listed at the top, even with no transactions yet.
          final days = {...activeDays, today}.toList()
            ..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              if (_calendarExpanded) ...[
                _MonthCalendar(
                  month: _month,
                  activeDays: activeDays,
                  today: today,
                  onMonthChanged: (m) => setState(() => _month = m),
                  onDaySelected: (d) => context.push('/day/${isoDate(d)}'),
                ),
                Divider(height: 1, thickness: 1, color: pal.border),
              ],
              Expanded(
                child: _DayList(
                  days: days,
                  today: today,
                  showEmptyHint: activeDays.isEmpty,
                  onTapDay: (d) => context.push('/day/${isoDate(d)}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Calendar with colored day status ────────────────────────────────────────

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.activeDays,
    required this.today,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  final DateTime month;
  final Set<DateTime> activeDays;
  final DateTime today;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  /// Weekday abbreviation for grid column [i] (0-based, left to right),
  /// given the locale's first-day-of-week convention.
  ///
  /// [firstDayOfWeekIndex] follows Flutter's convention: 0 = Sunday,
  /// 1 = Monday, ... 6 = Saturday. Jan 1, 2023 was a Sunday, so it's used
  /// as a stable reference point instead of juggling [DateTime.weekday]'s
  /// Monday-first numbering.
  String _weekdayLabel(String locale, int firstDayOfWeekIndex, int i) {
    final offsetFromSunday = (firstDayOfWeekIndex + i) % 7;
    final reference = DateTime(2023, 1, 1 + offsetFromSunday);
    return intl.DateFormat.E(locale).format(reference);
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final locale = Localizations.localeOf(context).languageCode;

    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfWeek = MaterialLocalizations.of(
      context,
    ).firstDayOfWeekIndex;
    final leading = (first.weekday - firstDayOfWeek + 7) % 7;
    final rows = (leading + daysInMonth + 6) ~/ 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                iconSize: 20,
                onPressed: () =>
                    onMonthChanged(DateTime(month.year, month.month - 1)),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    intl.DateFormat.yMMMM(locale).format(first),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: pal.text,
                    ),
                  ),
                ),
              ),
              IconButton(
                iconSize: 20,
                onPressed: () =>
                    onMonthChanged(DateTime(month.year, month.month + 1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _weekdayLabel(locale, firstDayOfWeek, i),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: pal.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.25,
            ),
            itemCount: rows * 7,
            itemBuilder: (context, i) {
              final dayNumber = i - leading + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }
              final date = DateTime(month.year, month.month, dayNumber);

              Color? statusColor;
              if (activeDays.contains(date)) {
                final totals = di.reportsController.totalsForDay(date);
                statusColor = netTotal(totals) >= 0 ? pal.income : pal.expense;
              }

              return _CalendarCell(
                date: date,
                isToday: date == today,
                statusColor: statusColor,
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
    required this.statusColor,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final Color? statusColor;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    final label = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: isToday
                ? pal.onPrimary
                : (isFuture ? pal.textMuted.withValues(alpha: 0.5) : pal.text),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday
                ? pal.onPrimary
                : (statusColor ?? Colors.transparent),
          ),
        ),
      ],
    );

    final cell = Container(
      margin: const EdgeInsets.all(2),
      decoration: isToday
          ? BoxDecoration(
              color: pal.primary,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Center(child: label),
    );

    if (isFuture) return cell;

    // Both today and past days are tappable.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: cell,
      ),
    );
  }
}

// ── Day list ─────────────────────────────────────────────────────────────────

class _DayList extends StatelessWidget {
  const _DayList({
    required this.days,
    required this.today,
    required this.onTapDay,
    this.showEmptyHint = false,
  });

  final List<DateTime> days;
  final DateTime today;
  final ValueChanged<DateTime> onTapDay;
  final bool showEmptyHint;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: days.length + (showEmptyHint ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (showEmptyHint && index == days.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                AppLocalizations.of(context).noTransactions,
                style: TextStyle(color: context.pal.textMuted),
              ),
            ),
          );
        }

        final day = days[index];
        return day == today
            ? _HeroTodayTile(day: day, onTap: () => onTapDay(day))
            : _DayRow(day: day, onTap: () => onTapDay(day));
      },
    );
  }
}

// ── Hero "Today" tile ─────────────────────────────────────────────────────────

class _HeroTodayTile extends StatelessWidget {
  const _HeroTodayTile({required this.day, required this.onTap});

  final DateTime day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    final txList = di.reportsController.transactionsForDay(day);

    // Both already carry the correct sign: income >= 0, expense <= 0.
    final incomeTotals = di.reportsController.totalsForDay(
      day,
      type: TransactionType.income,
    );
    final expenseTotals = di.reportsController.totalsForDay(
      day,
      type: TransactionType.expense,
    );

    final balanceTotals = <String, double>{
      for (final cur in {...incomeTotals.keys, ...expenseTotals.keys})
        cur: (incomeTotals[cur] ?? 0) + (expenseTotals[cur] ?? 0),
    };

    return Material(
      color: pal.surfaceHigh,
      borderRadius: BorderRadius.circular(kRadius + 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius + 2),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius + 2),
            border: Border.all(
              color: pal.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: pal.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.today.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: pal.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        intl.DateFormat.MMMd(locale).format(day),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: pal.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SignedMoneyText(
                        balanceTotals,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: pal.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        positiveColor: pal.income,
                        negativeColor: pal.expense,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: pal.textMuted),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (txList.isEmpty)
                Text(
                  l10n.tapToRecordToday,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pal.primary,
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '+${netTotal(incomeTotals)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: pal.income,
                      ),
                    ),
                    Text('  ·  ', style: TextStyle(color: pal.border)),
                    Text(
                      netTotal(expenseTotals).toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: pal.expense,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Standard past-day row ────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.onTap});

  final DateTime day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final label = intl.DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(day);

    final txCount = di.reportsController.transactionsForDay(day).length;
    final totals = di.reportsController.totalsForDay(
      day,
    ); // net, already signed

    return Material(
      color: pal.surfaceHigh,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: pal.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: pal.text,
                      ),
                    ),
                    if (txCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: pal.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: pal.border),
                        ),
                        child: Text(
                          '$txCount',
                          style: TextStyle(
                            fontSize: 11,
                            color: pal.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SignedMoneyText(
                totals,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: pal.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                positiveColor: pal.income,
                negativeColor: pal.expense,
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: pal.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
