import 'package:flutter_test/flutter_test.dart';
import 'package:io/features/auth/lock_watcher.dart';

void main() {
  final now = DateTime(2026, 9, 7, 12);
  DateTime minutesAgo(int m) => now.subtract(Duration(minutes: m));

  test('relocks after grace period in background', () {
    expect(
      shouldRelock(
        lockEnabled: true,
        authenticated: true,
        backgroundedAt: minutesAgo(6),
        timeoutMinutes: 5,
        now: now,
      ),
      isTrue,
    );
  });

  test('stays unlocked within grace period', () {
    expect(
      shouldRelock(
        lockEnabled: true,
        authenticated: true,
        backgroundedAt: minutesAgo(4),
        timeoutMinutes: 5,
        now: now,
      ),
      isFalse,
    );
  });

  test(
    'no relock when lock disabled, already locked, or never backgrounded',
    () {
      for (final args in [
        (false, true, minutesAgo(60)), // lock disabled
        (true, false, minutesAgo(60)), // already locked
      ]) {
        expect(
          shouldRelock(
            lockEnabled: args.$1,
            authenticated: args.$2,
            backgroundedAt: args.$3,
            timeoutMinutes: 5,
            now: now,
          ),
          isFalse,
        );
      }
      expect(
        shouldRelock(
          lockEnabled: true,
          authenticated: true,
          backgroundedAt: null,
          timeoutMinutes: 5,
          now: now,
        ),
        isFalse,
      );
    },
  );

  test('non-positive timeout never relocks', () {
    expect(
      shouldRelock(
        lockEnabled: true,
        authenticated: true,
        backgroundedAt: minutesAgo(60),
        timeoutMinutes: 0,
        now: now,
      ),
      isFalse,
    );
  });
}
