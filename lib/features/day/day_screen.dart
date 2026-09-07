import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' as semantics;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/currency.dart';
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
          '${amount.toStringAsFixed(2)} ${currencySymbol(currency)}',
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
        '${t.amount.toStringAsFixed(2)} ${t.currency}',
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
    final locale = Localizations.localeOf(context).languageCode;
    final isToday = DateUtils.isSameDay(_day, DateTime.now());

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.E(locale).format(_day).toUpperCase(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isToday ? pal.primary : pal.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat.yMMMd(locale).format(_day),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: pal.text,
              ),
            ),
          ],
        ),
        // Extends the AppBar's own Material surface downward so the title
        // row and the day summary read as a single header block.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: SignalBuilder(
            dependencies: [di.reportsController.groupedByDay],
            builder: (_) {
              final totals = _dayTotals();
              return _DaySummaryStrip(
                income: totals.income,
                expense: totals.expense,
              );
            },
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

    final balance = <String, double>{
      for (final cur in {...income.keys, ...expense.keys})
        cur: (income[cur] ?? 0) - (expense[cur] ?? 0),
    };

    final incomeText = formatMoneyMap(income);
    final expenseText = formatMoneyMap(expense, signed: false);
    final balanceText = formatMoneyMap(balance);

    return Semantics(
      label:
          '${l10n.income} $incomeText. '
          '${l10n.expense} $expenseText. '
          '${l10n.balance} $balanceText.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _stat(incomeText, pal.income),
                _divider(pal),
                _stat(
                  expenseText == '0.00' ? expenseText : '−$expenseText',
                  pal.expense,
                ),
                _divider(pal),
                _stat('= $balanceText', pal.text),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: pal.border),
        ],
      ),
    );
  }

  Widget _divider(AppPalette pal) => Container(
    width: 1.5,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: pal.border,
  );

  Widget _stat(String value, Color color) {
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
// ── Transaction list ─────────────────────────────────────────────────────────

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
            return Dismissible(
              key: ValueKey(t.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: pal.expenseSoft,
                  borderRadius: BorderRadius.circular(kRadius),
                ),
                child: Icon(Icons.delete_outline, color: pal.expense, size: 22),
              ),
              onDismissed: (_) {
                final id = t.id;
                if (id == null) return;
                di.transactionsController.remove(id);
                onDeleted(t);
              },
              child: _CompactTxRow(
                transaction: t,
                onTap: () => onTapTransaction(t),
              ),
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
                '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ${currencySymbol(transaction.currency)}',
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
                value: _currency,
                onChanged: (v) => setState(() => _currency = v),
              ),
              const SizedBox(width: 8),
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
                    isDense: true,
                    hintStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: pal.textMuted,
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
                    isDense: true,
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
