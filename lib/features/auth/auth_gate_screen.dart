import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:io/core/motion.dart';
import 'package:io/core/theme/palette.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../di.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/auth_controller.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  /// Guards against raced auth prompts: initState auto-try + rapid
  /// Unlock taps would otherwise throw `authInProgress` (see
  /// [AuthController.isAuthenticating]).
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAuth());
  }

  Future<void> _tryAuth() async {
    if (!mounted || _busy) return;
    if (!settingsController.settings.value.biometricEnabled) {
      _goHome();
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final ok = await authController.authenticate(
        localizedReason: l10n.authPromptReason,
        credentialTitle: l10n.appTitle,
      );
      if (!mounted) return;
      if (ok) {
        await _maybeWarnInsecureDevice();
        if (!mounted) return;
        _goHome();
      } else {
        // Silent cancels (user/system dismiss, raced call) carry no failure
        // — the gate stays put for an explicit retry, no snackbar spam.
        final failure = authController.lastFailure.value;
        if (failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message(AppLocalizations.of(context))),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// First-time warning for the insecure auto-allow path (device reports
  /// no lock mechanism). Shown exactly once ever, then remembered.
  Future<void> _maybeWarnInsecureDevice() async {
    if (!authController.insecureFallbackUsed) return;
    if (settingsController.settings.value.seenInsecureDeviceWarning) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.noDeviceLockTitle),
        content: Text(l10n.noDeviceLockMessage),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );
    await settingsController.setSeenInsecureDeviceWarning(true);
  }

  void _goHome() {
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: pal.surfaceHigh,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: pal.border),
                  ),
                  child: Icon(Icons.lock_outlined, size: 30, color: pal.text),
                ),
                const SizedBox(height: 20),
                Entrance(
                  delay: kMotionStagger * 2,
                  child: Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 32),
                Entrance(
                  delay: kMotionStagger * 4,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _tryAuth,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: Text(l10n.unlock),
                  ),
                ),
                const SizedBox(height: 16),
                SignalBuilder(
                  builder: (_) {
                    final failure = authController.lastFailure.value;
                    if (failure == null) return const SizedBox.shrink();
                    return Text(
                      failure.message(l10n),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: pal.expense),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Maps [AuthFailure] codes to localized strings. Lives in the UI layer
/// so the controller never carries display text.
extension AuthFailureMessage on AuthFailure {
  String message(AppLocalizations l10n) => switch (this) {
    AuthFailure.noBiometricsEnrolled => l10n.authNoBiometrics,
    AuthFailure.noCredentialsSet => l10n.authNoScreenLock,
    AuthFailure.timedOut => l10n.authTimedOut,
    AuthFailure.platform || AuthFailure.unexpected => l10n.authFailed,
  };
}
