import 'package:flutter_test/flutter_test.dart';
import 'package:io/models/transaction_model.dart';
import 'package:io/state/reports_controller.dart';
import 'package:io/state/transactions_controller.dart';
import '../fakes/fake_transaction_repository.dart';

TransactionModel _tx({
  required TransactionType type,
  required double amount,
  String currency = 'USD',
  String? payee,
}) {
  final now = DateTime(2026, 5, 10, 12);
  return TransactionModel(
    type: type,
    amount: amount,
    currency: currency,
    payee: payee,
    date: now,
    createdAt: now,
  );
}

void main() {
  test('totalsForDay is signed: income +, expense −, day net', () async {
    final tx = TransactionsController(FakeTransactionRepository());
    await tx.add(_tx(type: TransactionType.income, amount: 100));
    await tx.add(_tx(type: TransactionType.expense, amount: 25));
    final reports = ReportsController(tx);
    final day = DateTime(2026, 5, 10);

    expect(reports.totalsForDay(day, type: TransactionType.income), {
      'USD': 100.0,
    });
    // Signed by construction — Reports negates for display math.
    expect(reports.totalsForDay(day, type: TransactionType.expense), {
      'USD': -25.0,
    });
    expect(reports.totalsForDay(day), {'USD': 75.0});
  });

  test('payee suggestions capped + recency ordered', () async {
    final tx = TransactionsController(FakeTransactionRepository());
    for (var i = 0; i < 8; i++) {
      final day = DateTime(2026, 5, 1 + i, 12);
      await tx.add(
        TransactionModel(
          type: TransactionType.expense,
          amount: 1,
          currency: 'USD',
          payee: 'Shop $i',
          date: day,
          createdAt: day,
        ),
      );
    }
    final suggestions = tx.payeeSuggestions('');
    expect(suggestions.length, lessThanOrEqualTo(5));
    // Newest first (getAll orders date DESC).
    expect(suggestions.first, 'Shop 7');
  });
}
