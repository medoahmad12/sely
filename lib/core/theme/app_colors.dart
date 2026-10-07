import 'package:flutter/material.dart';

/// Brand palette. See docs/DESIGN_SYSTEM.md.
class AppColors {
  AppColors._();
  static const primary = Color(0xFF1E9BFF);
  static const primaryDark = Color(0xFF1366D6);
  static const navy = Color(0xFF2B2F8F);
  static const orange = Color(0xFFFF9F1C);
  static const yellow = Color(0xFFFFD43B);
  static const green = Color(0xFF3FBF4A);
  static const pink = Color(0xFFFF4F8B);
  static const purple = Color(0xFF7B5CF0);
  static const red = Color(0xFFFF5252);
  static const ink = Color(0xFF263159);
  static const skyTop = Color(0xFF6FD0FF);
  static const skyBottom = Color(0xFFE6F7FF);
  static const card = Colors.white;

  /// Favorite-color choices on the setup screen.
  static const childColors = <Color>[primary, pink, green, purple, orange];
}
