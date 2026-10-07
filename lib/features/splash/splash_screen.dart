import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/kid_scaffold.dart';
import '../home/home_screen.dart';
import '../setup/setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final hasProfile = AppScope.read(context).progress.profile != null;
      Navigator.of(context).pushReplacement(fadeRoute(hasProfile ? const HomeScreen() : const SetupScreen()));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.skyTop, AppColors.skyBottom]),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScaleTransition(
              scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(48 * u),
                child: Image.asset(
                  'assets/images/sely_icon.png',
                  width: 240 * u,
                  height: 240 * u,
                  errorBuilder: (_, __, ___) => Text('SELY', style: TextStyle(fontSize: 60 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
                ),
              ),
            ),
            SizedBox(height: 18 * u),
            FadeTransition(
              opacity: CurvedAnimation(parent: _c, curve: const Interval(0.5, 1)),
              child: Text(context.tr('tagline'),
                  style: TextStyle(fontSize: 28 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
            ),
          ]),
        ),
      ),
    );
  }
}
