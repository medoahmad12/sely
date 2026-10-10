import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import 'adventure_map_screen.dart';
import 'adventure_models.dart';
import 'rabbit.dart';

/// Big call-to-action on the home screen: opens the adventure map.
class AdventureCard extends StatelessWidget {
  const AdventureCard({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final app = context.app;
    final levels = AdventureMap.build(app.repo);
    final done = AdventureMap.doneCount(levels, app.progress);
    final started = done > 0;
    return Pressable(
      onTap: () => Navigator.of(context).push(fadeRoute(const AdventureMapScreen())),
      semanticLabel: context.tr(started ? 'adventure_continue' : 'adventure_start'),
      child: Container(
        key: const ValueKey('adventure_card'),
        height: 150 * u,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32 * u),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF3FBF6A), Color(0xFF1FA6A0)],
          ),
          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 14, offset: Offset(0, 8))],
        ),
        child: Row(children: [
          SizedBox(width: 8 * u),
          Padding(
            padding: EdgeInsets.only(top: 14 * u),
            child: Rabbit(size: 126 * u, mood: RabbitMood.happy),
          ),
          SizedBox(width: 6 * u),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                context.tr(started ? 'adventure_continue' : 'adventure_start'),
                maxLines: 2,
                style: TextStyle(fontSize: 26 * u, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15),
              ),
              SizedBox(height: 4 * u),
              Text(
                context.tr('adventure_sub'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16 * u, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.92)),
              ),
              SizedBox(height: 8 * u),
              ClipRRect(
                borderRadius: BorderRadius.circular(10 * u),
                child: LinearProgressIndicator(
                  value: levels.isEmpty ? 0 : done / levels.length,
                  minHeight: 10 * u,
                  backgroundColor: Colors.white.withValues(alpha: 0.35),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow),
                ),
              ),
            ]),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 14 * u),
            width: 60 * u,
            height: 60 * u,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.play_arrow_rounded, size: 42 * u, color: AppColors.green),
          ),
        ]),
      ),
    );
  }
}
