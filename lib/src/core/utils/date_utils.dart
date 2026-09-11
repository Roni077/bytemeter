import 'package:intl/intl.dart';
import '../../data/models/enums.dart';

/// Calculation result encapsulating billing cycle bounds and timing metrics.
class BillingCycleWindow {
  const BillingCycleWindow({
    required this.cycleStart,
    required this.cycleEnd,
    required this.elapsedDuration,
    required this.totalDuration,
    required this.daysRemaining,
    required this.elapsedRatio,
  });

  final DateTime cycleStart;
  final DateTime cycleEnd;
  final Duration elapsedDuration;
  final Duration totalDuration;
  final int daysRemaining;
  final double elapsedRatio;
}

/// Interval time bucket representing a slice of a day (e.g. 2-hour window).
class TimeBucket {
  const TimeBucket({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.label,
  });

  final int index;
  final DateTime startTime;
  final DateTime endTime;
  final String label;
}

/// Date and time window calculation helpers for historical analytics and billing cycles.
class AppDateUtils {
  const AppDateUtils._();

  /// Returns the start of the day (00:00:00.000) for the given [date].
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0, 0, 0);
  }

  /// Returns the end of the day (23:59:59.999) for the given [date].
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 0);
  }

  /// Returns the first millisecond of the month for the given [date].
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1, 0, 0, 0, 0, 0);
  }

  /// Returns the last millisecond of the month for the given [date].
  static DateTime endOfMonth(DateTime date) {
    final nextMonthFirstDay = (date.month == 12)
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonthFirstDay.subtract(const Duration(milliseconds: 1));
  }

  /// Generates a list of 90 consecutive calendar days ending at [referenceDate] (or today).
  static List<DateTime> get90DayRange([DateTime? referenceDate]) {
    final ref = startOfDay(referenceDate ?? DateTime.now());
    return List<DateTime>.generate(90, (index) {
      return ref.subtract(Duration(days: 89 - index));
    }, growable: false);
  }

  /// Generates 12 2-hour interval [TimeBucket] windows covering the entire 24-hour [date].
  static List<TimeBucket> generate2HourIntervals(DateTime date) {
    final base = startOfDay(date);
    final timeFormat = DateFormat('hh:mm a');

    return List<TimeBucket>.generate(12, (i) {
      final start = base.add(Duration(hours: i * 2));
      final end = (i == 11)
          ? endOfDay(date)
          : base.add(Duration(hours: (i + 1) * 2)).subtract(const Duration(milliseconds: 1));
      final label = '${timeFormat.format(start)} - ${timeFormat.format(start.add(const Duration(hours: 2)))}';

      return TimeBucket(
        index: i,
        startTime: start,
        endTime: end,
        label: label,
      );
    }, growable: false);
  }

  /// Formats a [date] into relative conversational text (e.g. "Today", "Yesterday", "Tue, Sep 10").
  static String formatRelativeDate(DateTime date, [DateTime? referenceDate]) {
    final today = startOfDay(referenceDate ?? DateTime.now());
    final target = startOfDay(date);
    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference == -1) {
      return 'Tomorrow';
    } else if (difference > 1 && difference < 7) {
      return DateFormat('EEEE').format(date); // e.g. "Monday"
    } else {
      return DateFormat('EEE, MMM d').format(date); // e.g. "Mon, Sep 10"
    }
  }

  /// Computes the exact billing cycle start, end, elapsed duration, and days remaining.
  static BillingCycleWindow calculateBillingCycleWindow({
    required DateTime now,
    required int cycleStartDay,
    required TimeIntervalType intervalType,
    int customDays = 30,
  }) {
    final current = now;

    if (intervalType == TimeIntervalType.daily) {
      final start = startOfDay(current);
      final end = endOfDay(current);
      final total = end.difference(start);
      final elapsed = current.difference(start);
      final ratio = total.inMilliseconds > 0
          ? (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

      return BillingCycleWindow(
        cycleStart: start,
        cycleEnd: end,
        elapsedDuration: elapsed,
        totalDuration: total,
        daysRemaining: 0,
        elapsedRatio: ratio,
      );
    }

    if (intervalType == TimeIntervalType.custom) {
      // Custom cycle anchored to start of current month with fixed duration
      final days = customDays > 0 ? customDays : 30;
      final start = DateTime(current.year, current.month, cycleStartDay.clamp(1, 28), 0, 0, 0);
      final adjustedStart = current.isBefore(start) ? start.subtract(Duration(days: days)) : start;
      final end = adjustedStart.add(Duration(days: days)).subtract(const Duration(milliseconds: 1));
      final total = end.difference(adjustedStart);
      final elapsed = current.difference(adjustedStart);
      final ratio = total.inMilliseconds > 0
          ? (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;
      final remaining = end.difference(current).inDays.clamp(0, days);

      return BillingCycleWindow(
        cycleStart: adjustedStart,
        cycleEnd: end,
        elapsedDuration: elapsed,
        totalDuration: total,
        daysRemaining: remaining,
        elapsedRatio: ratio,
      );
    }

    // Default: Monthly Interval
    final clampedDay = cycleStartDay.clamp(1, 31);
    DateTime cycleStart;
    DateTime cycleEnd;

    final daysInCurrentMonth = _daysInMonth(current.year, current.month);
    final targetStartDayInCurrentMonth = clampedDay.clamp(1, daysInCurrentMonth);

    if (current.day >= targetStartDayInCurrentMonth) {
      // Cycle started in current month
      cycleStart = DateTime(current.year, current.month, targetStartDayInCurrentMonth, 0, 0, 0);
      final nextMonth = current.month == 12 ? 1 : current.month + 1;
      final nextYear = current.month == 12 ? current.year + 1 : current.year;
      final daysInNextMonth = _daysInMonth(nextYear, nextMonth);
      final targetEndDay = clampedDay.clamp(1, daysInNextMonth);
      final nextStart = DateTime(nextYear, nextMonth, targetEndDay, 0, 0, 0);
      cycleEnd = nextStart.subtract(const Duration(milliseconds: 1));
    } else {
      // Cycle started in previous month
      final prevMonth = current.month == 1 ? 12 : current.month - 1;
      final prevYear = current.month == 1 ? current.year - 1 : current.year;
      final daysInPrevMonth = _daysInMonth(prevYear, prevMonth);
      final targetStartDay = clampedDay.clamp(1, daysInPrevMonth);
      cycleStart = DateTime(prevYear, prevMonth, targetStartDay, 0, 0, 0);
      cycleEnd = DateTime(current.year, current.month, targetStartDayInCurrentMonth, 0, 0, 0)
          .subtract(const Duration(milliseconds: 1));
    }

    final total = cycleEnd.difference(cycleStart);
    final elapsed = current.difference(cycleStart);
    final ratio = total.inMilliseconds > 0
        ? (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final remaining = (cycleEnd.difference(current).inHours / 24).ceil().clamp(0, 31);

    return BillingCycleWindow(
      cycleStart: cycleStart,
      cycleEnd: cycleEnd,
      elapsedDuration: elapsed,
      totalDuration: total,
      daysRemaining: remaining,
      elapsedRatio: ratio,
    );
  }

  static int _daysInMonth(int year, int month) {
    final nextMonthFirstDay = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return nextMonthFirstDay.subtract(const Duration(days: 1)).day;
  }
}
