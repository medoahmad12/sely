import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../models/content_models.dart';
import '../games/game_items.dart';
import '../games/quiz_view.dart';
import '../lesson/lesson_flow.dart';
import '../trace/trace_board.dart';
import '../../widgets/effects.dart';
import '../../widgets/pressable.dart';
import '../../widgets/speech_bubble.dart';

/// Lesson for one Arabic letter: listen -> shapes -> find -> trace.
class LetterLessonScreen extends StatelessWidget {
  const LetterLessonScreen({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final app = context.appRead;
    final letters = app.repo.letters;
    final letter = letters[index];
    final hasNext = index + 1 < letters.length;
    final pool = buildGameItems(ContentKind.arabic, app.repo, app.strings);
    final target = pool[index];
    final steps = <LessonStep>[
      LessonStep((c, next) => _IntroStep(letter: letter)),
      LessonStep((c, next) => _FormsStep(letter: letter)),
      LessonStep(
        (c, next) => QuizView(
          pool: pool,
          targets: [target, target],
          optionCount: 2 + c.appRead.adaptive.levelFor('ar_find'),
          skill: 'ar_find',
          onFinished: (_, __) => next(),
        ),
        showNext: false,
      ),
      LessonStep(
        (c, next) => Column(children: [
          SelyGuide(text: c.tr('lesson_trace'), mascotSize: 70, hat: c.app.progress.hat),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TraceBoard(shape: letter.trace, onComplete: next),
            ),
          ),
        ]),
        showNext: false,
      ),
    ];
    return LessonFlowScreen(
      title: context.tr('letter_label', {'x': letter.name}),
      lessonId: 'ar:${letter.id}',
      activity: context.tr('letter_label', {'x': letter.name}),
      steps: steps,
      nextLessonBuilder: hasNext ? () => LetterLessonScreen(index: index + 1) : null,
    );
  }
}

class _IntroStep extends StatefulWidget {
  const _IntroStep({required this.letter});
  final ArabicLetter letter;

  @override
  State<_IntroStep> createState() => _IntroStepState();
}

class _IntroStepState extends State<_IntroStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sayLetter());
  }

  void _sayLetter() {
    if (!mounted) return;
    unawaited(AppScope.read(context).audio.speak('ar_letter_${widget.letter.id}', widget.letter.name, lang: 'ar'));
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final l = widget.letter;
    return SingleChildScrollView(
      padding: EdgeInsets.all(12 * u),
      child: Column(children: [
        SelyGuide(text: context.tr('lesson_listen'), mascotSize: 70, hat: context.app.progress.hat),
        SizedBox(height: 8 * u),
        Pressable(
          semanticLabel: l.name,
          onTap: _sayLetter,
          child: Pulse(
            child: Container(
              width: 230 * u,
              height: 230 * u,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card * 1.4),
                boxShadow: AppShadows.soft(AppColors.primary),
              ),
              child: Text(l.glyph, style: TextStyle(fontSize: 170 * u, fontWeight: FontWeight.w900, color: AppColors.primaryDark, height: 1.2)),
            ),
          ),
        ),
        SizedBox(height: 8 * u),
        Text(l.name, style: TextStyle(fontSize: 38 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
        SizedBox(height: 10 * u),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12 * u,
          runSpacing: 12 * u,
          children: [
            for (var i = 0; i < l.words.length; i++) _WordTile(letterId: l.id, index: i, word: l.words[i]),
          ],
        ),
      ]),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.letterId, required this.index, required this.word});
  final String letterId;
  final int index;
  final WordItem word;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Pressable(
      semanticLabel: word.word,
      onTap: () => AppScope.read(context).audio.speak('ar_word_${letterId}_$index', word.word, lang: 'ar'),
      child: Container(
        width: 104 * u,
        padding: EdgeInsets.symmetric(vertical: 10 * u),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(word.emoji, style: TextStyle(fontSize: 52 * u)),
          Text(word.word, style: TextStyle(fontSize: 22 * u, fontWeight: FontWeight.w800, color: AppColors.navy)),
        ]),
      ),
    );
  }
}

class _FormsStep extends StatelessWidget {
  const _FormsStep({required this.letter});
  final ArabicLetter letter;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final entries = <(String, String, String, String)>[
      (context.tr('pos_alone'), letter.glyph, letter.words.first.emoji, letter.words.first.word),
      if (letter.forms['initial'] != null)
        (context.tr('pos_start'), letter.forms['initial']!.glyph, letter.forms['initial']!.emoji, letter.forms['initial']!.word),
      if (letter.forms['medial'] != null)
        (context.tr('pos_middle'), letter.forms['medial']!.glyph, letter.forms['medial']!.emoji, letter.forms['medial']!.word),
      if (letter.forms['final'] != null)
        (context.tr('pos_end'), letter.forms['final']!.glyph, letter.forms['final']!.emoji, letter.forms['final']!.word),
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.all(12 * u),
      child: Column(children: [
        SelyGuide(text: context.tr('lesson_forms'), mascotSize: 70, hat: context.app.progress.hat),
        SizedBox(height: 10 * u),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14 * u,
          runSpacing: 14 * u,
          children: [
            for (final e in entries)
              Pressable(
                semanticLabel: e.$4,
                onTap: () => AppScope.read(context).audio.speak('ar_form_${letter.id}_${entries.indexOf(e)}', e.$4, lang: 'ar'),
                child: Container(
                  width: 150 * u,
                  padding: EdgeInsets.all(10 * u),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(e.$1, style: TextStyle(fontSize: 18 * u, fontWeight: FontWeight.w800, color: AppColors.orange)),
                    Text(e.$2, style: TextStyle(fontSize: 76 * u, fontWeight: FontWeight.w900, color: AppColors.primaryDark, height: 1.3)),
                    Text(e.$3, style: TextStyle(fontSize: 38 * u)),
                    Text(e.$4, style: TextStyle(fontSize: 20 * u, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ]),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}
