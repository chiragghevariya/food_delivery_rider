import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App colors tailored for a premium delivery rider application.
/// Uses deep teal as the brand primary, slate as neutrals, and amber/emerald/red for statuses.
class AppColors {
  static const Color primary = Color(0xFF0F766E); // Modern Deep Teal (Teal 700)
  static const Color primaryLight = Color(0xFF14B8A6); // Teal 500
  static const Color primaryDark = Color(0xFF115E59); // Teal 800
  static const Color background = Color(0xFFF8FAFC); // Soft Slate Gray (Slate 50)
  static const Color card = Colors.white;
  static const Color text = Color(0xFF0F172A); // Charcoal Slate (Slate 900)
  static const Color textLight = Color(0xFF64748B); // Cool Grey (Slate 500)
  static const Color accent = Color(0xFFF59E0B); // Amber 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color danger = Color(0xFFEF4444); // Red 500
  static const Color border = Color(0xFFE2E8F0); // Slate 200
}

/// Builds the rider app theme with beautiful custom styling.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.card,
      background: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: AppColors.textLight),
    ),
  );
}
