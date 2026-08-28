import 'package:go_router/go_router.dart';
import 'package:io/core/motion.dart';
import '../features/add_transaction/add_transaction_screen.dart';
import '../features/auth/auth_gate_screen.dart';
import '../features/home/home_shell_screen.dart';
import '../models/transaction_model.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const AuthGateScreen()),
    GoRoute(path: '/home', builder: (_, _) => const HomeShellScreen()),
    GoRoute(
      path: '/add',
      pageBuilder: (context, state) {
        final typeParam = state.uri.queryParameters['type'];
        final type = typeParam == 'income'
            ? TransactionType.income
            : TransactionType.expense;

        return boxyPage(child: AddTransactionScreen(type: type));
      },
    ),
  ],
);
