import 'package:flutter/material.dart';
import '../../../data/models/enums.dart';
import '../../charts/weekly_bar_chart.dart';

/// Card encapsulating the 7-day Monday through Sunday stacked interactive bar chart.
class WeeklyChartCard extends StatelessWidget {
  const WeeklyChartCard({
    super.key,
    required this.weekData,
    this.selectedDayIndex,
    this.onDaySelected,
    this.metricBase = MetricBase.decimal1000,
    this.height = 260.0,
  });

  final List<WeeklyDayData> weekData;
  final int? selectedDayIndex;
  final void Function(int dayIndex, WeeklyDayData data)? onDaySelected;
  final MetricBase metricBase;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (weekData.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Card(
        child: SizedBox(
          height: 180,
          child: Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        ),
      );
    }

    return WeeklyBarChart(
      weekData: weekData,
      selectedDayIndex: selectedDayIndex,
      onDaySelected: onDaySelected,
      height: height,
    );
  }
}
