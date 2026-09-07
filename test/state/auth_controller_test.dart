import 'package:flutter_test/flutter_test.dart';
import 'package:io/state/auth_controller.dart';

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
}
