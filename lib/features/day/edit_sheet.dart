import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:io/core/currency.dart';
import 'package:io/core/theme/app_theme.dart';
import 'package:io/di.dart' as di;
import 'package:io/l10n/generated/app_localizations.dart';
import 'package:io/models/transaction_model.dart';

import 'currency_picker.dart';
import 'payee_field.dart';

class EditSheet extends StatefulWidget {
  const EditSheet({
    super.key,
    required this.transaction,
    required this.onDeleted,
  });

  final TransactionModel transaction;

  /// Called after removal + close; the parent shows the undo toast.
  final ValueChanged<TransactionModel> onDeleted;

  @override
  State<EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<EditSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _payeeCtrl;
  final _amountFocus = FocusNode();
  final _payeeFocus = FocusNode();
  late String _currency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _payeeCtrl = TextEditingController(text: widget.transaction.payee ?? '');
    _currency = widget.transaction.currency;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _amountFocus.requestFocus(),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _payeeCtrl.dispose();
    _amountFocus.dispose();
    _payeeFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
      return;
    }
    setState(() => _saving = true);
    final payee = _payeeCtrl.text.trim();
    final t = widget.transaction;

    await di.transactionsController.update(
      TransactionModel(
        id: t.id,
        type: t.type,
        amount: amount,
        currency: _currency,
        payee: payee.isEmpty ? null : payee,
        date: t.date,
        createdAt: t.createdAt,
      ),
    );
    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final t = widget.transaction;
    HapticFeedback.lightImpact();
    final id = t.id;
    if (id != null) await di.transactionsController.remove(id);
    navigator.pop();
    widget.onDeleted(t);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(kRadius),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.editTransaction,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kInk,
                    ),
                  ),
                ),
                CurrencyPicker(
                  value: _currency,
                  onChanged: (v) => setState(() => _currency = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              focusNode: _amountFocus,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _payeeFocus.requestFocus(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: kInk,
              ),
              // Border / fill / padding from inputDecorationTheme — only
              // the oversized type is sheet-specific.
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: const TextStyle(
                  color: kInkMuted,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                prefixText: '${currencySymbol(_currency)} ',
                prefixStyle: const TextStyle(
                  color: kInkMuted,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            PayeeField(
              controller: _payeeCtrl,
              focusNode: _payeeFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: l10n.payeeOptional,
                hintText: l10n.payeeHint,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _delete,
                    // Everything but the destructive color is themed.
                    style: OutlinedButton.styleFrom(foregroundColor: kExpense),
                    child: Text(l10n.delete),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? '...' : l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
