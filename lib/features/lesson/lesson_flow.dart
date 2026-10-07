import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/audio_service.dart';
import '../../services/progress_controller.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/result_view.dart';

class LessonStep {
  const LessonStep(this.builder, {this.showNext = true});

  /// Builds the step. Call [next] to advance (steps with their own goal call it when done).
  final Widget Function(BuildContext context, VoidCallback next) builder;
  final bool showNext;
}

/// Generic multi-step lesson: steps -> celebration. Letters, numbers and English
/// lessons only differ in the steps they pass in.
class LessonFlowScreen extends StatefulWidget {
  const LessonFlowScreen({
    super.key,
    required this.title,
    required this.steps,
    required this.lessonId,
    required this.activity,
    this.nextLessonBuilder,
  });
  final String title;
  final List<LessonStep> steps;
  final String lessonId;
  final String activity;
  final Widget Function()? nextLessonBuilder;

  @override
  State<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends State<LessonFlowScreen> {
  int _index = 0;
  LessonResult? _result;

  void _next() {
    if (!mounted) return;
    if (_index + 1 < widget.steps.length) {
      setState(() => _index++);
      return;
    }
    final app = AppScope.read(context);
    final r = app.progress.completeLesson(widget.lessonId, activity: widget.activity);
    app.audio.playSfx(Sfx.win);
    unawaited(app.say('lesson_done'));
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final result = _result;
    if (result != null) {
      return KidScaffold(
        title: widget.title,
        child: ResultView(
          title: context.tr('lesson_done'),
          stars: result.starsAwarded,
          bonusText: result.categoryBonus ? context.tr('bonus_msg') : null,
          actions: [
            if (widget.nextLessonBuilder != null)
              BigActionButton(
                label: context.tr('next_lesson'),
                icon: Icons.arrow_forward_rounded,
                color: AppColors.green,
                onTap: () => Navigator.of(context).pushReplacement(fadeRoute(widget.nextLessonBuilder!())),
              ),
            BigActionButton(
              label: context.tr('back'),
              icon: Icons.grid_view_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      );
    }
    final step = widget.steps[_index];
    return KidScaffold(
      title: widget.title,
      child: Column(children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 6 * u),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < widget.steps.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: (i == _index ? 34 : 14) * u,
                height: 14 * u,
                margin: EdgeInsets.symmetric(horizontal: 4 * u),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: i < _index ? AppColors.green : (i == _index ? AppColors.orange : Colors.white70),
                ),
              ),
          ]),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(key: ValueKey(_index), child: step.builder(context, _next)),
          ),
        ),
        if (step.showNext)
          Padding(
            padding: EdgeInsets.only(bottom: 14 * u, top: 6 * u),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                minimumSize: Size(150 * u, 68 * u),
              ),
              onPressed: _next,
              child: Icon(Icons.arrow_forward_rounded, size: 42 * u),
            ),
          ),
      ]),
    );
  }
}
