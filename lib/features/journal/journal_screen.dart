import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:io/core/widgets/signed_money_text.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/currency.dart';
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
            onPressed: () => setState(() {
              _calendarExpanded = !_calendarExpanded;
              if (_calendarExpanded) {
                // The stored month goes stale while the calendar is hidden —
                // reopen on the newest active month so it matches the list.
                final txDays = di.reportsController.txDays.value;
                final anchor = txDays.isEmpty
                    ? dateOnly(DateTime.now())
                    : txDays.first;
                _month = DateTime(anchor.year, anchor.month);
              }
            }),
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

/// Groups sorted-desc days into per-month sections, preserving order.
/// Pure (no widgets) so it can be unit-tested directly.
List<({DateTime month, List<DateTime> days})> groupDaysByMonth(
  List<DateTime> days,
) {
  final groups = <({DateTime month, List<DateTime> days})>[];
  for (final d in days) {
    final month = DateTime(d.year, d.month);
    if (groups.isEmpty || groups.last.month != month) {
      groups.add((month: month, days: [d]));
    } else {
      groups.last.days.add(d);
    }
  }
  return groups;
}

class _DayList extends StatefulWidget {
  const _DayList({
    required this.days,
    required this.today,
    required this.onTapDay,
  });

  /// Always non-empty: the caller includes today even with no transactions.
  final List<DateTime> days;
  final DateTime today;
  final ValueChanged<DateTime> onTapDay;

  @override
  State<_DayList> createState() => _DayListState();
}

class _DayListState extends State<_DayList> {
  final _listKey = GlobalKey();
  final _headerKeys = <DateTime, GlobalKey>{};
  DateTime? _visibleMonth;

  @override
  Widget build(BuildContext context) {
    if (widget.days.isEmpty) return const SizedBox.shrink();
    final groups = groupDaysByMonth(widget.days);
    _headerKeys.removeWhere((month, _) => !groups.any((g) => g.month == month));
    for (final g in groups) {
      _headerKeys.putIfAbsent(g.month, GlobalKey.new);
    }
    final visible = _visibleMonth;
    if (visible == null || !_headerKeys.containsKey(visible)) {
      _visibleMonth = groups.first.month;
    }
    // Re-sync after layout settles (e.g. new transactions shifted rows).
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMonth(groups));

    return Column(
      children: [
        // The one and only pinned header: shows the month at the top of
        // the viewport. Inline labels below scroll away normally.
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: _MonthLabel(month: _visibleMonth!),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.depth == 0 &&
                  (n is ScrollUpdateNotification ||
                      n is ScrollEndNotification)) {
                _syncMonth(groups);
              }
              return false;
            },
            child: CustomScrollView(
              key: _listKey,
              slivers: [
                for (var i = 0; i < groups.length; i++) ...[
                  // No inline label for the top group: it would sit directly
                  // under the fixed header showing the same month.
                  if (i > 0)
                    SliverToBoxAdapter(
                      child: Container(
                        key: _headerKeys[groups[i].month],
                        child: _MonthLabel(month: groups[i].month),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    sliver: SliverList.separated(
                      itemCount: groups[i].days.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final day = groups[i].days[index];
                        return day == widget.today
                            ? _HeroTodayTile(
                                day: day,
                                onTap: () => widget.onTapDay(day),
                              )
                            : _DayRow(
                                day: day,
                                onTap: () => widget.onTapDay(day),
                              );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Points [_visibleMonth] at the last month whose inline header has fully
  /// slid under the fixed header. Waiting for the full height (instead of
  /// first touch) means the fixed header never shows the same month as a
  /// still-visible inline label. No-ops (no rebuild) when unchanged.
  void _syncMonth(List<({DateTime month, List<DateTime> days})> groups) {
    if (!mounted || groups.isEmpty) return;
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null || !listBox.attached) return;
    final top = listBox.localToGlobal(Offset.zero).dy;
    var current = groups.first.month;
    for (final g in groups) {
      final box =
          _headerKeys[g.month]?.currentContext?.findRenderObject()
              as RenderBox?;
      // No box for the top group (its inline label is omitted) or not
      // laid out yet — neither affects the outcome.
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy + box.size.height <= top + 1) {
        current = g.month;
      } else {
        break;
      }
    }
    if (current != _visibleMonth) {
      setState(() => _visibleMonth = current);
    }
  }
}

// ── Month label (fixed header + inline) ───────────────────────────────────────

class _MonthLabel extends StatelessWidget {
  const _MonthLabel({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final locale = Localizations.localeOf(context).languageCode;
    final label = intl.DateFormat.yMMMM(locale).format(month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            locale == 'ar' ? label : label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: .center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: locale == 'ar' ? null : 0.6,
              color: pal.textMuted,
            ),
          ),
        ],
      ),
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
                        multiline: true,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        textAlign: TextAlign.right,
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
                _IncomeExpenseBreakdown(
                  incomeTotals: incomeTotals,
                  expenseTotals: expenseTotals,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Per-currency income/expense breakdown ────────────────────────────────────

/// Right-aligned compact breakdown for the hero tile: one row per currency
/// pairing that day's income and expense (`+X CUR · −Y CUR`), omitting the
/// side a currency has no transactions on. Single-currency days render a
/// single row, matching the old one-line look (now with currency symbols —
/// the previous `netTotal` sums were wrong for multi-currency days).
class _IncomeExpenseBreakdown extends StatelessWidget {
  const _IncomeExpenseBreakdown({
    required this.incomeTotals,
    required this.expenseTotals,
  });

  final Map<String, double> incomeTotals;
  final Map<String, double> expenseTotals;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final incomeStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: pal.income,
      height: 1.15,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final expenseStyle = incomeStyle.copyWith(color: pal.expense);
    final separatorStyle = TextStyle(
      fontSize: 12,
      height: 1.15,
      color: pal.border,
    );

    final entries = <String, ({double income, double expense})>{
      for (final cur in {...incomeTotals.keys, ...expenseTotals.keys})
        cur: (income: incomeTotals[cur] ?? 0, expense: expenseTotals[cur] ?? 0),
    }.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    entries.removeWhere((e) => e.value.income == 0 && e.value.expense == 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 1),
          Text.rich(
            TextSpan(
              children: [
                if (entries[i].value.income != 0)
                  TextSpan(
                    text:
                        '+${formatMoney(entries[i].value.income, entries[i].key)} '
                        '${currencySymbol(entries[i].key)}',
                    style: incomeStyle,
                  ),
                if (entries[i].value.income != 0 &&
                    entries[i].value.expense != 0)
                  TextSpan(text: '  ·  ', style: separatorStyle),
                if (entries[i].value.expense != 0)
                  TextSpan(
                    text:
                        '−${formatMoney(entries[i].value.expense.abs(), entries[i].key)} '
                        '${currencySymbol(entries[i].key)}',
                    style: expenseStyle,
                  ),
              ],
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
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
    final label = intl.DateFormat.MEd(
      Localizations.localeOf(context).languageCode,
    ).format(day);

    final totals = di.reportsController.totalsForDay(
      day,
    ); // net, already signed

    return Semantics(
      button: true,
      label: '$label, ${formatMoneyMap(totals)}',
      child: Material(
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
                    ],
                  ),
                ),
                SignedMoneyText(
                  totals,
                  multiline: true,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textAlign: TextAlign.right,
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
      ),
    );
  }
}
