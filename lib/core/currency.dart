class AppCurrency {
  final String code;
  final String symbol;
  const AppCurrency(this.code, this.symbol);
}

const kCurrencies = <AppCurrency>[
  AppCurrency('USD', '\$'),
  AppCurrency('EUR', '€'),
  AppCurrency('GBP', '£'),
  AppCurrency('SAR', 'SAR'),
  AppCurrency('SYP', 'ل.س'),
  AppCurrency('AED', 'AED'),
  AppCurrency('EGP', 'EGP'),
  AppCurrency('JOD', 'JOD'),
  AppCurrency('KWD', 'KWD'),
];

String currencySymbol(String code) {
  return kCurrencies
      .firstWhere((c) => c.code == code, orElse: () => AppCurrency(code, code))
      .symbol;
}
