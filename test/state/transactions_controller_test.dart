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
        category: 'sales',
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
        category: 'rent',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    final id = controller.transactions.value.first.id!;
    await controller.remove(id);
    expect(controller.transactions.value, isEmpty);
  });
}
