import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.skyBottom,
      textTheme: Typography.blackMountainView.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 64),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
      ),
    );
  }
}
