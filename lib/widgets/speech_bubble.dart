import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/responsive.dart';
import 'pressable.dart';
import 'sely_mascot.dart';

/// SELY with a speech bubble. Tapping the bubble repeats the spoken text.
class SelyGuide extends StatelessWidget {
  const SelyGuide({super.key, required this.text, this.onTap, this.mascotSize = 96, this.hat = 'none'});
  final String text;
  final VoidCallback? onTap;
  final double mascotSize;
  final String hat;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * u),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SelyMascot(size: mascotSize * u, hat: hat),
        SizedBox(width: 8 * u),
        Expanded(
          child: Pressable(
            onTap: onTap,
            semanticLabel: text,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * u, vertical: 12 * u),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card * u),
                boxShadow: AppShadows.card,
              ),
              child: Row(children: [
                Expanded(
                  child: Text(text,
                      style: TextStyle(fontSize: 22 * u, fontWeight: FontWeight.w800, color: AppColors.navy, height: 1.25)),
                ),
                if (onTap != null) Icon(Icons.volume_up_rounded, size: 30 * u, color: AppColors.primary),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
