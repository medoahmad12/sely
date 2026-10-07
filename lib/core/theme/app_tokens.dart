import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();
  static const double xs = 4, s = 8, m = 16, l = 24, xl = 32;
}

class AppRadius {
  AppRadius._();
  static const double card = 28, button = 36, chip = 20;
}

class AppShadows {
  AppShadows._();
  static List<BoxShadow> soft(Color c) => [
        BoxShadow(color: c.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6)),
      ];
  static const card = [
    BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 5)),
  ];
}
