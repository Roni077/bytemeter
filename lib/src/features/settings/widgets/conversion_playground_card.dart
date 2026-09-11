import 'package:flutter/material.dart';
import '../../../core/utils/data_size.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/enums.dart';

/// Interactive conversion playground demonstrating real-time calculations
/// with DataSize across Decimal (1000) vs Binary (1024) and Bytes vs Bits.
class ConversionPlaygroundCard extends StatefulWidget {
  const ConversionPlaygroundCard({
    super.key,
    required this.currentMetricBase,
    required this.currentSpeedUnitType,
  });

  final MetricBase currentMetricBase;
  final SpeedUnitType currentSpeedUnitType;

  @override
  State<ConversionPlaygroundCard> createState() => _ConversionPlaygroundCardState();
}

class _ConversionPlaygroundCardState extends State<ConversionPlaygroundCard> {
  // Sample bytes: default 1 GiB = 1,073,741,824 bytes
  int _sampleBytes = 1073741824;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = DataSize(_sampleBytes);

    final decFormatted = size.format(base: MetricBase.decimal1000, unitType: SpeedUnitType.bytes);
    final binFormatted = size.format(base: MetricBase.binary1024, unitType: SpeedUnitType.bytes);
    final speedBytes = size.format(base: widget.currentMetricBase, unitType: SpeedUnitType.bytes, isRate: true);
    final speedBits = size.format(base: widget.currentMetricBase, unitType: SpeedUnitType.bits, isRate: true);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Conversion Playground',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'See how the same byte value is calculated across measurement standards.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),

            // Quick Preset Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip('500 MB', 500 * 1000 * 1000),
                  const SizedBox(width: 8),
                  _buildPresetChip('1 GB (10⁹ B)', 1000 * 1000 * 1000),
                  const SizedBox(width: 8),
                  _buildPresetChip('1 GiB (2³⁰ B)', 1024 * 1024 * 1024),
                  const SizedBox(width: 8),
                  _buildPresetChip('10 GB', 10 * 1000 * 1000 * 1000),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Comparison Cards
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  // Decimal vs Binary
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Decimal (1000)',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.currentMetricBase == MetricBase.decimal1000
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              decFormatted,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: widget.currentMetricBase == MetricBase.decimal1000
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Binary (1024)',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.currentMetricBase == MetricBase.binary1024
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              binFormatted,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: widget.currentMetricBase == MetricBase.binary1024
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  // Speed Rate Comparison
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Speed (Bytes/s)',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.currentSpeedUnitType == SpeedUnitType.bytes
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              speedBytes,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: widget.currentSpeedUnitType == SpeedUnitType.bytes
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Speed (Bits/s)',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.currentSpeedUnitType == SpeedUnitType.bits
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              speedBits,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: widget.currentSpeedUnitType == SpeedUnitType.bits
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int bytes) {
    final isSelected = _sampleBytes == bytes;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        AppHaptics.selectionTick();
        setState(() {
          _sampleBytes = bytes;
        });
      },
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
      ),
    );
  }
}
