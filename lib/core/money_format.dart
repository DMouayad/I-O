import 'currency.dart';

/// Formats a `{currencyCode: amount}` map into a compact string like
/// `"+12.00 $ · 5.50 €"`. Entries with a zero amount are skipped.
///
/// Returns [zeroFallback] if there's nothing to show.
String formatMoneyMap(
  Map<String, double> amounts, {
  bool signed = true,
  String zeroFallback = '0.00',
}) {
  final entries = amounts.entries.where((e) => e.value != 0).toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  if (entries.isEmpty) return zeroFallback;

  return entries
      .map((e) {
        final sign = signed && e.value > 0 ? '+' : '';
        return '$sign${e.value.toStringAsFixed(2)} ${currencySymbol(e.key)}';
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
