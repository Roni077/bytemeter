import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_icon_avatar.dart';
import '../../../data/models/app_info.dart';

/// Priority package prefixes for heavy streaming and social media applications.
const List<String> _priorityPackageIdentifiers = [
  'com.google.android.youtube',
  'com.whatsapp',
  'com.instagram.android',
  'com.spotify.music',
  'com.netflix.mediaclient',
  'com.android.chrome',
  'org.telegram.messenger',
  'com.facebook.katana',
  'com.zhiliaoapp.musically', // TikTok
  'com.twitter.android',
  'com.discord',
  'com.reddit.frontpage',
  'com.amazon.avod.thirdpartyclient', // Prime Video
  'com.disney.disneyplus',
  'tv.twitch.android.app',
];

/// Searchable modal bottom sheet to pick an application for timeline filtering.
class AppSearchModal extends StatefulWidget {
  const AppSearchModal({
    super.key,
    required this.installedApps,
    this.selectedAppUid,
    required this.onAppSelected,
  });

  final List<AppInfo> installedApps;
  final int? selectedAppUid;
  final void Function(AppInfo? app) onAppSelected;

  /// Convenience helper to open the modal bottom sheet.
  static Future<AppInfo?> show({
    required BuildContext context,
    required List<AppInfo> installedApps,
    int? selectedAppUid,
  }) {
    return showModalBottomSheet<AppInfo?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppSearchModal(
        installedApps: installedApps,
        selectedAppUid: selectedAppUid,
        onAppSelected: (app) => Navigator.of(context).pop(app),
      ),
    );
  }

  @override
  State<AppSearchModal> createState() => _AppSearchModalState();
}

class _AppSearchModalState extends State<AppSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<AppInfo> _defaultSortedApps = const [];

  @override
  void initState() {
    super.initState();
    _computeDefaultSortedApps();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didUpdateWidget(covariant AppSearchModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.installedApps != oldWidget.installedApps) {
      _computeDefaultSortedApps();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _computeDefaultSortedApps() {
    final priorityApps = <AppInfo>[];
    final remainingApps = <AppInfo>[];

    for (final app in widget.installedApps) {
      final pkgLower = app.packageName.toLowerCase();
      final isPriority = _priorityPackageIdentifiers.any(pkgLower.contains);
      if (isPriority) {
        priorityApps.add(app);
      } else {
        remainingApps.add(app);
      }
    }

    // Sort remaining and priority alphabetically
    remainingApps.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    priorityApps.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    _defaultSortedApps = [...priorityApps, ...remainingApps];
  }

  List<AppInfo> _getSortedAndFilteredApps() {
    final query = _searchQuery;
    if (query.isEmpty) {
      return _defaultSortedApps;
    }

    return _defaultSortedApps.where((app) {
      final matchesLabel = app.label.toLowerCase().contains(query);
      final matchesPackage = app.packageName.toLowerCase().contains(query);
      final matchesUid = app.uid.toString().contains(query);
      return matchesLabel || matchesPackage || matchesUid;
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredApps = _getSortedAndFilteredApps();

    return Material(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Modal Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Application',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Text Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search apps, package name, or UID...',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => _searchController.clear(),
                  ),
              ],
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHighest),
            ),
          ),

          const SizedBox(height: 8),

          // App List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: filteredApps.length + 1, // +1 for "All Applications" option
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isAllSelected = widget.selectedAppUid == null;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.apps_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'All Applications',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Aggregated device bandwidth',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: isAllSelected
                        ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                        : null,
                    onTap: () {
                      AppHaptics.contextClick();
                      widget.onAppSelected(null);
                    },
                  );
                }

                final app = filteredApps[index - 1];
                final isSelected = widget.selectedAppUid == app.uid;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: AppIconAvatar.fromAppInfo(app: app, size: 40),
                  title: Text(
                    app.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${app.packageName} · UID ${app.uid}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    AppHaptics.contextClick();
                    widget.onAppSelected(app);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}
