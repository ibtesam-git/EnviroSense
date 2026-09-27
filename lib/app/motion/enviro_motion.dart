import 'package:flutter/material.dart';

/// Visual tokens and motion timings specified by UPGRADE2_0.pdf.
/// Keep this UI-only: existing BLE, models and repositories remain untouched.
abstract final class EnviroPalette {
  static const bg = Color(0xFF0B1110);
  static const surface = Color(0xFF141C1A);
  static const surfaceRaised = Color(0xFF1B2522);
  static const surfaceGlass = Color(0x8C1B2522); // 55% opacity

  static const brass = Color(0xFFC9A56A);
  static const brassGlow = Color(0x40C9A56A); // 25% opacity
  static const teal = Color(0xFF69D2BA);
  static const amberWarm = Color(0xFFE8B84B);
  static const violetCold = Color(0xFF6E85D6);
  static const coral = Color(0xFFE2725B); // alerts only

  static const textPrimary = Color(0xFFF3F1EA);
  static const textMuted = Color(0xFF9BA7A1);
  static const textFaint = Color(0x739BA7A1); // 45% opacity
  static const hairline = Color(0x0FFFFFFF); // 6% white

  static Color hairlineLive(Color accent) => accent.withValues(alpha: 0.35);
}

abstract final class EnviroMotion {
  static const pageDuration = Duration(milliseconds: 380);
  static const moodDuration = Duration(milliseconds: 1200);
  static const plantDuration = Duration(milliseconds: 2000);
  static const livePulseDuration = Duration(milliseconds: 1200);
  static const ambientDriftDuration = Duration(seconds: 16);
  static const shimmerDuration = Duration(milliseconds: 3200);

  static const elementSpring = SpringDescription(
    mass: 1,
    stiffness: 160,
    damping: 12,
  );
  static const valueSpring = SpringDescription(
    mass: 1,
    stiffness: 110,
    damping: 13,
  );
  static const hudSpring = SpringDescription(
    mass: 1,
    stiffness: 200,
    damping: 16,
  );
  static const plantSpring = SpringDescription(
    mass: 1,
    stiffness: 60,
    damping: 14,
  );
}

/// Color temperature is descriptive, not an alert. Coral is reserved for an
/// explicitly configured threshold breach.
Color enviroMoodColor(double temperatureC) {
  if (temperatureC < 18) return EnviroPalette.violetCold;
  if (temperatureC > 27) return EnviroPalette.amberWarm;
  return EnviroPalette.teal;
}

double enviroMoodTintOpacity(double temperatureC) {
  if (temperatureC >= 18 && temperatureC <= 27) return 0;
  final distance = temperatureC < 18 ? 18 - temperatureC : temperatureC - 27;
  return (distance / 30).clamp(0.0, 0.12).toDouble();
}
