import 'package:io/data/repositories/settings_repository.dart';
import 'package:io/models/app_settings.dart';

class FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  AppSettings load() => _settings;

  @override
  Future<void> saveLanguage(String code) async {
    _settings = _settings.copyWith(languageCode: code);
  }

  @override
  Future<void> saveDefaultCurrency(String code) async {
    _settings = _settings.copyWith(defaultCurrency: code);
  }

  @override
  Future<void> saveBiometricEnabled(bool value) async {
    _settings = _settings.copyWith(biometricEnabled: value);
  }
}
