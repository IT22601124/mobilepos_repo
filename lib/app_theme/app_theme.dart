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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: primaryBlue, width: 1.4),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFEAF1FB),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );

  // 2. Dark Theme Configuration
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF60A5FA), // Lighter blue for better visibility in dark
      secondary: secondaryGreen,
      surface: Color(0xFF0F172A), // Darker surface
      surfaceContainerHighest: Color(0xFF1E293B), // For cards and elevations
      inversePrimary: inversePrimaryDark,
      error: Color(0xFFF87171),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF1F5F9), // Slate 100 for better readability
      outline: Color(0xFF334155), // Slate 700 for borders
    ),
    scaffoldBackgroundColor: const Color(0xFF020617), // Rich black
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Color(0xFFF1F5F9),
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.4),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF0F172A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
