import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'core/theme/app_theme.dart';
import 'di.dart';
import 'l10n/generated/app_localizations.dart';
import 'routing/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final settings = settingsController.settings.value;
        return MaterialApp.router(
          title: 'IO',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          routerConfig: appRouter,
          locale: Locale(settings.languageCode),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        );
      },
    );
  }
}
