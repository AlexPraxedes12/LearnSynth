import 'package:flutter/material.dart';

/// Provides the dark theme used throughout the app. Copying this
/// implementation from the upstream repository ensures visual
/// consistency. You can tweak primary and accent colors here to
/// match your design needs.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF121212);
  static const Color accentTeal = Color(0xFF64FFDA);
  static const Color accentViolet = Color(0xFF9F7AEA);
  static const Color accentGray = Color(0xFF616161);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accentTeal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      useMaterial3: true,
    );
  }
}