import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const routeDuration = Duration(milliseconds: 420);
  static const reverseRouteDuration = Duration(milliseconds: 320);

  static const routeCurve = Curves.easeOutCubic;
  static const reverseRouteCurve = Curves.easeInCubic;

  static const routeSlide = Offset(0.045, 0);
  static const routeScaleStart = 0.985;
}
