import 'package:flutter/material.dart';
import 'transaction_model.dart';
import '../l10n/generated/app_localizations.dart';

class TxCategory {
  final String key;
  final TransactionType type;
  final IconData icon;
  const TxCategory(this.key, this.type, this.icon);
}

const incomeCategories = <TxCategory>[
  TxCategory('sales', TransactionType.income, Icons.point_of_sale_outlined),
  TxCategory(
    'services',
    TransactionType.income,
    Icons.design_services_outlined,
  ),
  TxCategory('other_income', TransactionType.income, Icons.attach_money),
];

const expenseCategories = <TxCategory>[
  TxCategory('rent', TransactionType.expense, Icons.home_work_outlined),
  TxCategory('packaging', TransactionType.expense, Icons.inventory_2_outlined),
  TxCategory('utilities', TransactionType.expense, Icons.bolt_outlined),
  TxCategory('supplies', TransactionType.expense, Icons.shopping_bag_outlined),
  TxCategory('salaries', TransactionType.expense, Icons.groups_outlined),
  TxCategory('marketing', TransactionType.expense, Icons.campaign_outlined),
  TxCategory(
    'transport',
    TransactionType.expense,
    Icons.local_shipping_outlined,
  ),
  TxCategory('other_expense', TransactionType.expense, Icons.more_horiz),
];

TxCategory categoryByKey(String key) {
  return [
    ...incomeCategories,
    ...expenseCategories,
  ].firstWhere((c) => c.key == key, orElse: () => incomeCategories.last);
}

String categoryLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'sales':
      return l10n.categorySales;
    case 'services':
      return l10n.categoryServices;
    case 'other_income':
      return l10n.categoryOtherIncome;
    case 'rent':
      return l10n.categoryRent;
    case 'packaging':
      return l10n.categoryPackaging;
    case 'utilities':
      return l10n.categoryUtilities;
    case 'supplies':
      return l10n.categorySupplies;
    case 'salaries':
      return l10n.categorySalaries;
    case 'marketing':
      return l10n.categoryMarketing;
    case 'transport':
      return l10n.categoryTransport;
    case 'other_expense':
      return l10n.categoryOtherExpense;
    default:
      return key;
  }
}
