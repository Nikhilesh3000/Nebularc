import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ============================================================================
  // Build a TextTheme manually (avoids material_ui / flutter TextTheme clash)
  // ============================================================================
  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 57, fontWeight: FontWeight.w400, color: color),
      displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 45, fontWeight: FontWeight.w400, color: color),
      displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 36, fontWeight: FontWeight.w400, color: color),
      headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32, fontWeight: FontWeight.w700, color: color),
      headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28, fontWeight: FontWeight.w700, color: color),
      headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 24, fontWeight: FontWeight.w700, color: color),
      titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 22, fontWeight: FontWeight.w600, color: color),
      titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleSmall: GoogleFonts.spaceGrotesk(
          fontSize: 14, fontWeight: FontWeight.w500, color: color),
      bodyLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall: GoogleFonts.spaceGrotesk(
          fontSize: 12, fontWeight: FontWeight.w400, color: color),
      labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 14, fontWeight: FontWeight.w600, color: color),
      labelMedium: GoogleFonts.spaceGrotesk(
          fontSize: 12, fontWeight: FontWeight.w500, color: color),
      labelSmall: GoogleFonts.spaceGrotesk(
          fontSize: 11, fontWeight: FontWeight.w500, color: color),
    );
  }

  // ============================================================================
  // LIGHT THEME
  // ============================================================================
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.cyan,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
        error: AppColors.danger,
      ),
      textTheme: _buildTextTheme(AppColors.lightText),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightText),
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: const TextStyle(color: AppColors.lightTextSubtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      dividerColor: AppColors.lightDivider,
      iconTheme: const IconThemeData(color: AppColors.lightText),
    );
  }

  // ============================================================================
  // DARK THEME
  // ============================================================================
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.cyan,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        error: AppColors.danger,
      ),
      textTheme: _buildTextTheme(AppColors.darkText),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkText),
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        hintStyle: const TextStyle(color: AppColors.darkTextSubtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
      ),
      dividerColor: AppColors.darkDivider,
      iconTheme: const IconThemeData(color: AppColors.darkText),
    );
  }
}