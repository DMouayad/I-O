// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'I&O';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get add => 'Add';

  @override
  String get addIncome => 'Add Income';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get category => 'Category';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get payeeOptional => 'Payee (optional)';

  @override
  String get payeeHint => 'e.g. Ahmed';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get totalIncome => 'Income';

  @override
  String get totalExpense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get defaultCurrency => 'Default Currency';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get biometricAuth => 'Biometric / PIN Lock';

  @override
  String get unlock => 'Unlock';

  @override
  String get about => 'About';

  @override
  String get invalidAmount => 'Please enter a valid amount';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get all => 'All';

  @override
  String get categorySales => 'Sales';

  @override
  String get categoryServices => 'Services';

  @override
  String get categoryOtherIncome => 'Other Income';

  @override
  String get categoryRent => 'Rent';

  @override
  String get categoryPackaging => 'Packaging';

  @override
  String get categoryUtilities => 'Utilities';

  @override
  String get categorySupplies => 'Supplies';

  @override
  String get categorySalaries => 'Salaries';

  @override
  String get categoryMarketing => 'Marketing';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryOtherExpense => 'Other Expense';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String savedWithAmount(String amount) {
    return 'Saved $amount';
  }

  @override
  String get undo => 'Undo';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirmTitle => 'Delete transaction?';

  @override
  String get deleteConfirmMessage => 'This action cannot be undone.';
}
