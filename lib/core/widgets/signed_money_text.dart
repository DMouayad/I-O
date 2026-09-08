import 'package:flutter/material.dart';

import '../currency.dart';
import '../money_format.dart';

/// Renders a per-currency amount map where only the leading +/- sign is
/// tinted with [positiveColor] / [negativeColor]; the number and currency
/// symbol keep [style]'s own color.
///
/// Single-line (default): multiple currencies are joined with " · ", each
/// carrying its own sign color.
///
/// Multiline ([multiline] = true): one currency per row in a compact
/// [Column] (1px row gap, tight line height). Single-entry maps render
/// identically to single-line mode so the common case doesn't shift.
/// Set [crossAxisAlignment]/[textAlign] to `end`/`right` for trailing
/// amounts (e.g. journal rows), `start`/`left` otherwise.
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
    this.zeroFallback = '0',
    this.multiline = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.textAlign = TextAlign.left,
  });

  final Map<String, double> amounts;
  final TextStyle style;
  final Color positiveColor;
  final Color negativeColor;
  final String zeroFallback;
  final bool multiline;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final entries = amounts.entries.where((e) => e.value != 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return Text(zeroFallback, style: style, textAlign: textAlign);
    }

    if (multiline && entries.length > 1) {
      final tight = style.copyWith(height: 1.15);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 1),
            Text.rich(
              TextSpan(children: _spansFor(entries[i].value, entries[i].key)),
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tight,
            ),
          ],
        ],
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < entries.length; i++) ..._joinedSpans(entries, i),
        ],
      ),
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<InlineSpan> _joinedSpans(List<MapEntry<String, double>> entries, int i) {
    final spans = <InlineSpan>[];
    if (i > 0) spans.add(TextSpan(text: ' · ', style: style));
    spans.addAll(_spansFor(entries[i].value, entries[i].key));
    return spans;
  }

  List<InlineSpan> _spansFor(double value, String currency) {
    final isNegative = value < 0;
    return [
      TextSpan(
        text: isNegative ? '−' : '+',
        style: style.copyWith(
          color: isNegative ? negativeColor : positiveColor,
        ),
      ),
      TextSpan(
        text:
            '${formatMoney(value.abs(), currency)} ${currencySymbol(currency)}',
        style: style,
      ),
    ];
  }
}
