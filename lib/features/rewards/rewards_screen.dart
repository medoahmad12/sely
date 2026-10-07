import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/sely_mascot.dart';
import 'reward_catalog.dart';

/// Cosmetic rewards unlocked by the number of stars earned (never purchased).
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final p = context.app.progress;
    return KidScaffold(
      title: context.tr('rewards_title'),
      child: ListView(
        padding: EdgeInsets.all(16 * u),
        children: [
          Center(child: SelyMascot(size: 190 * u, hat: p.hat)),
          Center(
            child: Text(context.tr('rewards_level', {'n': '${p.level}'}),
                style: TextStyle(fontSize: 26 * u, fontWeight: FontWeight.w900, color: AppColors.purple)),
          ),
          SizedBox(height: 14 * u),
          _Section(title: context.tr('rewards_hats')),
          Wrap(spacing: 12 * u, runSpacing: 12 * u, alignment: WrapAlignment.center, children: [
            for (final h in RewardCatalog.hats)
              _RewardCard(
                item: h,
                selected: p.hat == h.id,
                stars: p.stars,
                preview: h.id == 'none' ? const Text('🙂', style: TextStyle(fontSize: 44)) : SelyMascot(size: 70 * u, hat: h.id, waving: false),
                onSelect: () => p.equipHat(h.id),
              ),
          ]),
          SizedBox(height: 18 * u),
          _Section(title: context.tr('rewards_bgs')),
          Wrap(spacing: 12 * u, runSpacing: 12 * u, alignment: WrapAlignment.center, children: [
            for (final b in RewardCatalog.backgrounds)
              _RewardCard(
                item: b,
                selected: p.background == b.id,
                stars: p.stars,
                preview: Container(
                  width: 70 * u,
                  height: 70 * u,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: RewardCatalog.gradientFor(b.id)),
                  ),
                ),
                onSelect: () => p.equipBackground(b.id),
              ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 10 * context.u),
        child: Text(title, style: TextStyle(fontSize: 24 * context.u, fontWeight: FontWeight.w900, color: AppColors.navy)),
      );
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.item, required this.selected, required this.stars, required this.preview, required this.onSelect});
  final RewardItem item;
  final bool selected;
  final int stars;
  final Widget preview;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final unlocked = item.unlockedFor(stars);
    return Pressable(
      onTap: unlocked ? onSelect : null,
      semanticLabel: context.tr(item.nameKey),
      child: Container(
        width: 112 * u,
        padding: EdgeInsets.all(8 * u),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: selected ? AppColors.green : Colors.transparent, width: 5),
          boxShadow: AppShadows.card,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Opacity(opacity: unlocked ? 1 : 0.35, child: SizedBox(height: 74 * u, child: Center(child: preview))),
          SizedBox(height: 4 * u),
          Text(context.tr(item.nameKey),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16 * u, fontWeight: FontWeight.w800, color: AppColors.navy)),
          Text(unlocked ? (selected ? '✔' : ' ') : '🔒 ${item.cost}⭐',
              style: TextStyle(fontSize: 16 * u, fontWeight: FontWeight.w900, color: unlocked ? AppColors.green : AppColors.orange)),
        ]),
      ),
    );
  }
}
