import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/color_schemes.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/enums.dart';
import 'screens/about_settings_screen.dart';
import 'screens/data_privacy_settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/permissions_settings_screen.dart';
import 'screens/theme_settings_screen.dart';
import 'screens/units_settings_screen.dart';
import 'settings_controller.dart';
import 'widgets/settings_section_header.dart';
import 'widgets/settings_tile.dart';

/// Main Settings & Customization Hub screen managing navigation to all nested
/// sub-screens: Theme & Appearance, Status Bar Speed Meter, Units & Calculation Standards,
/// Permissions & Diagnostics, Storage & Privacy, and About & System Information.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.scrollController,
  });

  /// Optional scroll controller to coordinate scroll-to-top actions.
  final ScrollController? scrollController;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
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

    final grantedCount = (state.hasUsagePermission ? 1 : 0) +
        (state.isIgnoringBatteryOptimizations ? 1 : 0);
    final allGranted = grantedCount == 2;

    final themeModeLabel = switch (prefs.themeMode) {
      ThemeModePreference.auto => 'Auto System',
      ThemeModePreference.light => 'Light Material',
      ThemeModePreference.dark => 'Dark Material',
      ThemeModePreference.amoled => 'AMOLED Black',
    };

    final unitModeLabel = prefs.speedUnitType == SpeedUnitType.bits
        ? 'Bits (Mbps)'
        : 'Bytes (MB/s)';
    final metricBaseLabel = prefs.metricBase == MetricBase.decimal1000
        ? 'Decimal (1000)'
        : 'Binary (1024)';

    // Filter helper
    bool matchesQuery(String title, String subtitle, [List<String>? keywords]) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery;
      if (title.toLowerCase().contains(q) || subtitle.toLowerCase().contains(q)) {
        return true;
      }
      if (keywords != null) {
        for (final k in keywords) {
          if (k.toLowerCase().contains(q)) return true;
        }
      }
      return false;
    }

    final showTheme = matchesQuery(
      'Theme & Appearance',
      '$themeModeLabel · Frosted Blur ${prefs.enableBlur ? "On" : "Off"}',
      ['dark', 'light', 'amoled', 'color', 'monet', 'glass', 'haze', 'palette'],
    );

    final showNotifications = matchesQuery(
      'Status Bar Speed Meter',
      prefs.persistentNotificationEnabled
          ? 'Active · ${prefs.notificationIconStyle.name} icon · AOD ${prefs.aodModeEnabled ? "On" : "Off"}'
          : 'Service Stopped',
      ['notification', 'speed', 'meter', 'icon', 'status bar', 'aod', 'threshold'],
    );

    final showUnits = matchesQuery(
      'Units & Calculation Standards',
      '$unitModeLabel · $metricBaseLabel · Default ${prefs.overviewDefaultNetworkType.name}',
      ['units', 'bytes', 'bits', 'mbps', 'mb/s', 'decimal', 'binary', '1000', '1024', 'calculator'],
    );

    final showPermissions = matchesQuery(
      'Permissions & System Access',
      'Usage Access: ${state.hasUsagePermission ? "Granted" : "Required"} · Battery: ${state.isIgnoringBatteryOptimizations ? "Unrestricted" : "Optimized"}',
      ['permissions', 'usage stats', 'battery', 'doze', 'system', 'diagnostics', 'ping'],
    );

    final showPrivacy = matchesQuery(
      'Storage & Data Privacy',
      '100% Offline · Local SQLite DB · KeyStore Hardware Encryption',
      ['privacy', 'offline', 'sqlite', 'drift', 'database', 'keystore', 'encryption', 'telemetry', 'reset'],
    );

    final showAbout = matchesQuery(
      'About & System Info',
      'ByteMeter ⚡ · Version ${state.appVersion} · Open Source Licenses',
      ['about', 'version', 'licenses', 'github', 'credits', 'stack', 'flutter'],
    );

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
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          bottom: MediaQuery.of(context).padding.bottom + 96,
        ),
        children: [
          // 1. Instant Settings Search / Filter Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search settings, units, permissions...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Health & Service Quick Status Hero Banner
          if (_searchQuery.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: allGranted && state.isServiceRunning
                    ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: allGranted && state.isServiceRunning
                      ? colorScheme.primary.withValues(alpha: 0.25)
                      : colorScheme.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: state.isServiceRunning ? AppColorSchemes.safeColor : colorScheme.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.isServiceRunning
                          ? 'Service: Active · $grantedCount/2 Permissions'
                          : 'Service: Stopped · $grantedCount/2 Permissions',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    allGranted ? 'OPTIMAL' : 'ACTION REQUIRED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: allGranted ? AppColorSchemes.safeColor : colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // SECTION 1: APPEARANCE & INTERFACE
          if (showTheme) ...[
            const SettingsSectionHeader(title: 'Appearance & Interface'),
            SettingsTile(
              icon: Icons.palette_rounded,
              iconBackgroundColor: colorScheme.secondaryContainer,
              iconColor: colorScheme.onSecondaryContainer,
              title: 'Theme & Appearance',
              subtitle: '$themeModeLabel · Frosted Blur ${prefs.enableBlur ? "Enabled" : "Disabled"}',
              trailingBadge: prefs.themeMode.name.toUpperCase(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),
          ],

          // SECTION 2: SPEED METER & NOTIFICATIONS
          if (showNotifications) ...[
            const SettingsSectionHeader(title: 'Speed Meter & Notifications'),
            SettingsTile(
              icon: Icons.notifications_active_rounded,
              iconBackgroundColor: colorScheme.primaryContainer,
              iconColor: colorScheme.onPrimaryContainer,
              title: 'Status Bar Speed Meter',
              subtitle: prefs.persistentNotificationEnabled
                  ? 'Active · ${prefs.notificationIconStyle.name} icon · Threshold: ${prefs.silentSpeedThresholdKb} KB/s'
                  : 'Service Stopped · Sub-second meter disabled',
              trailingBadge: prefs.persistentNotificationEnabled ? 'ACTIVE' : 'OFF',
              trailingBadgeColor: prefs.persistentNotificationEnabled
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              trailingBadgeTextColor: prefs.persistentNotificationEnabled
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
          ],

          // SECTION 3: METRICS & FORMATTING
          if (showUnits) ...[
            const SettingsSectionHeader(title: 'Metrics & Formatting'),
            SettingsTile(
              icon: Icons.straighten_rounded,
              iconBackgroundColor: colorScheme.tertiaryContainer,
              iconColor: colorScheme.onTertiaryContainer,
              title: 'Units & Calculation Standards',
              subtitle: '$unitModeLabel · $metricBaseLabel · Default ${prefs.overviewDefaultNetworkType.name == "mobile" ? "Cellular" : "Wi-Fi"}',
              trailingBadge: '${prefs.speedUnitType == SpeedUnitType.bits ? "Bits" : "Bytes"} · ${prefs.metricBase.baseValue}',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UnitsSettingsScreen(),
                  ),
                );
              },
            ),
          ],

          // SECTION 4: SYSTEM & DIAGNOSTICS
          if (showPermissions) ...[
            const SettingsSectionHeader(title: 'System & Diagnostics'),
            SettingsTile(
              icon: Icons.security_rounded,
              iconBackgroundColor: colorScheme.primaryContainer,
              iconColor: colorScheme.onPrimaryContainer,
              title: 'Permissions & System Access',
              subtitle: 'Usage Access: ${state.hasUsagePermission ? "Granted" : "Required"} · Battery: ${state.isIgnoringBatteryOptimizations ? "Unrestricted" : "Optimized"}',
              trailingBadge: '$grantedCount/2 GRANTED',
              trailingBadgeColor: allGranted
                  ? colorScheme.primaryContainer
                  : colorScheme.errorContainer.withValues(alpha: 0.6),
              trailingBadgeTextColor: allGranted
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onErrorContainer,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PermissionsSettingsScreen(),
                  ),
                );
              },
            ),
          ],

          // SECTION 5: STORAGE & PRIVACY
          if (showPrivacy) ...[
            const SettingsSectionHeader(title: 'Storage & Privacy'),
            SettingsTile(
              icon: Icons.folder_special_rounded,
              iconBackgroundColor: colorScheme.tertiaryContainer,
              iconColor: colorScheme.onTertiaryContainer,
              title: 'Storage & Data Privacy',
              subtitle: '100% Offline · Local Drift SQLite DB · KeyStore Hardware Encryption',
              trailingBadge: 'LOCAL ONLY',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DataPrivacySettingsScreen(),
                  ),
                );
              },
            ),
          ],

          // SECTION 6: APP INFORMATION
          if (showAbout) ...[
            const SettingsSectionHeader(title: 'App Information'),
            SettingsTile(
              icon: Icons.info_outline_rounded,
              iconBackgroundColor: colorScheme.surfaceContainerHighest,
              iconColor: colorScheme.onSurfaceVariant,
              title: 'About & System Info',
              subtitle: 'ByteMeter ⚡ · Version ${state.appVersion} · Open Source Licenses',
              trailingBadge: 'v${state.appVersion}',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AboutSettingsScreen(),
                  ),
                );
              },
            ),
          ],

          // Empty search state
          if (!showTheme && !showNotifications && !showUnits && !showPermissions && !showPrivacy && !showAbout) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No matching settings found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try searching for theme, units, notifications, permissions, or privacy.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
