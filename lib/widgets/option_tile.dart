import 'package:flutter/material.dart';
import '../core/theme/app_tokens.dart';
import 'effects.dart';
import 'pressable.dart';

enum TileState { normal, wrong, hint, done, selected }

/// Big rounded card used for answer choices, letters and pictures.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.size,
    required this.child,
    required this.onTap,
    this.state = TileState.normal,
    this.color = Colors.white,
    this.shakeTrigger = 0,
    this.semanticLabel,
  });
  final double size;
  final Widget child;
  final VoidCallback? onTap;
  final TileState state;
  final Color color;
  final int shakeTrigger;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final border = switch (state) {
      TileState.selected => const Color(0xFFFF9F1C),
      TileState.done => const Color(0xFF3FBF4A),
      TileState.hint => const Color(0xFFFFD43B),
      _ => Colors.transparent,
    };
    Widget tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: state == TileState.wrong ? color.withValues(alpha: 0.45) : color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border, width: 5),
        boxShadow: state == TileState.wrong ? null : AppShadows.card,
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
    if (state == TileState.hint) tile = Pulse(child: tile);
    return Shake(
      trigger: shakeTrigger,
      child: Pressable(
        onTap: (state == TileState.wrong || state == TileState.done) ? null : onTap,
        semanticLabel: semanticLabel,
        child: Opacity(opacity: state == TileState.done ? 0.65 : 1, child: tile),
      ),
    );
  }
}
