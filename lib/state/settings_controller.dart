import 'package:signals_flutter/signals_flutter.dart';
import '../data/repositories/settings_repository.dart';
import '../models/app_settings.dart';

class SettingsController {
  SettingsController(this._repo);
  final SettingsRepository _repo;

  final Signal<AppSettings> settings = signal(const AppSettings());

  void load() => settings.value = _repo.load();

  Future<void> setLanguage(String code) async {
    await _repo.saveLanguage(code);
    settings.value = settings.value.copyWith(languageCode: code);
  }

  Future<void> setDefaultCurrency(String code) async {
    await _repo.saveDefaultCurrency(code);
    settings.value = settings.value.copyWith(defaultCurrency: code);
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _repo.saveBiometricEnabled(value);
    settings.value = settings.value.copyWith(biometricEnabled: value);
  }

  Future<void> setLockTimeoutMinutes(int value) async {
    assert(value > 0, 'lock timeout must be positive');
    await _repo.saveLockTimeoutMinutes(value);
    settings.value = settings.value.copyWith(lockTimeoutMinutes: value);
  }
}
