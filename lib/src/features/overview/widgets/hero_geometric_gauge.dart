import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bytemeter/src/core/theme/color_schemes.dart';
import 'package:bytemeter/src/core/theme/typography.dart';
import 'package:bytemeter/src/core/utils/data_size.dart';
import 'package:bytemeter/src/core/utils/haptics.dart';
import 'package:bytemeter/src/data/models/enums.dart';

/// Interactive 12-sided geometric cookie Hero gauge with continuous rotation,
/// pulsating network-aware radial glow, and spring scale bounce physics.
class HeroGeometricGauge extends StatefulWidget {
  const HeroGeometricGauge({
    super.key,
    required this.dataSize,
    this.networkType = NetworkType.mobile,
    this.label = "TODAY'S USAGE",
    this.secondaryLabel,
    this.size = 280.0,
    this.onTap,
    this.onLongPress,
  });

  /// The primary data size metric to display (3-part formatted).
  final DataSize dataSize;

  /// Active network interface type driving glow and polygon hues.
  final NetworkType networkType;

  /// Header title label (e.g. "TODAY'S USAGE", "LIVE SPEED").
  final String label;

  /// Optional secondary badge text (e.g. "↑ 1.2 MB/s · ↓ 4.5 MB/s").
  final String? secondaryLabel;

  /// Diameter size of the gauge canvas.
  final double size;

  /// Tap callback with spring bounce.
  final VoidCallback? onTap;

  /// Long press callback with haptics.
  final VoidCallback? onLongPress;

  @override
  State<HeroGeometricGauge> createState() => _HeroGeometricGaugeState();
}

class _HeroGeometricGaugeState extends State<HeroGeometricGauge>
    with TickerProviderStateMixin {
  // Continuous 50-second rotation loop
  late final AnimationController _rotationController;

  // Pulsating breathing radial glow (3.5s cycle)
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Touch spring bounce controller
  late final AnimationController _springController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _springController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _springController.forward();
    AppHaptics.toggleTick();
  }

  void _handlePointerUp(PointerUpEvent event) {
    _springController.reverse();
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _springController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = AppColorSchemes.getNetworkColor(colorScheme, widget.networkType);
    final containerColor = AppColorSchemes.getNetworkContainerColor(colorScheme, widget.networkType);
    final parts = widget.dataSize.toParts();

    return RepaintBoundary(
      child: Center(
        child: Listener(
          onPointerDown: _handlePointerDown,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: GestureDetector(
            onLongPress: () {
              AppHaptics.longPress();
              widget.onLongPress?.call();
            },
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Layer 1: Pulsating Radial Glow Background
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                containerColor.withValues(alpha: 0.35 + 0.15 * _pulseAnimation.value),
                                accentColor.withValues(alpha: 0.08 + 0.07 * _pulseAnimation.value),
                                Colors.transparent,
                              ],
                              stops: const [0.3, 0.7, 1.0],
                            ),
                          ),
                        );
                      },
                    ),

                    // Layer 2: Rotating 12-Sided Cookie Polygon
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: HeroGaugePainter(
                            rotationAngle: _rotationController.value * 2 * math.pi,
                            accentColor: accentColor,
                            containerColor: containerColor,
                            surfaceColor: colorScheme.surface,
                          ),
                        );
                      },
                    ),

                    // Layer 3: Foreground High-Precision 3-Part Typography
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header / Category Label
                          Text(
                            widget.label.toUpperCase(),
                            style: AppTypography.chartLabelStyle(
                              colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 11,
                            ).copyWith(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Expressive Numeric Row (Integer + Decimal)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  parts.first,
                                  style: AppTypography.heroIntegerStyle(
                                    colorScheme.onSurface,
                                    fontSize: widget.size * 0.28,
                                  ),
                                ),
                                if (parts.second.isNotEmpty)
                                  Text(
                                    parts.second,
                                    style: AppTypography.heroDecimalStyle(
                                      colorScheme.onSurfaceVariant,
                                      fontSize: widget.size * 0.13,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Unit Label Badge
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: containerColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              parts.third,
                              style: AppTypography.heroUnitStyle(
                                accentColor,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          // Optional Secondary Info Subtitle
                          if (widget.secondaryLabel != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.secondaryLabel!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom canvas painter generating the rotating 12-sided cookie polygon.
class HeroGaugePainter extends CustomPainter {
  const HeroGaugePainter({
    required this.rotationAngle,
    required this.accentColor,
    required this.containerColor,
    required this.surfaceColor,
  });

  final double rotationAngle;
  final Color accentColor;
  final Color containerColor;
  final Color surfaceColor;

  static const int lobes = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.44;
    final innerRadius = size.width * 0.38;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    final path = Path();
    final int points = lobes * 2;
    final double angleStep = (2 * math.pi) / points;

    // Build the 12-lobed cookie star polygon path with smooth cubic beziers
    for (int i = 0; i < points; i++) {
      final double currentAngle = i * angleStep;
      final double nextAngle = (i + 1) * angleStep;
      final double currentR = (i % 2 == 0) ? outerRadius : innerRadius;
      final double nextR = ((i + 1) % 2 == 0) ? outerRadius : innerRadius;

      final double x1 = currentR * math.cos(currentAngle);
      final double y1 = currentR * math.sin(currentAngle);
      final double x2 = nextR * math.cos(nextAngle);
      final double y2 = nextR * math.sin(nextAngle);

      if (i == 0) {
        path.moveTo(x1, y1);
      }

      // Control points for organic scalloped cookie edges
      final double midAngle = currentAngle + (angleStep / 2);
      final double midR = (currentR + nextR) / 2 * 1.04;
      final double cx = midR * math.cos(midAngle);
      final double cy = midR * math.sin(midAngle);

      path.quadraticBezierTo(cx, cy, x2, y2);
    }
    path.close();

    // Fill cookie interior with subtle gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          containerColor.withValues(alpha: 0.20),
          accentColor.withValues(alpha: 0.06),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: outerRadius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Stroke cookie boundary
    final strokePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          accentColor.withValues(alpha: 0.6),
          containerColor.withValues(alpha: 0.3),
          accentColor.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: outerRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Subtle inner circular guide track
    final innerTrackPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset.zero, innerRadius * 0.85, innerTrackPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HeroGaugePainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.containerColor != containerColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}
