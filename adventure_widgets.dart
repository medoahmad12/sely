import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import 'rabbit.dart';

/// Back button + title + progress dots + star counter, floating over the forest.
class AdventureTopBar extends StatelessWidget {
  const AdventureTopBar({super.key, required this.title, this.step, this.steps = 0});
  final String title;
  final int? step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Padding(
      padding: EdgeInsets.fromLTRB(12 * u, 8 * u, 12 * u, 4 * u),
      child: Row(children: [
        RoundIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
        SizedBox(width: 10 * u),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * u, vertical: 6 * u),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22 * u),
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20 * u, fontWeight: FontWeight.w900, color: AppColors.navy),
              ),
            ),
            if (steps > 0) ...[
              SizedBox(height: 6 * u),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < steps; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.symmetric(horizontal: 3 * u),
                    width: (i == step ? 26 : 12) * u,
                    height: 12 * u,
                    decoration: BoxDecoration(
                      color: i <= (step ?? 0) ? AppColors.orange : Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8 * u),
                    ),
                  ),
              ]),
            ],
          ]),
        ),
        SizedBox(width: 10 * u),
        const StarCounter(),
      ]),
    );
  }
}

/// Three stars; the earned ones pop in one after the other.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.stars, this.size = 62});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 3; i++)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4 * u),
          child: i < stars
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500 + 350 * i),
                  curve: Curves.elasticOut,
                  builder: (context, v, _) => Transform.scale(
                    scale: v,
                    child: Icon(Icons.star_rounded, size: size * u, color: AppColors.yellow, shadows: const [
                      Shadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3)),
                    ]),
                  ),
                )
              : Icon(Icons.star_rounded, size: size * u, color: Colors.white.withValues(alpha: 0.6)),
        ),
    ]);
  }
}

/// Arnoub with a speech bubble. Tap the bubble to hear the sentence again.
class RabbitSpeechBar extends StatelessWidget {
  const RabbitSpeechBar({
    super.key,
    required this.text,
    required this.onTap,
    this.mood = RabbitMood.idle,
    this.hopTrigger = 0,
    this.size = 118,
  });
  final String text;
  final VoidCallback onTap;
  final RabbitMood mood;
  final int hopTrigger;
  final double size;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * u),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Rabbit(size: size * u, mood: mood, hopTrigger: hopTrigger),
        SizedBox(width: 6 * u),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: 14 * u),
            child: Pressable(
              onTap: onTap,
              semanticLabel: text,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16 * u, vertical: 12 * u),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24 * u),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(fontSize: 20 * u, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.35),
                    ),
                  ),
                  SizedBox(width: 8 * u),
                  Icon(Icons.volume_up_rounded, size: 30 * u, color: AppColors.primary),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// End-of-level screen: Arnoub cheers, the stars pop in, then the action buttons.
class LevelCompleteView extends StatelessWidget {
  const LevelCompleteView({
    super.key,
    required this.title,
    required this.rating,
    required this.coins,
    required this.actions,
  });
  final String title;
  final int rating;
  final int coins;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16 * u),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Rabbit(size: 190 * u, mood: RabbitMood.cheer, hopTrigger: 1),
          SizedBox(height: 8 * u),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 22 * u, vertical: 12 * u),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(26 * u),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26 * u, fontWeight: FontWeight.w900, color: AppColors.navy),
            ),
          ),
          SizedBox(height: 14 * u),
          StarRating(stars: rating),
          if (coins > 0) ...[
            SizedBox(height: 10 * u),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * u, vertical: 6 * u),
              decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(20 * u)),
              child: Text(
                '+$coins ⭐',
                style: TextStyle(fontSize: 24 * u, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
          SizedBox(height: 18 * u),
          Wrap(alignment: WrapAlignment.center, spacing: 12 * u, runSpacing: 12 * u, children: actions),
        ]),
      ),
    );
  }
}
