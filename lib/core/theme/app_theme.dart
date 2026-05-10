import 'package:flutter/material.dart';

class AppTheme {
  static const defaultSeedColor = Color(0xFF8B6914);

  static ThemeData lightTheme(Color seedColor) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  static ThemeData darkTheme(Color seedColor) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  // Preset accent colors
  static const accentColors = [
    Color(0xFF8B6914), // Gold (default)
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFF7B1FA2), // Purple
    Color(0xFFD32F2F), // Red
    Color(0xFF00897B), // Teal
    Color(0xFFC2185B), // Pink
    Color(0xFFEF6C00), // Orange
  ];

  // Reading background presets
  static const readingBackgrounds = [
    Color(0xFFF5F0E6), // Warm white
    Color(0xFFF5E6C8), // Cream yellow
    Color(0xFFE8F0E4), // Light green
    Color(0xFF2C2C2C), // Dark gray
    Color(0xFF1A1A1A), // Pure black
  ];

  static const readingTextColors = [
    Color(0xFF333333), // Dark text (for light backgrounds)
    Color(0xFFE0E0E0), // Light text (for dark backgrounds)
  ];
}
