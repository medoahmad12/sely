import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/hold_to_unlock.dart';
import '../../widgets/sely_mascot.dart';

/// Shown when the parent's daily play limit is reached. Only the parent gate dismisses it.
class RestOverlay extends StatelessWidget {
  const RestOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Material(
      color: const Color(0xFF2B2F8F),
      child: SafeArea(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SelyMascot(size: 190 * u, sleepy: true, waving: false),
            SizedBox(height: 16 * u),
            Text('${context.tr('rest_title')} 🌙',
                style: TextStyle(fontSize: 36 * u, fontWeight: FontWeight.w900, color: Colors.white)),
            SizedBox(height: 8 * u),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * u),
              child: Text(context.tr('rest_body'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24 * u, color: Colors.white70, fontWeight: FontWeight.w700)),
            ),
            SizedBox(height: 40 * u),
            HoldToUnlock(size: 64, onUnlocked: () => AppScope.read(context).dismissRest()),
            SizedBox(height: 6 * u),
            Text(context.tr('rest_unlock'), style: TextStyle(fontSize: 14 * u, color: AppColors.skyTop)),
          ]),
        ),
      ),
    );
  }
}
