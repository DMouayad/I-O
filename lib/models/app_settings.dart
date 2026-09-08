class AppSettings {
  final String languageCode; // 'en' | 'ar'
  final String defaultCurrency;
  final bool biometricEnabled;

  /// Minutes in background before re-auth is required. Always > 0.
  final int lockTimeoutMinutes;

  /// Whether the first-time "no device lock" warning was already shown.
  /// Guards the insecure auto-allow path so it warns exactly once ever.
  final bool seenInsecureDeviceWarning;

  /// Last used USD→SYP swap rate, pre-filled on the swap screen. Null when
  /// the user never swapped.
  final double? lastSwapRate;

  const AppSettings({
    this.languageCode = 'en',
    this.defaultCurrency = 'USD',
    this.biometricEnabled = true,
    this.lockTimeoutMinutes = 5,
    this.seenInsecureDeviceWarning = false,
    this.lastSwapRate,
  });

  AppSettings copyWith({
    String? languageCode,
    String? defaultCurrency,
    bool? biometricEnabled,
    int? lockTimeoutMinutes,
    bool? seenInsecureDeviceWarning,
    double? lastSwapRate,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lockTimeoutMinutes: lockTimeoutMinutes ?? this.lockTimeoutMinutes,
      seenInsecureDeviceWarning:
          seenInsecureDeviceWarning ?? this.seenInsecureDeviceWarning,
      lastSwapRate: lastSwapRate ?? this.lastSwapRate,
    );
  }
}
