import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/currency.dart';
import '../../core/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/toast.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';
import '../../models/transaction_model.dart';
import 'currency_picker.dart';
import 'edit_sheet.dart';
import 'payee_field.dart';

class DayScreen extends StatefulWidget {
  const DayScreen({super.key, required this.day});

  final DateTime day;

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────

  /// Entry-bar add. The active tab decides the type; the list above the
  /// bar is the feedback, so no toast.
  Future<void> _addTransaction(
    double amount,
    String currency,
    String? payee,
  ) async {
    final now = DateTime.now();
    final id = await di.transactionsController.add(
      TransactionModel(
        type: _tabController.index == 0
            ? TransactionType.income
            : TransactionType.expense,
        amount: amount,
        currency: currency,
        payee: payee,
        date: DateTime(
          widget.day.year,
          widget.day.month,
          widget.day.day,
          now.hour,
          now.minute,
        ),
        createdAt: now,
      ),
    );
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      showTopToast(
        context,
        message: l10n.savedWithAmount(
          '${amount.toStringAsFixed(2)} ${currencySymbol(currency)}',
        ),
        actionLabel: l10n.undo,
        onAction: () => di.transactionsController.remove(id),
      );
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
      // Background / shape / border from bottomSheetTheme.
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: EditSheet(transaction: t, onDeleted: _showDeletedToast),
      ),
    );
  }

  String _formatTotals(Map<String, double> totals) {
    final keys = totals.keys.toList()..sort();
    return [
      for (final cur in keys)
        if (totals[cur] != 0)
          '${totals[cur]! > 0 ? '+' : ''}${totals[cur]!.toStringAsFixed(2)} ${currencySymbol(cur)}',
    ].join(' · ');
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dayLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(widget.day);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: SignalBuilder(
          builder: (_) {
            di.reportsController.groupedByDay.value; // signal dependency
            final totals = di.reportsController.totalsForDay(widget.day);
            final net = _formatTotals(totals);
            final isMulti = totals.values.where((v) => v != 0).length > 1;

            final dateText = Text(
              dayLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kInk,
              ),
            );
            final netText = Text(
              net,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kInkSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            );

            if (net.isEmpty) return dateText;
            // Multi-currency: full-width line below the date.
            if (isMulti) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  dateText,
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: netText,
                  ),
                ],
              );
            }
            return Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                dateText,
                const SizedBox(width: 8),
                Flexible(child: netText),
              ],
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.income),

            Tab(text: l10n.expense),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTab(TransactionType.income),
                  _buildTab(TransactionType.expense),
                ],
              ),
            ),
            _EntryBar(onAdd: _addTransaction),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(TransactionType type) {
    final l10n = AppLocalizations.of(context);
    return SignalBuilder(
      dependencies: [di.reportsController.groupedByDay],
      builder: (_) {
        final totals = {
          for (final e
              in di.reportsController
                  .totalsForDay(widget.day, type: type)
                  .entries)
            if (e.value != 0) e.key: e.value,
        };
        final list = di.reportsController.transactionsForDayAndType(
          widget.day,
          type,
        );

        return Column(
          children: [
            if (totals.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: AlignmentDirectional.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _TabTotal(totals: totals, type: type),
                  ),
                ),
              ),
              const Divider(),
            ],
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noTransactions,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: kInkMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final t = list[i];
                        return _DayTxRow(
                          transaction: t,
                          onTap: () => _openEditSheet(t),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Tab headline: one animated number per currency, e.g. "1,240.00 USD".
/// Lives in content (full width), not in the tab label — money never
/// belongs in navigation chrome.
class _TabTotal extends StatelessWidget {
  const _TabTotal({required this.totals, required this.type});

  final Map<String, double> totals;
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final color = type == TransactionType.income ? kIncome : kExpense;
    final keys = totals.keys.toList()..sort();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          CountUpText(
            value: totals[keys[i]]!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            currencySymbol(keys[i]),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kInkSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _DayTxRow extends StatelessWidget {
  const _DayTxRow({required this.transaction, required this.onTap});

  final TransactionModel transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? kIncome : kExpense;
    final payee = transaction.payee?.trim();
    final hasPayee = payee != null && payee.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: kBorder, width: 1),
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isIncome ? kIncomeSoft : kExpenseSoft,
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                  // Down = money in — same language as Reports.
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasPayee ? payee : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasPayee ? kInk : kInkMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ${currencySymbol(transaction.currency)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pinned entry bar ──────────────────────────────────────────────────────

/// Remembers the last used currency so rapid entry doesn't re-pick it.
String? _lastCurrency;

class _EntryBar extends StatefulWidget {
  const _EntryBar({required this.onAdd});

  /// Screen applies the active tab's type.
  final void Function(double amount, String currency, String? payee) onAdd;

  @override
  State<_EntryBar> createState() => _EntryBarState();
}

class _EntryBarState extends State<_EntryBar> {
  final _amountCtrl = TextEditingController();
  final _payeeCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _payeeFocus = FocusNode();
  late String _currency =
      _lastCurrency ?? di.settingsController.settings.value.defaultCurrency;
  bool _barFocused = false;
  bool _invalid = false;
  int _invalidToken = 0;

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(_syncFocus);
    _payeeFocus.addListener(_syncFocus);
  }

  void _syncFocus() {
    final focused = _amountFocus.hasFocus || _payeeFocus.hasFocus;
    if (focused != _barFocused) setState(() => _barFocused = focused);
  }

  @override
  void dispose() {
    _amountFocus.dispose();
    _payeeFocus.dispose();
    _amountCtrl.dispose();
    _payeeCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      // No button to disable — flash the bar instead.
      HapticFeedback.lightImpact();
      final token = ++_invalidToken;
      setState(() => _invalid = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _invalidToken == token) {
          setState(() => _invalid = false);
        }
      });
      return;
    }
    HapticFeedback.lightImpact();
    _lastCurrency = _currency;
    final payee = _payeeCtrl.text.trim();
    widget.onAdd(amount, _currency, payee.isEmpty ? null : payee);

    // Move focus off payee first (hides its suggestion panel without a
    // one-frame flicker), then clear + keep the keyboard up.
    _amountFocus.requestFocus();
    _amountCtrl.clear();
    _payeeCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Strong rule — the bar is the action zone; ink = action.
        Container(height: 2, color: kInk),
        AnimatedContainer(
          duration: kMotionFast,
          curve: kMotionCurve,
          // Resting = sunken; focused = lifted white; invalid = flash.
          color: _invalid
              ? kExpenseSoft
              : (_barFocused ? Colors.white : kSurfaceMuted),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1 — currency + amount
              Row(
                children: [
                  CurrencyPicker(
                    value: _currency,
                    onChanged: (v) => setState(() => _currency = v),
                  ),
                  // PopupMenuButton<String>(
                  //   initialValue: _currency,
                  //   tooltip: '',
                  //   padding: EdgeInsets.zero,
                  //   onSelected: (v) => setState(() => _currency = v),
                  //   itemBuilder: (_) => _currencyItems(_currency),
                  //   child: Padding(
                  //     padding: const EdgeInsetsDirectional.only(
                  //       start: 16,
                  //       end: 4,
                  //     ),
                  //     child: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Text(
                  //           _currency,
                  //           style: const TextStyle(
                  //             fontSize: 13,
                  //             fontWeight: FontWeight.w600,
                  //             color: kInkSecondary,
                  //           ),
                  //         ),
                  //         const Icon(
                  //           Icons.expand_more,
                  //           size: 16,
                  //           color: kInkMuted,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      focusNode: _amountFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _payeeFocus.requestFocus(),
                      onChanged: (_) {
                        if (_invalid) setState(() => _invalid = false);
                      },
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: kInk,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: kInkMuted,
                        ),
                        border: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(width: 2),
                        ),
                        contentPadding: EdgeInsetsDirectional.fromSTEB(
                          8,
                          12,
                          16,
                          12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, thickness: 1, color: kBorder),
              // Row 2 — payee (compact), suggestions open upward
              PayeeField(
                controller: _payeeCtrl,
                focusNode: _payeeFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: l10n.payeeOptional,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} // ── Edit sheet (edit-only — adds go through the pinned bar) ───────────────
