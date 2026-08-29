import 'package:flutter_test/flutter_test.dart';
import 'package:io/data/app_database.dart';
import 'package:io/data/repositories/transaction_repository.dart';
import 'package:io/models/transaction_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late TransactionRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute(createTransactionsTableSql);
    repo = SqfliteTransactionRepository(db);
  });

  tearDown(() async => db.close());

  test('insert then getAll returns the transaction', () async {
    final t = TransactionModel(
      type: TransactionType.income,
      amount: 100,
      currency: 'USD',
      date: DateTime(2024, 1, 1),
      createdAt: DateTime(2024, 1, 1),
    );
    await repo.insert(t);

    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.first.amount, 100);
    expect(all.first.type, TransactionType.income);
    expect(all.first.currency, 'USD');
  });

  test('delete removes the transaction', () async {
    final id = await repo.insert(
      TransactionModel(
        type: TransactionType.expense,
        amount: 50,
        currency: 'USD',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    await repo.delete(id);
    final all = await repo.getAll();
    expect(all, isEmpty);
  });

  test('getAll orders by date desc', () async {
    await repo.insert(
      TransactionModel(
        type: TransactionType.income,
        amount: 1,
        currency: 'USD',
        date: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      ),
    );
    await repo.insert(
      TransactionModel(
        type: TransactionType.income,
        amount: 2,
        currency: 'USD',
        date: DateTime(2024, 6, 1),
        createdAt: DateTime.now(),
      ),
    );

    final all = await repo.getAll();
    expect(all.first.amount, 2);
  });

  test('payee suggestions return distinct previous payees', () async {
    await repo.insert(
      TransactionModel(
        type: TransactionType.income,
        amount: 10,
        currency: 'USD',
        payee: 'Ahmed',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    await repo.insert(
      TransactionModel(
        type: TransactionType.income,
        amount: 20,
        currency: 'USD',
        payee: 'Ahmed', // duplicate
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    await repo.insert(
      TransactionModel(
        type: TransactionType.expense,
        amount: 5,
        currency: 'USD',
        payee: 'Landlord',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    final all = await repo.getPayeeSuggestions();
    expect(all, containsAll(['Ahmed', 'Landlord']));
    expect(all.where((e) => e == 'Ahmed').length, 1);

    final filtered = await repo.getPayeeSuggestions(query: 'ahm');
    expect(filtered, ['Ahmed']);
  });
}
