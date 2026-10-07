import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../services/audio_service.dart';

/// Scales down while pressed, plays the tap sound. Base of all big touch targets.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.semanticLabel, this.sound = true});
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool sound;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                if (widget.sound) AppScope.read(context).audio.playSfx(Sfx.tap);
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.93 : 1,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      ),
    );
  }
}
