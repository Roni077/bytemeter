import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/haptics.dart';
import '../settings_controller.dart';
import '../widgets/conversion_playground_card.dart';
import '../widgets/unit_settings_card.dart';

/// Nested sub-screen for configuring measurement units, speed formats (Bits vs Bytes),
/// calculation bases (Decimal 1000 vs Binary 1024), and interactive conversion tests.
class UnitsSettingsScreen extends ConsumerWidget {
  const UnitsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final prefs = state.preferences;

    return Scaffold(
      extendBodyBehindAppBar: prefs.enableBlur,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: prefs.enableBlur
                ? ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: AppBar(
              backgroundColor: prefs.enableBlur
                  ? colorScheme.surface.withValues(alpha: 0.75)
                  : colorScheme.surface,
              title: Text(
                'Units & Standards',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  AppHaptics.contextClick();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          // 1. Unit Settings Configuration Card
          UnitSettingsCard(
            speedUnitType: prefs.speedUnitType,
            metricBase: prefs.metricBase,
            defaultNetworkType: prefs.overviewDefaultNetworkType,
            onSpeedUnitChanged: (unit) => controller.setSpeedUnitType(unit),
            onMetricBaseChanged: (base) => controller.setMetricBase(base),
            onDefaultNetworkChanged: (type) => controller.setOverviewDefaultNetworkType(type),
          ),

          const SizedBox(height: 16),

          // 2. Interactive Live Conversion Playground
          ConversionPlaygroundCard(
            currentMetricBase: prefs.metricBase,
            currentSpeedUnitType: prefs.speedUnitType,
          ),

          const SizedBox(height: 16),

          // 3. Educational Standards Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Telecom vs Operating System Standards',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '• Decimal (1000): SI standard used by cellular telecom carriers and hard drive manufacturers (1 GB = 1,000,000,000 B).\n'
                  '• Binary (1024): IEC standard used by Android OS memory and software filesystems (1 GiB = 1,073,741,824 B).\n'
                  '• Bits vs Bytes: 8 bits = 1 byte. ISPs advertise bandwidth in Mbps (bits), while downloads are measured in MB/s (bytes).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
