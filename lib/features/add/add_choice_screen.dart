import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:io/core/motion.dart';
import 'package:io/core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class AddChoiceScreen extends StatelessWidget {
  const AddChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Entrance(
                      child: _AddTile(
                        label: l10n.addIncome,
                        iconColor: kIncome,
                        iconBackground: kIncomeSoft,
                        onTap: () => context.push('/add?type=income'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Entrance(
                      delay: kMotionStagger * 2,
                      child: _AddTile(
                        label: l10n.addExpense,
                        iconColor: kExpense,
                        iconBackground: kExpenseSoft,
                        onTap: () => context.push('/add?type=expense'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.label,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  final String label;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: kBorder, width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    child: Icon(Icons.add, color: iconColor, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: kInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
