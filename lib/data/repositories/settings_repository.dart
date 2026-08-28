import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_settings.dart';

abstract class SettingsRepository {
  AppSettings load();
  Future<void> saveLanguage(String code);
  Future<void> saveDefaultCurrency(String code);
  Future<void> saveBiometricEnabled(bool value);
}

class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kLang = 'language_code';
  static const _kCurrency = 'default_currency';
  static const _kBio = 'biometric_enabled';

  @override
  AppSettings load() => AppSettings(
    languageCode: _prefs.getString(_kLang) ?? 'en',
    defaultCurrency: _prefs.getString(_kCurrency) ?? 'USD',
    biometricEnabled: _prefs.getBool(_kBio) ?? true,
  );

  @override
  Future<void> saveLanguage(String code) => _prefs.setString(_kLang, code);

  @override
  Future<void> saveDefaultCurrency(String code) =>
      _prefs.setString(_kCurrency, code);

  @override
  Future<void> saveBiometricEnabled(bool value) => _prefs.setBool(_kBio, value);
}
