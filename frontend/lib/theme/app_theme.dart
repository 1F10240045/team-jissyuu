import 'package:flutter/material.dart';

class AppTheme {
  // LINEグリーンを基調としたカラー定義
  static const Color primaryColor = Color(0xFF06C755);
  static const Color backgroundColor = Color(0xFFF7F7F7);
  static const Color textColor = Color(0xFF111111);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}