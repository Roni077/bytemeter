import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/enums.dart';

/// Interactive grid selector for application theme mode (Auto, Light, Dark, AMOLED).
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  final ThemeModePreference selectedMode;
  final ValueChanged<ThemeModePreference> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final options = <_ThemeOption>[
      const _ThemeOption(
        mode: ThemeModePreference.auto,
        title: 'Auto System',
        subtitle: 'Dynamic wallpaper palette',
        icon: Icons.brightness_auto_rounded,
      ),
      const _ThemeOption(
        mode: ThemeModePreference.light,
        title: 'Light Material',
        subtitle: 'Clean & high legibility',
        icon: Icons.light_mode_rounded,
      ),
      const _ThemeOption(
        mode: ThemeModePreference.dark,
        title: 'Dark Material',
        subtitle: 'Muted low-strain dark',
        icon: Icons.dark_mode_rounded,
      ),
      const _ThemeOption(
        mode: ThemeModePreference.amoled,
        title: 'AMOLED Black',
        subtitle: 'Pitch black #000000',
        icon: Icons.contrast_rounded,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.palette_rounded,
                    color: colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Theme & Appearance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                final isSelected = selectedMode == opt.mode;

                return InkWell(
                  onTap: () {
                    AppHaptics.selectionTick();
                    onModeSelected(opt.mode);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.7)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              opt.icon,
                              size: 22,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.subtitle,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                    : colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final ThemeModePreference mode;
  final String title;
  final String subtitle;
  final IconData icon;
}
