import 'package:flutter/material.dart';
import 'core/utils/haptics.dart';
import 'features/data_plans/data_plans_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/navigation/widgets/modern_bottom_nav_bar.dart';
import 'features/settings/settings_screen.dart';

/// Root navigation container providing seamless floating bottom navigation between
/// Home, History, Data Plans, and Settings screens with frosted glass aesthetics,
/// fluid tab indicators, and active-tab scroll-to-top support.
class AppScaffold extends StatefulWidget {
  const AppScaffold({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late int _currentIndex;
  late final ScrollController _homeScrollController;
  late final ScrollController _historyScrollController;
  late final ScrollController _plansScrollController;
  late final ScrollController _settingsScrollController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _homeScrollController = ScrollController();
    _historyScrollController = ScrollController();
    _plansScrollController = ScrollController();
    _settingsScrollController = ScrollController();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(
        scrollController: _homeScrollController,
      ),
      HistoryScreen(
        scrollController: _historyScrollController,
      ),
      DataPlansScreen(
        scrollController: _plansScrollController,
      ),
      SettingsScreen(
        scrollController: _settingsScrollController,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: ModernBottomNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        onDestinationReselected: _onTabReselected,
      ),
    );
  }
}
