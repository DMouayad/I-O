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
  String get cancel => 'إلغاء';

  @override
  String get deleteDay => 'حذف معاملات اليوم…';

  @override
  String get deleteDayTitle => 'حذف المعاملات؟';

  @override
  String get deleteScopeDay => 'اليوم كله';

  @override
  String deletedCount(int count) {
    return 'تم حذف $count من المعاملات';
  }

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
  String get tapToRecordToday => 'اضغط لتسجيل معاملات اليوم';

  @override
  String get authPromptReason => 'قم بالمصادقة للوصول إلى بياناتك';

  @override
  String get authNoBiometrics =>
      'لا توجد بصمة مسجلة — استخدم رمز الجهاز أو سجّل بصمة في الإعدادات';

  @override
  String get authNoScreenLock =>
      'لا يوجد قفل شاشة — عيّن رمز PIN في إعدادات النظام';

  @override
  String get authTimedOut => 'انتهت مهلة المصادقة — حاول مجددًا';

  @override
  String get authFailed => 'فشلت المصادقة — حاول مجددًا';

  @override
  String get noDeviceLockTitle => 'لا يوجد قفل على الجهاز';

  @override
  String get noDeviceLockMessage =>
      'هذا الجهاز لا يحتوي على رمز PIN أو بصمة، لذلك سيُفتح التطبيق دون مصادقة. عيّن قفل شاشة لحماية بياناتك.';

  @override
  String get continueButton => 'متابعة';

  @override
  String get swapTitle => 'تبديل العملات';

  @override
  String get swapRateLabel => 'سعر اليوم';

  @override
  String swapRateHelper(String quote, String base) {
    return 'كم $quote مقابل 1 $base';
  }

  @override
  String get swapAmountLabel => 'المبلغ المراد تبديله';

  @override
  String get swapConfirm => 'بدّل';

  @override
  String get swapFrom => 'من';

  @override
  String get swapTo => 'إلى';

  @override
  String get swapInvalidRate => 'أدخل سعرًا صحيحًا أكبر من الصفر';

  @override
  String swapExceedsTotal(String available) {
    return 'يتجاوز المتاح $available';
  }

  @override
  String swapSaved(String from, String to) {
    return 'تم تبديل $from إلى $to';
  }

  @override
  String swapEmptySource(String bucket, String currency) {
    return 'لا يوجد $bucket بـ$currency للتبديل بعد';
  }

  @override
  String get swapPayee => 'تبديل عملة';
}
