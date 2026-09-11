import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/enums.dart';

/// Item descriptor defining icons, label, and semantics for navigation destinations.
class ModernNavItemData {
  const ModernNavItemData({
    required this.label,
    required this.outlinedIcon,
    required this.selectedIcon,
    this.tooltip,
  });

  final String label;
  final IconData outlinedIcon;
  final IconData selectedIcon;
  final String? tooltip;
}

/// A modern floating glassmorphic bottom navigation bar with fluid sliding indicator,
/// icon scale micro-interactions, responsive haptics, and AMOLED adaptation.
class ModernBottomNavBar extends ConsumerWidget {
  const ModernBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onDestinationReselected,
    this.items = defaultItems,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<int>? onDestinationReselected;
  final List<ModernNavItemData> items;

  /// Default 4 core navigation destinations for ByteMeter.
  static const List<ModernNavItemData> defaultItems = [
    ModernNavItemData(
      label: 'Overview',
      outlinedIcon: Icons.bolt_outlined,
      selectedIcon: Icons.bolt_rounded,
      tooltip: 'Live Speed & Overview',
    ),
    ModernNavItemData(
      label: 'History',
      outlinedIcon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      tooltip: 'History & Analytics',
    ),
    ModernNavItemData(
      label: 'Plans',
      outlinedIcon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card_rounded,
      tooltip: 'SIM Data Plans',
    ),
    ModernNavItemData(
      label: 'Settings',
      outlinedIcon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      tooltip: 'Settings & Customization',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final prefs = ref.watch(preferencesRepositoryProvider).current;
    final isAmoled = prefs.themeMode == ThemeModePreference.amoled;
    final enableBlur = prefs.enableBlur;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Background color determination based on theme & blur preferences
    final Color barBackground;
    if (!enableBlur) {
      barBackground = isAmoled
          ? AppColorSchemes.amoledSurfaceContainer
          : colorScheme.surfaceContainer;
    } else {
      if (isAmoled) {
        barBackground = AppColorSchemes.amoledSurfaceContainer.withValues(alpha: 0.88);
      } else if (isDark) {
        barBackground = colorScheme.surfaceContainer.withValues(alpha: 0.85);
      } else {
        barBackground = colorScheme.surface.withValues(alpha: 0.85);
      }
    }

    final borderColor = isAmoled
        ? colorScheme.outlineVariant.withValues(alpha: 0.3)
        : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.45);

    final shadowColor = Colors.black.withValues(
      alpha: isAmoled ? 0.5 : (isDark ? 0.35 : 0.08),
    );

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding + 8 : 16),
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: enableBlur
              ? ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            decoration: BoxDecoration(
              color: barBackground,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final itemCount = items.length;
                final itemWidth = totalWidth / itemCount;
                final indicatorWidth = itemWidth - 12;
                final indicatorHeight = 52.0;

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Smooth Animated Sliding Indicator Pill
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: (selectedIndex * itemWidth) + 6,
                      top: (constraints.maxHeight - indicatorHeight) / 2,
                      width: indicatorWidth,
                      height: indicatorHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isAmoled
                              ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                              : colorScheme.primaryContainer.withValues(
                                  alpha: isDark ? 0.55 : 0.75,
                                ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),

                    // Navigation Destination Item Buttons
                    Row(
                      children: List.generate(itemCount, (index) {
                        final item = items[index];
                        final isSelected = index == selectedIndex;

                        return Expanded(
                          child: Semantics(
                            selected: isSelected,
                            label: item.label,
                            button: true,
                            child: Tooltip(
                              message: item.tooltip ?? item.label,
                              waitDuration: const Duration(milliseconds: 700),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (selectedIndex == index) {
                                      AppHaptics.selectionTick();
                                      onDestinationReselected?.call(index);
                                    } else {
                                      AppHaptics.selectionTick();
                                      onDestinationSelected(index);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  splashColor: colorScheme.primary.withValues(alpha: 0.12),
                                  highlightColor: Colors.transparent,
                                  child: Center(
                                    child: _ModernNavItemContent(
                                      item: item,
                                      isSelected: isSelected,
                                      colorScheme: colorScheme,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal animated content for each navigation item (icon + animated scaling + weighted text).
class _ModernNavItemContent extends StatelessWidget {
  const _ModernNavItemContent({
    required this.item,
    required this.isSelected,
    required this.colorScheme,
  });

  final ModernNavItemData item;
  final bool isSelected;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final activeColor = colorScheme.onPrimaryContainer;
    final inactiveColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.75);

    final currentColor = isSelected ? activeColor : inactiveColor;

    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Icon(
              isSelected ? item.selectedIcon : item.outlinedIcon,
              key: ValueKey<bool>(isSelected),
              size: 22,
              color: currentColor,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: isSelected ? -0.2 : 0.0,
              color: currentColor,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
