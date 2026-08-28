import 'package:flutter_test/flutter_test.dart';
import 'package:io/models/transaction_model.dart';
import 'package:io/state/reports_controller.dart';
import 'package:io/state/transactions_controller.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  test('totalsByCurrency sums per currency independently', () async {
    final tc = TransactionsController(FakeTransactionRepository());
    await tc.add(
      TransactionModel(
        type: TransactionType.income,
        amount: 100,
        currency: 'USD',
        category: 'sales',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    await tc.add(
      TransactionModel(
        type: TransactionType.expense,
        amount: 40,
        currency: 'USD',
        category: 'rent',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    await tc.add(
      TransactionModel(
        type: TransactionType.income,
        amount: 500,
        currency: 'SAR',
        category: 'services',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    final rc = ReportsController(tc);
    rc.rangeType.value = ReportRangeType.all;

    final totals = rc.totalsByCurrency.value;
    expect(totals['USD']!.income, 100);
    expect(totals['USD']!.expense, 40);
    expect(totals['USD']!.balance, 60);
    expect(totals['SAR']!.income, 500);
    expect(totals.containsKey('SAR'), isTrue);
  });

  test('rangeType filters out old transactions', () async {
    final tc = TransactionsController(FakeTransactionRepository());
    await tc.add(
      TransactionModel(
        type: TransactionType.income,
        amount: 100,
        currency: 'USD',
        category: 'sales',
        date: DateTime.now().subtract(const Duration(days: 60)),
        createdAt: DateTime.now(),
      ),
    );

    final rc = ReportsController(tc);
    rc.rangeType.value = ReportRangeType.thisMonth;

    expect(rc.filtered.value, isEmpty);

    rc.rangeType.value = ReportRangeType.all;
    expect(rc.filtered.value.length, 1);
  });
}
