import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:io/core/theme/app_theme.dart';

import '../../core/currency.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../state/settings_controller.dart';
import '../../state/transactions_controller.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    required this.type,
    this.controller,
    this.settingsController,
  });

  final TransactionType type;
  final TransactionsController? controller;
  final SettingsController? settingsController;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _payee = '';
  late String _currency;
  String? _category;
  DateTime _date = DateTime.now();
  bool _saving = false;

  TransactionsController get _controller =>
      widget.controller ?? di.transactionsController;
  SettingsController get _settings =>
      widget.settingsController ?? di.settingsController;

  @override
  void initState() {
    super.initState();
    _currency = _settings.settings.value.defaultCurrency;
    _category = null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
      return;
    }
    setState(() => _saving = true);

    final payeeText = _payee.trim();
    final noteText = _noteController.text.trim();

    final t = TransactionModel(
      type: widget.type,
      amount: amount,
      currency: _currency,
      category: _category,
      payee: payeeText.isEmpty ? null : payeeText,
      note: noteText.isEmpty ? null : noteText,
      date: _date,
      createdAt: DateTime.now(),
    );

    final id = await _controller.add(t);

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    while (router.canPop()) {
      router.pop();
    }

    messenger.showSnackBar(
      SnackBar(
        showCloseIcon: true,
        persist: false,
        content: Text(
          l10n.savedWithAmount(
            '${widget.type == TransactionType.income ? '+' : '-'}'
            '${amount.toStringAsFixed(2)} $_currency',
          ),
        ),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => _controller.remove(id),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIncome = widget.type == TransactionType.income;
    final accent = isIncome ? kIncome : kExpense;
    final categories = isIncome ? incomeCategories : expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? l10n.addIncome : l10n.addExpense),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _CurrencyMenu(
                value: _currency,
                onSelected: (v) => setState(() => _currency = v),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Amount ──
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: kInkMuted,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                prefixText: '${currencySymbol(_currency)} ',
                prefixStyle: TextStyle(
                  color: kInkMuted,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            const SizedBox(height: 28),
            // ── Payee ──
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                final q = textEditingValue.text.trim();
                return _controller.payeeSuggestions(q);
              },
              onSelected: (value) => _payee = value,
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) => _payee = v,
                      decoration: InputDecoration(
                        labelText: l10n.payeeOptional,
                        hintText: l10n.payeeHint,
                        prefixIcon: const Icon(Icons.person_outlined),
                      ),
                      onSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadius),
                      side: const BorderSide(color: kBorder),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            visualDensity: VisualDensity.compact,
                            leading: Icon(
                              Icons.history,
                              size: 18,
                              color: kInkMuted,
                            ),
                            title: Text(
                              option,
                              style: TextTheme.of(
                                context,
                              ).bodyMedium?.copyWith(fontWeight: .w600),
                            ),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Category ──
            _SectionLabel(l10n.category),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((c) {
                return ChoiceChip(
                  visualDensity: .comfortable,
                  avatar: Icon(c.icon, size: 18),
                  label: Text(categoryLabel(l10n, c.key)),
                  selected: _category == c.key,
                  onSelected: (selected) =>
                      setState(() => _category = selected ? c.key : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Note ──
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.noteOptional),
            ),
            const SizedBox(height: 16),

            // ── Date ──
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadius),
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(kRadius),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: kBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: kInkSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat.yMMMd(
                              Localizations.localeOf(context).languageCode,
                            ).format(_date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: kInk,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          size: 20,
                          color: kInkMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Keep content above the pinned bar when keyboard is hidden.
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyMenu extends StatelessWidget {
  const _CurrencyMenu({required this.value, required this.onSelected});

  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onSelected,
      offset: const Offset(0, 36),
      itemBuilder: (context) => kCurrencies
          .map(
            (c) => PopupMenuItem<String>(
              value: c.code,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      c.code,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: c.code == value ? kInk : kInkSecondary,
                      ),
                    ),
                  ),
                  Text(
                    c.symbol,
                    style: TextStyle(
                      color: c.code == value ? kInk : kInkMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kInk,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18, color: kInkSecondary),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    // No uppercase / letter-spacing: must stay legible for Arabic (RTL).
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kInkSecondary,
      ),
    );
  }
}
