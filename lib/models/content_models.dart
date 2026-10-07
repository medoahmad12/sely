import 'dart:ui';

/// Smooths a polyline with a Catmull-Rom spline (used for curved trace strokes).
List<Offset> smoothPath(List<Offset> pts, {int steps = 8}) {
  if (pts.length < 3) return List.of(pts);
  final out = <Offset>[];
  for (var i = 0; i < pts.length - 1; i++) {
    final p0 = i == 0 ? pts[i] : pts[i - 1];
    final p1 = pts[i];
    final p2 = pts[i + 1];
    final p3 = i + 2 < pts.length ? pts[i + 2] : pts[i + 1];
    for (var s = 0; s < steps; s++) {
      final t = s / steps;
      final t2 = t * t;
      final t3 = t2 * t;
      out.add(Offset(
        _cr(p0.dx, p1.dx, p2.dx, p3.dx, t, t2, t3),
        _cr(p0.dy, p1.dy, p2.dy, p3.dy, t, t2, t3),
      ));
    }
  }
  out.add(pts.last);
  return out;
}

double _cr(double a, double b, double c, double d, double t, double t2, double t3) =>
    0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3);

List<Offset> _points(dynamic raw) => [
      for (final p in (raw as List? ?? const []))
        Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];

/// Strokes and dots (normalized 0..1 coordinates) a child has to trace.
class TraceShape {
  const TraceShape({required this.strokes, required this.dots});
  final List<List<Offset>> strokes;
  final List<Offset> dots;

  bool get isEmpty => strokes.isEmpty && dots.isEmpty;

  factory TraceShape.fromJson(Map<String, dynamic> json) {
    final strokes = <List<Offset>>[];
    for (final raw in (json['strokes'] as List? ?? const [])) {
      final m = raw as Map<String, dynamic>;
      final pts = _points(m['p']);
      if (pts.length < 2) continue;
      strokes.add(m['smooth'] == true ? smoothPath(pts) : pts);
    }
    return TraceShape(strokes: strokes, dots: _points(json['dots']));
  }
}

class WordItem {
  const WordItem({required this.emoji, required this.word});
  final String emoji;
  final String word;
  factory WordItem.fromJson(Map<String, dynamic> j) =>
      WordItem(emoji: j['emoji'] as String, word: j['word'] as String);
}

class LetterForm {
  const LetterForm({required this.glyph, required this.word, required this.emoji});
  final String glyph;
  final String word;
  final String emoji;
  factory LetterForm.fromJson(Map<String, dynamic> j) => LetterForm(
        glyph: j['glyph'] as String,
        word: j['word'] as String,
        emoji: j['emoji'] as String,
      );
}

class ArabicLetter {
  const ArabicLetter({
    required this.id,
    required this.glyph,
    required this.name,
    required this.words,
    required this.forms,
    required this.trace,
  });
  final String id;
  final String glyph;
  final String name;
  final List<WordItem> words;

  /// Keys: initial, medial, final (a letter may not have all of them).
  final Map<String, LetterForm> forms;
  final TraceShape trace;

  factory ArabicLetter.fromJson(Map<String, dynamic> j) {
    final forms = <String, LetterForm>{};
    (j['forms'] as Map<String, dynamic>? ?? const {}).forEach((k, v) {
      forms[k] = LetterForm.fromJson(v as Map<String, dynamic>);
    });
    final words = [
      for (final w in (j['words'] as List)) WordItem.fromJson(w as Map<String, dynamic>),
    ];
    if (words.isEmpty) throw const FormatException('letter without words');
    return ArabicLetter(
      id: j['id'] as String,
      glyph: j['glyph'] as String,
      name: j['name'] as String,
      words: words,
      forms: forms,
      trace: TraceShape.fromJson(j['trace'] as Map<String, dynamic>),
    );
  }
}

class NumberItem {
  const NumberItem({required this.value, required this.ar, required this.en, required this.trace});
  final int value;
  final String ar;
  final String en;
  final TraceShape trace;
  factory NumberItem.fromJson(Map<String, dynamic> j) => NumberItem(
        value: (j['value'] as num).toInt(),
        ar: j['ar'] as String,
        en: j['en'] as String,
        trace: TraceShape.fromJson(j['trace'] as Map<String, dynamic>),
      );
}

class EnglishItem {
  const EnglishItem({required this.id, required this.letter, required this.word, required this.emoji});
  final String id;
  final String letter;
  final String word;
  final String emoji;
  factory EnglishItem.fromJson(Map<String, dynamic> j) => EnglishItem(
        id: j['id'] as String,
        letter: j['letter'] as String,
        word: j['word'] as String,
        emoji: j['emoji'] as String,
      );
}

class ColorItem {
  const ColorItem({required this.id, required this.ar, required this.en, required this.value, required this.emoji});
  final String id;
  final String ar;
  final String en;
  final int value;
  final String emoji;
  Color get color => Color(value);
  factory ColorItem.fromJson(Map<String, dynamic> j) => ColorItem(
        id: j['id'] as String,
        ar: j['ar'] as String,
        en: j['en'] as String,
        value: (j['value'] as num).toInt(),
        emoji: j['emoji'] as String,
      );
}

class ShapeItem {
  const ShapeItem({required this.id, required this.ar, required this.en, required this.emoji});
  final String id;
  final String ar;
  final String en;
  final String emoji;
  factory ShapeItem.fromJson(Map<String, dynamic> j) => ShapeItem(
        id: j['id'] as String,
        ar: j['ar'] as String,
        en: j['en'] as String,
        emoji: j['emoji'] as String,
      );
}

class MathProblem {
  const MathProblem({required this.a, required this.b, required this.level, required this.isAdd});
  final int a;
  final int b;
  final int level;
  final bool isAdd;
  int get answer => isAdd ? a + b : a - b;
  factory MathProblem.fromJson(Map<String, dynamic> j, {required bool isAdd}) {
    final p = MathProblem(
      a: (j['a'] as num).toInt(),
      b: (j['b'] as num).toInt(),
      level: (j['level'] as num?)?.toInt() ?? 1,
      isAdd: isAdd,
    );
    if (p.a < 0 || p.b < 0 || p.answer < 0) throw const FormatException('bad math problem');
    return p;
  }
}
