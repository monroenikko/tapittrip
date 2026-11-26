import 'package:flutter/material.dart';

/// TapItTrip brand palette. Use only inside the theme layer.
abstract final class AppColors {
  static const navy = Color(0xFF00376D); // primary
  static const navyDeep = Color(0xFF00264D); // deep editorial navy
  static const orange = Color(0xFFF76405); // secondary
  static const sky = Color(0xFF0166BE); // tertiary
  static const orangeText = Color(0xFFB84A00); // orange text on light bg

  // Editorial neutral surfaces (paper-on-canvas separation)
  static const lightCanvas = Color(0xFFF4F5F7);
  static const lightPaper = Color(0xFFFFFFFF);
  static const lightOutline = Color(0xFFE2E6ED);
  static const darkCanvas = Color(0xFF0F1216);
  static const darkPaper = Color(0xFF171C22);
  static const darkOutline = Color(0xFF28303B);

  // Official third-party identity provider brand marks
  static const googleBlue = Color(0xFF4285F4);
  static const googleRed = Color(0xFFEA4335);
  static const googleYellow = Color(0xFFFBBC05);
  static const googleGreen = Color(0xFF34A853);
  static const facebookBlue = Color(0xFF1877F2);
}
