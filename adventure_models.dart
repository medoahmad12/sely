import '../../services/content_repository.dart';
import '../../services/progress_controller.dart';

enum LevelKind { arabicLetter, review }

/// One stop on the adventure map.
class AdventureLevel {
  const AdventureLevel({
    required this.id,
    required this.number,
    required this.kind,
    this.letterIndex = 0,
    this.reviewFrom = 0,
    this.reviewTo = 0,
  });

  /// Stable id stored in the child's progress, e.g. 'adv:ar:alef' or 'adv:rev:ar:0'.
  final String id;

  /// 1-based position on the map.
  final int number;
  final LevelKind kind;

  /// arabicLetter: index in repo.letters.
  final int letterIndex;

  /// review: reviews letters [reviewFrom, reviewTo) of repo.letters.
  final int reviewFrom;
  final int reviewTo;
}

/// Builds the map from the content, so adding a letter to the JSON adds a level.
/// Rules: levels are played in order; finishing a level (>= 1 star) opens the next one;
/// after every [reviewEvery] letters comes a review game.
class AdventureMap {
  AdventureMap._();

  static const int reviewEvery = 4;

  static List<AdventureLevel> build(ContentRepository repo) {
    final out = <AdventureLevel>[];
    final letters = repo.letters;
    for (var i = 0; i < letters.length; i++) {
      out.add(AdventureLevel(
        id: 'adv:ar:${letters[i].id}',
        number: out.length + 1,
        kind: LevelKind.arabicLetter,
        letterIndex: i,
      ));
      final endsGroup = (i + 1) % reviewEvery == 0 || i == letters.length - 1;
      if (endsGroup) {
        final from = (i ~/ reviewEvery) * reviewEvery;
        out.add(AdventureLevel(
          id: 'adv:rev:ar:$from',
          number: out.length + 1,
          kind: LevelKind.review,
          reviewFrom: from,
          reviewTo: i + 1,
        ));
      }
    }
    return out;
  }

  static bool isDone(AdventureLevel level, ProgressController progress) => progress.starsFor(level.id) > 0;

  static bool isUnlocked(List<AdventureLevel> levels, int index, ProgressController progress) =>
      index == 0 || isDone(levels[index - 1], progress);

  /// The level the child should play now: the first unfinished one (the last one when all are done).
  static int currentIndex(List<AdventureLevel> levels, ProgressController progress) {
    for (var i = 0; i < levels.length; i++) {
      if (!isDone(levels[i], progress)) return i;
    }
    return levels.isEmpty ? 0 : levels.length - 1;
  }

  static int doneCount(List<AdventureLevel> levels, ProgressController progress) =>
      levels.where((l) => isDone(l, progress)).length;
}
