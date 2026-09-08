import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/currency.dart';
import '../../core/money_format.dart';
import '../../core/theme/palette.dart';
import '../../core/toast.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';
import '../../models/transaction_model.dart';

/// The rate is always "1 USD = X SYP" (quote per base unit), regardless of
/// swap direction. [fromUsd] selects multiply vs. divide.
double convertSwapAmount({
  required double amount,
  required double rate,
  required bool fromUsd,
}) => fromUsd ? amount * rate : amount / rate;

/// Base currency of the swap rate. The screen supports exactly the two
/// [kCurrencies] entries, so the target is always "the other one". A third
/// currency would need an explicit direction picker here.
const _kRateBase = 'USD';

/// Records a same-day currency exchange: `expense(amount, from)` +
/// `income(converted, to)`. The source is always the day's income — you
/// can't convert money you don't have — so the amount is capped by the
/// income slice in the from-currency.
class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key, required this.day});

  final DateTime day;

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  late String _from =
      kCurrencies.any(
        (c) => c.code == di.settingsController.settings.value.defaultCurrency,
      )
      ? di.settingsController.settings.value.defaultCurrency
      : _kRateBase;

  late final TextEditingController _rateCtrl = TextEditingController(
    text: _initialRateText(),
  );
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  static String _initialRateText() {
    final last = di.settingsController.settings.value.lastSwapRate;
    return last == null ? '' : last.toString();
  }

  String get _to => kCurrencies.firstWhere((c) => c.code != _from).code;

  @override
  void dispose() {
    _rateCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  /// Day's income totals per currency — what's available to swap. Expense
  /// is irrelevant here, so this never goes negative.
  Map<String, double> _income() => di.reportsController.totalsForDay(
    widget.day,
    type: TransactionType.income,
  );

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final rate = parseAmount(_rateCtrl.text);
    final amount = parseAmount(_amountCtrl.text);
    final available = _income()[_from] ?? 0;
    if (rate == null ||
        rate <= 0 ||
        amount == null ||
        amount <= 0 ||
        amount > available + 1e-6) {
      return;
    }
    final converted = double.parse(
      convertSwapAmount(
        amount: amount,
        rate: rate,
        fromUsd: _from == _kRateBase,
      ).toStringAsFixed(2),
    );

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final date = DateTime(
        widget.day.year,
        widget.day.month,
        widget.day.day,
        now.hour,
        now.minute,
      );
      final payee = l10n.swapPayee;
      final expenseId = await di.transactionsController.add(
        TransactionModel(
          type: TransactionType.expense,
          amount: amount,
          currency: _from,
          payee: payee,
          date: date,
          createdAt: now,
        ),
      );
      int? incomeId;
      try {
        incomeId = await di.transactionsController.add(
          TransactionModel(
            type: TransactionType.income,
            amount: converted,
            currency: _to,
            payee: payee,
            date: date,
            createdAt: now,
          ),
        );
      } catch (_) {
        // Roll back the first leg so a half-written swap never lingers.
        await di.transactionsController.remove(expenseId);
        rethrow;
      }
      await di.settingsController.setLastSwapRate(rate);
      if (!mounted) return;
      final fromText = '${formatMoney(amount, _from)} ${currencySymbol(_from)}';
      final toText = '${formatMoney(converted, _to)} ${currencySymbol(_to)}';
      final capturedExpense = expenseId;
      final capturedIncome = incomeId;
      // Toast first: it lives on the root overlay, so it survives the pop
      // below and the Undo stays tappable on the day screen.
      showTopToast(
        context,
        message: l10n.swapSaved(fromText, toText),
        actionLabel: l10n.undo,
        onAction: () {
          di.transactionsController.remove(capturedIncome);
          di.transactionsController.remove(capturedExpense);
        },
      );
      context.pop();
    } catch (_) {
      // Entries keep their values so the user can retry.
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);

    final income = _income();
    final available = income[_from] ?? 0;

    final rate = parseAmount(_rateCtrl.text);
    final amount = parseAmount(_amountCtrl.text);
    final rateOk = rate != null && rate > 0;
    final amountOk = amount != null && amount > 0;
    final withinCap = amountOk && amount <= available + 1e-6;
    final canConfirm =
        rateOk && amountOk && withinCap && available > 0 && !_saving;

    final converted = (rateOk && amountOk)
        ? convertSwapAmount(
            amount: amount,
            rate: rate,
            fromUsd: _from == _kRateBase,
          )
        : null;

    String? amountError;
    if (_amountCtrl.text.trim().isNotEmpty) {
      if (!amountOk) {
        amountError = l10n.invalidAmount;
      } else if (!withinCap) {
        amountError = l10n.swapExceedsTotal(
          '${formatMoney(available, _from)} ${currencySymbol(_from)}',
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.swapTitle),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.currency_exchange),
            onPressed: canConfirm ? _confirm : null,
            label: Text(l10n.swapConfirm),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            l10n.swapFrom,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: pal.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            // height: 60,
            child: SegmentedButton<String>(
              segments: [
                for (final c in kCurrencies)
                  ButtonSegment(
                    value: c.code,
                    label: _CurrencyNetLabel(
                      code: c.code,
                      symbol: c.symbol,
                      available: income[c.code] ?? 0,
                    ),
                  ),
              ],
              style: SegmentedButton.styleFrom(
                visualDensity: .standard,
                tapTargetSize: .padded,
                fixedSize: Size.fromHeight(62),
                selectedBackgroundColor: pal.accent,
                selectedForegroundColor: pal.onPrimary,
                backgroundColor: pal.surfaceHigh,
                foregroundColor: pal.textMuted,
              ),
              selected: {_from},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _from = s.first),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.swapTo}: $_to ${currencySymbol(_to)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: pal.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: pal.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: l10n.swapRateLabel,
              errorText: _rateCtrl.text.trim().isNotEmpty && !rateOk
                  ? l10n.swapInvalidRate
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: .start,
            children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: pal.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.swapAmountLabel,
                    prefixText: '${currencySymbol(_from)} ',
                    helperText:
                        '${formatMoney(available, _from)} ${currencySymbol(_from)}',
                    errorText: amountError,
                    errorMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              if (converted != null) ...[
                SizedBox(
                  height: 62,
                  child: Center(child: Icon(Icons.arrow_forward)),
                ),
                Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: pal.surfaceHigh,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: pal.border),
                  ),
                  child: Text(
                    '${formatMoney(converted, _to)} ${currencySymbol(_to)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: pal.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Segment label showing the currency's swappable income for the day,
/// e.g. `1,200 $`. Inherits the segment's foreground (onPrimary on the
/// income/expense backgrounds), so no explicit text colors here.
class _CurrencyNetLabel extends StatelessWidget {
  const _CurrencyNetLabel({
    required this.code,
    required this.symbol,
    required this.available,
  });

  final String code;
  final String symbol;
  final double available;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${formatMoney(available, code)} $symbol',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    );
  }
}
