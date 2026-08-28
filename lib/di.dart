import 'package:shared_preferences/shared_preferences.dart';
import 'data/app_database.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'state/auth_controller.dart';
import 'state/reports_controller.dart';
import 'state/settings_controller.dart';
import 'state/transactions_controller.dart';

late final AppDatabase appDatabase;
late final TransactionRepository transactionRepository;
late final SettingsRepository settingsRepository;
late final TransactionsController transactionsController;
late final ReportsController reportsController;
late final SettingsController settingsController;
late final AuthController authController;

Future<void> setupDependencies() async {
  appDatabase = AppDatabase();
  await appDatabase.init();

  transactionRepository = SqfliteTransactionRepository(appDatabase.database);
  settingsRepository = SharedPrefsSettingsRepository(
    await SharedPreferences.getInstance(),
  );

  transactionsController = TransactionsController(transactionRepository);
  await transactionsController.load();

  reportsController = ReportsController(transactionsController);

  settingsController = SettingsController(settingsRepository);
  settingsController.load();

  authController = AuthController();
}
