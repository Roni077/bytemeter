import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/haptics.dart';
import 'notification_settings_screen.dart';
import 'settings_controller.dart';
import 'widgets/about_app_card.dart';
import 'widgets/permission_status_card.dart';
import 'widgets/theme_mode_selector.dart';
import 'widgets/unit_settings_card.dart';

/// Main Settings & Customization dashboard screen managing Dynamic Material You theming,
/// AMOLED dark mode, speed units, calculation bases, status bar notification icons, and Android permissions.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions and service state when returning from system settings
      ref.read(settingsControllerProvider.notifier).refreshPermissionStatuses();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Settings & Theming',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh Statuses',
                  onPressed: () {
                    AppHaptics.contextClick();
                    controller.refreshPermissionStatuses();
                  },
                ),
                const SizedBox(width: 8),
              ],
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
          // 1. Android System Permissions Status Card
          PermissionStatusCard(
            hasUsagePermission: state.hasUsagePermission,
            isIgnoringBatteryOptimizations: state.isIgnoringBatteryOptimizations,
            onRequestUsagePermission: () => controller.requestUsagePermission(),
            onRequestBatteryExemption: () => controller.requestIgnoreBatteryOptimizations(),
          ),

          const SizedBox(height: 16),

          // 2. Theme & Visual Appearance Grid Selector
          ThemeModeSelector(
            selectedMode: prefs.themeMode,
            onModeSelected: (mode) => controller.setThemeMode(mode),
          ),

          const SizedBox(height: 16),

          // 3. Frosted Glass Blur Effect Card
          Card(
            child: SwitchListTile.adaptive(
              value: prefs.enableBlur,
              title: Text(
                'Frosted Glass Blur (Haze)',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Translucent app bars with real-time backdrop blur. Disable on lower-end hardware for maximum smoothness.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              secondary: Icon(
                Icons.blur_on_rounded,
                color: colorScheme.primary,
              ),
              onChanged: (enabled) {
                AppHaptics.selectionTick();
                controller.setEnableBlur(enabled);
              },
            ),
          ),

          const SizedBox(height: 16),

          // 4. Notification & Status Bar Meter Navigation Card
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              title: Text(
                'Status Bar Speed Meter',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                prefs.persistentNotificationEnabled
                    ? 'Active · ${prefs.notificationIconStyle.name} icon · AOD ${prefs.aodModeEnabled ? "On" : "Off"}'
                    : 'Disabled',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                AppHaptics.contextClick();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 5. Units & Standards Configuration Card
          UnitSettingsCard(
            speedUnitType: prefs.speedUnitType,
            metricBase: prefs.metricBase,
            defaultNetworkType: prefs.overviewDefaultNetworkType,
            onSpeedUnitChanged: (unit) => controller.setSpeedUnitType(unit),
            onMetricBaseChanged: (base) => controller.setMetricBase(base),
            onDefaultNetworkChanged: (type) => controller.setOverviewDefaultNetworkType(type),
          ),

          const SizedBox(height: 16),

          // 6. About, Privacy & Open Source Card
          AboutAppCard(
            appVersion: state.appVersion,
          ),
        ],
      ),
    );
  }
}
