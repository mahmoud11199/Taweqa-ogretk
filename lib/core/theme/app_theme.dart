import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF667EEA);
  static const Color accent = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color bgDeep = Color(0xFF07071A);
  static const Color meterBg = Color(0xFF0F172A);
  static const Color meterCard = Color(0xFF1E293B);
  static const Color meterText = Color(0xFFF1F5F9);
  static const Color meterMuted = Color(0xFF94A3B8);
  static const Color meterPrimary = Color(0xFF22D3EE);
  static const Color meterBorder = Color(0x3374809F);
  static const Color fareNeon = Color(0xFFFFFF00);
  static const Color glassBg = Color(0x0AFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: meterBg,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: meterCard,
        foregroundColor: meterText,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: meterCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: meterBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: meterBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: meterBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: meterBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: meterPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(color: meterMuted),
      ),
    );
  }
}
