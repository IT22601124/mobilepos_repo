import 'package:flutter/material.dart';

class AppThemes {
  // Custom Color Palettes
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryDarkBlue = Color(0xFF1D4ED8);
  static const Color primaryLightBlue = Color(0xFFEFF6FF);
  static const Color inversePrimaryLight = Colors.black;

  static const Color inversePrimaryDark = Colors.white;

  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // 1. Light Theme Configuration
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: secondaryGreen,
      inversePrimary: inversePrimaryLight,
      surface: Colors.white,
      error: Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textDark,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );

  // 2. Dark Theme Configuration
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6), // Slightly lighter blue for dark contrast
      secondary: secondaryGreen,
      surface: Color(0xFF131A26),
      inversePrimary: inversePrimaryDark,
      error: Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF8FAFC),
    ),
    scaffoldBackgroundColor: const Color(0xFF0B0F19),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF131A26),
      foregroundColor: Color(0xFFF8FAFC),
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF131A26),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
    ),
  );
}
