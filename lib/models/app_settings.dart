class AppSettings {
  final String languageCode; // 'en' | 'ar'
  final String defaultCurrency;
  final bool biometricEnabled;

  /// Minutes in background before re-auth is required. Always > 0.
  final int lockTimeoutMinutes;

  const AppSettings({
    this.languageCode = 'en',
    this.defaultCurrency = 'USD',
    this.biometricEnabled = true,
    this.lockTimeoutMinutes = 5,
  });

  AppSettings copyWith({
    String? languageCode,
    String? defaultCurrency,
    bool? biometricEnabled,
    int? lockTimeoutMinutes,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lockTimeoutMinutes: lockTimeoutMinutes ?? this.lockTimeoutMinutes,
    );
  }
}
