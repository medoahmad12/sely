import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';

/// Parent gate: the button must be held for 3 seconds, a children rarely do by accident.
class HoldToUnlock extends StatefulWidget {
  const HoldToUnlock({super.key, required this.onUnlocked, this.size = 52, this.semanticLabel});
  final VoidCallback onUnlocked;
  final double size;
  final String? semanticLabel;

  @override
  State<HoldToUnlock> createState() => _HoldToUnlockState();
}

class _HoldToUnlockState extends State<HoldToUnlock> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onUnlocked();
        _c.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _cancel() {
    if (_c.status != AnimationStatus.completed) _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size * context.u;
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: Listener(
        onPointerDown: (_) => _c.forward(),
        onPointerUp: (_) => _cancel(),
        onPointerCancel: (_) => _cancel(),
        child: SizedBox(
          width: s,
          height: s,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Stack(alignment: Alignment.center, children: [
              Container(
                width: s * 0.82,
                height: s * 0.82,
                decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                child: Icon(Icons.lock_rounded, size: s * 0.46, color: AppColors.navy),
              ),
              SizedBox(
                width: s,
                height: s,
                child: CircularProgressIndicator(
                  value: _c.value,
                  strokeWidth: 5,
                  color: AppColors.orange,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
