import 'package:flutter_test/flutter_test.dart';
import 'package:io/core/money_format.dart';

void main() {
  test('SYP never shows decimals', () {
    expect(formatMoney(150000, 'SYP'), '150,000');
    expect(formatMoney(150000.4, 'SYP'), '150,000');
    expect(formatMoney(150000.5, 'SYP'), '150,001');
    expect(formatMoney(0, 'SYP'), '0');
  });

  test('USD shows one decimal only for fractional amounts', () {
    expect(formatMoney(10, 'USD'), '10');
    expect(formatMoney(10.0, 'USD'), '10');
    expect(formatMoney(10.5, 'USD'), '10.5');
    expect(formatMoney(10.55, 'USD'), '10.6');
    expect(formatMoney(1234.5, 'USD'), '1,234.5');
    expect(formatMoney(0, 'USD'), '0');
  });

  test('tiny negatives render as zero, not "-0"', () {
    expect(formatMoney(-0.04, 'USD'), '0');
    expect(formatMoney(-0.4, 'SYP'), '0');
  });

  test('large amounts get grouping with Latin digits', () {
    expect(formatMoney(1500000, 'SYP'), '1,500,000');
    expect(formatMoney(1234.5, 'USD'), '1,234.5');
  });

  test('formatMoneyMap uses per-currency rules', () {
    expect(
      formatMoneyMap({'SYP': 150000, 'USD': 10.5}),
      '+150,000 ل.س · +10.5 \$',
    );
    expect(formatMoneyMap({}), '0');
    expect(formatMoneyMap({'USD': 0}), '0');
  });
}
