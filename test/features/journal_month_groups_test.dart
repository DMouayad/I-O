import 'package:flutter_test/flutter_test.dart';
import 'package:io/features/journal/journal_screen.dart';

void main() {
  test('groups desc days into per-month sections in order', () {
    final groups = groupDaysByMonth([
      DateTime(2026, 9, 13),
      DateTime(2026, 9, 1),
      DateTime(2026, 8, 31),
      DateTime(2026, 8, 2),
    ]);

    expect(groups.length, 2);
    expect(groups[0].month, DateTime(2026, 9));
    expect(groups[0].days, [DateTime(2026, 9, 13), DateTime(2026, 9, 1)]);
    expect(groups[1].month, DateTime(2026, 8));
    expect(groups[1].days, [DateTime(2026, 8, 31), DateTime(2026, 8, 2)]);
  });

  test('splits December and January into separate year-aware groups', () {
    final groups = groupDaysByMonth([
      DateTime(2026, 1, 2),
      DateTime(2025, 12, 31),
    ]);

    expect(groups.length, 2);
    expect(groups[0].month, DateTime(2026, 1));
    expect(groups[1].month, DateTime(2025, 12));
  });

  test('handles single-day and empty input', () {
    final single = groupDaysByMonth([DateTime(2026, 9, 13)]);
    expect(single.length, 1);
    expect(single[0].month, DateTime(2026, 9));
    expect(single[0].days, [DateTime(2026, 9, 13)]);

    expect(groupDaysByMonth([]), isEmpty);
  });
}
