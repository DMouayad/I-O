import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' as semantics;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/currency.dart';
import '../../core/date_utils.dart';
import '../../core/money_format.dart';
import '../../core/theme/palette.dart';
import '../../core/toast.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';
import '../../models/transaction_model.dart';
import 'currency_picker.dart';
import 'edit_sheet.dart';
import 'payee_field.dart';

/// Tabs are fixed to these two types, in this order. Kept as an explicit
/// list (rather than `TransactionType.values`) so the UI doesn't silently
/// break if the model ever grows more transaction types.
const _tabTypes = [TransactionType.income, TransactionType.expense];

class DayScreen extends StatefulWidget {
  const DayScreen({super.key, required this.day});

  final DateTime day;

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen>
    with SingleTickerProviderStateMixin {
  late final DateTime _day = widget.day;
  late final TabController _tabController = TabController(
    length: _tabTypes.length,
    vsync: this,
  );

  TransactionType get _currentType => _tabTypes[_tabController.index];

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addTransaction(
    double amount,
    String currency,
    String? payee,
  ) async {
    final now = DateTime.now();
    final transaction = TransactionModel(
      type: _currentType,
      amount: amount,
      currency: currency,
      payee: payee,
      date: DateTime(_day.year, _day.month, _day.day, now.hour, now.minute),
      createdAt: now,
    );

    try {
      final id = await di.transactionsController.add(transaction);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      showTopToast(
        context,
        message: l10n.savedWithAmount(
          '${formatMoney(amount, currency)} ${currencySymbol(currency)}',
        ),
        actionLabel: l10n.undo,
        onAction: () => di.transactionsController.remove(id),
      );
    } catch (_) {
      // Swallow: the entry bar keeps its values so the user can retry.
      // (Wire this up to your error reporting / a toast if desired.)
    }
  }

  void _showDeletedToast(TransactionModel t) {
    final l10n = AppLocalizations.of(context);
    showTopToast(
      context,
      message: l10n.deletedWithAmount(
        '${formatMoney(t.amount, t.currency)} ${t.currency}',
      ),
      actionLabel: l10n.undo,
      onAction: () => di.transactionsController.add(t),
    );
  }

  void _openEditSheet(TransactionModel t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: EditSheet(transaction: t, onDeleted: _showDeletedToast),
      ),
    );
  }

  /// Bulk delete: one icon → confirm dialog with scope choice (current tab
  /// pre-selected) → toast with Undo. Scope `null` means the whole day.
  Future<void> _confirmDeleteDay() async {
    final initialType = _currentType;
    final incomeCount = di.reportsController
        .transactionsForDayAndType(_day, TransactionType.income)
        .length;
    final expenseCount = di.reportsController
        .transactionsForDayAndType(_day, TransactionType.expense)
        .length;
    final dayCount = incomeCount + expenseCount;
    if (dayCount == 0 || !mounted) return;

    final tabCount = initialType == TransactionType.income
        ? incomeCount
        : expenseCount;
    final result = await showDialog<({bool confirmed, TransactionType? scope})>(
      context: context,
      builder: (ctx) => _DeleteDayDialog(
        initialScope: tabCount > 0 ? initialType : null,
        incomeCount: incomeCount,
        expenseCount: expenseCount,
        dayCount: dayCount,
      ),
    );
    if (result?.confirmed != true || !mounted) return;

    final snapshot = await di.transactionsController.removeDay(
      _day,
      type: result!.scope,
    );
    if (!mounted || snapshot.isEmpty) return;
    final captured = List<TransactionModel>.of(snapshot);
    final l10n = AppLocalizations.of(context);
    showTopToast(
      context,
      message: l10n.deletedCount(captured.length),
      actionLabel: l10n.undo,
      onAction: () {
        di.transactionsController.restoreAll(captured);
      },
    );
  }

  ({Map<String, double> income, Map<String, double> expense}) _dayTotals() {
    final income = di.reportsController.totalsForDay(
      _day,
      type: TransactionType.income,
    );
    final expense = di.reportsController.totalsForDay(
      _day,
      type: TransactionType.expense,
    );
    return (
      income: {
        for (final e in income.entries)
          if (e.value != 0) e.key: e.value,
      },
      expense: {
        for (final e in expense.entries)
          if (e.value != 0) e.key: -e.value,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    // The whole Scaffold rebuilds on groupedByDay changes: Scaffold fixes
    // the app bar height from `bottom.preferredSize` when the AppBar is
    // constructed, so the AppBar itself must be rebuilt (with the matching
    // summary height) whenever the day's totals change. Entry-bar and tab
    // state live in child States, so this rebuild doesn't lose input.
    return SignalBuilder(
      dependencies: [di.reportsController.groupedByDay],
      builder: (_) {
        final totals = _dayTotals();
        final rows = _summaryRowCount(totals.income, totals.expense);
        final dayTxCount = di.reportsController.transactionsForDay(_day).length;
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: pal.surfaceHigh,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              DateFormat.yMEd(locale).format(_day),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: pal.text,
              ),
            ),
            actions: [
              IconButton(
                tooltip: l10n.swapTitle,
                icon: const Icon(Icons.currency_exchange, size: 20),
                onPressed: () => context.push('/day/${isoDate(_day)}/swap'),
              ),
              IconButton(
                tooltip: l10n.deleteDay,
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: dayTxCount == 0 ? null : _confirmDeleteDay,
              ),
            ],
            // Extends the AppBar's own Material surface downward so the title
            // row and the day summary read as a single header block. Height
            // grows with the tallest per-currency column (one row per
            // currency, ~18px each) so multi-currency days stack compactly
            // instead of squeezing into a single line.
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(42 + (rows - 1) * 18),
              child: _DaySummaryStrip(
                income: totals.income,
                expense: totals.expense,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _TypeTabBar(controller: _tabController),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      for (final type in _tabTypes)
                        _DayTransactionList(
                          day: _day,
                          type: type,
                          onTapTransaction: _openEditSheet,
                          onDeleted: _showDeletedToast,
                        ),
                    ],
                  ),
                ),
                _CompactEntryBar(
                  tabController: _tabController,
                  onAdd: _addTransaction,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tallest per-currency column (income / expense / net balance), at
  /// least 1. Mirrors the balance filtering in [_DaySummaryStrip].
  int _summaryRowCount(
    Map<String, double> income,
    Map<String, double> expense,
  ) {
    var rows = 1;
    if (income.length > rows) rows = income.length;
    if (expense.length > rows) rows = expense.length;
    var balanceRows = 0;
    for (final cur in {...income.keys, ...expense.keys}) {
      if ((income[cur] ?? 0) - (expense[cur] ?? 0) != 0) balanceRows++;
    }
    if (balanceRows > rows) rows = balanceRows;
    return rows;
  }
}

class _DeleteDayDialog extends StatefulWidget {
  const _DeleteDayDialog({
    required this.initialScope,
    required this.incomeCount,
    required this.expenseCount,
    required this.dayCount,
  });

  /// Pre-selected scope: the current tab, or `null` (whole day) when the
  /// current tab is empty. `null` scope always means the whole day.
  final TransactionType? initialScope;
  final int incomeCount;
  final int expenseCount;
  final int dayCount;

  @override
  State<_DeleteDayDialog> createState() => _DeleteDayDialogState();
}

class _DeleteDayDialogState extends State<_DeleteDayDialog> {
  late TransactionType? _scope = widget.initialScope;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.deleteDayTitle),
      // contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SegmentedButton<TransactionType?>(
        segments: [
          ButtonSegment(
            value: TransactionType.income,
            enabled: widget.incomeCount > 0,
            label: Text('${l10n.income} (${widget.incomeCount})'),
          ),
          ButtonSegment(
            value: TransactionType.expense,
            enabled: widget.expenseCount > 0,
            label: Text('${l10n.expense} (${widget.expenseCount})'),
          ),
          ButtonSegment(
            value: null,
            label: Text('${l10n.deleteScopeDay} (${widget.dayCount})'),
          ),
        ],
        selected: {_scope},
        onSelectionChanged: (s) => setState(() => _scope = s.first),
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(visualDensity: VisualDensity.standard),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop((confirmed: false, scope: _scope)),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: pal.expense,
            foregroundColor: pal.onPrimary,
          ),
          onPressed: () =>
              Navigator.of(context).pop((confirmed: true, scope: _scope)),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}

class _TypeTabBar extends StatelessWidget {
  const _TypeTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: pal.border)),
      ),
      child: AnimatedBuilder(
        animation: controller.animation!,
        builder: (context, _) {
          final t = controller.animation!.value.clamp(0.0, 1.0);
          final accent = Color.lerp(pal.income, pal.expense, t)!;
          return TabBar(
            controller: controller,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: accent.withValues(alpha: .10),
              border: Border(bottom: BorderSide(color: accent, width: 2)),
            ),
            labelColor: pal.text,
            unselectedLabelColor: pal.textMuted,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: l10n.income),
              Tab(text: l10n.expense),
            ],
          );
        },
      ),
    );
  }
}

class _DaySummaryStrip extends StatelessWidget {
  const _DaySummaryStrip({required this.income, required this.expense});

  final Map<String, double> income;
  final Map<String, double> expense;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);

    final currencies = {...income.keys, ...expense.keys}.toList()..sort();

    final balance = <String, double>{
      for (final cur in currencies)
        cur: (income[cur] ?? 0) - (expense[cur] ?? 0),
    };

    return Semantics(
      label:
          '${l10n.income} ${formatMoneyMap(income)}. '
          '${l10n.expense} ${formatMoneyMap(expense, signed: false)}. '
          '${l10n.balance} ${formatMoneyMap(balance)}.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: currencies.isEmpty
                  ? [_row(pal, null, 0, 0, multi: false)]
                  : [
                      for (var i = 0; i < currencies.length; i++) ...[
                        if (i > 0) const SizedBox(height: 4),
                        _row(
                          pal,
                          currencies[i],
                          income[currencies[i]] ?? 0,
                          expense[currencies[i]] ?? 0,
                          multi: currencies.length > 1,
                        ),
                      ],
                    ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: pal.border),
        ],
      ),
    );
  }

  /// One row per currency: income / expense / balance cells side by side,
  /// so multi-currency days stay aligned instead of stacking independently
  /// per stat (which broke alignment when currencies differed per stat).
  Widget _row(
    AppPalette pal,
    String? currency,
    double incomeVal,
    double expenseVal, {
    required bool multi,
  }) {
    final fontSize = multi ? 13.0 : 15.0;
    TextStyle style(Color color) => TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.15,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget cell(String text, Color color) => Flexible(
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style(color),
          ),
        ),
      ),
    );

    if (currency == null) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell('0', pal.income),
            _divider(pal),
            cell('0', pal.expense),
            _divider(pal),
            cell('0', pal.text),
          ],
        ),
      );
    }

    final balanceVal = incomeVal - expenseVal;
    final sym = currencySymbol(currency);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cell('+${formatMoney(incomeVal, currency)} $sym', pal.income),
          _divider(pal),
          cell('−${formatMoney(expenseVal, currency)} $sym', pal.expense),
          _divider(pal),
          cell(
            '= ${balanceVal < 0 ? '−' : '+'}${formatMoney(balanceVal.abs(), currency)} $sym',
            pal.text,
          ),
        ],
      ),
    );
  }

  Widget _divider(AppPalette pal) => Container(
    width: 1.5,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: pal.border,
  );
} // ── Transaction list ─────────────────────────────────────────────────────────

class _DayTransactionList extends StatelessWidget {
  const _DayTransactionList({
    required this.day,
    required this.type,
    required this.onTapTransaction,
    required this.onDeleted,
  });

  final DateTime day;
  final TransactionType type;
  final ValueChanged<TransactionModel> onTapTransaction;
  final ValueChanged<TransactionModel> onDeleted;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);

    return SignalBuilder(
      dependencies: [di.reportsController.groupedByDay],
      builder: (_) {
        final list = di.reportsController.transactionsForDayAndType(day, type);

        if (list.isEmpty) {
          return Center(
            child: Text(
              l10n.noTransactions,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: pal.textMuted,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final t = list[i];
            return _CompactTxRow(
              transaction: t,
              onTap: () => onTapTransaction(t),
            );
          },
        );
      },
    );
  }
}

class _CompactTxRow extends StatelessWidget {
  const _CompactTxRow({required this.transaction, required this.onTap});

  final TransactionModel transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? pal.income : pal.expense;
    final payee = transaction.payee?.trim();
    final hasPayee = payee != null && payee.isNotEmpty;

    return Material(
      color: pal.surfaceHigh,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: pal.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasPayee ? payee : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasPayee ? pal.text : pal.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isIncome ? '+' : '-'}${formatMoney(transaction.amount, transaction.currency)} ${currencySymbol(transaction.currency)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compact entry bar ────────────────────────────────────────────────────────

class _CompactEntryBar extends StatefulWidget {
  const _CompactEntryBar({required this.onAdd, required this.tabController});

  final void Function(double amount, String currency, String? payee) onAdd;
  final TabController tabController;

  @override
  State<_CompactEntryBar> createState() => _CompactEntryBarState();
}

class _CompactEntryBarState extends State<_CompactEntryBar> {
  /// Remembers the last picked currency for the lifetime of the app so
  /// switching days doesn't reset it. Encapsulated here rather than as a
  /// top-level global.
  static String? _lastUsedCurrency;

  final _amountCtrl = TextEditingController();
  final _payeeCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _payeeFocus = FocusNode();

  late String _currency =
      _lastUsedCurrency ?? di.settingsController.settings.value.defaultCurrency;

  bool _invalid = false;

  bool get _canSubmit => (parseAmount(_amountCtrl.text) ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    if (_invalid && _canSubmit) {
      setState(() => _invalid = false);
    } else {
      setState(() {}); // refresh submit-button enabled state
    }
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    _payeeCtrl.dispose();
    _amountFocus.dispose();
    _payeeFocus.dispose();
    super.dispose();
  }

  void _add() {
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      HapticFeedback.lightImpact();
      setState(() => _invalid = true);
      semantics.SemanticsService.sendAnnouncement(
        View.of(context),
        AppLocalizations.of(context).invalidAmount,
        Directionality.of(context),
      );
      return;
    }

    HapticFeedback.lightImpact();
    _lastUsedCurrency = _currency;
    final payee = _payeeCtrl.text.trim();
    widget.onAdd(amount, _currency, payee.isEmpty ? null : payee);

    _amountCtrl.clear();
    _payeeCtrl.clear();
    _amountFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: pal.surfaceHigh,
        border: Border(top: BorderSide(color: pal.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CurrencyPicker(
                value: currencySymbol(_currency),
                onChanged: (v) => setState(() => _currency = v),
                flush: true,
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: pal.border.withValues(alpha: 0.5),
              ),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  focusNode: _amountFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _payeeFocus.requestFocus(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _invalid ? pal.expense : pal.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: pal.textMuted.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: PayeeField(
                  controller: _payeeCtrl,
                  focusNode: _payeeFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                  decoration: InputDecoration(
                    hintText: l10n.payeeOptional,
                    hintStyle: TextStyle(fontSize: 13, color: pal.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedBuilder(
                animation: widget.tabController.animation!,
                builder: (context, _) {
                  final t = widget.tabController.animation!.value.clamp(
                    0.0,
                    1.0,
                  );
                  final accent = Color.lerp(pal.income, pal.expense, t)!;
                  return SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: _canSubmit ? accent : pal.border,
                        foregroundColor: pal.onPrimary,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: _canSubmit ? _add : null,
                      icon: const Icon(Icons.done, size: 20),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
