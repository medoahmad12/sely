import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../models/content_models.dart';
import '../../services/audio_service.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/option_tile.dart';
import '../../widgets/result_view.dart';
import '../../widgets/speech_bubble.dart';

/// Addition / subtraction practice (5 problems per session).
/// Level 1 problems are shown with objects; harder ones fall back to objects
/// automatically when the child makes mistakes (adaptive scaffolding).
class MathSessionScreen extends StatefulWidget {
  const MathSessionScreen({super.key, required this.isAdd});
  final bool isAdd;

  @override
  State<MathSessionScreen> createState() => _MathSessionScreenState();
}

class _MathSessionScreenState extends State<MathSessionScreen> {
  static const perSession = 5;
  late List<int> _queue;
  int _pos = 0;
  int _wrongHere = 0;
  bool _locked = false;
  bool _removed = false;
  bool _done = false;
  int _earned = 0;
  int _shake = 0;
  String _emoji = '🍎';
  final Set<int> _wrong = {};
  late List<int> _options;

  String get _cat => widget.isAdd ? 'add' : 'sub';
  String get _skill => 'math_$_cat';

  List<MathProblem> get _problems {
    final r = AppScope.read(context).repo;
    return widget.isAdd ? r.addProblems : r.subProblems;
  }

  MathProblem get _problem => _problems[_queue[_pos]];

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    final probs = _problems;
    if (probs.isEmpty) {
      _queue = [];
      _done = true;
      return;
    }
    var start = 0;
    for (var i = 0; i < probs.length; i++) {
      if (!app.progress.isDone('$_cat:$i')) {
        start = i;
        break;
      }
    }
    _queue = [for (var k = 0; k < perSession; k++) (start + k) % probs.length];
    _startProblem();
  }

  void _startProblem() {
    final app = AppScope.read(context);
    final p = _problem;
    final emojis = app.repo.mathEmojis;
    _emoji = emojis[(_queue[_pos] + (widget.isAdd ? 0 : 2)) % emojis.length];
    final set = <int>{p.answer};
    final upper = p.answer + 3 < 5 ? 5 : p.answer + 3;
    var guard = 0;
    while (set.length < 3 && guard++ < 60) {
      set.add(app.random.nextInt(upper + 1));
    }
    _options = set.toList()..sort();
    _wrong.clear();
    _wrongHere = 0;
    _locked = false;
    _removed = false;
    if (!widget.isAdd) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _removed = true);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(app.say(widget.isAdd ? 'add_prompt' : 'sub_prompt'));
    });
  }

  bool _objectsMode(AppState app) =>
      _problem.level == 1 || _wrongHere >= 1 || app.adaptive.needsSupport(_skill);

  Future<void> _answer(int v) async {
    if (_locked) return;
    final app = AppScope.read(context);
    if (v == _problem.answer) {
      _locked = true;
      app.progress.recordAnswer(_skill, _wrongHere == 0);
      app.progress.addStars(1);
      _earned++;
      app.progress.completeLesson('$_cat:${_queue[_pos]}', activity: app.strings.get(widget.isAdd ? 'add_title' : 'sub_title'));
      app.audio.playSfx(Sfx.correct);
      await showStarBurst(context, text: app.strings.get(app.cheerKey()));
      if (!mounted) return;
      if (_pos + 1 >= _queue.length) {
        app.progress.recordGame(_skill, activity: app.strings.get(widget.isAdd ? 'add_title' : 'sub_title'));
        app.audio.playSfx(Sfx.win);
        setState(() => _done = true);
      } else {
        setState(() {
          _pos++;
          _startProblem();
        });
      }
    } else {
      app.audio.playSfx(Sfx.wrong);
      unawaited(app.say('try_again'));
      setState(() {
        _wrongHere++;
        _wrong.add(v);
        _shake++;
      });
    }
  }

  void _again() => setState(() {
        _pos = 0;
        _done = false;
        _earned = 0;
        final probs = _problems;
        final app = AppScope.read(context);
        var start = 0;
        for (var i = 0; i < probs.length; i++) {
          if (!app.progress.isDone('$_cat:$i')) {
            start = i;
            break;
          }
        }
        _queue = [for (var k = 0; k < perSession; k++) (start + k) % probs.length];
        _startProblem();
      });

  Widget _group(int count, double u, {int faded = 0}) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 4 * u,
        runSpacing: 4 * u,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: (_removed && i >= count - faded) ? 0.15 : 1,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 500),
                scale: (_removed && i >= count - faded) ? 0.6 : 1,
                child: Text(_emoji, style: TextStyle(fontSize: 52 * u)),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final app = context.app;
    final title = context.tr(widget.isAdd ? 'add_title' : 'sub_title');
    if (_done) {
      return KidScaffold(
        title: title,
        child: ResultView(
          title: context.tr('session_done'),
          stars: _earned,
          actions: [
            BigActionButton(label: context.tr('play_again'), icon: Icons.replay_rounded, color: AppColors.green, onTap: _again),
            BigActionButton(label: context.tr('back'), icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
          ],
        ),
      );
    }
    final p = _problem;
    final objects = _objectsMode(app);
    final promptKey = widget.isAdd ? 'add_prompt' : 'sub_prompt';
    final sign = widget.isAdd ? '+' : '−';
    final big = TextStyle(fontSize: 64 * u, fontWeight: FontWeight.w900, color: AppColors.navy);

    Widget equation;
    if (objects) {
      equation = widget.isAdd
          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(child: _group(p.a, u)),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10 * u), child: Text('+', style: big)),
              Flexible(child: _group(p.b, u)),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10 * u), child: Text('= ؟', style: big)),
            ])
          : Column(mainAxisSize: MainAxisSize.min, children: [
              _group(p.a, u, faded: p.b),
              SizedBox(height: 6 * u),
              Text('${p.a} − ${p.b} = ؟', style: big),
            ]);
    } else {
      equation = Text('${p.a} $sign ${p.b} = ؟', textDirection: TextDirection.ltr, style: big.copyWith(fontSize: 84 * u));
    }

    return KidScaffold(
      title: title,
      child: Column(children: [
        SelyGuide(text: context.tr(promptKey), mascotSize: 80, hat: app.progress.hat, onTap: () => context.appRead.say(promptKey)),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12 * u),
              child: Container(
                padding: EdgeInsets.all(16 * u),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(AppRadius.card)),
                child: Directionality(textDirection: TextDirection.ltr, child: equation),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 18 * u),
          child: Wrap(alignment: WrapAlignment.center, spacing: 16 * u, children: [
            for (final o in _options)
              OptionTile(
                size: 100 * u,
                semanticLabel: '$o',
                state: _wrong.contains(o) ? TileState.wrong : (_wrong.length >= 2 && o == p.answer ? TileState.hint : TileState.normal),
                shakeTrigger: _wrong.contains(o) ? _shake : 0,
                onTap: () => _answer(o),
                child: Text('$o', style: TextStyle(fontSize: 64 * u, fontWeight: FontWeight.w900, color: AppColors.purple)),
              ),
          ]),
        ),
      ]),
    );
  }
}
