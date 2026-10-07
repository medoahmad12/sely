import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Gentle looping scale pulse (used as a hint).
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.active = true});
  final Widget child;
  final bool active;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(Pulse old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(scale: 1 + 0.08 * _c.value, child: child),
        child: widget.child,
      );
}

/// Horizontal shake that plays whenever [trigger] changes to a new value.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child, required this.trigger});
  final Widget child;
  final int trigger;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(math.sin(_c.value * math.pi * 6) * 10 * (1 - _c.value), 0),
          child: child,
        ),
        child: widget.child,
      );
}

/// Pops in with an elastic scale, delayed by [index] for a staggered entrance.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 450 + 70 * index),
        curve: Curves.easeOutBack,
        builder: (context, v, c) => Transform.scale(scale: v.clamp(0.0, 1.2).toDouble(), child: Opacity(opacity: v.clamp(0.0, 1.0).toDouble(), child: c)),
        child: child,
      );
}

/// Star burst + cheer text shown over everything for ~1 s.
Future<void> showStarBurst(BuildContext context, {String? text}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final entry = OverlayEntry(builder: (_) => _StarBurst(text: text));
  overlay.insert(entry);
  await Future<void>.delayed(const Duration(milliseconds: 1000));
  entry.remove();
}

class _StarBurst extends StatefulWidget {
  const _StarBurst({this.text});
  final String? text;

  @override
  State<_StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<_StarBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 950))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          final fade = (1 - _c.value * _c.value).clamp(0.0, 1.0).toDouble();
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 10; i++)
                Transform.translate(
                  offset: Offset(
                    math.cos(i * math.pi / 5) * shortest * 0.38 * t,
                    math.sin(i * math.pi / 5) * shortest * 0.38 * t,
                  ),
                  child: Opacity(
                    opacity: fade,
                    child: Text('⭐', style: TextStyle(fontSize: 22 + 20 * (1 - t), decoration: TextDecoration.none)),
                  ),
                ),
              if (widget.text != null)
                Transform.scale(
                  scale: 0.6 + 0.6 * Curves.elasticOut.transform(_c.value.clamp(0.0, 1.0).toDouble()),
                  child: Opacity(
                    opacity: fade,
                    child: Text(
                      widget.text!,
                      style: TextStyle(
                        fontSize: shortest * 0.12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFF9F1C),
                        decoration: TextDecoration.none,
                        shadows: const [Shadow(color: Colors.white, blurRadius: 10)],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
