import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';
import 'sely_mascot.dart';

/// End-of-lesson / end-of-game celebration with action buttons.
class ResultView extends StatelessWidget {
  const ResultView({super.key, required this.title, required this.stars, required this.actions, this.bonusText});
  final String title;
  final int stars;
  final String? bonusText;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16 * u),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SelyMascot(size: 170 * u, hat: context.app.progress.hat),
          SizedBox(height: 8 * u),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
          SizedBox(height: 12 * u),
          if (stars > 0)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: Text('+$stars ⭐',
                  style: TextStyle(fontSize: 46 * u, fontWeight: FontWeight.w900, color: AppColors.orange)),
            ),
          if (bonusText != null) ...[
            SizedBox(height: 6 * u),
            Text(bonusText!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22 * u, fontWeight: FontWeight.w800, color: AppColors.purple)),
          ],
          SizedBox(height: 20 * u),
          Wrap(alignment: WrapAlignment.center, spacing: 12 * u, runSpacing: 12 * u, children: actions),
        ]),
      ),
    );
  }
}

class BigActionButton extends StatelessWidget {
  const BigActionButton({super.key, required this.label, required this.icon, required this.onTap, this.color = AppColors.primary});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(150 * u, 64 * u),
        padding: EdgeInsets.symmetric(horizontal: 22 * u),
      ),
      onPressed: () {
        onTap();
      },
      icon: Icon(icon, size: 30 * u),
      label: Text(label),
    );
  }
}
