import 'package:go_router/go_router.dart';
import 'package:io/core/motion.dart';
import '../features/auth/auth_gate_screen.dart';
import '../features/day/day_screen.dart';
import '../features/day/swap_screen.dart';
import '../features/home/home_shell_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const AuthGateScreen()),
    GoRoute(path: '/home', builder: (_, _) => const HomeShellScreen()),
    GoRoute(
      path: '/day/:isoDate',
      pageBuilder: (context, state) {
        final iso = state.pathParameters['isoDate']!;
        final day = DateTime.parse(iso);
        return boxyPage(
          child: DayScreen(day: DateTime(day.year, day.month, day.day)),
        );
      },
      routes: [
        GoRoute(
          path: 'swap',
          pageBuilder: (context, state) {
            final iso = state.pathParameters['isoDate']!;
            final day = DateTime.parse(iso);
            return boxyPage(
              child: SwapScreen(day: DateTime(day.year, day.month, day.day)),
            );
          },
        ),
      ],
    ),
  ],
);
