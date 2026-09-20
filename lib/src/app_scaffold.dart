import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/core_providers.dart';
import 'core/utils/haptics.dart';
import 'features/data_plans/data_plans_screen.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/navigation/widgets/modern_bottom_nav_bar.dart';
import 'features/settings/screens/notification_settings_screen.dart';
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
  StreamSubscription<String>? _notificationActionSub;

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

    _notificationActionSub = ref
        .read(nativeTrafficBridgeProvider)
        .onNotificationAction
        .listen((action) {
      if (action == 'openNotificationSettings' && mounted) {
        setState(() {
          _currentIndex = 3;
          _visitedIndices.add(3);
        });
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NotificationSettingsScreen(),
          ),
        );
      }
    });

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
    _notificationActionSub?.cancel();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        body: _FadeIndexedStack(
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
      ),
    );
  }
}

class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _FadeIndexedStack({
    required this.index,
    required this.children,
  });

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}
