import 'package:flutter/material.dart';

class CerebroTheme {
  static const Color darkCharcoal = Color(0xFF121212);
  static const Color neonCyan = Color(0xFF00E5FF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkCharcoal,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        onPrimary: Colors.black,
        secondary: neonCyan,
        onSecondary: Colors.black,
        surface: darkCharcoal,
        onSurface: Colors.white,
        background: darkCharcoal,
        onBackground: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCharcoal,
        foregroundColor: neonCyan,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonCyan,
        foregroundColor: Colors.black,
      ),
    );
  }
}
