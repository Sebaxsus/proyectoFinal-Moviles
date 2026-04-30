import 'package:flutter/material.dart';

class AppTheme {
  // ---- Colores principales ----
  static const Color primary = Color(0xFF0A1628);      // Azul muy oscuro
  static const Color surface = Color(0xFF0F2044);      // Azul oscuro cards
  static const Color accent = Color(0xFF00D4AA);       // Verde agua / teal
  static const Color warning = Color(0xFFFFB347);      // Naranja advertencia
  static const Color danger = Color(0xFFFF4757);       // Rojo peligro
  static const Color safe = Color(0xFF2ED573);         // Verde seguro
  static const Color textPrimary = Color(0xFFE8F4FD);  // Blanco azulado
  static const Color textSecondary = Color(0xFF8BA3C7); // Gris azulado

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        onPrimary: primary,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accent.withOpacity(0.15), width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),
    );
  }

  // Función para obtener color según nivel de peligro
  static Color getLevelColor(double value, double maxValue) {
    final percentage = value / maxValue;
    if (percentage < 0.4) return safe;
    if (percentage < 0.7) return warning;
    return danger;
  }
}