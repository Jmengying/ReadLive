import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF8B6914);

  static final lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
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

  static final darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
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
