import 'package:intl/intl.dart';

import 'currency.dart';

/// Formats [amount] for [currencyCode], always with Latin digits:
/// SYP never shows decimals, anything else shows one decimal only when it
/// has a fractional part (10 → `10`, 10.5 → `10.5`). Large amounts get
/// grouping (`150,000`) regardless of app language.
String formatMoney(double amount, String currencyCode) {
  final fractionDigits = currencyCode == 'SYP' || !_hasTenth(amount) ? 0 : 1;
  final format = NumberFormat.decimalPattern('en')
    ..minimumFractionDigits = fractionDigits
    ..maximumFractionDigits = fractionDigits;
  // Round first so tiny negatives render as "0", not "-0".
  final factor = fractionDigits == 0 ? 1 : 10;
  final rounded = (amount * factor).round() / factor;
  return format.format(rounded == 0 ? 0 : rounded);
}

bool _hasTenth(double amount) {
  final tenth = (amount * 10).round() / 10;
  return tenth != tenth.roundToDouble();
}

/// Formats a `{currencyCode: amount}` map into a compact string like
/// `"+12 $ · 5.5 €"`. Entries with a zero amount are skipped.
///
/// Returns [zeroFallback] if there's nothing to show.
String formatMoneyMap(
  Map<String, double> amounts, {
  bool signed = true,
  String zeroFallback = '0',
}) {
  final entries = amounts.entries.where((e) => e.value != 0).toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  if (entries.isEmpty) return zeroFallback;

  return entries
      .map((e) {
        final sign = signed && e.value > 0 ? '+' : '';
        return '$sign${formatMoney(e.value, e.key)} ${currencySymbol(e.key)}';
      })
      .join(' · ');
}

/// Sums all values in a per-currency totals map, ignoring the fact that
/// different currencies aren't actually additive.
///
/// Only use this for a coarse "is this overall positive or negative" signal
/// (e.g. picking a dot color), never to *display* a number — for that, use
/// [formatMoneyMap] so each currency is shown separately.
double netTotal(Map<String, double> totals) =>
    totals.values.fold(0.0, (a, b) => a + b);
