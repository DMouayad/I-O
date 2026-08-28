import 'package:flutter/material.dart';
import 'package:io/core/theme/app_theme.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? kIncome : kExpense;
    final soft = isIncome ? kIncomeSoft : kExpenseSoft;
    final catKey = transaction.category;
    final cat = catKey != null ? categoryByKey(catKey) : null;
    final categoryText = catKey != null
        ? categoryLabel(l10n, catKey)
        : l10n.uncategorized;

    final payee = transaction.payee?.trim();
    final hasPayee = payee != null && payee.isNotEmpty;
    final note = transaction.note?.trim();
    final hasNote = note != null && note.isNotEmpty;

    // Payee is the primary identifier; the category takes over as title
    // only when there is no payee.
    final title = hasPayee ? payee : categoryText;
    final subtitle = [
      if (hasPayee) categoryText,
      if (hasNote) note,
    ].join('  •  ');

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: kExpense,
          borderRadius: BorderRadius.circular(kRadius),
        ),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.deleteConfirmTitle),
                content: Text(l10n.deleteConfirmMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: kExpense),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(kRadius),
              ),
              child: Icon(
                cat?.icon ?? Icons.label_outline,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: kInk,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kInkSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  transaction.currency,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: kInkMuted,
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
