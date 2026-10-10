import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/effects.dart';
import '../../widgets/hold_to_unlock.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/speech_bubble.dart';
import '../adventure/adventure_card.dart';
import '../arabic/arabic_world.dart';
import '../colors_shapes/colors_shapes_world.dart';
import '../english/english_world.dart';
import '../games/games_hub.dart';
import '../math/math_world.dart';
import '../math/numbers_world.dart';
import '../parent/parent_screen.dart';
import '../rewards/rewards_screen.dart';

/// SELY WORLD: the interactive home with one big tile per learning world.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppScope.read(context);
      if (!app.greeted) {
        app.greeted = true;
        _greet();
      }
    });
  }

  String _greeting(BuildContext context) =>
      context.tr('home_greet', {'name': context.app.progress.profile?.name ?? ''});

  void _greet() {
    final app = AppScope.read(context);
    final name = app.progress.profile?.name ?? '';
    app.audio.speak('home_greet', app.strings.get('home_greet', {'name': name}), lang: app.progress.locale, folder: 'ui');
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final p = context.app.progress;
    final worlds = <_World>[
      _World('📚', 'world_arabic', AppColors.primary, p.percent(['ar']), () => const ArabicWorldScreen()),
      _World('🔢', 'world_numbers', AppColors.purple, p.percent(['num']), () => const NumbersWorldScreen()),
      _World('➕', 'world_math', AppColors.green, p.percent(['add', 'sub']), () => const MathWorldScreen()),
      _World('🇬🇧', 'world_english', AppColors.orange, p.percent(['en']), () => const EnglishWorldScreen()),
      _World('🎨', 'world_colors', AppColors.pink, p.percent(['col', 'shp']), () => const ColorsShapesWorldScreen()),
      _World('🧠', 'world_games', const Color(0xFF00B8A9), null, () => const GamesHubScreen()),
      _World('🏆', 'world_rewards', const Color(0xFFFFB400), null, () => const RewardsScreen()),
    ];
    return KidScaffold(
      title: context.tr('app_name'),
      showBack: false,
      actions: [
        HoldToUnlock(
          semanticLabel: '${context.tr('parent_title')} - ${context.tr('parent_hold')}',
          onUnlocked: () => Navigator.of(context).push(fadeRoute(const ParentScreen())),
        ),
      ],
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: SelyGuide(text: _greeting(context), onTap: _greet, mascotSize: 110, hat: p.hat),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16 * u, 4 * u, 16 * u, 0),
            child: const AdventureCard(),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(16 * u),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220 * u,
              mainAxisSpacing: 16 * u,
              crossAxisSpacing: 16 * u,
              childAspectRatio: 0.95,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => PopIn(index: i, child: _WorldTile(world: worlds[i])),
              childCount: worlds.length,
            ),
          ),
        ),
      ]),
    );
  }
}

class _World {
  const _World(this.emoji, this.labelKey, this.color, this.progress, this.builder);
  final String emoji;
  final String labelKey;
  final Color color;
  final double? progress;
  final Widget Function() builder;
}

class _WorldTile extends StatelessWidget {
  const _WorldTile({required this.world});
  final _World world;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Pressable(
      semanticLabel: context.tr(world.labelKey),
      onTap: () => Navigator.of(context).push(fadeRoute(world.builder())),
      child: Container(
        decoration: BoxDecoration(
          color: world.color,
          borderRadius: BorderRadius.circular(AppRadius.card * 1.2),
          boxShadow: AppShadows.soft(world.color),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [world.color.withValues(alpha: 0.85), world.color],
          ),
        ),
        padding: EdgeInsets.all(12 * u),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(child: FittedBox(child: Text(world.emoji, style: const TextStyle(fontSize: 70)))),
          Text(context.tr(world.labelKey),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 22 * u, fontWeight: FontWeight.w900, color: Colors.white)),
          if (world.progress != null) ...[
            SizedBox(height: 8 * u),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: world.progress,
                minHeight: 10 * u,
                color: Colors.white,
                backgroundColor: Colors.white30,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
