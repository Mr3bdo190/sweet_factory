import 'package:flutter/material.dart';

class GlassTheme {
  // Modern Color Palette - Youthful, Romantic, Professional
  // Primary: Vibrant Purple (Romance)
  // Secondary: Bright Blue (Trust/Professional)
  // Accent: Pink (Youthful)
  
  static const Color primaryAccent = Color(0xFF8B5CF6);  // Violet - main brand color
  static const Color secondaryAccent = Color(0xFF3B82F6); // Blue - secondary
  static const Color accentPink = Color(0xFFEC4899);     // Pink - youthful accent
  
  // Background Colors
  static const Color backgroundDark = Color(0xFF0F172A); // Deep slate (modern dark)
  static const Color backgroundCard = Color(0xFF1E293B); // Card background
  static const Color surfaceLight = Color(0xFF334155);   // Elevated surfaces
  
  // Glassmorphism Colors
  static const Color glassWhite = Color(0x1AFFFFFF);     // Semi-transparent white
  static const Color glassBorder = Color(0x4DFFFFFF);    // Border color
  static const Color glassBorderLight = Color(0x1AFFFFFF); // Light border
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);    // Primary text
  static const Color textSecondary = Color(0xFF94A3B8); // Secondary text
  static const Color textMuted = Color(0xFF64748B);     // Muted text
  
  // Status Colors
  static const Color success = Color(0xFF10B981);       // Green
  static const Color warning = Color(0xFFF59E0B);       // Orange
  static const Color error = Color(0xFFEF4444);         // Red
  static const Color online = Color(0xFF22C55E);        // Online indicator

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryAccent,
      fontFamily: 'Inter', 
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 28),
        displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 24),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
        headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textMuted, fontSize: 12),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: secondaryAccent,
        tertiary: accentPink,
        surface: surfaceLight,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary, 
          fontSize: 20, 
          fontWeight: FontWeight.w600
        ),
      ),
      cardTheme: CardThemeData(
        color: backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: glassBorderLight.withValues(alpha: 0.3)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryAccent,
          side: const BorderSide(color: primaryAccent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAccent, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(
        color: glassBorderLight.withValues(alpha: 0.3),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Predefined decoration for standard glass containers
  static BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: backgroundCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: glassBorderLight.withValues(alpha: 0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }
  
  // Facebook-style card decoration
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: backgroundCard,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
