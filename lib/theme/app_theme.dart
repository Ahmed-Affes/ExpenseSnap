import 'package:flutter/material.dart';

/// Central theme definition for ExpenseSnap.
///
/// Follows the required clean, minimal, and premium financial application design:
/// - Background: #F7F8FA
/// - Main text: #17212F
/// - Primary accent: #0D766E (Teal)
/// - Surfaces: #FFFFFF
/// - Borders: #DDE4E8
class AppTheme {
  // Brand color palette
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF0D766E);
  static const Color primaryLight = Color(0xFFE6F4F2);
  static const Color textPrimary = Color(0xFF17212F);
  static const Color textSecondary = Color(0xFF5A6679);
  static const Color textMuted = Color(0xFF8B98A5);
  static const Color border = Color(0xFFDDE4E8);

  // Status colors
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color success = Color(0xFF059669);

  /// Main light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      fontFamily: null, // Uses default clean system font
      // AppBar theme: clean white surface with subtle separation
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Card theme: crisp border, flat modern elevation
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),

      // Input field theme for forms (Atelier 8 style)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),

      // Elevated Button: prominent primary action
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined Button: secondary actions
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation Bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
