import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';

/// Warning banner displayed when Android Usage Access permission has not been granted.
class PermissionBanner extends StatelessWidget {
  const PermissionBanner({
    super.key,
    required this.onRequestPermission,
  });

  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.errorContainer.withValues(alpha: 0.85),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.onErrorContainer,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Usage Access Required',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ByteMeter requires Android "Usage Access" permission to read network sockets, calculate hourly burn rates, and display per-app bandwidth usage.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.onErrorContainer,
                  foregroundColor: colorScheme.errorContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  AppHaptics.contextClick();
                  onRequestPermission();
                },
                child: const Text(
                  'Grant Permission',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
