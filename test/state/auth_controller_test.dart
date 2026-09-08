import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:io/state/auth_controller.dart';
import 'package:io/state/device_credential_auth.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  AuthController controller({required DateTime now}) {
    final c = AuthController();
    c.now = () => now;
    return c;
  }

  test('never unlocked is never expired', () {
    final c = controller(now: DateTime(2026, 9, 7, 12));
    expect(c.isExpired(timeoutMinutes: 5), isFalse);
  });

  test('fresh unlock is not expired', () {
    final now = DateTime(2026, 9, 7, 12);
    final c = controller(now: now);
    c.lastUnlockedAt = now;
    c.isAuthenticated.value = true;
    expect(c.isExpired(timeoutMinutes: 5), isFalse);
  });

  test('just under timeout is not expired, at timeout is expired', () {
    final unlockedAt = DateTime(2026, 9, 7, 12);
    final c = controller(now: unlockedAt);
    c.lastUnlockedAt = unlockedAt;

    c.now = () => unlockedAt.add(const Duration(minutes: 4, seconds: 59));
    expect(c.isExpired(timeoutMinutes: 5), isFalse);

    c.now = () => unlockedAt.add(const Duration(minutes: 5));
    expect(c.isExpired(timeoutMinutes: 5), isTrue);
  });

  test('non-positive timeout never expires', () {
    final unlockedAt = DateTime(2026, 9, 7, 12);
    final c = controller(now: unlockedAt);
    c.lastUnlockedAt = unlockedAt;
    c.now = () => unlockedAt.add(const Duration(hours: 1));
    expect(c.isExpired(timeoutMinutes: 0), isFalse);
    expect(c.isExpired(timeoutMinutes: -1), isFalse);
  });

  test('lock clears authentication', () {
    final c = controller(now: DateTime(2026, 9, 7, 12));
    c.isAuthenticated.value = true;
    c.lock();
    expect(c.isAuthenticated.value, isFalse);
  });

  test('lock clears unlock timestamp', () {
    final now = DateTime(2026, 9, 7, 12);
    final c = controller(now: now);
    c.lastUnlockedAt = now;
    c.lock();
    expect(c.lastUnlockedAt, isNull);
  });

  group('authenticate concurrency + device-credential strictness', () {
    test('raced call while dialog open returns false silently', () async {
      final fake = _BlockingAuth();
      final c = AuthController(auth: fake);
      final pending = c.authenticate();
      expect(c.isAuthenticating, isTrue);

      // Second call (double-tap / rebuilt gate) must not hit the plugin.
      final raced = await c.authenticate();
      expect(raced, isFalse);
      expect(fake.calls, 1);
      expect(c.lastFailure.value, isNull);

      fake.gate.complete(true);
      expect(await pending, isTrue);
      expect(c.isAuthenticated.value, isTrue);
      expect(c.isAuthenticating, isFalse);
    });

    test('noBiometricsEnrolled stays locked with PIN guidance', () async {
      final c = AuthController(
        auth: _ThrowingAuth(
          const LocalAuthException(
            code: LocalAuthExceptionCode.noBiometricsEnrolled,
          ),
        ),
        // Keyguard prompt unavailable too (e.g. non-Android test env).
        deviceCredential: _ConfirmResult(throwCode: 'unavailable'),
      );
      expect(await c.authenticate(), isFalse);
      expect(c.isAuthenticated.value, isFalse);
      expect(c.isAuthenticating, isFalse);
      expect(c.lastFailure.value, AuthFailure.noBiometricsEnrolled);
    });

    test('authInProgress from the platform is silent', () async {
      final c = AuthController(
        auth: _ThrowingAuth(
          const LocalAuthException(code: LocalAuthExceptionCode.authInProgress),
        ),
      );
      expect(await c.authenticate(), isFalse);
      expect(c.lastFailure.value, isNull);
      expect(c.isAuthenticated.value, isFalse);
    });

    test('cancel-like false return is silent', () async {
      final c = AuthController(auth: _FalseAuth());
      expect(await c.authenticate(), isFalse);
      expect(c.lastFailure.value, isNull);
      expect(c.isAuthenticated.value, isFalse);
    });

    test('late success after lock() is ignored (stale generation)', () async {
      final fake = _BlockingAuth();
      final c = AuthController(auth: fake);
      final pending = c.authenticate();
      // Watcher re-locks while the dialog is still open.
      c.lock();
      fake.gate.complete(true);
      expect(await pending, isFalse);
      expect(c.isAuthenticated.value, isFalse);
      expect(c.lastUnlockedAt, isNull);
      expect(c.isAuthenticating, isFalse);
    });

    test('hanging dialog times out and cancels the native call', () async {
      final fake = _BlockingAuth();
      final c = AuthController(auth: fake)
        ..authTimeout = const Duration(milliseconds: 20);
      expect(await c.authenticate(), isFalse);
      expect(c.lastFailure.value, AuthFailure.timedOut);
      expect(fake.stopCalls, 1);
      expect(c.isAuthenticated.value, isFalse);
      expect(c.isAuthenticating, isFalse);
      // Late native resolution is dropped — still locked.
      fake.gate.complete(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.isAuthenticated.value, isFalse);
    });

    test('no device lock auto-allows and flags the insecure path', () async {
      final fake = _BlockingAuth()..supported = false;
      final c = AuthController(auth: fake);
      expect(await c.authenticate(), isTrue);
      expect(c.isAuthenticated.value, isTrue);
      expect(c.insecureFallbackUsed, isTrue);
      expect(c.lastFailure.value, isNull);
    });

    test('Keyguard fallback unlocks when plugin reports no hardware', () async {
      final c = AuthController(
        auth: _ThrowingAuth(
          const LocalAuthException(
            code: LocalAuthExceptionCode.noBiometricHardware,
          ),
        ),
        deviceCredential: _ConfirmResult(value: true),
      );
      expect(await c.authenticate(), isTrue);
      expect(c.isAuthenticated.value, isTrue);
      expect(c.lastFailure.value, isNull);
      expect(c.isAuthenticating, isFalse);
    });

    test('Keyguard fallback cancel is silent', () async {
      final c = AuthController(
        auth: _ThrowingAuth(
          const LocalAuthException(
            code: LocalAuthExceptionCode.noBiometricsEnrolled,
          ),
        ),
        deviceCredential: _ConfirmResult(value: false),
      );
      expect(await c.authenticate(), isFalse);
      expect(c.isAuthenticated.value, isFalse);
      expect(c.lastFailure.value, isNull);
    });
  });
}

/// Blocks inside [authenticate] until [gate] completes, so tests can
/// interleave a second call the way a double-tap does on a real device.
class _BlockingAuth extends LocalAuthentication {
  final Completer<bool> gate = Completer<bool>();
  int calls = 0;
  int stopCalls = 0;
  bool supported = true;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> stopAuthentication() async {
    stopCalls++;
    return true;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    calls++;
    return gate.future;
  }
}

class _ThrowingAuth extends LocalAuthentication {
  _ThrowingAuth(this.error);
  final LocalAuthException error;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    throw error;
  }
}

class _FalseAuth extends LocalAuthentication {
  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async => false;
}

/// Fake Keyguard PIN screen for the device-credential fallback path.
class _ConfirmResult extends DeviceCredentialAuth {
  _ConfirmResult({this.value = false, this.throwCode});
  final bool value;
  final String? throwCode;

  @override
  Future<bool> confirm({
    required String title,
    required String description,
  }) async {
    if (throwCode != null) throw DeviceCredentialException(throwCode!);
    return value;
  }
}
