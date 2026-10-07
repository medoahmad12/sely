import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../models/content_models.dart';
import '../games/game_items.dart';
import '../games/quiz_view.dart';
import '../lesson/lesson_flow.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/speech_bubble.dart';

class EnglishWorldScreen extends StatelessWidget {
  const EnglishWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final items = context.app.repo.english;
    return KidScaffold(
      title: context.tr('world_english'),
      child: items.isEmpty
          ? Center(child: Text(context.tr('no_content'), style: TextStyle(fontSize: 24 * u)))
          : CustomScrollView(slivers: [
              SliverToBoxAdapter(child: SelyGuide(text: context.tr('english_new'), mascotSize: 84, hat: context.app.progress.hat)),
              SliverPadding(
                padding: EdgeInsets.all(16 * u),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160 * u,
                    mainAxisSpacing: 14 * u,
                    crossAxisSpacing: 14 * u,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final e = items[i];
                      final color = AppColors.childColors[i % AppColors.childColors.length];
                      final done = context.app.progress.isDone('en:${e.id}');
                      return PopIn(
                        index: i,
                        child: Pressable(
                          semanticLabel: e.word,
                          onTap: () => Navigator.of(context).push(fadeRoute(EnglishLessonScreen(index: i))),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: color, width: 4),
                              boxShadow: AppShadows.soft(color),
                            ),
                            child: Stack(children: [
                              Center(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text(e.emoji, style: TextStyle(fontSize: 46 * u)),
                                  Text(e.letter, style: TextStyle(fontSize: 40 * u, fontWeight: FontWeight.w900, color: color)),
                                ]),
                              ),
                              if (done) const Positioned(top: 4, right: 6, child: Text('⭐', style: TextStyle(fontSize: 22))),
                            ]),
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
            ]),
    );
  }
}

class EnglishLessonScreen extends StatelessWidget {
  const EnglishLessonScreen({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final app = context.appRead;
    final items = app.repo.english;
    final e = items[index];
    final pool = buildGameItems(ContentKind.englishWords, app.repo, app.strings);
    final letterPool = buildGameItems(ContentKind.englishLetters, app.repo, app.strings);
    return LessonFlowScreen(
      title: '${e.letter} - ${e.word}',
      lessonId: 'en:${e.id}',
      activity: '${e.letter} - ${e.word}',
      nextLessonBuilder: index + 1 < items.length ? () => EnglishLessonScreen(index: index + 1) : null,
      steps: [
        LessonStep((c, next) => _EnglishIntro(item: e)),
        LessonStep(
          (c, next) => QuizView(
            pool: letterPool,
            targets: [letterPool[index]],
            optionCount: 2 + c.appRead.adaptive.levelFor('en_letter'),
            skill: 'en_letter',
            onFinished: (_, __) => next(),
          ),
          showNext: false,
        ),
        LessonStep(
          (c, next) => QuizView(
            pool: pool,
            targets: [pool[index]],
            optionCount: 2 + c.appRead.adaptive.levelFor('en_word'),
            skill: 'en_word',
            onFinished: (_, __) => next(),
          ),
          showNext: false,
        ),
      ],
    );
  }
}

class _EnglishIntro extends StatefulWidget {
  const _EnglishIntro({required this.item});
  final EnglishItem item;

  @override
  State<_EnglishIntro> createState() => _EnglishIntroState();
}

class _EnglishIntroState extends State<_EnglishIntro> {
  int _bounce = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  Future<void> _say() async {
    if (!mounted) return;
    final audio = AppScope.read(context).audio;
    await audio.speak('en_letter_${widget.item.letter}', widget.item.letter, lang: 'en');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await audio.speak('en_word_${widget.item.id}', widget.item.word, lang: 'en');
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final e = widget.item;
    return SingleChildScrollView(
      padding: EdgeInsets.all(12 * u),
      child: Column(children: [
        SelyGuide(text: context.tr('tap_to_hear'), mascotSize: 70, hat: context.app.progress.hat),
        SizedBox(height: 8 * u),
        Pressable(
          semanticLabel: e.word,
          onTap: () {
            setState(() => _bounce++);
            _say();
          },
          child: Container(
            width: 260 * u,
            padding: EdgeInsets.all(16 * u),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card * 1.4),
              boxShadow: AppShadows.soft(AppColors.green),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text('${e.letter}${e.letter.toLowerCase()}',
                    style: TextStyle(fontSize: 100 * u, fontWeight: FontWeight.w900, color: AppColors.green, height: 1.1)),
              ),
              TweenAnimationBuilder<double>(
                key: ValueKey(_bounce),
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: Text(e.emoji, style: TextStyle(fontSize: 100 * u)),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(e.word, style: TextStyle(fontSize: 46 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
