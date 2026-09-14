import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/special_uids.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/app_info.dart';

/// Reusable reactive widget that renders an application launcher icon with
/// lazy background loading, in-memory caching, downsampling, and graceful fallbacks.
class AppIconAvatar extends ConsumerStatefulWidget {
  const AppIconAvatar({
    super.key,
    required this.uid,
    required this.packageName,
    this.label,
    this.iconBytes,
    this.isSpecial = false,
    this.size = 40,
    this.borderRadius,
    this.iconSize,
    this.backgroundColor,
  });

  /// Convenience factory creating an [AppIconAvatar] directly from an [AppInfo] model.
  factory AppIconAvatar.fromAppInfo({
    Key? key,
    required AppInfo app,
    double size = 40,
    BorderRadius? borderRadius,
    double? iconSize,
    Color? backgroundColor,
  }) {
    return AppIconAvatar(
      key: key,
      uid: app.uid,
      packageName: app.packageName,
      label: app.label,
      iconBytes: app.iconBytes,
      isSpecial: app.isSpecial,
      size: size,
      borderRadius: borderRadius,
      iconSize: iconSize,
      backgroundColor: backgroundColor,
    );
  }

  final int uid;
  final String packageName;
  final String? label;
  final Uint8List? iconBytes;
  final bool isSpecial;
  final double size;
  final BorderRadius? borderRadius;
  final double? iconSize;
  final Color? backgroundColor;

  @override
  ConsumerState<AppIconAvatar> createState() => _AppIconAvatarState();
}

class _AppIconAvatarState extends ConsumerState<AppIconAvatar> {
  Uint8List? _bytes;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _bytes = widget.iconBytes;
    if (_bytes == null && !_isSpecialApp()) {
      final repo = ref.read(networkUsageRepositoryProvider);
      final cached = repo.getCachedAppIcon(widget.packageName);
      if (cached != null) {
        _bytes = cached;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _lazyFetchIcon();
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant AppIconAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.iconBytes != oldWidget.iconBytes) {
      setState(() {
        _bytes = widget.iconBytes;
      });
    } else if (widget.packageName != oldWidget.packageName) {
      _bytes = widget.iconBytes;
      if (_bytes == null && !_isSpecialApp()) {
        final repo = ref.read(networkUsageRepositoryProvider);
        final cached = repo.getCachedAppIcon(widget.packageName);
        if (cached != null) {
          _bytes = cached;
        } else {
          _lazyFetchIcon();
        }
      }
    }
  }

  bool _isSpecialApp() {
    return widget.isSpecial ||
        widget.uid < 0 ||
        widget.packageName.isEmpty ||
        widget.packageName.startsWith('uid_') ||
        widget.packageName.startsWith('system.');
  }

  Future<void> _lazyFetchIcon() async {
    if (_bytes != null || _isFetching || !mounted || _isSpecialApp()) return;

    _isFetching = true;
    final repo = ref.read(networkUsageRepositoryProvider);
    final fetched = await repo.getAppIcon(widget.packageName);

    if (mounted) {
      setState(() {
        _bytes = fetched;
        _isFetching = false;
      });
    }
  }

  Widget _buildFallback(ColorScheme colorScheme, BorderRadius radius) {
    IconData iconData = Icons.android_rounded;
    Color iconColor = colorScheme.primary;

    if (widget.uid == SpecialUids.uidTethering) {
      iconData = Icons.wifi_tethering_rounded;
      iconColor = colorScheme.secondary;
    } else if (widget.uid == SpecialUids.uidRemoved) {
      iconData = Icons.delete_sweep_rounded;
      iconColor = colorScheme.error;
    } else if (widget.uid == SpecialUids.uidOtherUsers) {
      iconData = Icons.devices_other_rounded;
      iconColor = colorScheme.tertiary;
    } else if (widget.uid == SpecialUids.uidAll) {
      iconData = Icons.apps_rounded;
      iconColor = colorScheme.primary;
    }

    final effectiveBg = widget.backgroundColor ?? iconColor.withValues(alpha: 0.12);
    final resolvedIconSize = widget.iconSize ?? (widget.size * 0.55);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: Icon(
        iconData,
        size: resolvedIconSize,
        color: iconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(widget.size * 0.25);

    if (_bytes != null && _bytes!.isNotEmpty) {
      final cacheDim = (widget.size * 3).toInt().clamp(32, 256);
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          _bytes!,
          width: widget.size,
          height: widget.size,
          cacheWidth: cacheDim,
          cacheHeight: cacheDim,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(colorScheme, radius),
        ),
      );
    }

    return _buildFallback(colorScheme, radius);
  }
}
