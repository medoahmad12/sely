import 'package:flutter_test/flutter_test.dart';
import 'package:sely_kids/features/adventure/adventure_models.dart';
import 'package:sely_kids/services/arabic_speech.dart';
import 'package:sely_kids/services/progress_controller.dart';
import 'package:sely_kids/storage/storage_service.dart';
import 'test_helpers.dart';

void main() {
  final repo = realRepo();

  ProgressController fresh([MemoryStorage? s]) =>
      ProgressController(storage: s ?? MemoryStorage(), totals: repo.totals);

  test('the map has every letter plus a review game after every 4 letters', () {
    final levels = AdventureMap.build(repo);
    final letters = levels.where((l) => l.kind == LevelKind.arabicLetter).toList();
    final reviews = levels.where((l) => l.kind == LevelKind.review).toList();
    expect(letters.length, repo.letters.length);
    expect(reviews.length, (repo.letters.length / AdventureMap.reviewEvery).ceil());
    expect(levels.map((l) => l.id).toSet().length, levels.length);
    for (var i = 0; i < levels.length; i++) {
      expect(levels[i].number, i + 1);
    }
    // the first review covers letters 0..3 and comes right after the 4th letter
    expect(levels[4].kind, LevelKind.review);
    expect(levels[4].reviewFrom, 0);
    expect(levels[4].reviewTo, 4);
    // the last level is the review of the last group
    expect(levels.last.kind, LevelKind.review);
    expect(levels.last.reviewTo, repo.letters.length);
  });

  test('levels unlock one after the other', () {
    final p = fresh();
    final levels = AdventureMap.build(repo);
    expect(AdventureMap.isUnlocked(levels, 0, p), isTrue);
    expect(AdventureMap.isUnlocked(levels, 1, p), isFalse);
    expect(AdventureMap.currentIndex(levels, p), 0);

    p.setLevelStars(levels[0].id, 2);
    expect(AdventureMap.isUnlocked(levels, 1, p), isTrue);
    expect(AdventureMap.isUnlocked(levels, 2, p), isFalse);
    expect(AdventureMap.currentIndex(levels, p), 1);
    expect(AdventureMap.doneCount(levels, p), 1);

    // a worse replay never lowers the rating; ratings are capped at 3
    p.setLevelStars(levels[0].id, 1);
    expect(p.starsFor(levels[0].id), 2);
    p.setLevelStars(levels[0].id, 9);
    expect(p.starsFor(levels[0].id), 3);
  });

  test('finishing everything leaves the current marker on the last level', () {
    final p = fresh();
    final levels = AdventureMap.build(repo);
    for (final l in levels) {
      p.setLevelStars(l.id, 1);
    }
    expect(AdventureMap.currentIndex(levels, p), levels.length - 1);
    expect(AdventureMap.doneCount(levels, p), levels.length);
  });

  test('level ratings survive a restart and are cleared by a progress reset', () async {
    final storage = MemoryStorage();
    final a = fresh(storage);
    a.setLevelStars('adv:ar:alef', 3);
    a.setLevelStars('adv:ar:ba', 1);
    await a.save();

    final b = fresh(storage);
    await b.load();
    expect(b.starsFor('adv:ar:alef'), 3);
    expect(b.starsFor('adv:ar:ba'), 1);
    expect(b.starsFor('adv:ar:ta'), 0);

    b.resetProgress();
    expect(b.starsFor('adv:ar:alef'), 0);
  });

  test('Arabic speech: known words get full diacritics, others a pausal ending', () {
    expect(ArabicSpeech.vocalize('أين حرف باء؟'), 'أَيْنَ حَرْفْ بَاءْ؟');
    // taa marbuta is read as haa, a final long vowel gets no sukoon
    expect(ArabicSpeech.vocalize('بطة'), 'بطهْ');
    expect(ArabicSpeech.vocalize('نار'), 'نارْ');
    expect(ArabicSpeech.vocalize('كرسي'), 'كرسيْ');
    expect(ArabicSpeech.vocalize('أنا'), 'أَنَا');
    // nothing to do for empty text or text without Arabic
    expect(ArabicSpeech.vocalize(''), '');
    expect(ArabicSpeech.vocalize('Hello 123'), 'Hello 123');
  });

  test('Arabic speech is idempotent: already vowelled text is left alone', () {
    for (final t in ['أين حرف باء؟', 'بطة', 'أنا أرنوب! ساعدني أجد الأشياء التي تبدأ بحرف ألف']) {
      final once = ArabicSpeech.vocalize(t);
      expect(ArabicSpeech.vocalize(once), once);
    }
  });

  test('Arabic speech knows all 28 letter names', () {
    for (final l in repo.letters) {
      expect(ArabicSpeech.isKnown(l.name), isTrue, reason: l.name);
    }
  });
}
