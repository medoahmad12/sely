import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/audio_service.dart';
import '../../widgets/effects.dart';
import '../../widgets/option_tile.dart';
import '../../widgets/speech_bubble.dart';
import 'game_items.dart';

/// "Find it" engine: asks for each target in [targets], offering [optionCount]
/// choices from [pool]. Reused by lessons, color/shape quizzes and the Find game.
class QuizView extends StatefulWidget {
  const QuizView({
    super.key,
    required this.pool,
    required this.targets,
    required this.optionCount,
    required this.skill,
    required this.onFinished,
    this.onTargetDone,
  });
  final List<GameItem> pool;
  final List<GameItem> targets;
  final int optionCount;
  final String skill;

  /// (correctOnFirstTry, totalRounds)
  final void Function(int correct, int total) onFinished;
  final void Function(GameItem item, bool firstTry)? onTargetDone;

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _round = 0;
  int _correct = 0;
  bool _hadWrong = false;
  bool _locked = false;
  int _shake = 0;
  final Set<String> _wrong = {};
  late List<GameItem> _options;
  String? _message;

  GameItem get _target => widget.targets[_round];

  @override
  void initState() {
    super.initState();
    _options = _buildOptions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  List<GameItem> _buildOptions() {
    final app = AppScope.read(context);
    final others = widget.pool.where((e) => e.id != _target.id).toList()..shuffle(app.random);
    final n = (widget.optionCount - 1).clamp(1, others.isEmpty ? 1 : others.length).toInt();
    final opts = [_target, ...others.take(n)]..shuffle(app.random);
    return opts;
  }

  void _speakPrompt() {
    if (!mounted) return;
    final t = _target;
    AppScope.read(context).audio.speak(t.promptKey, t.prompt, lang: t.promptLang);
  }

  Future<void> _tap(GameItem it) async {
    if (_locked) return;
    final app = AppScope.read(context);
    if (it.id == _target.id) {
      _locked = true;
      final first = !_hadWrong;
      app.progress.recordAnswer(widget.skill, first);
      if (first) _correct++;
      app.progress.addStars(1);
      app.audio.playSfx(Sfx.correct);
      unawaited(app.audio.speak(it.audioKey, it.speakText, lang: it.lang));
      widget.onTargetDone?.call(it, first);
      await showStarBurst(context, text: app.strings.get(app.cheerKey()));
      if (!mounted) return;
      if (_round + 1 >= widget.targets.length) {
        widget.onFinished(_correct, widget.targets.length);
      } else {
        setState(() {
          _round++;
          _hadWrong = false;
          _locked = false;
          _wrong.clear();
          _message = null;
          _options = _buildOptions();
        });
        _speakPrompt();
      }
    } else {
      _hadWrong = true;
      app.audio.playSfx(Sfx.wrong);
      unawaited(app.say('try_again'));
      setState(() {
        _wrong.add(it.id);
        _shake++;
        _message = app.strings.get('try_again');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final t = _target;
    final hint = _wrong.length >= 2;
    return Column(children: [
      SizedBox(height: 4 * u),
      SelyGuide(
        text: _message ?? t.prompt,
        onTap: _speakPrompt,
        hat: context.app.progress.hat,
      ),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final n = _options.length;
          final cols = n <= 4 ? 2 : 3;
          final rows = (n / cols).ceil();
          const gap = 16.0;
          final size = ((c.maxWidth - 24 - gap * (cols - 1)) / cols)
              .clamp(80.0, 220.0)
              .toDouble();
          final byHeight = (c.maxHeight - gap * rows) / rows;
          final tile = size < byHeight ? size : byHeight.clamp(80.0, 220.0).toDouble();
          return Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final o in _options)
                  OptionTile(
                    key: ValueKey('opt_${o.id}'),
                    size: tile,
                    color: o.tileColor,
                    semanticLabel: o.semantics,
                    shakeTrigger: _wrong.contains(o.id) ? _shake : 0,
                    state: _wrong.contains(o.id)
                        ? TileState.wrong
                        : (hint && o.id == t.id ? TileState.hint : TileState.normal),
                    onTap: () => _tap(o),
                    child: SizedBox(width: tile * 0.84, height: tile * 0.84, child: Center(child: o.visual(tile))),
                  ),
              ],
            ),
          );
        }),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: 12 * u),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < widget.targets.length; i++)
            Container(
              width: 14 * u,
              height: 14 * u,
              margin: EdgeInsets.symmetric(horizontal: 4 * u),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _round ? AppColors.green : (i == _round ? AppColors.orange : Colors.white70),
              ),
            ),
        ]),
      ),
    ]);
  }
}
