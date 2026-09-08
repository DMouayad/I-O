import 'package:flutter/services.dart';

/// Thrown when the Keyguard device-credential prompt cannot be shown.
///
/// A user cancel is NOT an exception — [DeviceCredentialAuth.confirm]
/// returns false for it, mirroring local_auth's silent userCanceled path.
class DeviceCredentialException implements Exception {
  DeviceCredentialException(this.code, [this.message]);
  final String code;
  final String? message;

  @override
  String toString() => 'DeviceCredentialException($code): $message';
}

/// PIN/pattern/password prompt via Android's KeyguardManager.
///
/// Fallback for [LocalAuthentication.authenticate] on devices without
/// biometric hardware: the plugin throws `noBiometricHardware` instead of
/// showing the PIN screen there (upstream androidx/OEM issue — reported on
/// Xiaomi, Zebra, Samsung A0x, Huawei), while
/// `KeyguardManager.createConfirmDeviceCredentialIntent` shows it fine.
class DeviceCredentialAuth {
  static const _channel = MethodChannel('io.app/device_credential');

  /// Shows the system PIN screen. Returns true when the user confirmed,
  /// false when they dismissed it. Throws [DeviceCredentialException] when
  /// the prompt can't be shown (no screen lock, another prompt in flight,
  /// or non-Android platform).
  Future<bool> confirm({
    required String title,
    required String description,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('confirmDeviceCredential', {
        'title': title,
        'description': description,
      });
      return ok ?? false;
    } on MissingPluginException {
      throw DeviceCredentialException(
        'unavailable',
        'device credential channel missing (non-Android?)',
      );
    } on PlatformException catch (e) {
      throw DeviceCredentialException(e.code, e.message);
    }
  }
}
