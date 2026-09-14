import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/enums.dart';
import '../onboarding_controller.dart';
import '../onboarding_state.dart';

/// Step 3: Interactive Quick Preference Setup (Units, Metric Scaling, Theme, Notifications).
class SetupStepView extends StatelessWidget {
  const SetupStepView({
    super.key,
    required this.state,
    required this.controller,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: colorScheme.onTertiaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Preferences',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Customize how ByteMeter displays your network stats',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Speed Unit Format
          Text(
            'SPEED UNIT DISPLAY',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<SpeedUnitType>(
            segments: const [
              ButtonSegment(
                value: SpeedUnitType.bits,
                label: Text('Bits per second'),
                icon: Icon(Icons.speed_rounded, size: 16),
              ),
              ButtonSegment(
                value: SpeedUnitType.bytes,
                label: Text('Bytes per second'),
                icon: Icon(Icons.download_rounded, size: 16),
              ),
            ],
            selected: {state.speedUnitType},
            onSelectionChanged: (set) {
              AppHaptics.selectionTick();
              controller.setSpeedUnit(set.first);
            },
          ),
          const SizedBox(height: 6),
          Text(
            state.speedUnitType == SpeedUnitType.bits
                ? 'Scale: ${SpeedUnitType.bits.unitSymbols} (Telecom & ISP standard)'
                : 'Scale: ${SpeedUnitType.bytes.unitSymbols} (OS & download standard)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // 2. Metric Base Scaling
          Text(
            'METRIC UNIT BASE',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<MetricBase>(
            segments: const [
              ButtonSegment(
                value: MetricBase.decimal1000,
                label: Text('Decimal (1000 B)'),
              ),
              ButtonSegment(
                value: MetricBase.binary1024,
                label: Text('Binary (1024 B)'),
              ),
            ],
            selected: {state.metricBase},
            onSelectionChanged: (set) {
              AppHaptics.selectionTick();
              controller.setMetricBase(set.first);
            },
          ),
          const SizedBox(height: 20),

          // 3. Persistent Speed Meter Switch
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: SwitchListTile(
              value: state.persistentNotificationEnabled,
              onChanged: (val) {
                AppHaptics.selectionTick();
                controller.setPersistentNotification(val);
              },
              title: const Text(
                'Persistent Speed Meter',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Show live speed in status bar and notifications',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.notifications_active_rounded,
                    color: colorScheme.onPrimaryContainer, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Default Network Tab
          Text(
            'DEFAULT HOME NETWORK',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<NetworkType>(
            segments: const [
              ButtonSegment(
                value: NetworkType.mobile,
                label: Text('Cellular / Mobile'),
                icon: Icon(Icons.signal_cellular_alt_rounded, size: 16),
              ),
              ButtonSegment(
                value: NetworkType.wifi,
                label: Text('Wi-Fi Network'),
                icon: Icon(Icons.wifi_rounded, size: 16),
              ),
            ],
            selected: {state.homeDefaultNetworkType},
            onSelectionChanged: (set) {
              AppHaptics.selectionTick();
              controller.setDefaultNetworkType(set.first);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
