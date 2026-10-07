import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/content_models.dart';

/// Loads all educational content from assets/data/*.json.
/// Invalid entries are skipped; unreadable files are recorded in [loadErrors].
class ContentRepository {
  ContentRepository({
    this.letters = const [],
    this.numbers = const [],
    this.english = const [],
    this.colors = const [],
    this.shapes = const [],
    this.addProblems = const [],
    this.subProblems = const [],
    this.mathEmojis = const ['🍎'],
    this.loadErrors = const [],
  });

  final List<ArabicLetter> letters;
  final List<NumberItem> numbers;
  final List<EnglishItem> english;
  final List<ColorItem> colors;
  final List<ShapeItem> shapes;
  final List<MathProblem> addProblems;
  final List<MathProblem> subProblems;
  final List<String> mathEmojis;
  final List<String> loadErrors;

  /// Lesson totals per category prefix (used for progress percentages).
  Map<String, int> get totals => {
        'ar': letters.length,
        'num': numbers.length,
        'add': addProblems.length,
        'sub': subProblems.length,
        'en': english.length,
        'col': colors.length,
        'shp': shapes.length,
      };

  static Future<ContentRepository> load({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    final errors = <String>[];
    Future<dynamic> read(String name) async {
      try {
        return jsonDecode(await b.loadString('assets/data/$name.json'));
      } catch (_) {
        errors.add(name);
        return null;
      }
    }

    return ContentRepository.fromData(
      letters: await read('arabic_letters'),
      numbers: await read('numbers'),
      english: await read('english'),
      colors: await read('colors'),
      shapes: await read('shapes'),
      math: await read('math'),
      errors: errors,
    );
  }

  /// Builds a repository from already-decoded JSON (also used by tests).
  factory ContentRepository.fromData({
    dynamic letters,
    dynamic numbers,
    dynamic english,
    dynamic colors,
    dynamic shapes,
    dynamic math,
    List<String> errors = const [],
  }) {
    final errs = List<String>.of(errors);
    List<T> parse<T>(dynamic raw, String name, T Function(Map<String, dynamic>) f) {
      final out = <T>[];
      if (raw is! List) return out;
      for (final e in raw) {
        try {
          out.add(f(e as Map<String, dynamic>));
        } catch (_) {
          if (!errs.contains('$name (item)')) errs.add('$name (item)');
        }
      }
      return out;
    }

    final m = math is Map<String, dynamic> ? math : const <String, dynamic>{};
    final emojis = [
      for (final e in (m['emojis'] as List? ?? const [])) if (e is String) e,
    ];
    return ContentRepository(
      letters: parse(letters, 'arabic_letters', ArabicLetter.fromJson),
      numbers: parse(numbers, 'numbers', NumberItem.fromJson),
      english: parse(english, 'english', EnglishItem.fromJson),
      colors: parse(colors, 'colors', ColorItem.fromJson),
      shapes: parse(shapes, 'shapes', ShapeItem.fromJson),
      addProblems: parse(m['add'], 'math.add', (j) => MathProblem.fromJson(j, isAdd: true)),
      subProblems: parse(m['sub'], 'math.sub', (j) => MathProblem.fromJson(j, isAdd: false)),
      mathEmojis: emojis.isEmpty ? const ['🍎'] : emojis,
      loadErrors: errs,
    );
  }
}
