import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bytemeter/src/core/utils/data_size.dart';
import 'package:bytemeter/src/core/utils/size_measurer.dart';
import 'package:bytemeter/src/features/charts/weekly_bar_chart.dart';
import 'package:bytemeter/src/features/charts/scrollable_bar_chart.dart';

void main() {
  group('Hero 12-Sided Cookie Geometry Math', () {
    test('12-Sided Cookie Polygon generates exactly 24 alternating vertex points', () {
      const int lobes = 12;
      const int points = lobes * 2;
      const double outerRadius = 100.0;
      const double innerRadius = 85.0;

      final generatedPoints = <Offset>[];
      const double angleStep = (2 * math.pi) / points;

      for (int i = 0; i < points; i++) {
        final double currentAngle = i * angleStep;
        final double currentR = (i % 2 == 0) ? outerRadius : innerRadius;
        final double x = currentR * math.cos(currentAngle);
        final double y = currentR * math.sin(currentAngle);
        generatedPoints.add(Offset(x, y));
      }

      expect(generatedPoints.length, equals(24));
      // First point at angle 0 should be on positive X axis with outer radius
      expect(generatedPoints[0].dx, closeTo(100.0, 0.001));
      expect(generatedPoints[0].dy, closeTo(0.0, 0.001));

      // Second point at pi/12 should have inner radius magnitude
      final r2 = math.sqrt(
        generatedPoints[1].dx * generatedPoints[1].dx +
            generatedPoints[1].dy * generatedPoints[1].dy,
      );
      expect(r2, closeTo(85.0, 0.001));
    });
  });

  group('WeeklyDayData & DailyHistoryData Models', () {
    test('WeeklyDayData correctly sums cellular and wifi bytes', () {
      final day = WeeklyDayData(
        date: DateTime(2026, 9, 10),
        cellularBytes: 1000000,
        wifiBytes: 2500000,
      );

      expect(day.totalBytes, equals(3500000));
      expect(DataSize(day.totalBytes).toMB(), closeTo(3.5, 0.01));
    });

    test('DailyHistoryData handles optional query filter bytes correctly', () {
      final normalDay = DailyHistoryData(
        date: DateTime(2026, 9, 10),
        cellularBytes: 500,
        wifiBytes: 1500,
      );
      expect(normalDay.totalBytes, equals(2000));

      final filteredDay = DailyHistoryData(
        date: DateTime(2026, 9, 10),
        cellularBytes: 500,
        wifiBytes: 1500,
        primaryQueryBytes: 300,
        secondaryQueryBytes: 100,
      );
      expect(filteredDay.totalBytes, equals(400));
    });
  });

  group('AppUsageBarData & Binary-Search Text Fitting', () {
    testWidgets('SizeMeasurer.findOptimalFontSize converges to legible font size', (tester) async {
      const text = '1.85 GB';
      const baseStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

      final wideFit = SizeMeasurer.findOptimalFontSize(
        text: text,
        baseStyle: baseStyle,
        maxWidth: 150.0,
        minFontSize: 8.0,
        maxFontSize: 14.0,
      );
      expect(wideFit, greaterThanOrEqualTo(13.0));

      final narrowFit = SizeMeasurer.findOptimalFontSize(
        text: text,
        baseStyle: baseStyle,
        maxWidth: 20.0,
        minFontSize: 8.0,
        maxFontSize: 14.0,
      );
      expect(narrowFit, equals(8.0));
    });

    testWidgets('SizeMeasurer.measureText returns non-zero dimensions', (tester) async {
      const text = '250 MB';
      const style = TextStyle(fontSize: 12);
      final size = SizeMeasurer.measureText(text: text, style: style);

      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });
  });

  group('Extra Pack Sweep Angle Math', () {
    test('Sweep angle calculation correctly clamps ratio between 0.0 and 1.0', () {
      const double totalSweepAngle = math.pi * 1.30;

      double computeSweep(int used, int total) {
        final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
        return (totalSweepAngle * progress).clamp(0.0, totalSweepAngle);
      }

      expect(computeSweep(0, 5000), equals(0.0));
      expect(computeSweep(2500, 5000), closeTo(totalSweepAngle * 0.5, 0.001));
      expect(computeSweep(5000, 5000), closeTo(totalSweepAngle, 0.001));
      expect(computeSweep(6000, 5000), closeTo(totalSweepAngle, 0.001));
    });
  });
}
