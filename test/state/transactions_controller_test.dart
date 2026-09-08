import 'package:flutter_test/flutter_test.dart';
import 'package:io/models/transaction_model.dart';
import 'package:io/state/transactions_controller.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  test('add appends a transaction and load populates list', () async {
    final controller = TransactionsController(FakeTransactionRepository());
    expect(controller.transactions.value, isEmpty);

    await controller.add(
      TransactionModel(
        type: TransactionType.income,
        amount: 200,
        currency: 'USD',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    expect(controller.transactions.value.length, 1);
    expect(controller.transactions.value.first.amount, 200);
  });

  test('remove deletes a transaction', () async {
    final controller = TransactionsController(FakeTransactionRepository());
    await controller.add(
      TransactionModel(
        type: TransactionType.expense,
        amount: 30,
        currency: 'USD',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    final id = controller.transactions.value.first.id!;
    await controller.remove(id);
    expect(controller.transactions.value, isEmpty);
  });

  test('seedYearToDate wipes existing and inserts demo data', () async {
    final controller = TransactionsController(FakeTransactionRepository());
    await controller.add(
      TransactionModel(
        type: TransactionType.expense,
        amount: 30,
        currency: 'USD',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    final count = await controller.seedYearToDate();
    expect(count, greaterThan(100));
    expect(controller.transactions.value.length, count);
    // The manually added transaction is gone (wiped).
    expect(controller.transactions.value.any((t) => t.amount == 30), isFalse);
    // Roughly 90/10 SYP/USD split.
    final syp = controller.transactions.value
        .where((t) => t.currency == 'SYP')
        .length;
    expect(syp / count, inInclusiveRange(0.8, 0.98));
  });

  test('seedYearToDate appends when wipe is false', () async {
    final controller = TransactionsController(FakeTransactionRepository());
    await controller.seedYearToDate();
    final first = controller.transactions.value.length;
    final added = await controller.seedYearToDate(wipe: false);
    expect(controller.transactions.value.length, first + added);
  });
}
