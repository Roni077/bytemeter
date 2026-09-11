import 'package:bytemeter/src/core/utils/date_utils.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateUtils Boundary & Range Calculations', () {
    test('startOfDay and endOfDay accuracy', () {
      final date = DateTime(2026, 9, 10, 15, 30, 45, 123);
      final start = AppDateUtils.startOfDay(date);
      final end = AppDateUtils.endOfDay(date);

      expect(start, equals(DateTime(2026, 9, 10, 0, 0, 0, 0, 0)));
      expect(end, equals(DateTime(2026, 9, 10, 23, 59, 59, 999, 0)));
      expect(end.difference(start).inMilliseconds, equals(86399999));
    });

    test('startOfMonth and endOfMonth accuracy', () {
      final sepDate = DateTime(2026, 9, 15);
      final sepStart = AppDateUtils.startOfMonth(sepDate);
      final sepEnd = AppDateUtils.endOfMonth(sepDate);

      expect(sepStart, equals(DateTime(2026, 9, 1, 0, 0, 0, 0, 0)));
      expect(sepEnd.month, equals(9));
      expect(sepEnd.day, equals(30));
      expect(sepEnd.hour, equals(23));
      expect(sepEnd.minute, equals(59));

      final decDate = DateTime(2026, 12, 10);
      final decEnd = AppDateUtils.endOfMonth(decDate);
      expect(decEnd.month, equals(12));
      expect(decEnd.day, equals(31));
    });

    test('90-Day Range Generator', () {
      final ref = DateTime(2026, 9, 10);
      final range = AppDateUtils.get90DayRange(ref);

      expect(range.length, equals(90));
      expect(range.last, equals(DateTime(2026, 9, 10)));
      expect(range.first, equals(DateTime(2026, 9, 10).subtract(const Duration(days: 89))));

      // Verify each consecutive day step is exactly 1 day
      for (int i = 1; i < range.length; i++) {
        expect(range[i].difference(range[i - 1]).inDays, equals(1));
      }
    });

    test('12 2-hour interval time buckets', () {
      final date = DateTime(2026, 9, 10);
      final buckets = AppDateUtils.generate2HourIntervals(date);

      expect(buckets.length, equals(12));
      expect(buckets.first.startTime, equals(DateTime(2026, 9, 10, 0, 0)));
      expect(buckets.last.startTime, equals(DateTime(2026, 9, 10, 22, 0)));
      expect(buckets[0].label, contains('12:00 AM'));
    });

    test('formatRelativeDate returns expected labels', () {
      final now = DateTime(2026, 9, 10, 12, 0);
      expect(AppDateUtils.formatRelativeDate(DateTime(2026, 9, 10, 8, 0), now), equals('Today'));
      expect(AppDateUtils.formatRelativeDate(DateTime(2026, 9, 9, 20, 0), now), equals('Yesterday'));
      expect(AppDateUtils.formatRelativeDate(DateTime(2026, 9, 11, 10, 0), now), equals('Tomorrow'));
    });
  });

  group('Billing Cycle Calculations', () {
    test('Daily billing cycle calculation', () {
      final now = DateTime(2026, 9, 10, 12, 0);
      final cycle = AppDateUtils.calculateBillingCycleWindow(
        now: now,
        cycleStartDay: 1,
        intervalType: TimeIntervalType.daily,
      );

      expect(cycle.cycleStart, equals(DateTime(2026, 9, 10, 0, 0)));
      expect(cycle.cycleEnd.day, equals(10));
      expect(cycle.daysRemaining, equals(0));
      expect(cycle.elapsedRatio, closeTo(0.5, 0.05));
    });

    test('Monthly billing cycle calculation (current month start)', () {
      final now = DateTime(2026, 9, 15, 12, 0);
      final cycle = AppDateUtils.calculateBillingCycleWindow(
        now: now,
        cycleStartDay: 5,
        intervalType: TimeIntervalType.monthly,
      );

      expect(cycle.cycleStart, equals(DateTime(2026, 9, 5, 0, 0)));
      expect(cycle.cycleEnd.month, equals(10));
      expect(cycle.cycleEnd.day, equals(4));
      expect(cycle.daysRemaining, greaterThan(0));
      expect(cycle.elapsedRatio, greaterThan(0.0));
      expect(cycle.elapsedRatio, lessThan(1.0));
    });

    test('Monthly billing cycle calculation (previous month start)', () {
      final now = DateTime(2026, 9, 2, 12, 0);
      final cycle = AppDateUtils.calculateBillingCycleWindow(
        now: now,
        cycleStartDay: 15,
        intervalType: TimeIntervalType.monthly,
      );

      expect(cycle.cycleStart, equals(DateTime(2026, 8, 15, 0, 0)));
      expect(cycle.cycleEnd.month, equals(9));
      expect(cycle.cycleEnd.day, equals(14));
    });
  });
}
