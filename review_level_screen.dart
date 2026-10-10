import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../models/content_models.dart';
import '../../services/audio_service.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/result_view.dart';
import '../games/game_items.dart';
import '../games/quiz_view.dart';
import 'adventure_models.dart';
import 'adventure_widgets.dart';
import 'forest_scene.dart';

/// Every few letters the map has a review game: find the letters just learned.
class ReviewLevelScreen extends StatefulWidget {
  const ReviewLevelScreen({super.key, required this.level, this.nextBuilder});
  final AdventureLevel level;
  final Widget Function()? nextBuilder;

  @override
  State<ReviewLevelScreen> createState() => _ReviewLevelScreenState();
}

class _ReviewLevelScreenState extends State<ReviewLevelScreen> {
  late final List<GameItem> _pool;
  late final List<GameItem> _targets;
  int? _rating;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _pool = buildGameItems(ContentKind.arabic, app.repo, app.strings);
    final to = widget.level.reviewTo.clamp(0, _pool.length).toInt();
    final from = widget.level.reviewFrom.clamp(0, to).toInt();
    _targets = _pool.sublist(from, to)..shuffle(app.random);
  }

  void _finished(int correct, int total) {
    if (!mounted) return;
    final app = AppScope.read(context);
    final acc = total == 0 ? 1.0 : correct / total;
    final rating = acc >= 0.99 ? 3 : (acc >= 0.5 ? 2 : 1);
    app.progress.setLevelStars(widget.level.id, rating);
    unawaited(app.audio.playSfx(Sfx.win));
    setState(() => _rating = rating);
  }

  @override
  Widget build(BuildContext context) {
    final rating = _rating;
    final next = widget.nextBuilder;
    return Scaffold(
      body: ForestBackground(
        child: SafeArea(
          child: Column(children: [
            AdventureTopBar(title: context.tr('adv_review')),
            Expanded(
              child: rating == null
                  ? QuizView(
                      pool: _pool,
                      targets: _targets,
                      optionCount: 3,
                      skill: 'ar_review',
                      onFinished: _finished,
                    )
                  : LevelCompleteView(
                      title: context.tr('adv_review'),
                      rating: rating,
                      coins: 0,
                      actions: [
                        if (next != null)
                          BigActionButton(
                            label: context.tr('next_level'),
                            icon: Icons.arrow_forward_rounded,
                            color: AppColors.green,
                            onTap: () => Navigator.of(context).pushReplacement(fadeRoute(next())),
                          ),
                        BigActionButton(
                          label: context.tr('adv_map'),
                          icon: Icons.map_rounded,
                          color: AppColors.primary,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
