import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2F6FED);
  static const alerta = Color(0xFFC62828);
  static const exito = Color(0xFF2E7D32);
  static const fondo = Color(0xFFF5F7FB);
  static const texto = Color(0xFF1B1F2A);
  static const textoSuave = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary),
        scaffoldBackgroundColor: AppColors.fondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
