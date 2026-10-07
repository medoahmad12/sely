import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Resolution-independent sizing helpers (phones and tablets).
extension ResponsiveContext on BuildContext {
  /// Scale factor relative to a 390 dp wide phone.
  double get u => (MediaQuery.sizeOf(this).shortestSide / 390).clamp(0.8, 1.7).toDouble();
}

double clampTo(double v, double lo, double hi) => math.max(lo, math.min(hi, v));

String formatDuration(int seconds, {String minLabel = 'min', String secLabel = 's'}) {
  if (seconds < 60) return '$seconds $secLabel';
  final m = seconds ~/ 60;
  if (m < 60) return '$m $minLabel';
  final h = m ~/ 60;
  final rem = m % 60;
  return '${h}h ${rem}$minLabel';
}
