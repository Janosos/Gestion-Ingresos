import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors from HTML
  static const Color primary = Color(0xFF137FEC);
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color backgroundDark = Color(0xFF101922);
  static const Color cardDark = Color(0xFF182430);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  
  static const Color textLight = Color(0xFF1E293B); // Slate 800
  static const Color textDark = Color(0xFFF1F5F9); // Slate 100
  static const Color textMutedLight = Color(0xFF64748B); // Slate 500
  static const Color textMutedDark = Color(0xFF94A3B8); // Slate 400

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: Colors.white,
        onSurface: textLight,
        error: danger,
      ),
      textTheme: GoogleFonts.manropeTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: textLight,
        displayColor: textLight,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
        ),
      ),


      iconTheme: const IconThemeData(color: textLight),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: cardDark,
        onSurface: textDark,
        error: danger,
      ),
      textTheme: GoogleFonts.manropeTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
       cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B)), // Slate 800
        ),
      ),

      iconTheme: const IconThemeData(color: textDark),
    );
  }
}
