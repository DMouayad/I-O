import 'package:flutter/material.dart';
import 'package:io/core/currency.dart';
import 'package:io/core/theme/palette.dart';

class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.flush = false,
  });

  final String value;
  final ValueChanged<String> onChanged;

  /// When true, renders without its own background/border — for embedding
  /// directly inside another surface (e.g. the day-screen entry bar) so it
  /// reads as part of that surface rather than a nested floating chip.
  final bool flush;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      tooltip: value,
      itemBuilder: (_) => [
        for (final c in kCurrencies)
          PopupMenuItem<String>(
            value: c.code,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  child: c.code == value
                      ? Icon(Icons.check, size: 16, color: pal.primary)
                      : null,
                ),
                Text(
                  c.code,
                  style: TextStyle(
                    fontWeight: c.code == value
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: c.code == value ? pal.text : pal.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  c.symbol,
                  style: TextStyle(color: pal.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.symmetric(horizontal: flush ? 6 : 10, vertical: 8),
        decoration: flush
            ? null
            : BoxDecoration(
                color: pal.surfaceHigh,
                border: Border.all(color: pal.border),
                borderRadius: BorderRadius.circular(kRadius),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: pal.text,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: pal.textMuted),
          ],
        ),
      ),
    );
  }
}
