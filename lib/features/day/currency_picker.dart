import 'package:flutter/material.dart';
import 'package:io/core/currency.dart';
import 'package:io/core/theme/app_theme.dart';

class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      // Color / shape / elevation from popupMenuTheme.
      itemBuilder: (_) => _currencyItems(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kInk,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16, color: kInkMuted),
          ],
        ),
      ),
    );
  }
}

List<PopupMenuItem<String>> _currencyItems(String current) => kCurrencies
    .map(
      (c) => PopupMenuItem<String>(
        value: c.code,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              c.code,
              style: TextStyle(
                fontWeight: c.code == current
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: c.code == current ? kInk : kInkSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              c.symbol,
              style: const TextStyle(color: kInkMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    )
    .toList();
