import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/enums.dart';

/// Card widget allowing customization of measurement units and calculation standards.
class UnitSettingsCard extends StatelessWidget {
  const UnitSettingsCard({
    super.key,
    required this.speedUnitType,
    required this.metricBase,
    required this.defaultNetworkType,
    required this.onSpeedUnitChanged,
    required this.onMetricBaseChanged,
    required this.onDefaultNetworkChanged,
  });

  final SpeedUnitType speedUnitType;
  final MetricBase metricBase;
  final NetworkType defaultNetworkType;
  final ValueChanged<SpeedUnitType> onSpeedUnitChanged;
  final ValueChanged<MetricBase> onMetricBaseChanged;
  final ValueChanged<NetworkType> onDefaultNetworkChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.straighten_rounded,
                    color: colorScheme.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Units & Standards',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Speed Unit Format (Bits vs Bytes)
            Text(
              'Speed Unit Format',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select whether live speed is displayed in Bytes/s or Bits/s.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<SpeedUnitType>(
                segments: const [
                  ButtonSegment<SpeedUnitType>(
                    value: SpeedUnitType.bytes,
                    label: Text('Bytes (MB/s, kB/s)'),
                    icon: Icon(Icons.storage_rounded, size: 16),
                  ),
                  ButtonSegment<SpeedUnitType>(
                    value: SpeedUnitType.bits,
                    label: Text('Bits (Mbps, kbps)'),
                    icon: Icon(Icons.speed_rounded, size: 16),
                  ),
                ],
                selected: {speedUnitType},
                onSelectionChanged: (selected) {
                  AppHaptics.selectionTick();
                  onSpeedUnitChanged(selected.first);
                },
              ),
            ),

            const Divider(height: 28),

            // 2. Metric Base Calculation (Decimal 1000 vs Binary 1024)
            Text(
              'Metric Base Calculation',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Decimal uses 1000 multipliers (GB/MB). Binary uses 1024 (GiB/MiB).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<MetricBase>(
                segments: const [
                  ButtonSegment<MetricBase>(
                    value: MetricBase.decimal1000,
                    label: Text('Decimal (1000)'),
                    icon: Icon(Icons.tag_rounded, size: 16),
                  ),
                  ButtonSegment<MetricBase>(
                    value: MetricBase.binary1024,
                    label: Text('Binary (1024)'),
                    icon: Icon(Icons.memory_rounded, size: 16),
                  ),
                ],
                selected: {metricBase},
                onSelectionChanged: (selected) {
                  AppHaptics.selectionTick();
                  onMetricBaseChanged(selected.first);
                },
              ),
            ),

            const Divider(height: 28),

            // 3. Default Overview Network Type
            Text(
              'Default Overview Interface',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Default network type shown when ByteMeter launches.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<NetworkType>(
                segments: const [
                  ButtonSegment<NetworkType>(
                    value: NetworkType.mobile,
                    label: Text('Cellular Data'),
                    icon: Icon(Icons.sim_card_rounded, size: 16),
                  ),
                  ButtonSegment<NetworkType>(
                    value: NetworkType.wifi,
                    label: Text('Wi-Fi Network'),
                    icon: Icon(Icons.wifi_rounded, size: 16),
                  ),
                ],
                selected: {defaultNetworkType},
                onSelectionChanged: (selected) {
                  AppHaptics.selectionTick();
                  onDefaultNetworkChanged(selected.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
