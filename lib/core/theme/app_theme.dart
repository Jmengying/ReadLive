import 'package:flutter/material.dart';

class AppTheme {
  static const defaultSeedColor = Color(0xFF8B6914);

  static ThemeData lightTheme(Color seedColor) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS system gray
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFFF2F2F7),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: Colors.white,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE5E5EA),
          thickness: 0.5,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
      );

  static ThemeData darkTheme(Color seedColor) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF000000), // iOS pure black
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF000000),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: const Color(0xFF1C1C1E),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF38383A),
          thickness: 0.5,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
      );

  // Preset accent colors
  static const accentColors = [
    Color(0xFF8B6914), // Gold (default)
    Color(0xFF007AFF), // iOS Blue
    Color(0xFF34C759), // iOS Green
    Color(0xFFAF52DE), // iOS Purple
    Color(0xFFFF3B30), // iOS Red
    Color(0xFF5AC8FA), // iOS Teal
    Color(0xFFFF2D55), // iOS Pink
    Color(0xFFFF9500), // iOS Orange
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
