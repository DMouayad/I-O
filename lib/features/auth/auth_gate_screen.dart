import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:io/core/motion.dart';
import 'package:io/core/theme/palette.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../di.dart';
import '../../l10n/generated/app_localizations.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAuth());
  }

  Future<void> _tryAuth() async {
    if (!settingsController.settings.value.biometricEnabled) {
      _goHome();
      return;
    }
    final ok = await authController.authenticate();
    if (ok) {
      _goHome();
    } else {
      if (!mounted) return;
      final err = authController.lastError.value;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err ?? 'Authentication failed')));
    }
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
                    onPressed: _tryAuth,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l10n.unlock),
                  ),
                ),
                const SizedBox(height: 16),
                SignalBuilder(
                  builder: (_) {
                    final err = authController.lastError.value;
                    if (err == null) return const SizedBox.shrink();
                    return Text(
                      err,
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
