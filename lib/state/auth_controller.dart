import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AuthController {
  final LocalAuthentication _auth = LocalAuthentication();
  final Signal<bool> isAuthenticated = signal(false);
  final Signal<String?> lastError = signal(null);

  Future<bool> authenticate() async {
    lastError.value = null;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        // No lock mechanism available on this device/emulator.
        debugPrint('[AuthController] isDeviceSupported=false → auto-allow');
        isAuthenticated.value = true;
        return true;
      }
      debugPrint(
        '[AuthController] isDeviceSupported=true → calling authenticate(biometricOnly:false)',
      );
      final ok = await _auth.authenticate(
        localizedReason: 'Authenticate to access your data',
        biometricOnly: false,
      );
      debugPrint('[AuthController] authenticate result: $ok');
      isAuthenticated.value = ok;
      if (!ok) {
        lastError.value = 'Authentication returned false (canceled/failed)';
      }
      return ok;
    } on LocalAuthException catch (e) {
      debugPrint(
        '[AuthController] LocalAuthException code=${e.code.name} desc=${e.description} details=${e.details}',
      );
      // OEM/BiometricPrompt compat path the check fails while isDeviceSupported
      // is true because a PIN is set → treat as device-secure pass (option A).
      if (e.code == LocalAuthExceptionCode.noBiometricHardware ||
          e.code == LocalAuthExceptionCode.noBiometricsEnrolled) {
        debugPrint(
          '[AuthController] ${e.code.name} but isDeviceSupported=true → allowing (PIN-unlocked device)',
        );
        // Verify device still reports secure (defensive re-check).
        try {
          final stillSupported = await _auth.isDeviceSupported();
          if (stillSupported) {
            lastError.value = null;
            isAuthenticated.value = true;
            return true;
          }
        } catch (_) {}
      }
      // userCanceled/systemCanceled are silent — don't surface as error.
      if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled) {
        lastError.value = null;
      } else {
        lastError.value =
            'LocalAuthException ${e.code.name}${e.description != null ? ': ${e.description}' : ''}';
      }
      isAuthenticated.value = false;
      return false;
    } on PlatformException catch (e) {
      debugPrint(
        '[AuthController] PlatformException code=${e.code} message=${e.message} details=${e.details}',
      );
      lastError.value = 'PlatformException ${e.code}: ${e.message}';
      isAuthenticated.value = false;
      return false;
    } catch (e, st) {
      debugPrint('[AuthController] Unexpected error: $e');
      debugPrint('$st');
      lastError.value = 'Unexpected error: $e';
      isAuthenticated.value = false;
      return false;
    }
  }
}
