import 'dart:math' as math;
import 'dart:ui';
import '../../models/content_models.dart';

/// Resamples a polyline into points roughly [spacing] apart (normalized units).
List<Offset> resamplePolyline(List<Offset> pts, double spacing) {
  if (pts.length < 2) return List.of(pts);
  final out = <Offset>[pts.first];
  var carry = 0.0;
  for (var i = 1; i < pts.length; i++) {
    var a = pts[i - 1];
    final b = pts[i];
    var seg = (b - a).distance;
    while (seg > 0 && carry + seg >= spacing) {
      final need = spacing - carry;
      a = Offset.lerp(a, b, need / seg)!;
      out.add(a);
      seg = (b - a).distance;
      carry = 0;
    }
    carry += seg;
  }
  if ((out.last - pts.last).distance > spacing * 0.3) out.add(pts.last);
  return out;
}

/// Decides whether the child followed a [TraceShape]. Pure Dart: works in
/// normalized 0..1 coordinates so it is independent of screen size.
///
/// A trace is complete when enough checkpoints along the guide were touched
/// ([coverage]) AND most finger samples stayed near the guide ([accuracy]),
/// so scribbling over the whole box does not count.
class TraceEvaluator {
  TraceEvaluator(this.shape, {this.tolerance = 0.09, this.spacing = 0.045}) {
    for (final s in shape.strokes) {
      final pts = resamplePolyline(s, spacing);
      checkpoints.add(pts);
      hit.add(List<bool>.filled(pts.length, false));
      _guide.addAll(resamplePolyline(s, tolerance * 0.5));
    }
    dots = List.of(shape.dots);
    dotHit = List<bool>.filled(dots.length, false);
    _guide.addAll(dots);
    _total = checkpoints.fold<int>(0, (a, b) => a + b.length) + dots.length;
  }

  final TraceShape shape;
  final double tolerance;
  final double spacing;

  final List<List<Offset>> checkpoints = [];
  final List<List<bool>> hit = [];
  late final List<Offset> dots;
  late final List<bool> dotHit;
  final List<Offset> _guide = [];
  late final int _total;

  int _hitCount = 0;
  int _samples = 0;
  int _onPath = 0;
  Offset? _last;

  static const double completeCoverage = 0.92;
  static const double minAccuracy = 0.55;

  double get coverage => _total == 0 ? 0 : _hitCount / _total;
  double get accuracy => _samples == 0 ? 0 : _onPath / _samples;
  int get sampleCount => _samples;

  /// Enough of the path was covered and every dot touched (accuracy not considered).
  bool get covered => coverage >= completeCoverage && dotHit.every((h) => h);

  /// Covered and the child stayed on the path.
  bool get isComplete => covered && accuracy >= minAccuracy;

  /// Covered but sloppy (scribbling): the board should reset.
  bool get isScribble => covered && accuracy < minAccuracy;

  /// First not-yet-touched checkpoint, used to animate a "start here" hint.
  Offset? get hintPoint {
    for (var s = 0; s < checkpoints.length; s++) {
      for (var i = 0; i < checkpoints[s].length; i++) {
        if (!hit[s][i]) return checkpoints[s][i];
      }
    }
    for (var i = 0; i < dots.length; i++) {
      if (!dotHit[i]) return dots[i];
    }
    return null;
  }

  void addPoint(Offset p) {
    final prev = _last;
    _last = p;
    if (prev == null) {
      _sample(p);
      return;
    }
    final dist = (p - prev).distance;
    final steps = math.max(1, (dist / (tolerance * 0.5)).ceil());
    for (var i = 1; i <= steps; i++) {
      _sample(Offset.lerp(prev, p, i / steps)!);
    }
  }

  void endStroke() => _last = null;

  void reset() {
    for (final h in hit) {
      h.fillRange(0, h.length, false);
    }
    dotHit.fillRange(0, dotHit.length, false);
    _hitCount = 0;
    _samples = 0;
    _onPath = 0;
    _last = null;
  }

  void _sample(Offset p) {
    _samples++;
    final onPathR2 = math.pow(tolerance * 1.5, 2).toDouble();
    final hitR2 = math.pow(tolerance, 2).toDouble();
    for (final g in _guide) {
      if ((g - p).distanceSquared <= onPathR2) {
        _onPath++;
        break;
      }
    }
    for (var s = 0; s < checkpoints.length; s++) {
      final pts = checkpoints[s];
      for (var i = 0; i < pts.length; i++) {
        if (!hit[s][i] && (pts[i] - p).distanceSquared <= hitR2) {
          hit[s][i] = true;
          _hitCount++;
        }
      }
    }
    final dotR2 = math.pow(tolerance * 1.4, 2).toDouble();
    for (var i = 0; i < dots.length; i++) {
      if (!dotHit[i] && (dots[i] - p).distanceSquared <= dotR2) {
        dotHit[i] = true;
        _hitCount++;
      }
    }
  }
}
