import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../models/content_models.dart';
import '../../services/audio_service.dart';
import '../../widgets/kid_scaffold.dart';
import 'trace_evaluator.dart';

/// Real finger-tracing surface. Draws the dotted guide, colors the parts the
/// child has covered and calls [onComplete] when [TraceEvaluator] says it's done.
class TraceBoard extends StatefulWidget {
  const TraceBoard({super.key, required this.shape, required this.onComplete, this.color = AppColors.primary});
  final TraceShape shape;
  final VoidCallback onComplete;
  final Color color;

  @override
  State<TraceBoard> createState() => _TraceBoardState();
}

class _TraceBoardState extends State<TraceBoard> with SingleTickerProviderStateMixin {
  late TraceEvaluator _eval = TraceEvaluator(widget.shape);
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  final List<List<Offset>> _trail = [];
  bool _finished = false;
  bool _showRetry = false;

  @override
  void didUpdateWidget(TraceBoard old) {
    super.didUpdateWidget(old);
    if (old.shape != widget.shape) {
      _eval = TraceEvaluator(widget.shape);
      _clear();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static const _padFraction = 0.1;

  Offset _toNorm(Offset px, double size) {
    final pad = size * _padFraction;
    final inner = size - 2 * pad;
    return Offset((px.dx - pad) / inner, (px.dy - pad) / inner);
  }

  void _clear() {
    setState(() {
      _eval.reset();
      _trail.clear();
      _finished = false;
      _showRetry = false;
    });
  }

  void _down(Offset px, double size) {
    if (_finished) return;
    _trail.add([px]);
    _eval.addPoint(_toNorm(px, size));
    _after();
  }

  void _move(Offset px, double size) {
    if (_finished || _trail.isEmpty) return;
    _trail.last.add(px);
    _eval.addPoint(_toNorm(px, size));
    _after();
  }

  void _up() {
    _eval.endStroke();
    if (!_finished) _after();
  }

  void _after() {
    if (_eval.isScribble) {
      AppScope.read(context).audio.playSfx(Sfx.wrong);
      unawaited(AppScope.read(context).say('trace_retry'));
      _eval.reset();
      _trail.clear();
      setState(() => _showRetry = true);
      return;
    }
    if (_eval.isComplete) {
      _finished = true;
      setState(() => _showRetry = false);
      AppScope.read(context).audio.playSfx(Sfx.correct);
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted) widget.onComplete();
      });
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return LayoutBuilder(builder: (context, c) {
      final size = (c.maxHeight.isFinite
              ? clampTo(c.maxHeight - 76 * u, 120, c.maxWidth)
              : c.maxWidth)
          .clamp(120.0, c.maxWidth)
          .toDouble();
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Listener(
              key: const Key('trace_surface'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => _down(e.localPosition, size),
              onPointerMove: (e) => _move(e.localPosition, size),
              onPointerUp: (_) => _up(),
              onPointerCancel: (_) => _up(),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => CustomPaint(
                  size: Size.square(size),
                  painter: _TracePainter(
                    eval: _eval,
                    trail: _trail,
                    color: widget.color,
                    pulse: _pulse.value,
                    showHint: !_finished,
                    padFraction: _padFraction,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8 * u),
        SizedBox(
          height: 60 * u,
          child: _showRetry
              ? Text(context.tr('trace_retry'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20 * u, fontWeight: FontWeight.w800, color: AppColors.orange))
              : RoundIconButton(
                  icon: Icons.refresh_rounded,
                  label: context.tr('trace_clear'),
                  onTap: _clear,
                ),
        ),
      ]);
    });
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.eval,
    required this.trail,
    required this.color,
    required this.pulse,
    required this.showHint,
    required this.padFraction,
  });
  final TraceEvaluator eval;
  final List<List<Offset>> trail;
  final Color color;
  final double pulse;
  final bool showHint;
  final double padFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = size.width * padFraction;
    final inner = size.width - 2 * pad;
    Offset px(Offset n) => Offset(pad + n.dx * inner, pad + n.dy * inner);
    final stroke = size.width * 0.075;

    // dashed guide
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFCFD8DC);
    for (final pts in eval.shape.strokes) {
      final path = Path()..moveTo(px(pts.first).dx, px(pts.first).dy);
      for (final p in pts.skip(1)) {
        final o = px(p);
        path.lineTo(o.dx, o.dy);
      }
      final dash = stroke * 0.5, gap = stroke * 0.9;
      for (final m in path.computeMetrics()) {
        var d = 0.0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, (d + dash).clamp(0, m.length).toDouble()), guide);
          d += dash + gap;
        }
      }
    }
    for (final d in eval.dots) {
      canvas.drawCircle(px(d), stroke * 0.8, Paint()..color = const Color(0xFFCFD8DC));
    }

    // covered parts
    final done = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (var s = 0; s < eval.checkpoints.length; s++) {
      final pts = eval.checkpoints[s];
      final hits = eval.hit[s];
      for (var i = 0; i < pts.length; i++) {
        if (!hits[i]) continue;
        if (i + 1 < pts.length && hits[i + 1]) {
          canvas.drawLine(px(pts[i]), px(pts[i + 1]), done);
        } else {
          canvas.drawCircle(px(pts[i]), stroke / 2, Paint()..color = color);
        }
      }
    }
    for (var i = 0; i < eval.dots.length; i++) {
      if (eval.dotHit[i]) canvas.drawCircle(px(eval.dots[i]), stroke * 0.8, Paint()..color = color);
    }

    // finger trail
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.35
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.35);
    for (final t in trail) {
      if (t.length < 2) continue;
      final path = Path()..moveTo(t.first.dx, t.first.dy);
      for (final p in t.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, trailPaint);
    }

    // "start here" hint
    final hint = eval.hintPoint;
    if (showHint && hint != null) {
      final c = px(hint);
      canvas.drawCircle(c, stroke * (0.7 + 0.35 * pulse), Paint()..color = const Color(0xFF3FBF4A).withValues(alpha: 0.85));
      canvas.drawCircle(c, stroke * 0.25, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}
