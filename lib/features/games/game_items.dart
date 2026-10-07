import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/content_models.dart';
import '../../services/content_repository.dart';
import '../../widgets/shape_icon.dart';

enum ContentKind { arabic, numbers, colors, shapes, englishLetters, englishWords }

extension ContentKindX on ContentKind {
  String get labelKey => switch (this) {
        ContentKind.arabic => 'kind_arabic',
        ContentKind.numbers => 'kind_numbers',
        ContentKind.colors => 'kind_colors',
        ContentKind.shapes => 'kind_shapes',
        ContentKind.englishLetters => 'kind_en_letters',
        ContentKind.englishWords => 'kind_en_words',
      };
  String get chipText => switch (this) {
        ContentKind.arabic => 'ب',
        ContentKind.numbers => '123',
        ContentKind.colors => '🎨',
        ContentKind.shapes => '⭐',
        ContentKind.englishLetters => 'A',
        ContentKind.englishWords => '🍎',
      };
}

/// One thing a game can ask about. Games are written once and work with any
/// [ContentKind] because they only use this class.
class GameItem {
  const GameItem({
    required this.id,
    required this.visual,
    required this.picture,
    required this.speakText,
    required this.lang,
    required this.prompt,
    required this.promptLang,
    required this.semantics,
    this.trace,
    this.tileColor = Colors.white,
  });

  /// Unique within one kind, e.g. "ba", "3", "red".
  final String id;

  /// The thing the child taps/chooses (letter glyph, digit, swatch, shape...).
  final Widget Function(double size) visual;

  /// Text shown for the "picture" side in Match/Memory (emoji or a word).
  final String picture;

  /// Word spoken when the item is touched.
  final String speakText;
  final String lang;

  /// Question shown and spoken in Find-it games.
  final String prompt;
  final String promptLang;
  final String semantics;
  final TraceShape? trace;
  final Color tileColor;

  String get audioKey => 'item_$id';
  String get promptKey => 'prompt_$id';
}

Widget _text(String t, double size, {Color color = AppColors.navy, double factor = 0.55, FontWeight w = FontWeight.w900}) =>
    Text(t, style: TextStyle(fontSize: size * factor, fontWeight: w, color: color, height: 1.1));

List<GameItem> buildGameItems(ContentKind kind, ContentRepository repo, AppStrings s) {
  switch (kind) {
    case ContentKind.arabic:
      return [
        for (final l in repo.letters)
          GameItem(
            id: 'ar_${l.id}',
            visual: (sz) => _text(l.glyph, sz, factor: 0.7),
            picture: l.words.first.emoji,
            speakText: l.name,
            lang: 'ar',
            prompt: s.get('find_letter', {'x': l.name}),
            promptLang: s.code,
            semantics: l.name,
            trace: l.trace,
          ),
      ];
    case ContentKind.numbers:
      return [
        for (final n in repo.numbers)
          GameItem(
            id: 'num_${n.value}',
            visual: (sz) => _text('${n.value}', sz, factor: 0.7, color: AppColors.purple),
            picture: n.value == 0 ? '🚫' : '⭐' * n.value,
            speakText: n.ar,
            lang: 'ar',
            prompt: s.get('find_number', {'x': '${n.value}'}),
            promptLang: s.code,
            semantics: '${n.value}',
            trace: n.trace,
          ),
      ];
    case ContentKind.colors:
      return [
        for (final c in repo.colors)
          GameItem(
            id: 'col_${c.id}',
            visual: (sz) => Container(
              width: sz * 0.85,
              height: sz * 0.85,
              decoration: BoxDecoration(
                color: c.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26, width: 3),
              ),
            ),
            picture: c.emoji,
            speakText: c.ar,
            lang: 'ar',
            prompt: s.get('find_color', {'x': c.ar}),
            promptLang: s.code,
            semantics: c.ar,
          ),
      ];
    case ContentKind.shapes:
      return [
        for (final sh in repo.shapes)
          GameItem(
            id: 'shp_${sh.id}',
            visual: (sz) => ShapeIcon(shape: sh.id, size: sz * 0.85, color: AppColors.childColors[sh.id.length % 5]),
            picture: sh.emoji,
            speakText: sh.ar,
            lang: 'ar',
            prompt: s.get('find_shape', {'x': sh.ar}),
            promptLang: s.code,
            semantics: sh.ar,
          ),
      ];
    case ContentKind.englishLetters:
      return [
        for (final e in repo.english)
          GameItem(
            id: 'enl_${e.id}',
            visual: (sz) => _text('${e.letter}${e.letter.toLowerCase()}', sz, factor: 0.55, color: AppColors.green),
            picture: e.emoji,
            speakText: e.letter,
            lang: 'en',
            prompt: s.get('find_en_letter', {'x': e.letter}).replaceAll('{x}', e.letter),
            promptLang: 'en',
            semantics: e.letter,
          ),
      ];
    case ContentKind.englishWords:
      return [
        for (final e in repo.english)
          GameItem(
            id: 'enw_${e.id}',
            visual: (sz) => Text(e.emoji, style: TextStyle(fontSize: sz * 0.6)),
            picture: e.word,
            speakText: e.word,
            lang: 'en',
            prompt: s.get('find_en_word', {'x': e.word}),
            promptLang: 'en',
            semantics: e.word,
          ),
      ];
  }
}
