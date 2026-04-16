import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central provider for the application's visual themes.
/// 
/// It offers distinct [ThemeData] presets that can be toggled to 
/// change the app's aesthetic from high-tech to standard.
class ThemeService {
  /// A high-contrast, dark theme with a "cyberpunk" aesthetic.
  static ThemeData get cyberLabTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FFFF),
        secondary: Color(0xFF8A2BE2),
        error: Color(0xFFFF4444),
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        outline: Color(0x33FFFFFF),
      ),
      textTheme: GoogleFonts.spaceMonoTextTheme(
        ThemeData.dark().textTheme,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFF121212),
        titleTextStyle: GoogleFonts.spaceMono(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF00FFFF),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Color(0xFF0A0A0A),
        selectedItemColor: Color(0xFF00FFFF),
        unselectedItemColor: Color(0xFF5F5E5A),
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0x33FFFFFF), width: 0.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// A clean, professional light theme suitable for general use.
  static ThemeData get presentationTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF185FA5),
        secondary: Color(0xFF1D9E75),
        surface: Colors.white,
        onSurface: Colors.black,
        outline: Color(0x1A000000),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1A000000), width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFFFAFAFA),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF185FA5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF185FA5),
        unselectedItemColor: Color(0xFF757575),
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0x1A000000), width: 0.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
