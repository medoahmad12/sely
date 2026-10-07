import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import 'count_game.dart';
import 'game_items.dart';
import 'match_game.dart';
import 'memory_game.dart';
import 'quiz_screen.dart';
import 'trace_game.dart';

class GamesHubScreen extends StatefulWidget {
  const GamesHubScreen({super.key});

  @override
  State<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends State<GamesHubScreen> {
  ContentKind _kind = ContentKind.arabic;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final games = <(String, String, Color, Widget Function())>[
      ('🔍', 'game_find', AppColors.orange, () => QuizScreen(kind: _kind, title: context.tr('game_find'))),
      ('🧩', 'game_match', AppColors.green, () => MatchGameScreen(kind: _kind)),
      ('🧠', 'game_memory', AppColors.purple, () => MemoryGameScreen(kind: _kind)),
      ('✏️', 'game_trace', AppColors.pink, () => const TracePickerScreen()),
      ('🍎', 'game_count', AppColors.primary, () => const CountGameScreen()),
    ];
    return KidScaffold(
      title: context.tr('world_games'),
      child: Column(children: [
        SizedBox(
          height: 78 * u,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12 * u, vertical: 8 * u),
            children: [
              for (final k in ContentKind.values)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5 * u),
                  child: Pressable(
                    semanticLabel: context.tr(k.labelKey),
                    onTap: () => setState(() => _kind = k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 66 * u,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _kind == k ? AppColors.orange : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.chip * u),
                        boxShadow: AppShadows.card,
                      ),
                      child: Text(k.chipText,
                          style: TextStyle(fontSize: 30 * u, fontWeight: FontWeight.w900, color: _kind == k ? Colors.white : AppColors.navy)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(16 * u),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220 * u, mainAxisSpacing: 16 * u, crossAxisSpacing: 16 * u, childAspectRatio: 1.0),
            itemCount: games.length,
            itemBuilder: (context, i) {
              final g = games[i];
              final played = context.app.progress.gamesPlayed[switch (i) { 0 => 'find', 1 => 'match', 2 => 'memory', 3 => 'trace', _ => 'count' }] ?? 0;
              return PopIn(
                index: i,
                child: Pressable(
                  semanticLabel: context.tr(g.$2),
                  onTap: () => Navigator.of(context).push(fadeRoute(g.$4())),
                  child: Container(
                    decoration: BoxDecoration(
                      color: g.$3,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      boxShadow: AppShadows.soft(g.$3),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(g.$1, style: TextStyle(fontSize: 64 * u)),
                      Text(context.tr(g.$2), style: TextStyle(fontSize: 26 * u, fontWeight: FontWeight.w900, color: Colors.white)),
                      if (played > 0) Text('×$played', style: TextStyle(fontSize: 18 * u, fontWeight: FontWeight.w800, color: Colors.white70)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
