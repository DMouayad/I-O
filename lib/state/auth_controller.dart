import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'device_credential_auth.dart';

/// Localizable auth failure. The UI layer maps these to [AppLocalizations]
/// strings; [AuthController.lastErrorDetail] keeps the raw technical detail
/// for non-localizable cases (debug/logging only, never shown directly).
enum AuthFailure {
  noBiometricsEnrolled,
  noCredentialsSet,
  timedOut,
  platform,
  unexpected,
}

class AuthController {
  AuthController({
    LocalAuthentication? auth,
    DeviceCredentialAuth? deviceCredential,
  }) : _auth = auth ?? LocalAuthentication(),
       _deviceCredential = deviceCredential ?? DeviceCredentialAuth();

  final LocalAuthentication _auth;
  final DeviceCredentialAuth _deviceCredential;
  final Signal<bool> isAuthenticated = signal(false);
  final Signal<AuthFailure?> lastFailure = signal(null);

  /// Raw detail for [AuthFailure.platform]/[AuthFailure.unexpected].
  /// Debug/logging only — the UI shows the localized generic string.
  String? lastErrorDetail;

  /// True when the last [authenticate] call took the insecure path
  /// (device reports no lock mechanism → auto-allowed). The gate uses this
  /// to show the first-time no-device-lock warning. Reset on every call.
  bool insecureFallbackUsed = false;

  /// True while an [authenticate] call is awaiting the system dialog.
  /// Used to drop raced calls (double-tap, re-navigation) that would
  /// otherwise throw `authInProgress` and strand the gate on an error.
  bool _inProgress = false;
  bool get isAuthenticating => _inProgress;

  /// Bumped by [lock] so a still-pending dialog that resolves afterwards
  /// (possible with [persistAcrossBackgrounding]) can't undo the re-lock.
  int _generation = 0;

  /// Safety net if the native dialog never resolves. Test seam: shrink in
  /// tests to avoid waiting out the real minute.
  Duration authTimeout = const Duration(minutes: 1);

  /// Last successful unlock. Null until the first unlock this session —
  /// expiry checks treat that as "not expired" (fresh launch always gates).
  DateTime? lastUnlockedAt;

  /// Test seam: allows freezing "now" in widget/unit tests.
  DateTime Function() now = DateTime.now;

  void _markUnlocked() {
    isAuthenticated.value = true;
    lastUnlockedAt = now();
  }

  /// Drops the session. Bumps [_generation] so an in-flight [authenticate]
  /// that resolves afterwards is treated as stale and ignored.
  /// The lifecycle watcher calls this on resume past the grace period;
  /// the router then sends the user back to the gate.
  void lock() {
    _generation++;
    isAuthenticated.value = false;
    lastFailure.value = null;
    lastErrorDetail = null;
    lastUnlockedAt = null;
  }

  /// True when [lastUnlockedAt] is older than [timeoutMinutes]. Returns
  /// false when never unlocked this session or timeout is non-positive.
  bool isExpired({required int timeoutMinutes}) {
    final unlockedAt = lastUnlockedAt;
    if (timeoutMinutes <= 0 || unlockedAt == null) return false;
    return now().difference(unlockedAt).inSeconds >= timeoutMinutes * 60;
  }

  Future<bool> authenticate({
    String? localizedReason,
    String? credentialTitle,
  }) async {
    if (_inProgress) {
      // Raced call (double-tap, gate rebuilt while dialog open).
      // local_auth would throw authInProgress — stay silent instead.
      debugPrint('[AuthController] authenticate skipped: already in progress');
      return false;
    }
    _inProgress = true;
    final generation = _generation;
    lastFailure.value = null;
    lastErrorDetail = null;
    insecureFallbackUsed = false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        // No lock mechanism on this device/emulator: nothing to prompt
        // with. Kept as an explicit auto-allow flow — the gate shows a
        // first-time warning via [insecureFallbackUsed].
        debugPrint('[AuthController] isDeviceSupported=false → auto-allow');
        insecureFallbackUsed = true;
        _markUnlocked();
        return true;
      }
      debugPrint(
        '[AuthController] isDeviceSupported=true → calling authenticate(biometricOnly:false)',
      );
      final ok = await _auth
          .authenticate(
            localizedReason:
                localizedReason ?? 'Authenticate to access your data',
            biometricOnly: false,
            // System may cancel auth when the app backgrounds mid-prompt
            // (call, screen off) — retry on return instead of surfacing
            // systemCanceled and stranding the gate.
            persistAcrossBackgrounding: true,
          )
          .timeout(authTimeout);
      if (generation != _generation) {
        // lock() ran while the dialog was open — this result is stale.
        debugPrint('[AuthController] stale result ignored (locked meanwhile)');
        return false;
      }
      debugPrint('[AuthController] authenticate result: $ok');
      if (ok) {
        _markUnlocked();
      } else {
        // Canceled/dismissed without an exception — silent, the gate
        // stays put with the Unlock button for an explicit retry.
        isAuthenticated.value = false;
      }
      return ok;
    } on LocalAuthException catch (e) {
      debugPrint(
        '[AuthController] LocalAuthException code=${e.code.name} desc=${e.description} details=${e.details}',
      );
      if (generation != _generation) return false;
      // The plugin refuses the PIN fallback on devices without biometric
      // hardware (it throws instead of showing the PIN screen — upstream
      // androidx/OEM issue). Fall back to the Keyguard PIN screen, which
      // works fine there.
      if (e.code == LocalAuthExceptionCode.noBiometricHardware ||
          e.code == LocalAuthExceptionCode.noBiometricsEnrolled) {
        debugPrint(
          '[AuthController] trying Keyguard device-credential fallback',
        );
        try {
          final confirmed = await _deviceCredential
              .confirm(
                title: credentialTitle ?? 'Authenticate',
                description:
                    localizedReason ?? 'Authenticate to access your data',
              )
              .timeout(authTimeout);
          if (generation != _generation) return false;
          if (confirmed) {
            debugPrint('[AuthController] device-credential fallback confirmed');
            _markUnlocked();
            return true;
          }
          // Dismissed — silent, like userCanceled.
          return false;
        } on DeviceCredentialException catch (fallbackError) {
          debugPrint(
            '[AuthController] device-credential fallback failed: $fallbackError',
          );
          if (generation != _generation) return false;
          lastFailure.value = AuthFailure.noBiometricsEnrolled;
          lastErrorDetail = 'device credential fallback: $fallbackError';
          isAuthenticated.value = false;
          return false;
        } on TimeoutException {
          debugPrint('[AuthController] device-credential fallback timed out');
          if (generation != _generation) return false;
          lastFailure.value = AuthFailure.timedOut;
          isAuthenticated.value = false;
          return false;
        }
      } else if (e.code == LocalAuthExceptionCode.noCredentialsSet) {
        lastFailure.value = AuthFailure.noCredentialsSet;
      } else if (e.code == LocalAuthExceptionCode.authInProgress ||
          e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled) {
        // Raced / dismissed — silent, don't surface as error.
        lastFailure.value = null;
      } else {
        lastFailure.value = AuthFailure.platform;
        lastErrorDetail =
            'LocalAuthException ${e.code.name}${e.description != null ? ': ${e.description}' : ''}';
      }
      isAuthenticated.value = false;
      return false;
    } on PlatformException catch (e) {
      debugPrint(
        '[AuthController] PlatformException code=${e.code} message=${e.message} details=${e.details}',
      );
      if (generation != _generation) return false;
      // Legacy plugin versions report concurrency as a PlatformException.
      if (e.code == 'auth_in_progress' || e.code == 'authInProgress') {
        lastFailure.value = null;
      } else {
        lastFailure.value = AuthFailure.platform;
        lastErrorDetail = 'PlatformException ${e.code}: ${e.message}';
      }
      isAuthenticated.value = false;
      return false;
    } on TimeoutException {
      debugPrint('[AuthController] authenticate timed out after $authTimeout');
      // Best-effort cancel so a retry starts clean instead of hitting
      // authInProgress against the orphaned native dialog.
      try {
        await _auth.stopAuthentication();
      } catch (_) {}
      if (generation != _generation) return false;
      lastFailure.value = AuthFailure.timedOut;
      isAuthenticated.value = false;
      return false;
    } catch (e, st) {
      debugPrint('[AuthController] Unexpected error: $e');
      debugPrint('$st');
      if (generation != _generation) return false;
      lastFailure.value = AuthFailure.unexpected;
      lastErrorDetail = '$e';
      isAuthenticated.value = false;
      return false;
    } finally {
      _inProgress = false;
    }
  }
}
