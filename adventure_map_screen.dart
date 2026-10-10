import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/audio_service.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import 'adventure_models.dart';
import 'forest_quest_screen.dart';
import 'forest_scene.dart';
import 'rabbit.dart';
import 'review_level_screen.dart';

/// The screen a level opens. [nextBuilder] lets the "next level" button chain straight on.
Widget levelScreen(List<AdventureLevel> levels, int index) {
  final level = levels[index];
  final hasNext = index + 1 < levels.length;
  Widget Function()? next;
  if (hasNext) next = () => levelScreen(levels, index + 1);
  switch (level.kind) {
    case LevelKind.arabicLetter:
      return ForestQuestScreen(
        letterIndex: level.letterIndex,
        levelId: level.id,
        levelNumber: level.number,
        nextBuilder: next,
      );
    case LevelKind.review:
      return ReviewLevelScreen(level: level, nextBuilder: next);
  }
}

enum _NodeState { locked, current, done }

class AdventureMapScreen extends StatefulWidget {
  const AdventureMapScreen({super.key});

  @override
  State<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen> {
  final ScrollController _scroll = ScrollController();
  bool _centered = false;
  int _shakeIndex = -1;
  int _shakeTick = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _open(List<AdventureLevel> levels, int i) {
    final app = AppScope.read(context);
    if (!AdventureMap.isUnlocked(levels, i, app.progress)) {
      unawaited(app.audio.playSfx(Sfx.wrong));
      unawaited(app.say('adv_locked'));
      setState(() {
        _shakeIndex = i;
        _shakeTick++;
      });
      return;
    }
    Navigator.of(context).push(fadeRoute(levelScreen(levels, i)));
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final app = context.app;
    final levels = AdventureMap.build(app.repo);
    final current = AdventureMap.currentIndex(levels, app.progress);
    final done = AdventureMap.doneCount(levels, app.progress);

    return Scaffold(
      body: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final vp = box.maxHeight;
        final spacing = 130.0 * u;
        final topPad = 240.0 * u;
        final bottomPad = 170.0 * u;
        final height = topPad + bottomPad + math.max(0, levels.length - 1) * spacing;

        Offset centerOf(int i) =>
            Offset(w / 2 + math.sin(i * 0.85) * w * 0.26, height - bottomPad - i * spacing);
        final centers = [for (var i = 0; i < levels.length; i++) centerOf(i)];

        if (!_centered && levels.isNotEmpty) {
          _centered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scroll.hasClients) return;
            final target = height - (centers[current].dy + vp / 2);
            _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent).toDouble());
          });
        }

        final nodeR = 38.0 * u;
        final cur = levels.isEmpty ? Offset.zero : centers[current];
        final rabbitSize = 84.0 * u;
        final rabbitLeft = (cur.dx > w / 2 ? cur.dx - nodeR - rabbitSize - 4 * u : cur.dx + nodeR + 4 * u)
            .clamp(0.0, math.max(0.0, w - rabbitSize))
            .toDouble();

        return Stack(children: [
          SingleChildScrollView(
            controller: _scroll,
            reverse: true,
            child: SizedBox(
              width: w,
              height: height,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _MapPainter(centers: centers, current: current, u: u)),
                  ),
                ),
                Positioned(left: 0, right: 0, top: 70 * u, child: _SoonSign(text: context.tr('adv_soon'))),
                Positioned(left: 0, right: 0, bottom: 24 * u, child: Center(child: Text('🏡', style: TextStyle(fontSize: 64 * u)))),
                for (var i = 0; i < levels.length; i++)
                  Positioned(
                    left: centers[i].dx - nodeR,
                    top: centers[i].dy - nodeR,
                    width: nodeR * 2,
                    height: nodeR * 2 + 26 * u,
                    child: Shake(
                      trigger: _shakeIndex == i ? _shakeTick : 0,
                      child: _LevelNode(
                        key: ValueKey('level_${levels[i].id}'),
                        level: levels[i],
                        glyph: levels[i].kind == LevelKind.arabicLetter ? app.repo.letters[levels[i].letterIndex].glyph : '',
                        stars: app.progress.starsFor(levels[i].id),
                        state: i == current && !AdventureMap.isDone(levels[i], app.progress)
                            ? _NodeState.current
                            : (AdventureMap.isDone(levels[i], app.progress) ? _NodeState.done : _NodeState.locked),
                        radius: nodeR,
                        onTap: () => _open(levels, i),
                      ),
                    ),
                  ),
                if (levels.isNotEmpty)
                  Positioned(
                    left: rabbitLeft,
                    top: cur.dy - rabbitSize * 0.75,
                    child: IgnorePointer(child: Rabbit(size: rabbitSize, mood: RabbitMood.happy)),
                  ),
              ]),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12 * u, 8 * u, 12 * u, 0),
                child: Row(children: [
                  RoundIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
                  SizedBox(width: 10 * u),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16 * u, vertical: 8 * u),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.93),
                        borderRadius: BorderRadius.circular(24 * u),
                        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            context.tr('adv_title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 22 * u, fontWeight: FontWeight.w900, color: AppColors.navy),
                          ),
                        ),
                        Text(
                          '$done / ${levels.length}',
                          style: TextStyle(fontSize: 18 * u, fontWeight: FontWeight.w900, color: AppColors.orange),
                        ),
                      ]),
                    ),
                  ),
                  SizedBox(width: 10 * u),
                  const StarCounter(),
                ]),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

class _SoonSign extends StatelessWidget {
  const _SoonSign({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 300 * u),
        padding: EdgeInsets.symmetric(horizontal: 18 * u, vertical: 10 * u),
        decoration: BoxDecoration(
          color: const Color(0xFFB9824F),
          borderRadius: BorderRadius.circular(18 * u),
          border: Border.all(color: const Color(0xFF8D5A3B), width: 4),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18 * u, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3),
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    super.key,
    required this.level,
    required this.glyph,
    required this.stars,
    required this.state,
    required this.radius,
    required this.onTap,
  });
  final AdventureLevel level;
  final String glyph;
  final int stars;
  final _NodeState state;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final locked = state == _NodeState.locked;
    final colors = switch (state) {
      _NodeState.locked => const [Color(0xFFB8C2CC), Color(0xFF8E9AA6)],
      _NodeState.current => const [Color(0xFFFFB347), Color(0xFFFF8A00)],
      _NodeState.done => const [Color(0xFF63D184), Color(0xFF2E9E57)],
    };
    final review = level.kind == LevelKind.review;
    Widget face;
    if (locked) {
      face = Icon(Icons.lock_rounded, size: radius * 0.9, color: Colors.white);
    } else if (review) {
      face = Text('🎁', style: TextStyle(fontSize: radius * 0.95));
    } else {
      face = Text(
        glyph,
        style: TextStyle(fontSize: radius * 1.05, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15),
      );
    }
    final circle = Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 5))],
      ),
      child: face,
    );
    return Pressable(
      onTap: onTap,
      semanticLabel: '${level.number}',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Pulse(active: state == _NodeState.current, child: circle),
        SizedBox(height: 2 * u),
        SizedBox(
          height: 22 * u,
          child: state == _NodeState.done
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < 3; i++)
                    Icon(Icons.star_rounded, size: 20 * u, color: i < stars ? AppColors.yellow : Colors.white.withValues(alpha: 0.7)),
                ])
              : Text(
                  '${level.number}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15 * u, fontWeight: FontWeight.w900, color: Colors.white, shadows: const [
                    Shadow(color: Color(0x88000000), blurRadius: 4),
                  ]),
                ),
        ),
      ]),
    );
  }
}

/// Meadow at the bottom, sky at the top, a sandy road through the levels
/// (gold up to the current one) and trees, bushes and flowers along it.
class _MapPainter extends CustomPainter {
  _MapPainter({required this.centers, required this.current, required this.u});
  final List<Offset> centers;
  final int current;
  final double u;

  Path _road(int upTo) {
    final path = Path();
    if (centers.isEmpty) return path;
    path.moveTo(centers[0].dx, centers[0].dy + 90 * u);
    path.lineTo(centers[0].dx, centers[0].dy);
    for (var i = 1; i <= upTo && i < centers.length; i++) {
      final p = centers[i - 1];
      final q = centers[i];
      final my = (p.dy + q.dy) / 2;
      path.cubicTo(p.dx, my, q.dx, my, q.dx, q.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3FF), Color(0xFFBFEFFF), Color(0xFF8FE08F), Color(0xFF4FBF63)],
          stops: [0.0, 0.18, 0.55, 1.0],
        ).createShader(rect),
    );

    // clouds near the top
    for (var i = 0; i < 4; i++) {
      drawCloud(canvas, Offset(size.width * (0.15 + 0.23 * i), 30 * u + 38 * u * (i % 2)), 26 * u, alpha: 0.85);
    }

    // scenery along the path
    for (var i = 0; i < centers.length; i++) {
      final c = centers[i];
      final side = c.dx > size.width / 2 ? -1.0 : 1.0;
      final tx = (c.dx + side * size.width * 0.34).clamp(30 * u, size.width - 30 * u).toDouble();
      drawTree(canvas, Offset(tx, c.dy + 30 * u), 120 * u, math.sin(i * 1.7) * 0.6, variant: i % 3 == 0 ? 1 : 0);
      drawBush(canvas, Offset(c.dx + side * 70 * u, c.dy + 62 * u), 26 * u);
      if (i % 2 == 0) {
        drawFlower(canvas, Offset(c.dx - side * 80 * u, c.dy + 40 * u), 10 * u, i % 4 == 0 ? const Color(0xFFFF4F8B) : Colors.white);
      }
    }

    // road
    final full = _road(centers.length - 1);
    canvas.drawPath(
      full,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 58 * u
        ..color = const Color(0xFFD9B77A),
    );
    canvas.drawPath(
      full,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 46 * u
        ..color = const Color(0xFFF6E3B4),
    );
    // gold trail up to the current level
    if (current > 0) {
      canvas.drawPath(
        _road(current),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 46 * u
          ..color = const Color(0xFFFFD66B),
      );
    }
    // dashed center line
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4 * u
      ..color = Colors.white.withValues(alpha: 0.9);
    for (final m in full.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 14 * u, m.length)), dash);
        d += 30 * u;
      }
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.current != current || old.centers.length != centers.length || old.u != u;
}
