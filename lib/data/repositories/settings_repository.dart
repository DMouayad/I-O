import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_settings.dart';

abstract class SettingsRepository {
  AppSettings load();
  Future<void> saveLanguage(String code);
  Future<void> saveDefaultCurrency(String code);
  Future<void> saveBiometricEnabled(bool value);
  Future<void> saveLockTimeoutMinutes(int value);
  Future<void> saveSeenInsecureDeviceWarning(bool value);
}

class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kLang = 'language_code';
  static const _kCurrency = 'default_currency';
  static const _kBio = 'biometric_enabled';
  static const _kLockTimeout = 'lock_timeout_minutes';
  static const _kInsecureWarning = 'seen_insecure_device_warning';

  @override
  AppSettings load() => AppSettings(
    languageCode: _prefs.getString(_kLang) ?? 'en',
    defaultCurrency: _prefs.getString(_kCurrency) ?? 'USD',
    biometricEnabled: _prefs.getBool(_kBio) ?? true,
    lockTimeoutMinutes: _sanitizeTimeout(_prefs.getInt(_kLockTimeout)),
    seenInsecureDeviceWarning: _prefs.getBool(_kInsecureWarning) ?? false,
  );

  @override
  Future<void> saveLanguage(String code) => _prefs.setString(_kLang, code);

  @override
  Future<void> saveDefaultCurrency(String code) =>
      _prefs.setString(_kCurrency, code);

  @override
  Future<void> saveBiometricEnabled(bool value) => _prefs.setBool(_kBio, value);

  @override
  Future<void> saveLockTimeoutMinutes(int value) =>
      _prefs.setInt(_kLockTimeout, value);

  @override
  Future<void> saveSeenInsecureDeviceWarning(bool value) =>
      _prefs.setBool(_kInsecureWarning, value);
}

/// Guards against corrupt/legacy stored values (e.g. 0 from another version).
int _sanitizeTimeout(int? stored) => stored == null || stored <= 0 ? 5 : stored;
