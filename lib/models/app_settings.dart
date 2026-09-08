class AppSettings {
  final String languageCode; // 'en' | 'ar'
  final String defaultCurrency;
  final bool biometricEnabled;

  /// Minutes in background before re-auth is required. Always > 0.
  final int lockTimeoutMinutes;

  /// Whether the first-time "no device lock" warning was already shown.
  /// Guards the insecure auto-allow path so it warns exactly once ever.
  final bool seenInsecureDeviceWarning;

  const AppSettings({
    this.languageCode = 'en',
    this.defaultCurrency = 'USD',
    this.biometricEnabled = true,
    this.lockTimeoutMinutes = 5,
    this.seenInsecureDeviceWarning = false,
  });

  AppSettings copyWith({
    String? languageCode,
    String? defaultCurrency,
    bool? biometricEnabled,
    int? lockTimeoutMinutes,
    bool? seenInsecureDeviceWarning,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lockTimeoutMinutes: lockTimeoutMinutes ?? this.lockTimeoutMinutes,
      seenInsecureDeviceWarning:
          seenInsecureDeviceWarning ?? this.seenInsecureDeviceWarning,
    );
  }
}
