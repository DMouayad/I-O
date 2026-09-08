import 'package:flutter_test/flutter_test.dart';
import 'package:io/features/day/swap_screen.dart';

void main() {
  test('USD -> SYP multiplies by the rate', () {
    expect(convertSwapAmount(amount: 100, rate: 10000, fromUsd: true), 1000000);
  });

  test('SYP -> USD divides by the rate', () {
    expect(
      convertSwapAmount(amount: 1000000, rate: 10000, fromUsd: false),
      100,
    );
  });

  test('fractional amounts survive the round trip', () {
    final toSyp = convertSwapAmount(amount: 12.5, rate: 11500.5, fromUsd: true);
    final back = convertSwapAmount(
      amount: toSyp,
      rate: 11500.5,
      fromUsd: false,
    );
    expect(back, closeTo(12.5, 1e-9));
  });
}
