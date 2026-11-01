import 'package:flutter/material.dart';

class AppTheme{

  // Light Theme Definition
    static final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF172033),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      dividerColor: const Color(0xFFE2E8F0),
    );

    // Dark Theme Definition
    static final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
        surface: const Color(0xFF131B2E),
      ),
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF131B2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      dividerColor: Colors.white.withValues(alpha: 0.08),
    );


}