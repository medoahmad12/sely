import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../games/count_game.dart';
import '../games/game_items.dart';
import '../games/quiz_view.dart';
import '../lesson/lesson_flow.dart';
import '../trace/trace_board.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/speech_bubble.dart';

class NumbersWorldScreen extends StatelessWidget {
  const NumbersWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final nums = context.app.repo.numbers;
    return KidScaffold(
      title: context.tr('world_numbers'),
      child: nums.isEmpty
          ? Center(child: Text(context.tr('no_content'), style: TextStyle(fontSize: 24 * u)))
          : CustomScrollView(slivers: [
              SliverToBoxAdapter(child: SelyGuide(text: context.tr('numbers_new'), mascotSize: 84, hat: context.app.progress.hat)),
              SliverPadding(
                padding: EdgeInsets.all(16 * u),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130 * u,
                    mainAxisSpacing: 14 * u,
                    crossAxisSpacing: 14 * u,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final n = nums[i];
                      final color = AppColors.childColors[i % AppColors.childColors.length];
                      final done = context.app.progress.isDone('num:${n.value}');
                      return PopIn(
                        index: i,
                        child: Pressable(
                          semanticLabel: '${n.value}',
                          onTap: () => Navigator.of(context).push(fadeRoute(NumberLessonScreen(index: i))),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: color, width: 4),
                              boxShadow: AppShadows.soft(color),
                            ),
                            child: Stack(children: [
                              Center(
                                child: Text('${n.value}',
                                    style: TextStyle(fontSize: 60 * u, fontWeight: FontWeight.w900, color: color)),
                              ),
                              if (done) const Positioned(top: 4, right: 6, child: Text('⭐', style: TextStyle(fontSize: 22))),
                            ]),
                          ),
                        ),
                      );
                    },
                    childCount: nums.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16 * u, 0, 16 * u, 24 * u),
                  child: Center(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.orange, minimumSize: Size(220 * u, 68 * u)),
                      onPressed: () => Navigator.of(context).push(fadeRoute(const CountGameScreen())),
                      icon: const Text('🍎', style: TextStyle(fontSize: 30)),
                      label: Text(context.tr('count_title')),
                    ),
                  ),
                ),
              ),
            ]),
    );
  }
}

class NumberLessonScreen extends StatelessWidget {
  const NumberLessonScreen({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final app = context.appRead;
    final nums = app.repo.numbers;
    final n = nums[index];
    final pool = buildGameItems(ContentKind.numbers, app.repo, app.strings);
    final target = pool[index];
    return LessonFlowScreen(
      title: '${n.value}',
      lessonId: 'num:${n.value}',
      activity: context.tr('world_numbers'),
      nextLessonBuilder: index + 1 < nums.length ? () => NumberLessonScreen(index: index + 1) : null,
      steps: [
        LessonStep((c, next) => _CountStep(value: n.value, word: n.ar)),
        LessonStep(
          (c, next) => QuizView(
            pool: pool,
            targets: [target, target],
            optionCount: 2 + c.appRead.adaptive.levelFor('num_find'),
            skill: 'num_find',
            onFinished: (_, __) => next(),
          ),
          showNext: false,
        ),
        LessonStep(
          (c, next) => Column(children: [
            SelyGuide(text: c.tr('num_trace'), mascotSize: 70, hat: c.app.progress.hat),
            Expanded(child: Padding(padding: const EdgeInsets.all(12), child: TraceBoard(shape: n.trace, onComplete: next))),
          ]),
          showNext: false,
        ),
      ],
    );
  }
}

class _CountStep extends StatefulWidget {
  const _CountStep({required this.value, required this.word});
  final int value;
  final String word;

  @override
  State<_CountStep> createState() => _CountStepState();
}

class _CountStepState extends State<_CountStep> {
  final Set<int> _counted = {};
  late final String _emoji;

  @override
  void initState() {
    super.initState();
    final emojis = AppScope.read(context).repo.mathEmojis;
    _emoji = emojis[widget.value % emojis.length];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(AppScope.read(context).audio.speak('ar_num_${widget.value}', widget.word, lang: 'ar'));
    });
  }

  void _tap(int i) {
    if (_counted.contains(i)) return;
    setState(() => _counted.add(i));
    final k = _counted.length;
    final app = AppScope.read(context);
    final ar = app.repo.numbers.where((e) => e.value == k).map((e) => e.ar).firstOrNull ?? '$k';
    unawaited(app.audio.speak('ar_num_$k', ar, lang: 'ar'));
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return SingleChildScrollView(
      padding: EdgeInsets.all(12 * u),
      child: Column(children: [
        SelyGuide(text: context.tr('num_listen'), mascotSize: 70, hat: context.app.progress.hat),
        SizedBox(height: 8 * u),
        Pressable(
          onTap: () => AppScope.read(context).audio.speak('ar_num_${widget.value}', widget.word, lang: 'ar'),
          child: Container(
            width: 200 * u,
            height: 200 * u,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.card * 1.4), boxShadow: AppShadows.soft(AppColors.purple)),
            child: Text('${widget.value}', style: TextStyle(fontSize: 140 * u, fontWeight: FontWeight.w900, color: AppColors.purple)),
          ),
        ),
        Text(widget.word, style: TextStyle(fontSize: 34 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
        SizedBox(height: 8 * u),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8 * u,
          runSpacing: 8 * u,
          children: [
            for (var i = 0; i < widget.value; i++)
              Pressable(
                sound: false,
                onTap: () => _tap(i),
                child: AnimatedScale(
                  scale: _counted.contains(i) ? 1.25 : 1,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Opacity(
                    opacity: _counted.contains(i) ? 1 : 0.8,
                    child: Container(
                      width: 62 * u,
                      height: 62 * u,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _counted.contains(i) ? const Color(0xFFFFF3C4) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(_emoji, style: TextStyle(fontSize: 38 * u)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}
