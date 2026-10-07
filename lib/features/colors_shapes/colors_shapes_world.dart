import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../games/game_items.dart';
import '../games/quiz_screen.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';

class ColorsShapesWorldScreen extends StatelessWidget {
  const ColorsShapesWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final cards = <(String, String, VoidCallback, Color)>[
      ('🎨', 'colors_learn', () => Navigator.of(context).push(fadeRoute(const LearnScreen(kind: ContentKind.colors))), AppColors.pink),
      ('🎯', 'colors_play', () => Navigator.of(context).push(fadeRoute(QuizScreen(kind: ContentKind.colors, title: context.tr('colors_play'), completeCategory: 'col'))), AppColors.orange),
      ('🔷', 'shapes_learn', () => Navigator.of(context).push(fadeRoute(const LearnScreen(kind: ContentKind.shapes))), AppColors.purple),
      ('⭐', 'shapes_play', () => Navigator.of(context).push(fadeRoute(QuizScreen(kind: ContentKind.shapes, title: context.tr('shapes_play'), completeCategory: 'shp'))), AppColors.green),
    ];
    return KidScaffold(
      title: context.tr('world_colors'),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16 * u),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16 * u,
            runSpacing: 16 * u,
            children: [
              for (var i = 0; i < cards.length; i++)
                PopIn(
                  index: i,
                  child: Pressable(
                    onTap: cards[i].$3,
                    semanticLabel: context.tr(cards[i].$2),
                    child: Container(
                      width: 160 * u,
                      height: 170 * u,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: cards[i].$4, width: 5),
                        boxShadow: AppShadows.soft(cards[i].$4),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(cards[i].$1, style: TextStyle(fontSize: 60 * u)),
                        SizedBox(height: 6 * u),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6 * u),
                          child: Text(context.tr(cards[i].$2),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
                        ),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid of colors or shapes; touching one says its name.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key, required this.kind});
  final ContentKind kind;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final app = context.appRead;
    final items = buildGameItems(kind, app.repo, app.strings);
    final isColors = kind == ContentKind.colors;
    return KidScaffold(
      title: context.tr(isColors ? 'colors_learn' : 'shapes_learn'),
      child: items.isEmpty
          ? Center(child: Text(context.tr('no_content')))
          : GridView.builder(
              padding: EdgeInsets.all(16 * u),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170 * u,
                mainAxisSpacing: 14 * u,
                crossAxisSpacing: 14 * u,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final it = items[i];
                return PopIn(
                  index: i,
                  child: Pressable(
                    semanticLabel: it.semantics,
                    onTap: () => unawaited(AppScope.read(context).audio.speak(it.audioKey, it.speakText, lang: it.lang)),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
                      child: LayoutBuilder(
                        builder: (context, c) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          it.visual(c.maxWidth * 0.62),
                          SizedBox(height: 4 * u),
                          Text(it.speakText, style: TextStyle(fontSize: 22 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
