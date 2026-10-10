import 'package:flutter_test/flutter_test.dart';
import 'package:sely_kids/services/content_repository.dart';
import 'package:sely_kids/features/trace/trace_evaluator.dart';
import 'test_helpers.dart';

void main() {
  final repo = realRepo();

  test('demo content meets the minimums', () {
    expect(repo.loadErrors, isEmpty);
    expect(repo.letters.length, 28);
    expect(repo.numbers.length, 11);
    expect(repo.addProblems.length, greaterThanOrEqualTo(5));
    expect(repo.subProblems.length, greaterThanOrEqualTo(5));
    expect(repo.english.length, 26);
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

  test('the English alphabet is complete: A to Z once each, every word starts with its letter', () {
    final letters = repo.english.map((e) => e.letter).toList();
    expect(letters, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''));
    for (final e in repo.english) {
      expect(e.word.toUpperCase().startsWith(e.letter), isTrue, reason: '${e.letter} / ${e.word}');
    }
  });

  test('Arabic letters are unique and every example word really has the letter in the right place', () {
    expect(repo.letters.map((l) => l.id).toSet().length, repo.letters.length);
    expect(repo.letters.map((l) => l.glyph).toSet().length, repo.letters.length);
    bool is_(String g, String ch) => g == '\u0627' ? '\u0623\u0625\u0622\u0627'.contains(ch) : ch == g;
    for (final l in repo.letters) {
      for (final w in l.words) {
        expect(is_(l.glyph, w.word[0]), isTrue, reason: '${l.id}: ${w.word} should start with ${l.glyph}');
      }
      final initial = l.forms['initial'];
      if (initial != null) expect(is_(l.glyph, initial.word[0]), isTrue, reason: '${l.id} initial ${initial.word}');
      final medial = l.forms['medial'];
      if (medial != null) {
        final mid = medial.word.substring(1, medial.word.length - 1);
        expect(mid.split('').any((c) => is_(l.glyph, c)), isTrue, reason: '${l.id} medial ${medial.word}');
      }
      final fin = l.forms['final'];
      if (fin != null) expect(is_(l.glyph, fin.word[fin.word.length - 1]), isTrue, reason: '${l.id} final ${fin.word}');
    }
  });
}
