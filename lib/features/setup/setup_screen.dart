import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive.dart';
import '../../models/child_profile.dart';
import '../../widgets/kid_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/sely_mascot.dart';
import '../home/home_screen.dart';

/// First-run setup: name (or nickname), age 3/4/5, favorite color. No personal data beyond that.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController();
  int _age = 4;
  int _color = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).say('setup_hello');
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _start() {
    final app = AppScope.read(context);
    final name = _name.text.trim();
    app.progress.setProfile(ChildProfile(name: name.isEmpty ? '⭐' : name, age: _age, colorIndex: _color));
    Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final nicks = [for (var i = 1; i <= 6; i++) context.tr('nick_$i')];
    return KidScaffold(
      title: context.tr('app_name'),
      showBack: false,
      showStars: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16 * u),
        child: Column(children: [
          SelyMascot(size: 130 * u),
          Text(context.tr('setup_hello'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
          SizedBox(height: 12 * u),
          TextField(
            controller: _name,
            maxLength: 16,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28 * u, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: context.tr('setup_name_hint'),
              filled: true,
              fillColor: Colors.white,
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.card), borderSide: BorderSide.none),
            ),
          ),
          SizedBox(height: 6 * u),
          Text(context.tr('setup_pick_nick'), style: TextStyle(fontSize: 18 * u, color: AppColors.navy)),
          SizedBox(height: 6 * u),
          Wrap(spacing: 8 * u, runSpacing: 8 * u, alignment: WrapAlignment.center, children: [
            for (final n in nicks)
              Pressable(
                onTap: () => setState(() => _name.text = n),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16 * u, vertical: 10 * u),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.chip * u), boxShadow: AppShadows.card),
                  child: Text(n, style: TextStyle(fontSize: 22 * u, fontWeight: FontWeight.w800, color: AppColors.navy)),
                ),
              ),
          ]),
          SizedBox(height: 18 * u),
          Text(context.tr('setup_age'), style: TextStyle(fontSize: 26 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
          SizedBox(height: 8 * u),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final a in const [3, 4, 5])
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * u),
                child: Pressable(
                  semanticLabel: '$a',
                  onTap: () => setState(() => _age = a),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 84 * u,
                    height: 84 * u,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _age == a ? AppColors.orange : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.card,
                    ),
                    child: Text('$a', style: TextStyle(fontSize: 48 * u, fontWeight: FontWeight.w900, color: _age == a ? Colors.white : AppColors.navy)),
                  ),
                ),
              ),
          ]),
          SizedBox(height: 18 * u),
          Text(context.tr('setup_color'), style: TextStyle(fontSize: 26 * u, fontWeight: FontWeight.w900, color: AppColors.navy)),
          SizedBox(height: 8 * u),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < AppColors.childColors.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * u),
                child: Pressable(
                  semanticLabel: '${i + 1}',
                  onTap: () => setState(() => _color = i),
                  child: Container(
                    width: 56 * u,
                    height: 56 * u,
                    decoration: BoxDecoration(
                      color: AppColors.childColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: _color == i ? AppColors.navy : Colors.white, width: 5),
                    ),
                    child: _color == i ? const Icon(Icons.check_rounded, color: Colors.white, size: 30) : null,
                  ),
                ),
              ),
          ]),
          SizedBox(height: 24 * u),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.green, minimumSize: Size(240 * u, 72 * u)),
            onPressed: _start,
            icon: Icon(Icons.play_arrow_rounded, size: 40 * u),
            label: Text(context.tr('setup_start')),
          ),
        ]),
      ),
    );
  }
}
