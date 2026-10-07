import 'package:flutter_test/flutter_test.dart';
import 'package:sely_kids/services/content_repository.dart';
import 'package:sely_kids/features/trace/trace_evaluator.dart';
import 'test_helpers.dart';

void main() {
  final repo = realRepo();

  test('demo content meets the minimums', () {
    expect(repo.loadErrors, isEmpty);
    expect(repo.letters.length, greaterThanOrEqualTo(10));
    expect(repo.numbers.length, 11);
    expect(repo.addProblems.length, greaterThanOrEqualTo(5));
    expect(repo.subProblems.length, greaterThanOrEqualTo(5));
    expect(repo.english.length, greaterThanOrEqualTo(10));
    expect(repo.colors.length, greaterThanOrEqualTo(5));
    expect(repo.shapes.length, greaterThanOrEqualTo(5));
  });

  test('every letter has words and a traceable path', () {
    for (final l in repo.letters) {
      expect(l.words, isNotEmpty, reason: l.id);
      expect(l.trace.isEmpty, isFalse, reason: l.id);
      // The reference path itself must pass the evaluator.
      final e = TraceEvaluator(l.trace);
      for (final s in l.trace.strokes) {
        e.endStroke();
        for (final p in s) {
          e.addPoint(p);
        }
      }
      e.endStroke();
      for (final d in l.trace.dots) {
        e.addPoint(d);
        e.endStroke();
      }
      expect(e.isComplete, isTrue, reason: 'letter ${l.id} should be traceable');
    }
  });

  test('every number has a traceable path and valid math answers', () {
    for (final n in repo.numbers) {
      final e = TraceEvaluator(n.trace);
      for (final s in n.trace.strokes) {
        e.endStroke();
        for (final p in s) {
          e.addPoint(p);
        }
      }
      expect(e.isComplete, isTrue, reason: 'number ${n.value}');
    }
    for (final p in [...repo.addProblems, ...repo.subProblems]) {
      expect(p.answer, greaterThanOrEqualTo(0));
    }
  });

  test('invalid entries are skipped, not fatal', () {
    final r = ContentRepository.fromData(
      letters: [
        {'id': 'bad'},
        readData('arabic_letters')[0]
      ],
      numbers: 'not a list',
    );
    expect(r.letters.length, 1);
    expect(r.numbers, isEmpty);
    expect(r.loadErrors, isNotEmpty);
  });

  test('totals map matches content', () {
    expect(repo.totals['ar'], repo.letters.length);
    expect(repo.totals['num'], 11);
  });
}
