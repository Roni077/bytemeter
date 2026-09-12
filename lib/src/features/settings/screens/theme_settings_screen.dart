import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/haptics.dart';
import '../settings_controller.dart';
import '../widgets/live_theme_preview_card.dart';
import '../widgets/theme_mode_selector.dart';

/// Nested sub-screen for customizing application theme mode, AMOLED pitch black,
/// and frosted glass backdrop blur (haze) effects.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

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
        child: prefs.enableBlur
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: _buildAppBar(context, theme, colorScheme, true),
                ),
              )
            : _buildAppBar(context, theme, colorScheme, false),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // 1. Live Interactive Theme Preview
          LiveThemePreviewCard(
            selectedMode: prefs.themeMode,
          ),

          const SizedBox(height: 16),

          // 2. Theme Mode Grid Selector
          ThemeModeSelector(
            selectedMode: prefs.themeMode,
            onModeSelected: (mode) => controller.setThemeMode(mode),
          ),

          const SizedBox(height: 16),

          // 3. Frosted Glass Blur (Haze) Switch Card
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
                'Translucent app bars with real-time backdrop blur. Disable on lower-end devices for maximum smoothness.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.blur_on_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              onChanged: (enabled) {
                AppHaptics.selectionTick();
                controller.setEnableBlur(enabled);
              },
            ),
          ),

          const SizedBox(height: 16),

          // 4. AMOLED Display Energy Efficiency Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.energy_savings_leaf_rounded,
                  size: 22,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AMOLED Black uses pure #000000 pixels to turn off OLED subpixels completely, minimizing display battery consumption.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool hasBlur,
  ) {
    return AppBar(
      backgroundColor: hasBlur
          ? colorScheme.surface.withValues(alpha: 0.75)
          : colorScheme.surface,
      title: Text(
        'Theme & Appearance',
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
    );
  }
}

