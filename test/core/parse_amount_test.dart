import 'package:flutter_test/flutter_test.dart';
import 'package:io/core/currency.dart';

void main() {
  test('plain + western decimals', () {
    expect(parseAmount('12.50'), 12.5);
    expect(parseAmount('  100 '), 100.0);
    expect(parseAmount('0.00'), 0.0);
  });

  test('comma as decimal when no dot present', () {
    expect(parseAmount('12,50'), 12.5);
  });

  test('commas as thousands when dot present', () {
    expect(parseAmount('1,000.50'), 1000.5);
  });

  test('arabic-indic digits + arabic separators', () {
    expect(parseAmount('١٢٫٥٠'), 12.5);
    expect(parseAmount('١٬٠٠٠٫٥٠'), 1000.5);
  });

  test('invalid input returns null', () {
    expect(parseAmount(''), isNull);
    expect(parseAmount('   '), isNull);
    expect(parseAmount('abc'), isNull);
    expect(parseAmount('--12'), isNull);
  });
}
