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
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: neonCyan,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: neonCyan,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.15,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white70,
          letterSpacing: 0.25,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: neonCyan,
          letterSpacing: 1.25,
        ),
        // Monospace-like feel for numerical readouts using bodySmall
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.white60,
          fontFamily: 'monospace',
        ),
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
