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
  String get addIncome => 'Add Income';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get payeeOptional => 'Payee (optional)';

  @override
  String get payeeHint => 'e.g. Ahmed';

  @override
  String get save => 'Save';

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
  String get lockAfter => 'Lock after';

  @override
  String get minutesShort => 'min';

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
  String savedWithAmount(String amount) {
    return 'Saved $amount';
  }

  @override
  String get undo => 'Undo';

  @override
  String get delete => 'Delete';

  @override
  String deletedWithAmount(String amount) {
    return 'Deleted $amount';
  }

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get journal => 'Journal';

  @override
  String get topPayees => 'Top payees';

  @override
  String get collapseCalendar => 'Collapse calendar';

  @override
  String get expandCalendar => 'Expand calendar';

  @override
  String get tapToRecordToday => 'Tap to record today transactions';

  @override
  String get authPromptReason => 'Authenticate to access your data';

  @override
  String get authNoBiometrics =>
      'No biometrics enrolled — use device PIN or enroll in Settings';

  @override
  String get authNoScreenLock =>
      'No screen lock set — set a PIN in system Settings';

  @override
  String get authTimedOut => 'Authentication timed out — please try again';

  @override
  String get authFailed => 'Authentication failed — please try again';

  @override
  String get noDeviceLockTitle => 'No device lock set';

  @override
  String get noDeviceLockMessage =>
      'This device has no PIN or biometrics, so the app will open without authentication. Set a screen lock to protect your data.';

  @override
  String get continueButton => 'Continue';

  @override
  String get swapTitle => 'Swap currencies';

  @override
  String get swapRateLabel => 'Today\'s rate';

  @override
  String swapRateHelper(String quote, String base) {
    return 'How many $quote per 1 $base';
  }

  @override
  String get swapAmountLabel => 'Amount to swap';

  @override
  String get swapConfirm => 'Swap';

  @override
  String get swapFrom => 'From';

  @override
  String get swapTo => 'To';

  @override
  String get swapInvalidRate => 'Enter a valid rate above zero';

  @override
  String swapExceedsTotal(String available) {
    return 'Exceeds available $available';
  }

  @override
  String swapSaved(String from, String to) {
    return 'Swapped $from → $to';
  }

  @override
  String swapEmptySource(String bucket, String currency) {
    return 'No $bucket in $currency to swap yet';
  }

  @override
  String get swapPayee => 'Exchange';
}
