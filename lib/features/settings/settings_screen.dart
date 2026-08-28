import 'package:flutter/material.dart';
import 'package:io/core/theme/app_theme.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../core/currency.dart';
import '../../di.dart' as di;
import '../../l10n/generated/app_localizations.dart';
import '../../state/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.controller});
  final SettingsController? controller;

  SettingsController get _c => controller ?? di.settingsController;

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
              const Divider(),
              ListTile(title: Text(l10n.about), subtitle: const Text('v1.0.0')),
            ],
          );
        },
      ),
    );
  }
}

/// Trailing dropdown styled like the boxed inputs: white, 1px border, no
/// default underline.
class _DropdownBox extends StatelessWidget {
  const _DropdownBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(kRadius),
        iconSize: 20,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kInk,
        ),
      ),
    );
  }
}
