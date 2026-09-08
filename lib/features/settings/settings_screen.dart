import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:io/core/theme/palette.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/currency.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';
import '../../state/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.controller});
  final SettingsController? controller;

  SettingsController get _c => controller ?? di.settingsController;

  Future<void> _confirmSeed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed demo data?'),
        content: const Text(
          'This deletes all existing transactions and inserts generated demo data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seed'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final count = await di.transactionsController.seedYearToDate();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Seeded $count transactions')));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const gap = SizedBox(height: 6);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SignalBuilder(
        builder: (context) {
          final s = _c.settings.value;
          return ListView(
            children: [
              ListTile(
                title: Text(l10n.language),
                trailing: _DropdownBox(
                  value: s.languageCode,
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                    DropdownMenuItem(value: 'ar', child: Text(l10n.arabic)),
                  ],
                  onChanged: (v) {
                    if (v != null) _c.setLanguage(v);
                  },
                ),
              ),
              gap,
              ListTile(
                title: Text(l10n.defaultCurrency),
                trailing: _DropdownBox(
                  value: s.defaultCurrency,
                  items: kCurrencies
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.code,
                          child: Text(c.code),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _c.setDefaultCurrency(v);
                  },
                ),
              ),
              gap,
              const Divider(),
              SwitchListTile(
                title: Text(l10n.biometricAuth),
                value: s.biometricEnabled,
                onChanged: _c.setBiometricEnabled,
              ),
              if (s.biometricEnabled)
                ListTile(
                  title: Text(l10n.lockAfter),
                  trailing: _DropdownBox<int>(
                    value: s.lockTimeoutMinutes,
                    items: const [1, 5, 15, 30]
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m ${l10n.minutesShort}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _c.setLockTimeoutMinutes(v);
                    },
                  ),
                ),
              const Divider(),
              ListTile(title: Text(l10n.about), subtitle: const Text('v1.0.0')),
              // Debug-only: hard-coded strings, no l10n needed.
              if (kDebugMode) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: const Text('Seed demo data'),
                  subtitle: const Text('Replaces all transactions'),
                  onTap: () => _confirmSeed(context),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Trailing dropdown styled like the boxed inputs: white, 1px border, no
/// default underline.
class _DropdownBox<T> extends StatelessWidget {
  const _DropdownBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: pal.surfaceHigh,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: pal.border),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(kRadius),
        iconSize: 20,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: pal.text,
        ),
      ),
    );
  }
}
