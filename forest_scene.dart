import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Colors of the forest world. Everything is vector-drawn: no image files.
class ForestPalette {
  ForestPalette._();
  static const skyTop = Color(0xFF4FC3FF);
  static const skyBottom = Color(0xFFDDF7FF);
  static const hillFar = Color(0xFF6CC3A4);
  static const hillMid = Color(0xFF45B06D);
  static const ground = Color(0xFF5DCB6B);
  static const groundDark = Color(0xFF3FAE58);
  static const trunk = Color(0xFF8D5A3B);
  static const leafDark = Color(0xFF278E4E);
  static const leaf = Color(0xFF35AD62);
  static const leafLight = Color(0xFF63D184);
  static const pine = Color(0xFF1F8A5B);
  static const sun = Color(0xFFFFD43B);
}

void drawCloud(Canvas canvas, Offset c, double s, {double alpha = 0.95}) {
  final p = Paint()..color = Colors.white.withValues(alpha: alpha);
  canvas.drawCircle(c + Offset(-0.9 * s, 0.1 * s), 0.55 * s, p);
  canvas.drawCircle(c + Offset(-0.2 * s, -0.3 * s), 0.75 * s, p);
  canvas.drawCircle(c + Offset(0.7 * s, 0.0), 0.6 * s, p);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: c + Offset(-0.1 * s, 0.35 * s), width: 2.8 * s, height: 0.7 * s),
      Radius.circular(0.35 * s),
    ),
    p,
  );
}

/// [sway] is -1..1 (how far the canopy leans). [variant] 0 = round tree, 1 = pine.
void drawTree(Canvas canvas, Offset base, double h, double sway, {int variant = 0}) {
  final trunkW = h * 0.12;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx - trunkW / 2, base.dy - h * 0.45, trunkW, h * 0.45),
      Radius.circular(trunkW * 0.3),
    ),
    Paint()..color = ForestPalette.trunk,
  );
  final dx = sway * h * 0.04;
  if (variant == 1) {
    final p = Paint()..color = ForestPalette.pine;
    for (var i = 0; i < 3; i++) {
      final y = base.dy - h * (0.28 + 0.2 * i);
      final w = h * (0.5 - 0.1 * i);
      final shift = dx * (i + 1) * 0.5;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx + shift, y - h * 0.3)
          ..lineTo(base.dx - w / 2 + shift * 0.5, y)
          ..lineTo(base.dx + w / 2 + shift * 0.5, y)
          ..close(),
        p,
      );
    }
    return;
  }
  final dark = Paint()..color = ForestPalette.leafDark;
  final mid = Paint()..color = ForestPalette.leaf;
  final light = Paint()..color = ForestPalette.leafLight;
  canvas.drawCircle(Offset(base.dx + dx, base.dy - h * 0.62), h * 0.30, dark);
  canvas.drawCircle(Offset(base.dx - h * 0.18 + dx, base.dy - h * 0.52), h * 0.22, mid);
  canvas.drawCircle(Offset(base.dx + h * 0.2 + dx, base.dy - h * 0.52), h * 0.22, mid);
  canvas.drawCircle(Offset(base.dx - h * 0.04 + dx * 1.2, base.dy - h * 0.7), h * 0.18, light);
}

void drawBush(Canvas canvas, Offset c, double s) {
  final dark = Paint()..color = ForestPalette.leafDark;
  final mid = Paint()..color = ForestPalette.leaf;
  canvas.drawCircle(c + Offset(-0.5 * s, 0), 0.5 * s, dark);
  canvas.drawCircle(c + Offset(0.5 * s, 0), 0.5 * s, dark);
  canvas.drawCircle(c + Offset(0, -0.25 * s), 0.6 * s, mid);
}

void drawFlower(Canvas canvas, Offset c, double s, Color petal) {
  canvas.drawLine(
    c,
    c + Offset(0, s * 1.4),
    Paint()
      ..color = ForestPalette.leafDark
      ..strokeWidth = s * 0.18
      ..strokeCap = StrokeCap.round,
  );
  final p = Paint()..color = petal;
  for (var i = 0; i < 5; i++) {
    final a = i * 2 * math.pi / 5;
    canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (s * 0.42), s * 0.34, p);
  }
  canvas.drawCircle(c, s * 0.3, Paint()..color = const Color(0xFFFFE066));
}

/// [phase] 0..1 loops once per [ForestBackground] cycle (the sun makes one slow turn).
void drawSun(Canvas canvas, Offset c, double r, double phase) {
  canvas.drawCircle(
    c,
    r * 2.6,
    Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x66FFE66D), Color(0x00FFE66D)],
      ).createShader(Rect.fromCircle(center: c, radius: r * 2.6)),
  );
  final ray = Paint()
    ..color = ForestPalette.sun
    ..strokeWidth = r * 0.14
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 12; i++) {
    final a = phase * 2 * math.pi + i * math.pi / 6;
    final d = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(c + d * (r * 1.25), c + d * (r * 1.6), ray);
  }
  canvas.drawCircle(c, r, Paint()..color = ForestPalette.sun);
  canvas.drawCircle(c + Offset(-r * 0.25, -r * 0.25), r * 0.45, Paint()..color = const Color(0x55FFFFFF));
}

/// [flap] is -1..1.
void drawButterfly(Canvas canvas, Offset c, double s, double flap, Color color) {
  final w = 0.35 + 0.65 * flap.abs();
  final wing = Paint()..color = color;
  final wing2 = Paint()..color = color.withValues(alpha: 0.8);
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.5 * w, -s * 0.15), width: s * w, height: s * 0.9), wing);
  canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.5 * w, -s * 0.15), width: s * w, height: s * 0.9), wing);
  canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.4 * w, s * 0.3), width: s * 0.7 * w, height: s * 0.6), wing2);
  canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.4 * w, s * 0.3), width: s * 0.7 * w, height: s * 0.6), wing2);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s * 0.12, height: s * 0.8),
      Radius.circular(s * 0.06),
    ),
    Paint()..color = const Color(0xFF4A3B5C),
  );
  canvas.restore();
}

/// Full-screen animated forest. Put screen content in [child].
class ForestBackground extends StatefulWidget {
  const ForestBackground({super.key, this.child});
  final Widget? child;

  @override
  State<ForestBackground> createState() => _ForestBackgroundState();
}

class _ForestBackgroundState extends State<ForestBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(painter: _ForestPainter(_c.value)),
          ),
        ),
      ),
      if (widget.child != null) Positioned.fill(child: widget.child!),
    ]);
  }
}

class _ForestPainter extends CustomPainter {
  _ForestPainter(this.phase);
  final double phase;

  static const _treeXs = [0.06, 0.24, 0.47, 0.7, 0.9];
  static const _treeHs = [0.25, 0.2, 0.27, 0.21, 0.26];
  static const _flowerXs = [0.08, 0.2, 0.34, 0.5, 0.63, 0.78, 0.92];
  static const _flowerColors = [
    Color(0xFFFF4F8B),
    Color(0xFFFFFFFF),
    Color(0xFFFF9F1C),
    Color(0xFFB388FF),
    Color(0xFFFF4F8B),
    Color(0xFFFFFFFF),
    Color(0xFFFF9F1C),
  ];

  double _hill(double x, double w, double h, double base, double amp, double freq, double shift) =>
      h * base + math.sin(x / w * 2 * math.pi * freq + shift) * h * amp;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tau = 2 * math.pi;

    // sky
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ForestPalette.skyTop, ForestPalette.skyBottom],
        ).createShader(Offset.zero & size),
    );

    drawSun(canvas, Offset(w * 0.82, h * 0.12), w * 0.07, phase);

    // clouds drifting right, wrapping around
    for (var i = 0; i < 3; i++) {
      final x = ((phase * (1 + i) * 0.5 + i * 0.37) % 1.3 - 0.15) * w;
      drawCloud(canvas, Offset(x, h * (0.09 + 0.07 * i)), w * (0.06 + 0.012 * i), alpha: 0.9);
    }

    // far hills
    final far = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w + 8; x += 8) {
      far.lineTo(x, _hill(x, w, h, 0.5, 0.03, 1.1, 0.6));
    }
    far
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(far, Paint()..color = ForestPalette.hillFar);

    // mid hills with swaying trees
    final mid = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w + 8; x += 8) {
      mid.lineTo(x, _hill(x, w, h, 0.62, 0.035, 1.5, 2.0));
    }
    mid
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mid, Paint()..color = ForestPalette.hillMid);

    for (var i = 0; i < _treeXs.length; i++) {
      final x = _treeXs[i] * w;
      final y = _hill(x, w, h, 0.62, 0.035, 1.5, 2.0) + h * 0.03;
      final sway = math.sin(phase * tau * 3 + i * 1.3);
      drawTree(canvas, Offset(x, y), h * _treeHs[i], sway, variant: i.isOdd ? 1 : 0);
    }

    // foreground meadow
    final groundTop = h * 0.8;
    canvas.drawRect(
      Rect.fromLTRB(0, groundTop, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ForestPalette.ground, ForestPalette.groundDark],
        ).createShader(Rect.fromLTRB(0, groundTop, w, h)),
    );
    drawBush(canvas, Offset(w * 0.04, groundTop + h * 0.01), w * 0.09);
    drawBush(canvas, Offset(w * 0.97, groundTop + h * 0.015), w * 0.1);
    for (var i = 0; i < _flowerXs.length; i++) {
      final bob = math.sin(phase * tau * 2 + i) * 1.5;
      drawFlower(
        canvas,
        Offset(_flowerXs[i] * w, groundTop + h * (0.04 + 0.045 * ((i * 5) % 3)) + bob),
        w * 0.022,
        _flowerColors[i],
      );
    }

    // butterflies
    for (var i = 0; i < 2; i++) {
      final a = phase * tau * (2 + i) + i * 2.0;
      final c = Offset(w * (0.3 + 0.35 * i + 0.1 * math.sin(a)), h * (0.42 + 0.06 * i + 0.04 * math.sin(a * 1.5)));
      drawButterfly(canvas, c, w * 0.035, math.sin(phase * tau * 40 + i), i == 0 ? const Color(0xFFFF8AD8) : const Color(0xFFFFB84D));
    }

    // falling leaves
    final leaf = Paint()..color = const Color(0xFFFFB84D).withValues(alpha: 0.85);
    for (var i = 0; i < 5; i++) {
      final t = (phase * 2 + i * 0.2) % 1.0;
      final x = w * (0.12 + 0.19 * i) + math.sin(t * tau * 2 + i) * w * 0.03;
      canvas.save();
      canvas.translate(x, t * h * 0.85);
      canvas.rotate(t * tau * 2 + i);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.02, height: w * 0.012), leaf);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ForestPainter old) => old.phase != phase;
}
