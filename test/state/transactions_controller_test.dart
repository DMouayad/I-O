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

  test('removeDay deletes one day and restoreAll brings it back', () async {
    TransactionModel tx(TransactionType type, double amount, DateTime date) =>
        TransactionModel(
          type: type,
          amount: amount,
          currency: 'USD',
          date: date,
          createdAt: date,
        );
    final controller = TransactionsController(FakeTransactionRepository());
    await controller.add(
      tx(TransactionType.income, 100, DateTime(2024, 5, 13, 9)),
    );
    await controller.add(
      tx(TransactionType.expense, 40, DateTime(2024, 5, 13, 10)),
    );
    await controller.add(
      tx(TransactionType.expense, 7, DateTime(2024, 5, 14, 10)),
    );

    final snapshot = await controller.removeDay(DateTime(2024, 5, 13));
    expect(snapshot.length, 2);
    expect(controller.transactions.value.length, 1);
    expect(controller.transactions.value.first.amount, 7);

    await controller.restoreAll(snapshot);
    expect(controller.transactions.value.length, 3);
  });

  test('removeDay with type removes only that tab slice', () async {
    final controller = TransactionsController(FakeTransactionRepository());
    final day = DateTime(2024, 5, 13, 10);
    await controller.add(
      TransactionModel(
        type: TransactionType.income,
        amount: 100,
        currency: 'USD',
        date: day,
        createdAt: day,
      ),
    );
    await controller.add(
      TransactionModel(
        type: TransactionType.expense,
        amount: 40,
        currency: 'USD',
        date: day,
        createdAt: day,
      ),
    );

    final snapshot = await controller.removeDay(
      DateTime(2024, 5, 13),
      type: TransactionType.expense,
    );
    expect(snapshot.length, 1);
    expect(controller.transactions.value.length, 1);
    expect(controller.transactions.value.first.type, TransactionType.income);
  });

  test('removeDay on an empty day returns empty and changes nothing', () async {
    final controller = TransactionsController(FakeTransactionRepository());
    await controller.add(
      TransactionModel(
        type: TransactionType.income,
        amount: 100,
        currency: 'USD',
        date: DateTime(2024, 5, 13, 10),
        createdAt: DateTime(2024, 5, 13, 10),
      ),
    );

    final snapshot = await controller.removeDay(DateTime(2024, 5, 14));
    expect(snapshot, isEmpty);
    expect(controller.transactions.value.length, 1);
  });
}
