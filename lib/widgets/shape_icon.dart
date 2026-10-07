import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Geometric shapes drawn with CustomPainter (no image assets).
class ShapeIcon extends StatelessWidget {
  const ShapeIcon({super.key, required this.shape, required this.size, this.color = const Color(0xFF1E9BFF)});
  final String shape;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ShapePainter(shape, color));
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.shape, this.color);
  final String shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final fill = Paint()..color = color;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withValues(alpha: 0.18);
    Path path;
    switch (shape) {
      case 'circle':
        path = Path()..addOval(Rect.fromLTWH(w * .08, h * .08, w * .84, h * .84));
        break;
      case 'square':
        path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .12, h * .12, w * .76, h * .76), Radius.circular(w * .06)));
        break;
      case 'rectangle':
        path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .04, h * .24, w * .92, h * .52), Radius.circular(w * .06)));
        break;
      case 'triangle':
        path = Path()
          ..moveTo(w * .5, h * .1)
          ..lineTo(w * .92, h * .85)
          ..lineTo(w * .08, h * .85)
          ..close();
        break;
      case 'star':
        path = Path();
        for (var i = 0; i < 10; i++) {
          final r = (i.isEven ? 0.46 : 0.2) * w;
          final a = -math.pi / 2 + i * math.pi / 5;
          final p = Offset(w / 2 + r * math.cos(a), h * .54 + r * math.sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        path.close();
        break;
      case 'heart':
        path = Path()
          ..moveTo(w / 2, h * .88)
          ..cubicTo(-w * .08, h * .52, w * .08, h * .08, w / 2, h * .3)
          ..cubicTo(w * .92, h * .08, w * 1.08, h * .52, w / 2, h * .88)
          ..close();
        break;
      default:
        path = Path()..addOval(Rect.fromLTWH(w * .1, h * .1, w * .8, h * .8));
    }
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_ShapePainter o) => o.shape != shape || o.color != color;
}
