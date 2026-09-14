import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/enums.dart';

/// Interactive visual grid selector for application theme mode (Auto, Light, Dark, AMOLED).
/// Features miniature visual UI mockup canvases for each theme style and tight, space-efficient geometry.
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
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.palette_rounded,
                    color: colorScheme.onSecondaryContainer,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Mode',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Choose application visual style',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedMode.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
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
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Visual theme canvas mockup
                        _ThemeVisualPreview(
                          mode: opt.mode,
                          isSelected: isSelected,
                        ),
                        const SizedBox(height: 8),
                        // Title and selection indicator
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                opt.title,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: colorScheme.primary,
                              )
                            else
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Subtitle
                        Text(
                          opt.subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

/// Miniature visual UI mockup showcasing the theme palette in action.
class _ThemeVisualPreview extends StatelessWidget {
  const _ThemeVisualPreview({
    required this.mode,
    required this.isSelected,
  });

  final ThemeModePreference mode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildPreviewContent(),
      ),
    );
  }

  Widget _buildPreviewContent() {
    switch (mode) {
      case ThemeModePreference.auto:
        return Row(
          children: [
            // Light side
            Expanded(
              child: Container(
                color: const Color(0xFFF1F5F9),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 14,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Dark side
            Expanded(
              child: Container(
                color: const Color(0xFF181A22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 14,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case ThemeModePreference.light:
        return Container(
          color: const Color(0xFFF1F5F9),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 16,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF005AC1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Icon(
                    Icons.light_mode_rounded,
                    size: 12,
                    color: Color(0xFFD97706),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF005AC1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case ThemeModePreference.dark:
        return Container(
          color: const Color(0xFF14151B),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 16,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Icon(
                    Icons.dark_mode_rounded,
                    size: 12,
                    color: Color(0xFF93C5FD),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF22242D),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF333544)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF60A5FA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF475569),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case ThemeModePreference.amoled:
        return Container(
          color: const Color(0xFF000000),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 16,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Icon(
                    Icons.contrast_rounded,
                    size: 12,
                    color: Color(0xFF38BDF8),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0C0E),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
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
