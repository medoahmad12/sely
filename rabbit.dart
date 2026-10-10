import 'dart:math' as math;
import 'package:flutter/material.dart';

enum RabbitMood { idle, happy, sad, cheer, thinking }

/// Arnoub (أرنوب), the forest rabbit. Drawn entirely in code; blinks, breathes and
/// wiggles his ears. Change [hopTrigger] to make him hop.
class Rabbit extends StatefulWidget {
  const Rabbit({super.key, this.size = 140, this.mood = RabbitMood.idle, this.hopTrigger = 0});
  final double size;
  final RabbitMood mood;
  final int hopTrigger;

  @override
  State<Rabbit> createState() => _RabbitState();
}

class _RabbitState extends State<Rabbit> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final AnimationController _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void didUpdateWidget(Rabbit old) {
    super.didUpdateWidget(old);
    if (old.hopTrigger != widget.hopTrigger) _hop.forward(from: 0);
  }

  @override
  void dispose() {
    _idle.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Semantics(
      label: 'أرنوب',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _hop]),
          builder: (context, _) {
            final t = _idle.value;
            final bt = (t * 3) % 1.0;
            final blink = bt > 0.93 ? (1 - ((bt - 0.965).abs() / 0.035)).clamp(0.0, 1.0).toDouble() : 0.0;
            final breathe = math.sin(t * 2 * math.pi) * s * 0.012;
            final hop = -math.sin(_hop.value * math.pi) * s * 0.2;
            return Transform.translate(
              offset: Offset(0, breathe + hop),
              child: CustomPaint(
                size: Size.square(s),
                painter: _RabbitPainter(
                  mood: widget.mood,
                  blink: blink,
                  wiggle: math.sin(t * 2 * math.pi * 2) * 0.07,
                  armWave: math.sin(t * 2 * math.pi * 5),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RabbitPainter extends CustomPainter {
  _RabbitPainter({required this.mood, required this.blink, required this.wiggle, required this.armWave});
  final RabbitMood mood;
  final double blink;
  final double wiggle;
  final double armWave;

  static const _fur = Color(0xFFFFF6EA);
  static const _furShade = Color(0xFFEBD5BA);
  static const _pink = Color(0xFFFFA9B8);
  static const _ink = Color(0xFF3B2E4A);
  static const _scarf = Color(0xFFFF8A3D);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _ink;
    final sad = mood == RabbitMood.sad;
    final up = mood == RabbitMood.cheer;

    // tail
    fill.color = Colors.white;
    canvas.drawCircle(const Offset(24, 82), 6.5, fill);

    // ears (drawn first so the head overlaps their base)
    for (final left in [true, false]) {
      final dir = left ? -1.0 : 1.0;
      canvas.save();
      canvas.translate(left ? 39 : 61, 28);
      final base = sad ? 0.55 : 0.1;
      canvas.rotate(dir * base + (left ? wiggle : -wiggle));
      final len = sad ? 26.0 : 36.0;
      fill.color = _fur;
      canvas.drawOval(Rect.fromLTWH(-7.5, -len, 15, len + 4), fill);
      fill.color = _pink;
      canvas.drawOval(Rect.fromLTWH(-4, -len + 5, 8, len - 6), fill);
      canvas.restore();
    }

    // body
    fill.color = _fur;
    canvas.drawOval(const Rect.fromLTWH(26, 62, 48, 38), fill);
    fill.color = _furShade;
    canvas.drawOval(const Rect.fromLTWH(34, 74, 32, 24), fill);
    // feet
    fill.color = _fur;
    canvas.drawOval(const Rect.fromLTWH(26, 90, 22, 10), fill);
    canvas.drawOval(const Rect.fromLTWH(52, 90, 22, 10), fill);
    fill.color = _pink;
    canvas.drawCircle(const Offset(37, 95), 2.4, fill);
    canvas.drawCircle(const Offset(63, 95), 2.4, fill);

    // arms
    final arm = Paint()
      ..color = _fur
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;
    if (up) {
      final lift = armWave * 2;
      canvas.drawLine(const Offset(34, 72), Offset(24, 52 + lift), arm);
      canvas.drawLine(const Offset(66, 72), Offset(76, 52 - lift), arm);
    } else if (mood == RabbitMood.happy) {
      canvas.drawLine(const Offset(34, 74), const Offset(30, 84), arm);
      canvas.drawLine(const Offset(66, 72), Offset(77, 62 + armWave * 3), arm);
    } else {
      canvas.drawLine(const Offset(34, 74), const Offset(32, 86), arm);
      canvas.drawLine(const Offset(66, 74), const Offset(68, 86), arm);
    }

    // scarf
    fill.color = _scarf;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(31, 62, 38, 9), const Radius.circular(5)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(58, 66, 8, 15), const Radius.circular(4)), fill);

    // head
    fill.color = _fur;
    canvas.drawCircle(const Offset(50, 46), 24, fill);
    line.strokeWidth = 1.1;
    line.color = _furShade;
    canvas.drawArc(Rect.fromCircle(center: const Offset(50, 46), radius: 24), 0.3, 2.6, false, line);
    line.color = _ink;

    // cheeks
    fill.color = const Color(0x66FF8FA3);
    canvas.drawCircle(const Offset(34, 54), 5, fill);
    canvas.drawCircle(const Offset(66, 54), 5, fill);

    // eyes
    for (final cx in [41.0, 59.0]) {
      if (mood == RabbitMood.happy || mood == RabbitMood.cheer) {
        line.strokeWidth = 2;
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, 46), width: 9, height: 7), math.pi, math.pi, false, line);
      } else {
        final eh = 9.5 * (1 - blink * 0.92);
        fill.color = _ink;
        final lookX = mood == RabbitMood.thinking ? 1.5 : 0.0;
        final lookY = mood == RabbitMood.thinking ? -1.5 : 0.0;
        canvas.drawOval(Rect.fromCenter(center: Offset(cx + lookX, 46 + lookY), width: 7.5, height: eh), fill);
        if (blink < 0.6) {
          fill.color = Colors.white;
          canvas.drawCircle(Offset(cx + 1.4 + lookX, 44 + lookY), 1.3, fill);
        }
      }
    }
    if (sad) {
      line.strokeWidth = 1.6;
      canvas.drawLine(const Offset(36, 38), const Offset(45, 41), line);
      canvas.drawLine(const Offset(64, 38), const Offset(55, 41), line);
    }

    // nose + mouth
    fill.color = const Color(0xFFFF7A93);
    canvas.drawOval(const Rect.fromLTWH(47, 50, 6, 4.5), fill);
    line.strokeWidth = 1.5;
    if (mood == RabbitMood.happy || mood == RabbitMood.cheer) {
      fill.color = const Color(0xFFE53950);
      canvas.drawPath(
        Path()
          ..moveTo(43, 56)
          ..quadraticBezierTo(50, 69, 57, 56)
          ..close(),
        fill,
      );
      fill.color = const Color(0xFFFF9BAD);
      canvas.drawOval(const Rect.fromLTWH(46.5, 61, 7, 4), fill);
    } else if (sad) {
      canvas.drawPath(
        Path()
          ..moveTo(44, 62)
          ..quadraticBezierTo(50, 56, 56, 62),
        line,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(44, 56)
          ..quadraticBezierTo(47, 60, 50, 56)
          ..quadraticBezierTo(53, 60, 56, 56),
        line,
      );
    }

    // whiskers
    line.strokeWidth = 0.8;
    line.color = const Color(0xFFB8A58F);
    canvas.drawLine(const Offset(30, 54), const Offset(20, 52), line);
    canvas.drawLine(const Offset(30, 57), const Offset(20, 58), line);
    canvas.drawLine(const Offset(70, 54), const Offset(80, 52), line);
    canvas.drawLine(const Offset(70, 57), const Offset(80, 58), line);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RabbitPainter o) =>
      o.mood != mood || o.blink != blink || o.wiggle != wiggle || o.armWave != armWave;
}
