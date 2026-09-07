// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'I&O';

  @override
  String get income => 'دخل';

  @override
  String get expense => 'مصروف';

  @override
  String get reports => 'التقارير';

  @override
  String get settings => 'الإعدادات';

  @override
  String get addIncome => 'إضافة دخل';

  @override
  String get addExpense => 'إضافة مصروف';

  @override
  String get payeeOptional => 'الجهة (اختياري)';

  @override
  String get payeeHint => 'مثال: أحمد';

  @override
  String get save => 'حفظ';

  @override
  String get balance => 'الرصيد';

  @override
  String get defaultCurrency => 'العملة الافتراضية';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get biometricAuth => 'قفل بصمة / رمز الدخول';

  @override
  String get lockAfter => 'القفل بعد';

  @override
  String get minutesShort => 'د';

  @override
  String get unlock => 'فتح القفل';

  @override
  String get about => 'حول التطبيق';

  @override
  String get invalidAmount => 'يرجى إدخال مبلغ صحيح';

  @override
  String get noTransactions => 'لا توجد معاملات بعد';

  @override
  String get today => 'اليوم';

  @override
  String savedWithAmount(String amount) {
    return 'تم الحفظ $amount';
  }

  @override
  String get undo => 'تراجع';

  @override
  String get delete => 'حذف';

  @override
  String deletedWithAmount(String amount) {
    return 'تم حذف $amount';
  }

  @override
  String get editTransaction => 'تعديل المعاملة';

  @override
  String get journal => 'السجل';

  @override
  String get topPayees => 'أكبر الجهات';

  @override
  String get collapseCalendar => 'طيّ التقويم';

  @override
  String get expandCalendar => 'توسيع التقويم';

  @override
  String get tapToRecordToday => '+ اضغط لتسجيل معاملات اليوم';
}
