import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/responsive.dart';
import '../features/rewards/reward_catalog.dart';
import 'pressable.dart';

/// Page route with a soft fade + slight upward slide.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );

class StarCounter extends StatelessWidget {
  const StarCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Semantics(
      label: '${context.app.progress.stars}',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * u, vertical: 6 * u),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.chip * u),
          boxShadow: AppShadows.card,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('⭐', style: TextStyle(fontSize: 24 * u)),
          SizedBox(width: 6 * u),
          Text('${context.app.progress.stars}',
              style: TextStyle(fontSize: 22 * u, fontWeight: FontWeight.w900, color: AppColors.orange)),
        ]),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, this.color = Colors.white, this.iconColor = AppColors.primaryDark, this.label});
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: 60 * u,
        height: 60 * u,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: AppShadows.card),
        child: Icon(icon, size: 34 * u, color: iconColor),
      ),
    );
  }
}

/// Standard screen frame: themed gradient background, big back button, title, stars.
class KidScaffold extends StatelessWidget {
  const KidScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
    this.showStars = true,
    this.actions = const [],
  });
  final String title;
  final Widget child;
  final bool showBack;
  final bool showStars;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final colors = RewardCatalog.gradientFor(context.app.progress.background);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12 * u, 8 * u, 12 * u, 4 * u),
              child: Row(children: [
                if (showBack)
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: context.tr('back'),
                    onTap: () => Navigator.of(context).maybePop(),
                  )
                else
                  SizedBox(width: 4 * u),
                SizedBox(width: 10 * u),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 26 * u, fontWeight: FontWeight.w900, color: AppColors.navy),
                  ),
                ),
                ...actions,
                if (showStars) ...[SizedBox(width: 8 * u), const StarCounter()],
              ]),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: child),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
