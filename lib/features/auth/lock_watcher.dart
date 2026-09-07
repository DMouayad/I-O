import 'package:flutter/widgets.dart';
import 'package:io/di.dart' as di;
import 'package:io/routing/app_router.dart';

/// Re-locks the app when it returns from background after the grace period.
///
/// Wraps the whole app (see [MyApp]). On backgrounding it stamps the time;
/// on resume, when the biometric lock is enabled and the user was away longer
/// than [lockTimeoutMinutes], it locks and routes back to the auth gate.
class LockWatcher extends StatefulWidget {
  const LockWatcher({super.key, required this.child});
  final Widget child;

  @override
  State<LockWatcher> createState() => _LockWatcherState();
}

class _LockWatcherState extends State<LockWatcher> with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt = di.authController.now();
    } else if (state == AppLifecycleState.resumed) {
      _onResumed();
    }
  }

  void _onResumed() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (!shouldRelock(
      lockEnabled: di.settingsController.settings.value.biometricEnabled,
      authenticated: di.authController.isAuthenticated.value,
      backgroundedAt: backgroundedAt,
      timeoutMinutes: di.settingsController.settings.value.lockTimeoutMinutes,
      now: di.authController.now(),
    )) {
      return;
    }
    di.authController.lock();
    if (appRouter.state.uri.toString() != '/') {
      appRouter.go('/');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Pure relock decision, kept free of widget/DI for unit testing.
bool shouldRelock({
  required bool lockEnabled,
  required bool authenticated,
  required DateTime? backgroundedAt,
  required int timeoutMinutes,
  required DateTime now,
}) {
  if (!lockEnabled || !authenticated) return false;
  if (timeoutMinutes <= 0 || backgroundedAt == null) return false;
  return now.difference(backgroundedAt).inSeconds >= timeoutMinutes * 60;
}
