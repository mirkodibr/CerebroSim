import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central provider for the application's visual themes.
/// 
/// It offers distinct [ThemeData] presets that can be toggled to 
/// change the app's aesthetic from high-tech to standard.
class ThemeService {
  /// A high-contrast, dark theme with a "cyberpunk" aesthetic.
  static ThemeData get cyberLabTheme {
    final baseTheme = ThemeData.dark();
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
      textTheme: GoogleFonts.spaceMonoTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.rajdhani(
          textStyle: baseTheme.textTheme.displayLarge,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.rajdhani(
          textStyle: baseTheme.textTheme.displayMedium,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: GoogleFonts.rajdhani(
          textStyle: baseTheme.textTheme.displaySmall,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.rajdhani(
          textStyle: baseTheme.textTheme.headlineLarge,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.rajdhani(
          textStyle: baseTheme.textTheme.headlineMedium,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.rajdhani(
          textStyle: baseTheme.textTheme.headlineSmall,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.inter(textStyle: baseTheme.textTheme.bodyLarge),
        bodyMedium: GoogleFonts.inter(textStyle: baseTheme.textTheme.bodyMedium),
        bodySmall: GoogleFonts.inter(textStyle: baseTheme.textTheme.bodySmall),
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
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 20,
          fontWeight: FontWeight.w700,
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
    final baseTheme = ThemeData.light();
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
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseTheme.textTheme.displayLarge,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          textStyle: baseTheme.textTheme.displayMedium,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          textStyle: baseTheme.textTheme.displaySmall,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          textStyle: baseTheme.textTheme.headlineLarge,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          textStyle: baseTheme.textTheme.headlineMedium,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          textStyle: baseTheme.textTheme.headlineSmall,
          fontWeight: FontWeight.w700,
        ),
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
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
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
