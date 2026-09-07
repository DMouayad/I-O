import 'package:flutter/material.dart';

import '../currency.dart';

/// Renders a per-currency amount map where only the leading +/- sign is
/// tinted with [positiveColor] / [negativeColor]; the number and currency
/// symbol keep [style]'s own color. Multiple currencies are joined with
/// " · ", each carrying its own sign color.
///
/// Expects [amounts] to already carry the correct sign per entry (positive
/// for income-like values, negative for expense-like values) — this widget
/// does not flip or reinterpret signs.
class SignedMoneyText extends StatelessWidget {
  const SignedMoneyText(
    this.amounts, {
    super.key,
    required this.style,
    required this.positiveColor,
    required this.negativeColor,
    this.zeroFallback = '0.00',
  });

  final Map<String, double> amounts;
  final TextStyle style;
  final Color positiveColor;
  final Color negativeColor;
  final String zeroFallback;

  @override
  Widget build(BuildContext context) {
    final entries = amounts.entries.where((e) => e.value != 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return Text(zeroFallback, style: style);
    }

    final spans = <InlineSpan>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) spans.add(TextSpan(text: ' · ', style: style));
      final value = entries[i].value;
      final isNegative = value < 0;
      spans.add(
        TextSpan(
          text: isNegative ? '−' : '+',
          style: style.copyWith(
            color: isNegative ? negativeColor : positiveColor,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text:
              '${value.abs().toStringAsFixed(2)} ${currencySymbol(entries[i].key)}',
          style: style,
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }
}
