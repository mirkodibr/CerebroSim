import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central provider for the application's visual themes.
/// 
/// It offers distinct [ThemeData] presets that can be toggled to 
/// change the app's aesthetic from high-tech to standard.
class ThemeService {
  /// A high-contrast, dark theme with a "cyberpunk" aesthetic.
  /// 
  /// Uses a pure black background and neon cyan/purple accents.
  /// The [GoogleFonts.spaceMono] font is used to reinforce the 
  /// technical, laboratory-like atmosphere.
  static ThemeData get cyberLabTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FFFF),
        secondary: Color(0xFF8A2BE2),
        error: Color(0xFFFF4444),
        surface: Color(0xFF1E1E1E),
      ),
      textTheme: GoogleFonts.spaceMonoTextTheme(
        ThemeData.dark().textTheme,
      ),
    );
  }

  /// A clean, professional light theme suitable for general use.
  /// 
  /// Uses the [GoogleFonts.inter] font for high legibility 
  /// and more traditional color schemes (blue and teal).
  static ThemeData get presentationTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF185FA5),
        secondary: Color(0xFF1D9E75),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ),
    );
  }
}
