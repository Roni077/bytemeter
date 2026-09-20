import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/utils/data_size.dart';
import '../../core/utils/haptics.dart';
import 'home_controller.dart';
import 'widgets/network_usage_summary_card.dart';
import 'widgets/permission_banner.dart';
import 'widgets/weekly_chart_card.dart';

/// Main interactive Home Dashboard screen featuring live speed monitoring,
/// 12-sided geometric cookie Hero gauge, predictive burn-rate cards, and weekly breakdown.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.scrollController,
  });

  /// Optional scroll controller to coordinate scroll-to-top actions.
  final ScrollController? scrollController;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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
      // Re-check permissions and refresh data when app returns to foreground
      ref.read(homeControllerProvider.notifier).loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final homeState = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    final prefs = prefsRepo.current;

    return Scaffold(
      extendBodyBehindAppBar: prefs.enableBlur,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: prefs.enableBlur
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: _buildAppBar(context, colorScheme, theme, true),
                ),
              )
            : _buildAppBar(context, colorScheme, theme, false),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          AppHaptics.selectionTick();
          await controller.loadDashboardData(refresh: true);
        },
        child: ListView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            bottom: MediaQuery.paddingOf(context).bottom + 96,
          ),
          children: [
            // Permission Alert Banner (if usage access missing)
            if (!homeState.hasUsagePermission) ...[
              PermissionBanner(
                onRequestPermission: () => controller.requestUsagePermission(),
              ),
              const SizedBox(height: 16),
            ],

            // Live Speed Badge
            const Center(child: _LiveSpeedSecondaryBadge()),
            const SizedBox(height: 20),

            // Mobile Data Summary Card
            NetworkUsageSummaryCard(
              title: 'Mobile Data',
              icon: Icons.cell_tower,
              todayBytes: homeState.todayMobileUsage.totalBytes,
              weekBytes: homeState.totalWeekCellularBytes,
              monthBytes: homeState.totalMonthCellularBytes,
            ),
            const SizedBox(height: 16),

            // Wi-Fi Data Summary Card
            NetworkUsageSummaryCard(
              title: 'Wi-Fi',
              icon: Icons.wifi,
              todayBytes: homeState.todayWifiUsage.totalBytes,
              weekBytes: homeState.totalWeekWifiBytes,
              monthBytes: homeState.totalMonthWifiBytes,
            ),
            const SizedBox(height: 24),

            // Weekly Mon-Sun Interactive Stacked Bar Chart
            WeeklyChartCard(
              weekData: homeState.weekData,
              selectedDayIndex: homeState.selectedDayIndex,
              metricBase: prefs.metricBase,
              onDaySelected: (index, data) {
                AppHaptics.contextClick();
                controller.selectDay(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ColorScheme colorScheme, ThemeData theme, bool hasBlur) {
    return AppBar(
      backgroundColor: hasBlur
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
              Icons.bolt_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'ByteMeter',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: const [
        SizedBox(width: 8),
      ],
    );
  }
}

/// Backward compatibility alias
typedef OverviewScreen = HomeScreen;

/// Isolated granular consumer widget displaying real-time upload and download speeds.
/// Keeps 1-second ticker rebuilds confined strictly to this leaf text widget.
class _LiveSpeedSecondaryBadge extends ConsumerWidget {
  const _LiveSpeedSecondaryBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final liveSpeedAsync = ref.watch(speedStreamProvider);
    final prefsRepo = ref.watch(preferencesRepositoryProvider);
    final prefs = prefsRepo.current;
    final snapshot = liveSpeedAsync.valueOrNull;

    final upSpeedFormatted = DataSize(snapshot?.uploadBytesPerSec ?? 0).format(
      base: prefs.metricBase,
      unitType: prefs.speedUnitType,
      isRate: true,
      decimals: 1,
    );
    final downSpeedFormatted = DataSize(snapshot?.downloadBytesPerSec ?? 0).format(
      base: prefs.metricBase,
      unitType: prefs.speedUnitType,
      isRate: true,
      decimals: 1,
    );
    final secondarySpeedLabel = '↑ $upSpeedFormatted  ·  ↓ $downSpeedFormatted';

    return Text(
      secondarySpeedLabel,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
