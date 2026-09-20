import 'package:flutter/material.dart';

/// Centralized dimensions, spacing, and radii for the ByteMeter app.
class AppDimens {
  const AppDimens._();

  // Spacing & Padding
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Radii
  static const Radius radiusSm = Radius.circular(8.0);
  static const Radius radiusMd = Radius.circular(12.0);
  static const Radius radiusLg = Radius.circular(20.0);
  static const Radius radiusXl = Radius.circular(28.0);

  // Border Radii
  static final BorderRadius borderRadiusSm = BorderRadius.all(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.all(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.all(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.all(radiusXl);
}
