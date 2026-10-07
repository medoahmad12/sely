import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/effects.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import 'math_session.dart';

class MathWorldScreen extends StatelessWidget {
  const MathWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final p = context.app.progress;
    final entries = [
      ('➕', 'add_title', true, AppColors.green, p.percent(['add'])),
      ('➖', 'sub_title', false, AppColors.pink, p.percent(['sub'])),
    ];
    return KidScaffold(
      title: context.tr('world_math'),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16 * u),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 20 * u,
            runSpacing: 20 * u,
            children: [
              for (var i = 0; i < entries.length; i++)
                PopIn(
                  index: i,
                  child: Pressable(
                    onTap: () => Navigator.of(context).push(fadeRoute(MathSessionScreen(isAdd: entries[i].$3))),
                    semanticLabel: context.tr(entries[i].$2),
                    child: Container(
                      width: 210 * u,
                      padding: EdgeInsets.symmetric(vertical: 22 * u, horizontal: 12 * u),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: entries[i].$4, width: 5),
                        boxShadow: AppShadows.soft(entries[i].$4),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(entries[i].$1, style: TextStyle(fontSize: 76 * u)),
                        SizedBox(height: 6 * u),
                        Text(context.tr(entries[i].$2),
                            style: TextStyle(fontSize: 30 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
                        SizedBox(height: 10 * u),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: entries[i].$5,
                            minHeight: 14 * u,
                            color: entries[i].$4,
                            backgroundColor: Colors.black12,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
