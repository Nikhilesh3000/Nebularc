import 'package:flutter/material.dart';

/// Central color palette for Nebularc.
/// Light and dark variants for every UI surface.
class AppColors {
  AppColors._();

  // ---- Brand (same in both themes) ----
  static const Color primary = Color(0xFF8A2BE2);        // Neon purple
  static const Color primaryLight = Color(0xFFB57BFF);   // Lighter purple
  static const Color pink = Color(0xFFE84393);           // Hot pink
  static const Color cyan = Color(0xFF00D2D3);           // Teal
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color danger = Color(0xFFFF4757);

  // ---- Aurora gradient (used in hero + buttons) ----
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, pink],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF9B59B6), Color(0xFFE84393)],
  );

  // ============================================================================
  // LIGHT THEME
  // ============================================================================
  static const Color lightBg = Color(0xFFF5F5F8);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceAlt = Color(0xFFEFEFF5);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightTextSubtle = Color(0xFF6C6C7A);
  static const Color lightBorder = Color(0xFFE5E5EE);
  static const Color lightDivider = Color(0xFFEBEBF2);

  // ============================================================================
  // DARK THEME
  // ============================================================================
  static const Color darkBg = Color(0xFF070A14);
  static const Color darkSurface = Color(0xFF131825);
  static const Color darkSurfaceAlt = Color(0xFF1C2130);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSubtle = Color(0xB3FFFFFF); // 70% white
  static const Color darkBorder = Color(0x1AFFFFFF);     // 10% white
  static const Color darkDivider = Color(0x14FFFFFF);    // 8% white

  // ============================================================================
  // Aurora Blob Colors (used in the background gradient decoration)
  // ============================================================================
  static const List<Color> auroraBlobs = [
    Color(0xFFFFB6E0), // soft pink
    Color(0xFFC7A8FF), // light purple
    Color(0xFFA8E6FF), // light blue
    Color(0xFFFFD6A8), // soft peach
  ];
}
