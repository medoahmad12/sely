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
import '../../widgets/result_view.dart';
import '../../widgets/speech_bubble.dart';
import 'game_items.dart';

class _Card {
  _Card(this.item, this.isPicture);
  final GameItem item;
  final bool isPicture;
}

/// Flip two cards at a time and find matching pairs (item card + picture card).
class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key, required this.kind});
  final ContentKind kind;

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late List<_Card> _cards;
  final Set<int> _faceUp = {};
  final Set<int> _matched = {};
  bool _busy = false;
  bool _done = false;
  int _earned = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  void _prepare() {
    final app = AppScope.read(context);
    final pool = buildGameItems(widget.kind, app.repo, app.strings)..shuffle(app.random);
    final pairs = (1 + app.adaptive.levelFor('memory')).clamp(2, 4).toInt();
    _cards = [
      for (final it in pool.take(pairs)) ...[_Card(it, false), _Card(it, true)],
    ]..shuffle(app.random);
    _faceUp.clear();
    _matched.clear();
    _busy = false;
    _done = false;
    _earned = 0;
  }

  Future<void> _flip(int i) async {
    if (_busy || _faceUp.contains(i) || _matched.contains(i)) return;
    final app = AppScope.read(context);
    setState(() => _faceUp.add(i));
    final c = _cards[i];
    unawaited(app.audio.speak(c.item.audioKey, c.item.speakText, lang: c.item.lang));
    if (_faceUp.length < 2) return;
    _busy = true;
    final a = _faceUp.first;
    final b = _faceUp.last;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_cards[a].item.id == _cards[b].item.id) {
      app.progress.recordAnswer('memory', true);
      app.progress.addStars(1);
      _earned++;
      app.audio.playSfx(Sfx.correct);
      setState(() {
        _matched.addAll([a, b]);
        _faceUp.clear();
        _busy = false;
      });
      if (_matched.length == _cards.length) {
        await showStarBurst(context, text: app.strings.get(app.cheerKey()));
        if (!mounted) return;
        app.progress.addStars(2, activity: app.strings.get('game_memory'));
        app.progress.recordGame('memory', activity: app.strings.get('game_memory'));
        app.audio.playSfx(Sfx.win);
        setState(() {
          _earned += 2;
          _done = true;
        });
      }
    } else {
      app.progress.recordAnswer('memory', false);
      setState(() {
        _faceUp.clear();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final title = context.tr('game_memory');
    if (_done) {
      return KidScaffold(
        title: title,
        child: ResultView(
          title: context.tr('game_done_title'),
          stars: _earned,
          actions: [
            BigActionButton(label: context.tr('play_again'), icon: Icons.replay_rounded, color: AppColors.green, onTap: () => setState(_prepare)),
            BigActionButton(label: context.tr('back'), icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
          ],
        ),
      );
    }
    return KidScaffold(
      title: title,
      child: Column(children: [
        SelyGuide(text: context.tr('memory_prompt'), mascotSize: 76, hat: context.app.progress.hat),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final n = _cards.length;
            final cols = n <= 4 ? 2 : (n <= 6 ? 3 : 4);
            final rows = (n / cols).ceil();
            final byW = (c.maxWidth - 24 - 12 * (cols - 1)) / cols;
            final byH = (c.maxHeight - 12 * rows) / rows;
            final size = (byW < byH ? byW : byH).clamp(70.0, 190.0).toDouble();
            return Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < n; i++) _buildCard(i, size, u),
                ],
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _buildCard(int i, double size, double u) {
    final card = _cards[i];
    final up = _faceUp.contains(i) || _matched.contains(i);
    return Pressable(
      sound: false,
      onTap: () => _flip(i),
      semanticLabel: up ? card.item.semantics : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Container(
          key: ValueKey('$i-$up'),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: up ? Colors.white : AppColors.purple,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: _matched.contains(i) ? AppColors.green : Colors.transparent, width: 5),
            boxShadow: AppShadows.card,
          ),
          child: up
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.all(size * .1),
                    child: card.isPicture
                        ? Text(card.item.picture, style: TextStyle(fontSize: size * .5, fontWeight: FontWeight.w800, color: AppColors.navy))
                        : SizedBox(width: size * .8, height: size * .8, child: Center(child: card.item.visual(size))),
                  ),
                )
              : Text('?', style: TextStyle(fontSize: size * .5, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ),
    );
  }
}
