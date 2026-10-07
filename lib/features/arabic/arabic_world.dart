import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../models/content_models.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/speech_bubble.dart';
import 'letter_lesson.dart';

class ArabicWorldScreen extends StatelessWidget {
  const ArabicWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final app = context.app;
    final letters = app.repo.letters;
    return KidScaffold(
      title: context.tr('world_arabic'),
      child: letters.isEmpty
          ? Center(child: Text(context.tr('no_content'), style: TextStyle(fontSize: 24 * u)))
          : CustomScrollView(slivers: [
              SliverToBoxAdapter(child: SelyGuide(text: context.tr('arabic_new'), mascotSize: 84, hat: app.progress.hat)),
              SliverPadding(
                padding: EdgeInsets.all(16 * u),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150 * u,
                    mainAxisSpacing: 14 * u,
                    crossAxisSpacing: 14 * u,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => PopIn(index: i, child: _LetterCard(letter: letters[i], index: i)),
                    childCount: letters.length,
                  ),
                ),
              ),
            ]),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({required this.letter, required this.index});
  final ArabicLetter letter;
  final int index;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final done = context.app.progress.isDone('ar:${letter.id}');
    final color = AppColors.childColors[index % AppColors.childColors.length];
    return Pressable(
      semanticLabel: letter.name,
      onTap: () => Navigator.of(context).push(fadeRoute(LetterLessonScreen(index: index))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.soft(color),
          border: Border.all(color: color, width: 4),
        ),
        child: Stack(children: [
          Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(letter.glyph, style: TextStyle(fontSize: 72 * u, fontWeight: FontWeight.w900, color: color)),
              ),
            ),
          ),
          if (done) const Positioned(top: 6, right: 8, child: Text('⭐', style: TextStyle(fontSize: 26))),
        ]),
      ),
    );
  }
}
