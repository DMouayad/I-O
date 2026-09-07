class AppCurrency {
  final String code;
  final String symbol;
  const AppCurrency(this.code, this.symbol);
}

const kCurrencies = <AppCurrency>[
  AppCurrency('USD', '\$'),
  AppCurrency('SYP', 'ل.س'),
];

String currencySymbol(String code) {
  return kCurrencies
      .firstWhere((c) => c.code == code, orElse: () => AppCurrency(code, code))
      .symbol;
}

/// Locale-tolerant amount parse: accepts Arabic-Indic digits, Arabic decimal
/// separator, and comma-as-decimal (e.g. `12,50`). Returns null when invalid.
double? parseAmount(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    final ei = eastern.indexOf(ch);
    if (ei >= 0) {
      buf.write(western[ei]);
      continue;
    }
    final pi = persian.indexOf(ch);
    if (pi >= 0) {
      buf.write(western[pi]);
      continue;
    }
    // Arabic decimal separator → '.', thousands separator → drop.
    if (ch == '٫') {
      buf.write('.');
      continue;
    }
    if (ch == '٬') continue;
    buf.write(ch);
  }
  s = buf.toString().replaceAll(RegExp(r"[\s'’]"), '');
  final hasDot = s.contains('.');
  final hasComma = s.contains(',');
  if (hasComma && !hasDot) {
    // Only commas: treat as decimal separator (ar `12,50`).
    s = s.replaceAll(',', '.');
  } else if (hasComma) {
    // Both: commas are thousands grouping.
    s = s.replaceAll(',', '');
  }
  return double.tryParse(s);
}
