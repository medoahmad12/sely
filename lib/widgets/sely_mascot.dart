import 'dart:math' as math;
import 'package:flutter/material.dart';

/// SELY - the original blue mascot, drawn entirely with CustomPainter (no image files).
class SelyMascot extends StatefulWidget {
  const SelyMascot({super.key, this.size = 140, this.hat = 'none', this.waving = true, this.sleepy = false});
  final double size;
  final String hat;
  final bool waving;
  final bool sleepy;

  @override
  State<SelyMascot> createState() => _SelyMascotState();
}

class _SelyMascotState extends State<SelyMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'SELY',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final bt = (t * 4) % 1.0;
            final blink = widget.sleepy
                ? 1.0
                : (bt > 0.94 ? (1 - ((bt - 0.97).abs() / 0.03)).clamp(0.0, 1.0).toDouble() : 0.0);
            final bob = math.sin(t * 2 * math.pi) * widget.size * 0.02;
            return Transform.translate(
              offset: Offset(0, bob),
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _SelyPainter(
                  blink: blink,
                  wave: widget.waving ? math.sin(t * 2 * math.pi * 4) : 0,
                  hat: widget.hat,
                  sleepy: widget.sleepy,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SelyPainter extends CustomPainter {
  _SelyPainter({required this.blink, required this.wave, required this.hat, required this.sleepy});
  final double blink;
  final double wave;
  final String hat;
  final bool sleepy;

  static const _blue = Color(0xFF3AAAFF);
  static const _blueDark = Color(0xFF2386E0);
  static const _orange = Color(0xFFFFB02E);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final fill = Paint()..style = PaintingStyle.fill;

    // body
    fill.color = _blueDark;
    canvas.drawOval(Rect.fromLTWH(27, 66, 46, 34), fill);
    fill.color = const Color(0xFF8AD4FF);
    canvas.drawOval(Rect.fromLTWH(37, 74, 26, 22), fill);
    // backpack strap
    fill.color = _orange;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(30, 72, 5, 20), const Radius.circular(2)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(65, 72, 5, 20), const Radius.circular(2)), fill);

    // waving arm
    final arm = Paint()
      ..color = _blue
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final a = -0.9 + wave * 0.35;
    canvas.drawLine(const Offset(70, 78), Offset(70 + 18 * math.cos(a), 78 + 18 * math.sin(a)), arm);

    // ears
    for (final left in [true, false]) {
      canvas.save();
      canvas.translate(left ? 24 : 76, 26);
      canvas.rotate(left ? -0.45 : 0.45);
      fill.color = _blue;
      canvas.drawOval(Rect.fromLTWH(-9, -16, 18, 30), fill);
      fill.color = _orange;
      canvas.drawOval(Rect.fromLTWH(-5, -12, 10, 20), fill);
      canvas.restore();
    }

    // head
    final head = Rect.fromCircle(center: const Offset(50, 48), radius: 31);
    fill.shader = const RadialGradient(
      center: Alignment(-0.3, -0.4),
      colors: [Color(0xFF7FCBFF), _blue],
    ).createShader(head);
    canvas.drawCircle(const Offset(50, 48), 31, fill);
    fill.shader = null;

    // tuft
    fill.color = _blue;
    canvas.drawPath(
      Path()
        ..moveTo(50, 20)
        ..quadraticBezierTo(44, 10, 52, 8)
        ..quadraticBezierTo(58, 12, 50, 20),
      fill,
    );

    // cheeks
    fill.color = const Color(0x66FF6F91);
    canvas.drawCircle(const Offset(29, 57), 6, fill);
    canvas.drawCircle(const Offset(71, 57), 6, fill);

    // eyes
    for (final cx in [37.0, 63.0]) {
      final h = 18 * (1 - blink * 0.92);
      fill.color = Colors.white;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, 45), width: 15, height: h), fill);
      if (blink < 0.7) {
        fill.color = const Color(0xFF14336E);
        canvas.drawCircle(Offset(cx + 0.5, 46), 6.2 * (1 - blink * 0.4), fill);
        fill.color = Colors.white;
        canvas.drawCircle(Offset(cx + 2.5, 43.5), 1.8, fill);
      } else {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, 45), width: 14, height: 8),
          0,
          math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const Color(0xFF14336E),
        );
      }
    }

    // nose + mouth
    fill.color = _blueDark;
    canvas.drawOval(Rect.fromLTWH(47, 53, 6, 4), fill);
    if (sleepy) {
      canvas.drawArc(
        Rect.fromLTWH(42, 59, 16, 8),
        0,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF14336E),
      );
    } else {
      fill.color = const Color(0xFFE53950);
      canvas.drawPath(
        Path()
          ..moveTo(39, 60)
          ..quadraticBezierTo(50, 76, 61, 60)
          ..close(),
        fill,
      );
      fill.color = const Color(0xFFFF8FA3);
      canvas.drawOval(Rect.fromLTWH(45, 65, 10, 5), fill);
    }

    _drawHat(canvas, fill);
    canvas.restore();
  }

  void _drawHat(Canvas canvas, Paint fill) {
    switch (hat) {
      case 'party':
        fill.color = const Color(0xFFFF4F8B);
        canvas.drawPath(
          Path()
            ..moveTo(36, 22)
            ..lineTo(64, 22)
            ..lineTo(50, -2)
            ..close(),
          fill,
        );
        fill.color = const Color(0xFFFFD43B);
        canvas.drawCircle(const Offset(50, -1), 3.5, fill);
        canvas.drawRect(Rect.fromLTWH(36, 20, 28, 3), fill);
        break;
      case 'crown':
        fill.color = const Color(0xFFFFC107);
        canvas.drawPath(
          Path()
            ..moveTo(34, 22)
            ..lineTo(34, 6)
            ..lineTo(42, 14)
            ..lineTo(50, 2)
            ..lineTo(58, 14)
            ..lineTo(66, 6)
            ..lineTo(66, 22)
            ..close(),
          fill,
        );
        fill.color = const Color(0xFFFF4F8B);
        canvas.drawCircle(const Offset(50, 14), 2.5, fill);
        break;
      case 'glasses':
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = const Color(0xFF2B2F8F);
        canvas.drawCircle(const Offset(37, 45), 10, p);
        canvas.drawCircle(const Offset(63, 45), 10, p);
        canvas.drawLine(const Offset(47, 45), const Offset(53, 45), p);
        break;
      case 'bow':
        fill.color = const Color(0xFFFF4F8B);
        canvas.drawPath(
          Path()
            ..moveTo(50, 70)
            ..lineTo(36, 64)
            ..lineTo(36, 78)
            ..close()
            ..moveTo(50, 70)
            ..lineTo(64, 64)
            ..lineTo(64, 78)
            ..close(),
          fill,
        );
        fill.color = const Color(0xFFFFD43B);
        canvas.drawCircle(const Offset(50, 70), 3.5, fill);
        break;
    }
  }

  @override
  bool shouldRepaint(_SelyPainter o) =>
      o.blink != blink || o.wave != wave || o.hat != hat || o.sleepy != sleepy;
}
