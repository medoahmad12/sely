import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/result_view.dart';
import 'game_items.dart';
import 'quiz_view.dart';

/// Full-screen "Find it" game session over any [ContentKind].
/// When [completeCategory] is set (colors/shapes) each correct item is saved as a finished lesson.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.kind, required this.title, this.completeCategory, this.rounds = 5});
  final ContentKind kind;
  final String title;
  final String? completeCategory;
  final int rounds;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<GameItem> _pool;
  late List<GameItem> _targets;
  int _generation = 0;
  int? _earned;

  String get _skill => 'find_${widget.kind.name}';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  void _prepare() {
    final app = AppScope.read(context);
    _pool = buildGameItems(widget.kind, app.repo, app.strings);
    final list = List<GameItem>.of(_pool)..shuffle(app.random);
    final cat = widget.completeCategory;
    if (cat != null) {
      // Items the child has not finished yet come first.
      list.sort((a, b) {
        final da = app.progress.isDone('$cat:${a.id.split('_').last}') ? 1 : 0;
        final db = app.progress.isDone('$cat:${b.id.split('_').last}') ? 1 : 0;
        return da.compareTo(db);
      });
    }
    _targets = list.take(widget.rounds.clamp(1, list.isEmpty ? 1 : list.length).toInt()).toList();
    _earned = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_pool.isEmpty) {
      return KidScaffold(title: widget.title, child: Center(child: Text(context.tr('no_content'))));
    }
    final earned = _earned;
    if (earned != null) {
      return KidScaffold(
        title: widget.title,
        child: ResultView(
          title: context.tr('game_done_title'),
          stars: earned,
          actions: [
            BigActionButton(
              label: context.tr('play_again'),
              icon: Icons.replay_rounded,
              color: AppColors.green,
              onTap: () => setState(() {
                _generation++;
                _prepare();
              }),
            ),
            BigActionButton(label: context.tr('back'), icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
          ],
        ),
      );
    }
    final app = context.appRead;
    return KidScaffold(
      title: widget.title,
      child: QuizView(
        key: ValueKey(_generation),
        pool: _pool,
        targets: _targets,
        optionCount: (2 + app.adaptive.levelFor(_skill)).clamp(2, _pool.length).toInt(),
        skill: _skill,
        onTargetDone: (item, firstTry) {
          final cat = widget.completeCategory;
          if (cat != null) app.progress.completeLesson('$cat:${item.id.split('_').last}', activity: widget.title);
        },
        onFinished: (correct, total) {
          app.progress.addStars(2, activity: widget.title);
          app.progress.recordGame('find', activity: widget.title);
          setState(() => _earned = total + 2);
        },
      ),
    );
  }
}
