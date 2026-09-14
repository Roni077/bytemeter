import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_icon_avatar.dart';
import '../../../data/models/app_info.dart';

/// Modal bottom sheet allowing users to select zero-rated / carrier-free apps
/// to exclude from their data plan quota calculations.
class ExcludedAppsSheet extends StatefulWidget {
  const ExcludedAppsSheet({
    super.key,
    required this.installedApps,
    required this.initialExcludedUids,
  });

  final List<AppInfo> installedApps;
  final List<int> initialExcludedUids;

  static Future<List<int>?> show(
    BuildContext context, {
    required List<AppInfo> installedApps,
    required List<int> initialExcludedUids,
  }) {
    return showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExcludedAppsSheet(
        installedApps: installedApps,
        initialExcludedUids: initialExcludedUids,
      ),
    );
  }

  @override
  State<ExcludedAppsSheet> createState() => _ExcludedAppsSheetState();
}

class _ExcludedAppsSheetState extends State<ExcludedAppsSheet> {
  late final Set<int> _excludedUids;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _excludedUids = Set<int>.from(widget.initialExcludedUids);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppInfo> get _filteredApps {
    if (_searchQuery.isEmpty) {
      return widget.installedApps;
    }
    final q = _searchQuery.toLowerCase();
    return widget.installedApps.where((app) {
      return app.label.toLowerCase().contains(q) ||
          app.packageName.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  void _toggleApp(int uid) {
    AppHaptics.selectionTick();
    setState(() {
      if (_excludedUids.contains(uid)) {
        _excludedUids.remove(uid);
      } else {
        _excludedUids.add(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final apps = _filteredApps;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zero-Rated App Exclusions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Traffic from selected apps won\'t deduct from your quota',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    AppHaptics.contextClick();
                    Navigator.of(context).pop(_excludedUids.toList(growable: false));
                  },
                  child: Text('Done (${_excludedUids.length})'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search installed applications...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),

          const SizedBox(height: 8),

          // App List
          Expanded(
            child: apps.isEmpty
                ? Center(
                    child: Text(
                      'No applications found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final isSelected = _excludedUids.contains(app.uid);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleApp(app.uid),
                        secondary: AppIconAvatar.fromAppInfo(
                          app: app,
                          size: 40,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                        title: Text(
                          app.label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          app.packageName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
