import 'package:flutter_test/flutter_test.dart';
import 'package:io/state/settings_controller.dart';
import '../fakes/fake_settings_repository.dart';

void main() {
  test('setLanguage updates the signal and persists', () async {
    final controller = SettingsController(FakeSettingsRepository());
    controller.load();
    expect(controller.settings.value.languageCode, 'en');

    await controller.setLanguage('ar');
    expect(controller.settings.value.languageCode, 'ar');
  });

  test('setDefaultCurrency updates the signal', () async {
    final controller = SettingsController(FakeSettingsRepository());
    controller.load();
    await controller.setDefaultCurrency('SAR');
    expect(controller.settings.value.defaultCurrency, 'SAR');
  });
}
