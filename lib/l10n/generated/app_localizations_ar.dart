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
  String get add => 'إضافة';

  @override
  String get addIncome => 'إضافة دخل';

  @override
  String get addExpense => 'إضافة مصروف';

  @override
  String get category => 'الفئة';

  @override
  String get noteOptional => 'ملاحظة (اختياري)';

  @override
  String get payeeOptional => 'الجهة (اختياري)';

  @override
  String get payeeHint => 'مثال: أحمد';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get totalIncome => 'الدخل';

  @override
  String get totalExpense => 'المصروف';

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
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get all => 'الكل';

  @override
  String get categorySales => 'مبيعات';

  @override
  String get categoryServices => 'خدمات';

  @override
  String get categoryOtherIncome => 'دخل آخر';

  @override
  String get categoryRent => 'إيجار';

  @override
  String get categoryPackaging => 'تغليف';

  @override
  String get categoryUtilities => 'فواتير';

  @override
  String get categorySupplies => 'مستلزمات';

  @override
  String get categorySalaries => 'رواتب';

  @override
  String get categoryMarketing => 'تسويق';

  @override
  String get categoryTransport => 'نقل';

  @override
  String get categoryOtherExpense => 'مصروف آخر';

  @override
  String get uncategorized => 'غير مصنّف';

  @override
  String savedWithAmount(String amount) {
    return 'تم الحفظ $amount';
  }

  @override
  String get undo => 'تراجع';

  @override
  String get delete => 'حذف';

  @override
  String get deleteConfirmTitle => 'حذف المعاملة؟';

  @override
  String get deleteConfirmMessage => 'لا يمكن التراجع عن هذا الإجراء.';
}
