import 'package:flutter/material.dart';

class ExtensionTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      primaryColor: const Color(0xFF6366F1),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFF8B5CF6),
        surface: Color(0xFF161B22),
        error: Color(0xFFF85149),
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFC9D1D9)),
        bodyMedium: TextStyle(color: Color(0xFFC9D1D9)),
        bodySmall: TextStyle(color: Color(0xFF8B949E)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF30363D),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF21262D),
        selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
        labelStyle: const TextStyle(color: Color(0xFF8B949E)),
        side: const BorderSide(color: Color(0xFF30363D)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFF8B949E),
        ),
      ),
    );
  }
}




