import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bytemeter/src/core/theme/app_theme.dart';
import 'package:bytemeter/src/core/utils/data_size.dart';
import 'package:bytemeter/src/data/models/enums.dart';
import 'package:bytemeter/src/features/home/widgets/hero_geometric_gauge.dart';
import 'package:bytemeter/src/features/charts/weekly_bar_chart.dart';
import 'package:bytemeter/src/features/charts/scrollable_bar_chart.dart';
import 'package:bytemeter/src/features/charts/comparative_line_chart.dart';
import 'package:bytemeter/src/features/charts/app_usage_bar_chart.dart';
import 'package:bytemeter/src/features/charts/extra_pack_progress_chart.dart';

void main() {
  Widget buildTestApp(Widget child, [ThemeModePreference pref = ThemeModePreference.light]) {
    return MaterialApp(
      theme: AppTheme.buildTheme(
        preference: pref,
        platformBrightness: Brightness.light,
      ),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('HeroGeometricGauge Widget Tests', () {
    testWidgets('Renders 3-part data size and responds to tap gesture', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestApp(
          HeroGeometricGauge(
            dataSize: const DataSize(1500000000), // 1.50 GB
            networkType: NetworkType.mobile,
            label: "TODAY'S USAGE",
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify label and parts rendered
      expect(find.text("TODAY'S USAGE"), findsOneWidget);
      expect(find.text("1"), findsOneWidget);
      expect(find.text(".5"), findsOneWidget);
      expect(find.text("GB"), findsOneWidget);

      // Tap gauge
      await tester.tap(find.byType(HeroGeometricGauge));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapped, isTrue);
    });

    testWidgets('Renders Wi-Fi mode and custom secondary label', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const HeroGeometricGauge(
            dataSize: DataSize(450000000), // 450 MB
            networkType: NetworkType.wifi,
            label: 'LIVE SPEED',
            secondaryLabel: '↑ 1.2 MB/s · ↓ 4.5 MB/s',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('LIVE SPEED'), findsOneWidget);
      expect(find.text('↑ 1.2 MB/s · ↓ 4.5 MB/s'), findsOneWidget);
      expect(find.text('450'), findsOneWidget);
      expect(find.text('MB'), findsOneWidget);
    });
  });

  group('WeeklyBarChart Widget Tests', () {
    testWidgets('Renders 7 days, handles hit testing and legend toggling', (tester) async {
      final weekData = List.generate(7, (i) {
        return WeeklyDayData(
          date: DateTime(2026, 9, 7 + i),
          cellularBytes: 200000000 * (i + 1),
          wifiBytes: 500000000 * (i + 1),
        );
      });

      int? selectedIndex;
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: 400,
            height: 300,
            child: WeeklyBarChart(
              weekData: weekData,
              onDaySelected: (index, data) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('WEEKLY USAGE'), findsOneWidget);
      expect(find.text('Cellular'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);

      // Tap on the chart area to trigger hit testing
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump(const Duration(milliseconds: 100));
      expect(selectedIndex, isNotNull);

      // Toggle Cellular legend
      await tester.tap(find.text('Cellular'));
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('ScrollableBarChart Widget Tests', () {
    testWidgets('Renders 90-day timeline and allows dragging', (tester) async {
      final now = DateTime(2026, 9, 10);
      final historyData = List.generate(90, (i) {
        return DailyHistoryData(
          date: now.subtract(Duration(days: 89 - i)),
          cellularBytes: 100000000,
          wifiBytes: 300000000,
        );
      });

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: 400,
            height: 300,
            child: ScrollableBarChart(
              historyData: historyData,
              selectedDate: now,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('90-DAY TIMELINE'), findsOneWidget);

      // Drag timeline horizontally
      await tester.drag(find.byType(CustomScrollView), const Offset(-50, 0));
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('ComparativeLineChart Widget Tests', () {
    testWidgets('Renders dual query proportional comparison bar', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SizedBox(
            width: 300,
            height: 50,
            child: ComparativeLineChart(
              primaryBytes: 1200000000, // 1.2 GB
              secondaryBytes: 400000000, // 400 MB
              primaryLabel: '↓ 1.20 GB',
              secondaryLabel: '↑ 400 MB',
            ),
          ),
        ),
      );

      expect(find.byType(ComparativeLineChart), findsOneWidget);
    });
  });

  group('AppUsageBarChart Widget Tests', () {
    testWidgets('Renders ranked app list with proportional bars', (tester) async {
      final apps = [
        const AppUsageBarData(
          uid: 10001,
          appName: 'YouTube',
          packageName: 'com.google.android.youtube',
          bytes: 4500000000,
        ),
        const AppUsageBarData(
          uid: 10002,
          appName: 'Spotify',
          packageName: 'com.spotify.music',
          bytes: 1200000000,
        ),
      ];

      AppUsageBarData? tappedApp;

      await tester.pumpWidget(
        buildTestApp(
          AppUsageBarChart(
            apps: apps,
            onAppTap: (app) {
              tappedApp = app;
            },
          ),
        ),
      );

      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget);

      await tester.tap(find.text('YouTube'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tappedApp?.appName, equals('YouTube'));
    });
  });

  group('ExtraPackProgressChart Widget Tests', () {
    testWidgets('Renders circular progress arc and remaining quota', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const ExtraPackProgressChart(
            usedBytes: 3500000000, // 3.5 GB used
            totalBytes: 5000000000, // 5.0 GB total (1.5 GB left)
            name: '+5 GB Booster',
            expiryLabel: 'Expires in 4 days',
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('+5 GB Booster'), findsOneWidget);
      expect(find.text('Expires in 4 days'), findsOneWidget);
      expect(find.text('LEFT'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('.5'), findsOneWidget);
      expect(find.text('GB'), findsOneWidget);
    });
  });
}
