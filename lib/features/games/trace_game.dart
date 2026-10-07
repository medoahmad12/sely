import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../services/audio_service.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/speech_bubble.dart';
import '../trace/trace_board.dart';
import 'game_items.dart';

/// Trace game: pick a letter or number, then trace it.
class TracePickerScreen extends StatefulWidget {
  const TracePickerScreen({super.key});

  @override
  State<TracePickerScreen> createState() => _TracePickerScreenState();
}

class _TracePickerScreenState extends State<TracePickerScreen> {
  ContentKind _kind = ContentKind.arabic;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final app = context.appRead;
    final items = buildGameItems(_kind, app.repo, app.strings).where((e) => e.trace != null).toList();
    return KidScaffold(
      title: context.tr('game_trace'),
      child: Column(children: [
        SelyGuide(text: context.tr('trace_pick'), mascotSize: 76, hat: context.app.progress.hat),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8 * u),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final k in const [ContentKind.arabic, ContentKind.numbers])
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * u),
                child: ChoiceChip(
                  label: Text(context.tr(k == ContentKind.arabic ? 'letters' : 'numbers'), style: TextStyle(fontSize: 22 * u, fontWeight: FontWeight.w800)),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                  padding: EdgeInsets.all(10 * u),
                ),
              ),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(16 * u),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120 * u, mainAxisSpacing: 12 * u, crossAxisSpacing: 12 * u),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              final color = AppColors.childColors[i % 5];
              return Pressable(
                semanticLabel: it.semantics,
                onTap: () => Navigator.of(context).push(fadeRoute(TraceGameScreen(item: it))),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: color, width: 4), boxShadow: AppShadows.card),
                  child: Center(child: it.visual(100 * u)),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class TraceGameScreen extends StatelessWidget {
  const TraceGameScreen({super.key, required this.item});
  final GameItem item;

  @override
  Widget build(BuildContext context) {
    final app = context.appRead;
    return KidScaffold(
      title: context.tr('game_trace'),
      child: Column(children: [
        SelyGuide(text: context.tr(item.id.startsWith('num_') ? 'num_trace' : 'lesson_trace'), mascotSize: 70, hat: context.app.progress.hat),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TraceBoard(
              shape: item.trace!,
              onComplete: () async {
                app.progress.addStars(2, activity: context.tr('game_trace'));
                app.progress.recordGame('trace', activity: context.tr('game_trace'));
                app.audio.playSfx(Sfx.win);
                unawaited(app.say('trace_great'));
                await showStarBurst(context, text: context.tr('trace_great'));
                if (context.mounted) Navigator.of(context).maybePop();
              },
            ),
          ),
        ),
      ]),
    );
  }
}
