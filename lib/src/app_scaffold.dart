import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/core_providers.dart';
import 'core/utils/haptics.dart';
import 'features/data_plans/data_plans_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/navigation/widgets/modern_bottom_nav_bar.dart';
import 'features/settings/settings_screen.dart';

/// Root navigation container providing seamless floating bottom navigation between
/// Home, History, Data Plans, and Settings screens with frosted glass aesthetics,
/// fluid tab indicators, and active-tab scroll-to-top support.
class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold>
    with WidgetsBindingObserver {
  late int _currentIndex;
  late final Set<int> _visitedIndices;
  late final ScrollController _homeScrollController;
  late final ScrollController _historyScrollController;
  late final ScrollController _plansScrollController;
  late final ScrollController _settingsScrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _visitedIndices = {_currentIndex};
    _homeScrollController = ScrollController();
    _historyScrollController = ScrollController();
    _plansScrollController = ScrollController();
    _settingsScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(preferencesRepositoryProvider).ensureServiceRunningIfAllowed();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(preferencesRepositoryProvider).ensureServiceRunningIfAllowed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeScrollController.dispose();
    _historyScrollController.dispose();
    _plansScrollController.dispose();
    _settingsScrollController.dispose();
    super.dispose();
  }

  ScrollController _getScrollController(int index) {
    switch (index) {
      case 0:
        return _homeScrollController;
      case 1:
        return _historyScrollController;
      case 2:
        return _plansScrollController;
      case 3:
        return _settingsScrollController;
      default:
        return _homeScrollController;
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      _onTabReselected(index);
      return;
    }
    AppHaptics.selectionTick();
    setState(() {
      _currentIndex = index;
      _visitedIndices.add(index);
    });
  }

  void _onTabReselected(int index) {
    AppHaptics.selectionTick();
    final controller = _getScrollController(index);
    if (controller.hasClients) {
      controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildTab(int index) {
    if (!_visitedIndices.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return HomeScreen(
          scrollController: _homeScrollController,
        );
      case 1:
        return HistoryScreen(
          scrollController: _historyScrollController,
        );
      case 2:
        return DataPlansScreen(
          scrollController: _plansScrollController,
        );
      case 3:
        return SettingsScreen(
          scrollController: _settingsScrollController,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (int i = 0; i < 4; i++)
            TickerMode(
              enabled: i == _currentIndex,
              child: _buildTab(i),
            ),
        ],
      ),
      bottomNavigationBar: ModernBottomNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        onDestinationReselected: _onTabReselected,
      ),
    );
  }
}
