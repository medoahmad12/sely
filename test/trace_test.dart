import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sely_kids/features/trace/trace_evaluator.dart';
import 'package:sely_kids/models/content_models.dart';

void main() {
  const alef = TraceShape(strokes: [
    [Offset(0.5, 0.1), Offset(0.5, 0.9)]
  ], dots: []);

  test('resampling keeps endpoints and spacing', () {
    final pts = resamplePolyline(const [Offset(0, 0), Offset(1, 0)], 0.1);
    expect(pts.first, const Offset(0, 0));
    expect((pts.last - const Offset(1, 0)).distance, lessThan(0.05));
    expect(pts.length, greaterThanOrEqualTo(10));
  });

  test('following the path completes the trace', () {
    final e = TraceEvaluator(alef);
    for (var y = 0.1; y <= 0.9; y += 0.02) {
      e.addPoint(Offset(0.5, y));
    }
    e.endStroke();
    expect(e.coverage, greaterThan(0.92));
    expect(e.isComplete, isTrue);
  });

  test('a slightly wobbly path still counts', () {
    final e = TraceEvaluator(alef);
    for (var y = 0.1; y <= 0.9; y += 0.02) {
      e.addPoint(Offset(0.5 + 0.04 * math.sin(y * 30), y));
    }
    expect(e.isComplete, isTrue);
  });

  test('touching only part of the path is not complete', () {
    final e = TraceEvaluator(alef);
    for (var y = 0.1; y <= 0.4; y += 0.02) {
      e.addPoint(Offset(0.5, y));
    }
    expect(e.isComplete, isFalse);
    expect(e.coverage, lessThan(0.6));
    expect(e.hintPoint, isNotNull);
  });

  test('drawing somewhere else does not count', () {
    final e = TraceEvaluator(alef);
    for (var y = 0.1; y <= 0.9; y += 0.02) {
      e.addPoint(Offset(0.1, y));
    }
    expect(e.coverage, 0);
    expect(e.isComplete, isFalse);
  });

  test('scribbling over the whole box is detected as a scribble', () {
    final e = TraceEvaluator(alef);
    for (var row = 0; row <= 20; row++) {
      final y = row / 20;
      for (var x = 0.0; x <= 1; x += 0.02) {
        e.addPoint(Offset(row.isEven ? x : 1 - x, y));
      }
      e.endStroke();
    }
    expect(e.covered, isTrue);
    expect(e.isScribble, isTrue);
    expect(e.isComplete, isFalse);
    e.reset();
    expect(e.coverage, 0);
  });

  test('dots must be touched', () {
    const shape = TraceShape(strokes: [
      [Offset(0.2, 0.5), Offset(0.8, 0.5)]
    ], dots: [Offset(0.5, 0.9)]);
    final e = TraceEvaluator(shape);
    for (var x = 0.2; x <= 0.8; x += 0.02) {
      e.addPoint(Offset(x, 0.5));
    }
    expect(e.isComplete, isFalse);
    e.endStroke();
    e.addPoint(const Offset(0.5, 0.9));
    expect(e.isComplete, isTrue);
  });

  test('smoothPath passes through the control points', () {
    final s = smoothPath(const [Offset(0, 0), Offset(1, 1), Offset(2, 0)]);
    expect(s.first, const Offset(0, 0));
    expect(s.last, const Offset(2, 0));
    expect(s.length, greaterThan(3));
  });
}
