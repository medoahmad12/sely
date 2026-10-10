import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/content_models.dart';
import '../../services/audio_service.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/result_view.dart';
import '../trace/trace_board.dart';
import 'adventure_widgets.dart';
import 'forest_scene.dart';
import 'rabbit.dart';

enum _Phase { intro, collect, trace, done }

class _QuestItem {
  _QuestItem({required this.emoji, required this.word, required this.wordIndex, required this.correct});
  final String emoji;
  final String word;
  final int wordIndex;
  final bool correct;
  bool found = false;
  int shake = 0;
}

/// A letter level in the forest: Arnoub asks for help, the child finds the things that
/// start with the letter, then traces the letter with him. Rating: 3 stars with no
/// mistakes, 2 with one or two, 1 otherwise.
class ForestQuestScreen extends StatefulWidget {
  const ForestQuestScreen({
    super.key,
    required this.letterIndex,
    required this.levelId,
    required this.levelNumber,
    this.nextBuilder,
  });
  final int letterIndex;
  final String levelId;
  final int levelNumber;

  /// Builds the next level's screen (null on the last level).
  final Widget Function()? nextBuilder;

  @override
  State<ForestQuestScreen> createState() => _ForestQuestScreenState();
}

class _ForestQuestScreenState extends State<ForestQuestScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final ArabicLetter _letter;
  late final List<_QuestItem> _items;
  _Phase _phase = _Phase.intro;
  int _mistakes = 0;
  bool _slip = false;
  int _hop = 0;
  RabbitMood _mood = RabbitMood.happy;
  bool _finished = false;
  int _rating = 0;
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _letter = app.repo.letters[widget.letterIndex];
    _items = _buildItems(app, _letter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sayIntro();
    });
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  List<_QuestItem> _buildItems(AppState app, ArabicLetter letter) {
    final correct = <_QuestItem>[
      for (var i = 0; i < letter.words.length && i < 3; i++)
        _QuestItem(emoji: letter.words[i].emoji, word: letter.words[i].word, wordIndex: i, correct: true),
    ];
    final seen = correct.map((c) => c.emoji).toSet();
    final pool = <_QuestItem>[];
    for (final other in app.repo.letters) {
      if (other.id == letter.id || other.words.isEmpty) continue;
      final w = other.words.first;
      pool.add(_QuestItem(emoji: w.emoji, word: w.word, wordIndex: 0, correct: false));
    }
    pool.shuffle(app.random);
    final distractors = <_QuestItem>[];
    for (final p in pool) {
      if (distractors.length >= 3) break;
      if (seen.add(p.emoji)) distractors.add(p);
    }
    return [...correct, ...distractors]..shuffle(app.random);
  }

  Future<void> _say(String key, [Map<String, String> args = const {}]) => AppScope.read(context).say(key, args);

  void _sayIntro() => unawaited(_say('quest_intro', {'x': _letter.name}));

  void _sayLetter() => unawaited(AppScope.read(context).audio.speak('ar_letter_${_letter.id}', _letter.name, lang: 'ar'));

  void _sayWord(int i) {
    final w = _letter.words[i];
    unawaited(AppScope.read(context).audio.speak('ar_word_${_letter.id}_$i', w.word, lang: 'ar'));
  }

  void _toCollect() {
    setState(() {
      _phase = _Phase.collect;
      _mood = RabbitMood.idle;
    });
    unawaited(_say('quest_collect', {'x': _letter.name}));
  }

  void _toTrace() {
    if (!mounted || _phase != _Phase.collect) return;
    setState(() {
      _phase = _Phase.trace;
      _mood = RabbitMood.idle;
    });
    unawaited(_say('quest_trace', {'x': _letter.name}));
  }

  void _onItemTap(_QuestItem it) {
    if (it.found || _phase != _Phase.collect) return;
    final app = AppScope.read(context);
    if (it.correct) {
      app.progress.recordAnswer('ar_collect', !_slip);
      _slip = false;
      unawaited(app.audio.playSfx(Sfx.correct));
      _sayWord(it.wordIndex);
      setState(() {
        it.found = true;
        _hop++;
        _mood = RabbitMood.happy;
      });
      if (_items.where((e) => e.correct).every((e) => e.found)) {
        Future<void>.delayed(const Duration(milliseconds: 1100), _toTrace);
      }
    } else {
      _slip = true;
      _mistakes++;
      unawaited(app.audio.playSfx(Sfx.wrong));
      unawaited(_say('quest_not_this', {'x': _letter.name}));
      setState(() {
        it.shake++;
        _mood = RabbitMood.sad;
      });
      Future<void>.delayed(const Duration(milliseconds: 1300), () {
        if (mounted && _phase == _Phase.collect) setState(() => _mood = RabbitMood.idle);
      });
    }
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    final app = AppScope.read(context);
    final rating = _mistakes == 0 ? 3 : (_mistakes <= 2 ? 2 : 1);
    final result = app.progress.completeLesson(
      'ar:${_letter.id}',
      activity: app.strings.get('letter_label', {'x': _letter.name}),
    );
    app.progress.setLevelStars(widget.levelId, rating);
    unawaited(app.audio.playSfx(Sfx.win));
    setState(() {
      _phase = _Phase.done;
      _rating = rating;
      _coins = result.starsAwarded;
      _mood = RabbitMood.cheer;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(showStarBurst(context, text: app.strings.get(app.cheerKey())));
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = switch (_phase) {
      _Phase.intro => 0,
      _Phase.collect => 1,
      _Phase.trace => 2,
      _Phase.done => 3,
    };
    return Scaffold(
      body: ForestBackground(
        child: SafeArea(
          child: Column(children: [
            AdventureTopBar(title: context.tr('level_label', {'n': '${widget.levelNumber}'}), step: step, steps: 4),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(key: ValueKey(_phase), child: _body(context)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (_phase) {
      case _Phase.intro:
        return _intro(context);
      case _Phase.collect:
        return _collect(context);
      case _Phase.trace:
        return _trace(context);
      case _Phase.done:
        return _done(context);
    }
  }

  Widget _intro(BuildContext context) {
    final u = context.u;
    return Column(children: [
      Expanded(
        child: Center(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Pulse(
                child: Pressable(
                  onTap: _sayLetter,
                  semanticLabel: _letter.name,
                  child: Container(
                    width: 190 * u,
                    height: 190 * u,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(44 * u),
                      boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 16, offset: Offset(0, 8))],
                    ),
                    child: Text(
                      _letter.glyph,
                      style: TextStyle(fontSize: 140 * u, fontWeight: FontWeight.w900, color: AppColors.navy, height: 1.1),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12 * u),
              Wrap(alignment: WrapAlignment.center, spacing: 10 * u, runSpacing: 10 * u, children: [
                for (var i = 0; i < _letter.words.length; i++)
                  Pressable(
                    onTap: () => _sayWord(i),
                    semanticLabel: _letter.words[i].word,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14 * u, vertical: 8 * u),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.93), borderRadius: BorderRadius.circular(22 * u)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_letter.words[i].emoji, style: TextStyle(fontSize: 34 * u)),
                        SizedBox(width: 8 * u),
                        Text(
                          _letter.words[i].word,
                          style: TextStyle(fontSize: 24 * u, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                      ]),
                    ),
                  ),
              ]),
            ]),
          ),
        ),
      ),
      RabbitSpeechBar(
        text: context.tr('quest_intro', {'x': _letter.name}),
        onTap: _sayIntro,
        mood: _mood,
        hopTrigger: _hop,
      ),
      SizedBox(height: 6 * u),
      FilledButton(
        key: const ValueKey('quest_start'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.green, minimumSize: Size(170 * u, 68 * u)),
        onPressed: _toCollect,
        child: Icon(Icons.arrow_forward_rounded, size: 42 * u),
      ),
      SizedBox(height: 12 * u),
    ]);
  }

  Widget _collect(BuildContext context) {
    final u = context.u;
    final targets = _items.where((e) => e.correct).toList();
    return Column(children: [
      SizedBox(height: 6 * u),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * u, vertical: 6 * u),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(24 * u)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('🧺', style: TextStyle(fontSize: 32 * u)),
          SizedBox(width: 8 * u),
          for (final t in targets)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 3 * u),
              width: 46 * u,
              height: 46 * u,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.found ? const Color(0xFFE8F8EA) : const Color(0xFFEFF3F8),
                borderRadius: BorderRadius.circular(14 * u),
                border: Border.all(color: t.found ? AppColors.green : const Color(0xFFCBD5E1), width: 2),
              ),
              child: Text(t.found ? t.emoji : '', style: TextStyle(fontSize: 28 * u)),
            ),
        ]),
      ),
      Expanded(
        child: Center(
          child: SingleChildScrollView(
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, _) => Wrap(
                alignment: WrapAlignment.center,
                spacing: 14 * u,
                runSpacing: 14 * u,
                children: [
                  for (var i = 0; i < _items.length; i++) _bubble(context, _items[i], i),
                ],
              ),
            ),
          ),
        ),
      ),
      RabbitSpeechBar(
        text: context.tr('quest_collect', {'x': _letter.name}),
        onTap: () => unawaited(_say('quest_collect', {'x': _letter.name})),
        mood: _mood,
        hopTrigger: _hop,
      ),
      SizedBox(height: 12 * u),
    ]);
  }

  Widget _bubble(BuildContext context, _QuestItem it, int i) {
    final u = context.u;
    final bob = math.sin(_float.value * 2 * math.pi + i * 1.3) * 7 * u;
    return Transform.translate(
      offset: Offset(0, bob),
      child: AnimatedScale(
        scale: it.found ? 0 : 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeIn,
        child: Shake(
          trigger: it.shake,
          child: Pressable(
            key: ValueKey('quest_item_${it.emoji}'),
            onTap: () => _onItemTap(it),
            semanticLabel: it.word,
            child: Container(
              width: 96 * u,
              height: 96 * u,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Text(it.emoji, style: TextStyle(fontSize: 54 * u)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trace(BuildContext context) {
    final u = context.u;
    return Column(children: [
      Expanded(
        child: Padding(
          padding: EdgeInsets.all(12 * u),
          child: TraceBoard(shape: _letter.trace, color: AppColors.green, onComplete: _finish),
        ),
      ),
      RabbitSpeechBar(
        text: context.tr('quest_trace', {'x': _letter.name}),
        onTap: () => unawaited(_say('quest_trace', {'x': _letter.name})),
        mood: _mood,
        hopTrigger: _hop,
        size: 100,
      ),
      SizedBox(height: 10 * u),
    ]);
  }

  Widget _done(BuildContext context) {
    final next = widget.nextBuilder;
    return LevelCompleteView(
      title: context.tr('quest_done', {'x': _letter.name}),
      rating: _rating,
      coins: _coins,
      actions: [
        if (next != null)
          BigActionButton(
            label: context.tr('next_level'),
            icon: Icons.arrow_forward_rounded,
            color: AppColors.green,
            onTap: () => Navigator.of(context).pushReplacement(fadeRoute(next())),
          ),
        BigActionButton(
          label: context.tr('adv_map'),
          icon: Icons.map_rounded,
          color: AppColors.primary,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
