import 'package:flutter/material.dart';

class AppleDesign {
  // الألوان الأساسية
  static const Color primary = Color(0xFF0066CC); // Action Blue
  static const Color primaryFocus = Color(0xFF0071E3);
  static const Color primaryOnDark = Color(0xFF2997FF);
  
  // ألوان الخلفيات والنصوص
  static const Color ink = Color(0xFF1D1D1F);
  static const Color bodyMuted = Color(0xFFCCCCCC);
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color parchment = Color(0xFFF5F5F7);
  static const Color surfacePearl = Color(0xFFFAFAFC);
  static const Color surfaceTile1 = Color(0xFF272729);
  static const Color surfaceTile2 = Color(0xFF2A2A2C);
  static const Color surfaceBlack = Color(0xFF000000);
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color hairline = Color(0xFFE0E0E0);

  // تصميم النصوص (Typography)
  static TextStyle displayLg = const TextStyle(fontSize: 40, fontWeight: FontWeight.w600, letterSpacing: 0, color: onDark);
  static TextStyle tagline = const TextStyle(fontSize: 21, fontWeight: FontWeight.w600, letterSpacing: 0.231, color: onDark);
  static TextStyle body = const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.374, color: onDark);
  static TextStyle caption = const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.224, color: bodyMuted);
}
