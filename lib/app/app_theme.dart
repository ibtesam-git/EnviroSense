import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF0B1110);
  static const surface = Color(0xFF141C1A);
  static const surfaceRaised = Color(0xFF1B2522);
  static const brass = Color(0xFFC9A56A);
  static const teal = Color(0xFF69D2BA);
  static const textPrimary = Color(0xFFF3F1EA);
  static const textMuted = Color(0xFF9BA7A1);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: brass,
      brightness: Brightness.dark,
    ).copyWith(
      primary: brass,
      secondary: teal,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
    );
  }
}
