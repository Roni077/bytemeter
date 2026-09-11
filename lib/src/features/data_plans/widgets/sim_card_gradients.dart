import 'package:flutter/material.dart';

/// Predefined gradient themes for SIM Data Plan visual cards.
class SimCardGradients {
  const SimCardGradients._();

  static const List<SimCardGradientTheme> themes = [
    // 0: Electric Sapphire
    SimCardGradientTheme(
      id: 0,
      name: 'Electric Sapphire',
      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
      accentColor: Color(0xFF93C5FD),
      chipColor: Color(0xFFBFDBFE),
    ),
    // 1: Royal Amethyst
    SimCardGradientTheme(
      id: 1,
      name: 'Royal Amethyst',
      colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF8B5CF6)],
      accentColor: Color(0xFFC4B5FD),
      chipColor: Color(0xFFDDD6FE),
    ),
    // 2: Emerald Cyber
    SimCardGradientTheme(
      id: 2,
      name: 'Emerald Cyber',
      colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF10B981)],
      accentColor: Color(0xFF6EE7B7),
      chipColor: Color(0xFFA7F3D0),
    ),
    // 3: Sunset Ember
    SimCardGradientTheme(
      id: 3,
      name: 'Sunset Ember',
      colors: [Color(0xFF7F1D1D), Color(0xFFDC2626), Color(0xFFF59E0B)],
      accentColor: Color(0xFFFDE68A),
      chipColor: Color(0xFFFEF08A),
    ),
    // 4: Midnight Titanium
    SimCardGradientTheme(
      id: 4,
      name: 'Midnight Titanium',
      colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
      accentColor: Color(0xFF94A3B8),
      chipColor: Color(0xFFCBD5E1),
    ),
    // 5: Rose Quartz
    SimCardGradientTheme(
      id: 5,
      name: 'Rose Quartz',
      colors: [Color(0xFF701A75), Color(0xFFC026D3), Color(0xFFEC4899)],
      accentColor: Color(0xFFF472B6),
      chipColor: Color(0xFFFBCFE8),
    ),
  ];

  /// Returns the [SimCardGradientTheme] for the given [index], wrapping if needed.
  static SimCardGradientTheme getTheme(int index) {
    if (themes.isEmpty) {
      return const SimCardGradientTheme(
        id: 0,
        name: 'Default',
        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        accentColor: Color(0xFF93C5FD),
        chipColor: Color(0xFFBFDBFE),
      );
    }
    final safeIndex = index.abs() % themes.length;
    return themes[safeIndex];
  }
}

/// Metadata model encapsulating a SIM card gradient palette.
class SimCardGradientTheme {
  const SimCardGradientTheme({
    required this.id,
    required this.name,
    required this.colors,
    required this.accentColor,
    required this.chipColor,
  });

  final int id;
  final String name;
  final List<Color> colors;
  final Color accentColor;
  final Color chipColor;

  LinearGradient get gradient => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
