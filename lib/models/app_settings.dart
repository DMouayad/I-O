class AppSettings {
  final String languageCode; // 'en' | 'ar'
  final String defaultCurrency;
  final bool biometricEnabled;

  const AppSettings({
    this.languageCode = 'en',
    this.defaultCurrency = 'USD',
    this.biometricEnabled = true,
  });

  AppSettings copyWith({
    String? languageCode,
    String? defaultCurrency,
    bool? biometricEnabled,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}
