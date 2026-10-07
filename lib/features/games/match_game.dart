import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/audio_service.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/option_tile.dart';
import '../../widgets/result_view.dart';
import '../../widgets/speech_bubble.dart';
import 'game_items.dart';

/// Two columns: tap an item, then tap its picture (or the other way round).
class MatchGameScreen extends StatefulWidget {
  const MatchGameScreen({super.key, required this.kind});
  final ContentKind kind;

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends State<MatchGameScreen> {
  late List<GameItem> _chosen;
  late List<GameItem> _left;
  late List<GameItem> _right;
  final Set<String> _matched = {};
  String? _selId;
  bool _selLeft = true;
  int _shake = 0;
  String? _wrongId;
  int _earned = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  void _prepare() {
    final app = AppScope.read(context);
    final pool = buildGameItems(widget.kind, app.repo, app.strings)..shuffle(app.random);
    final pairs = (1 + app.adaptive.levelFor('match')).clamp(2, 4).toInt();
    _chosen = pool.take(pairs).toList();
    _left = List.of(_chosen)..shuffle(app.random);
    _right = List.of(_chosen)..shuffle(app.random);
    _matched.clear();
    _selId = null;
    _earned = 0;
    _done = false;
    _wrongId = null;
  }

  Future<void> _tap(GameItem it, bool left) async {
    final app = AppScope.read(context);
    if (_selId == null || _selLeft == left) {
      setState(() {
        _selId = it.id;
        _selLeft = left;
        _wrongId = null;
      });
      unawaited(app.audio.speak(it.audioKey, it.speakText, lang: it.lang));
      return;
    }
    if (_selId == it.id) {
      _matched.add(it.id);
      _selId = null;
      app.progress.recordAnswer('match', true);
      app.progress.addStars(1);
      _earned++;
      app.audio.playSfx(Sfx.correct);
      unawaited(app.audio.speak(it.audioKey, it.speakText, lang: it.lang));
      if (_matched.length == _chosen.length) {
        await showStarBurst(context, text: app.strings.get(app.cheerKey()));
        if (!mounted) return;
        app.progress.addStars(2, activity: app.strings.get('game_match'));
        app.progress.recordGame('match', activity: app.strings.get('game_match'));
        app.audio.playSfx(Sfx.win);
        setState(() {
          _earned += 2;
          _done = true;
        });
      } else {
        setState(() {});
      }
    } else {
      app.progress.recordAnswer('match', false);
      app.audio.playSfx(Sfx.wrong);
      unawaited(app.say('try_again'));
      setState(() {
        _wrongId = it.id;
        _shake++;
        _selId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final title = context.tr('game_match');
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
        SelyGuide(text: context.tr('match_prompt'), mascotSize: 76, hat: context.app.progress.hat),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final n = _chosen.length;
            final byW = (c.maxWidth - 60) / 2;
            final byH = (c.maxHeight - 16 * n) / n;
            final size = (byW < byH ? byW : byH).clamp(70.0, 170.0).toDouble();
            Widget column(List<GameItem> items, bool left) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final it in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: OptionTile(
                          size: size,
                          semanticLabel: it.semantics,
                          shakeTrigger: _wrongId == it.id ? _shake : 0,
                          state: _matched.contains(it.id)
                              ? TileState.done
                              : (_selId == it.id && _selLeft == left ? TileState.selected : TileState.normal),
                          onTap: () => _tap(it, left),
                          child: left
                              ? SizedBox(width: size * .8, height: size * .8, child: Center(child: it.visual(size)))
                              : Text(it.picture, style: TextStyle(fontSize: size * .5, color: AppColors.navy, fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                );
            return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [column(_left, true), column(_right, false)]);
          }),
        ),
        SizedBox(height: 8 * u),
      ]),
    );
  }
}
