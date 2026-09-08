import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'I&O'**
  String get appTitle;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @payeeOptional.
  ///
  /// In en, this message translates to:
  /// **'Payee (optional)'**
  String get payeeOptional;

  /// No description provided for @payeeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmed'**
  String get payeeHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @defaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrency;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric / PIN Lock'**
  String get biometricAuth;

  /// No description provided for @lockAfter.
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get lockAfter;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @savedWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Saved {amount}'**
  String savedWithAmount(String amount);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletedWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Deleted {amount}'**
  String deletedWithAmount(String amount);

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @topPayees.
  ///
  /// In en, this message translates to:
  /// **'Top payees'**
  String get topPayees;

  /// No description provided for @collapseCalendar.
  ///
  /// In en, this message translates to:
  /// **'Collapse calendar'**
  String get collapseCalendar;

  /// No description provided for @expandCalendar.
  ///
  /// In en, this message translates to:
  /// **'Expand calendar'**
  String get expandCalendar;

  /// No description provided for @tapToRecordToday.
  ///
  /// In en, this message translates to:
  /// **'Tap to record today transactions'**
  String get tapToRecordToday;

  /// No description provided for @authPromptReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access your data'**
  String get authPromptReason;

  /// No description provided for @authNoBiometrics.
  ///
  /// In en, this message translates to:
  /// **'No biometrics enrolled — use device PIN or enroll in Settings'**
  String get authNoBiometrics;

  /// No description provided for @authNoScreenLock.
  ///
  /// In en, this message translates to:
  /// **'No screen lock set — set a PIN in system Settings'**
  String get authNoScreenLock;

  /// No description provided for @authTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Authentication timed out — please try again'**
  String get authTimedOut;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed — please try again'**
  String get authFailed;

  /// No description provided for @noDeviceLockTitle.
  ///
  /// In en, this message translates to:
  /// **'No device lock set'**
  String get noDeviceLockTitle;

  /// No description provided for @noDeviceLockMessage.
  ///
  /// In en, this message translates to:
  /// **'This device has no PIN or biometrics, so the app will open without authentication. Set a screen lock to protect your data.'**
  String get noDeviceLockMessage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @swapTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap currencies'**
  String get swapTitle;

  /// No description provided for @swapRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s rate'**
  String get swapRateLabel;

  /// No description provided for @swapRateHelper.
  ///
  /// In en, this message translates to:
  /// **'How many {quote} per 1 {base}'**
  String swapRateHelper(String quote, String base);

  /// No description provided for @swapAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to swap'**
  String get swapAmountLabel;

  /// No description provided for @swapConfirm.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swapConfirm;

  /// No description provided for @swapFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get swapFrom;

  /// No description provided for @swapTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get swapTo;

  /// No description provided for @swapInvalidRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid rate above zero'**
  String get swapInvalidRate;

  /// No description provided for @swapExceedsTotal.
  ///
  /// In en, this message translates to:
  /// **'Exceeds available {available}'**
  String swapExceedsTotal(String available);

  /// No description provided for @swapSaved.
  ///
  /// In en, this message translates to:
  /// **'Swapped {from} → {to}'**
  String swapSaved(String from, String to);

  /// No description provided for @swapEmptySource.
  ///
  /// In en, this message translates to:
  /// **'No {bucket} in {currency} to swap yet'**
  String swapEmptySource(String bucket, String currency);

  /// No description provided for @swapPayee.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get swapPayee;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
