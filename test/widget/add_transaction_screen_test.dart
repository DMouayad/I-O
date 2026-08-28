import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:io/features/add_transaction/add_transaction_screen.dart';
import 'package:io/l10n/generated/app_localizations.dart';
import 'package:io/models/transaction_model.dart';
import 'package:io/state/settings_controller.dart';
import 'package:io/state/transactions_controller.dart';
import '../fakes/fake_settings_repository.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  testWidgets(
    'entering a valid amount and saving adds a transaction and pops',
    (tester) async {
      final tc = TransactionsController(FakeTransactionRepository());
      final sc = SettingsController(FakeSettingsRepository());
      sc.load();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AddTransactionScreen(
            type: TransactionType.income,
            controller: tc,
            settingsController: sc,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '150');
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(tc.transactions.value.length, 1);
      expect(tc.transactions.value.first.amount, 150);
    },
  );

  testWidgets('invalid amount shows an error and does not save', (
    tester,
  ) async {
    final tc = TransactionsController(FakeTransactionRepository());
    final sc = SettingsController(FakeSettingsRepository());
    sc.load();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddTransactionScreen(
          type: TransactionType.expense,
          controller: tc,
          settingsController: sc,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tc.transactions.value, isEmpty);
    expect(find.text('Please enter a valid amount'), findsOneWidget);
  });
}
