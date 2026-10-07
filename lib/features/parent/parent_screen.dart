import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/child_profile.dart';
import '../../widgets/kid_scaffold.dart';

/// Everything a parent needs: child info, progress, usage, settings, reset.
class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    final app = context.app;
    final p = app.progress;
    final profile = p.profile;
    String dur(int s) => formatDuration(s, minLabel: context.tr('minutes_short'), secLabel: context.tr('seconds_short'));
    final last = p.lastActivityTitle == null
        ? context.tr('parent_none_yet')
        : '${p.lastActivityTitle} • ${_when(p.lastActivityTime)}';
    final games = p.gamesPlayed.entries.map((e) => '${e.key} ×${e.value}').join('   ');

    return KidScaffold(
      title: context.tr('parent_title'),
      showStars: false,
      child: ListView(
        padding: EdgeInsets.all(16 * u),
        children: [
          if (p.loadFailed) _Note(context.tr('storage_warning')),
          _Card(title: context.tr('parent_child'), children: [
            _Row(context.tr('parent_name'), profile?.name ?? '-'),
            _Row(context.tr('parent_age'), '${profile?.age ?? '-'}'),
            _Row(context.tr('parent_level'), '${p.level}'),
            _Row(context.tr('parent_stars'), '${p.stars} ⭐'),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: profile == null ? null : () => _editProfile(context, profile),
                icon: const Icon(Icons.edit_rounded),
                label: Text(context.tr('parent_edit')),
              ),
            ),
          ]),
          _Card(title: context.tr('parent_progress'), children: [
            _Bar(context.tr('prog_arabic'), p.percent(['ar']), AppColors.primary),
            _Bar(context.tr('prog_math'), p.percent(['num', 'add', 'sub']), AppColors.purple),
            _Bar(context.tr('prog_english'), p.percent(['en']), AppColors.green),
            _Bar(context.tr('prog_colors'), p.percent(['col', 'shp']), AppColors.pink),
            _Row(context.tr('parent_lessons'), '${p.completedLessons}'),
            _Row(context.tr('parent_games'), games.isEmpty ? context.tr('parent_none_yet') : games),
            _Row(context.tr('parent_last'), last),
          ]),
          _Card(title: context.tr('parent_today'), children: [
            _Row(context.tr('parent_today'), dur(p.todaySeconds)),
            _Row(context.tr('parent_total'), dur(p.totalSeconds)),
            SizedBox(height: 8 * u),
            Text(context.tr('set_limit'), style: TextStyle(fontSize: 17 * u, fontWeight: FontWeight.w800)),
            Wrap(spacing: 8 * u, children: [
              for (final m in const [0, 15, 30, 60])
                ChoiceChip(
                  label: Text(m == 0 ? context.tr('limit_off') : '$m ${context.tr('minutes_short')}'),
                  selected: p.dailyLimitMinutes == m,
                  onSelected: (_) => p.setDailyLimit(m),
                ),
            ]),
          ]),
          _Card(title: context.tr('parent_settings'), children: [
            SwitchListTile(title: Text(context.tr('set_voice')), value: p.voiceOn, onChanged: p.setVoice),
            SwitchListTile(title: Text(context.tr('set_sfx')), value: p.sfxOn, onChanged: p.setSfx),
            SwitchListTile(title: Text(context.tr('set_music')), value: p.musicOn, onChanged: p.setMusic),
            ListTile(
              title: Text(context.tr('set_language')),
              trailing: SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'ar', label: Text('العربية')), ButtonSegment(value: 'en', label: Text('English'))],
                selected: {p.locale},
                onSelectionChanged: (s) => p.setLocale(s.first),
              ),
            ),
          ]),
          if (app.repo.loadErrors.isNotEmpty) _Note('${context.tr('content_errors')}: ${app.repo.loadErrors.join(', ')}'),
          SizedBox(height: 8 * u),
          Center(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(context.tr('parent_reset')),
            ),
          ),
          SizedBox(height: 24 * u),
        ],
      ),
    );
  }

  static String _when(DateTime? t) {
    if (t == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _confirmReset(BuildContext context) async {
    final app = context.appRead;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(ctx.tr('reset_confirm'), style: const TextStyle(fontSize: 20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(100, 48)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('confirm')),
          ),
        ],
      ),
    );
    if (ok == true) app.progress.resetProgress();
  }

  Future<void> _editProfile(BuildContext context, ChildProfile profile) async {
    final app = context.appRead;
    final controller = TextEditingController(text: profile.name);
    var age = profile.age;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(ctx.tr('parent_child')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: controller, maxLength: 16, decoration: InputDecoration(labelText: ctx.tr('parent_name'))),
            Wrap(spacing: 8, children: [
              for (final a in const [3, 4, 5])
                ChoiceChip(label: Text('$a'), selected: age == a, onSelected: (_) => setState(() => age = a)),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(100, 48)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('parent_save')),
            ),
          ],
        ),
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (saved == true && name.isNotEmpty) {
      app.progress.setProfile(profile.copyWith(name: name, age: age));
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Card(
      margin: EdgeInsets.only(bottom: 14 * u),
      child: Padding(
        padding: EdgeInsets.all(14 * u),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 20 * u, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
          SizedBox(height: 8 * u),
          ...children,
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 4 * context.u),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(fontSize: 16 * context.u, color: Colors.black54))),
          Expanded(flex: 3, child: Text(value, style: TextStyle(fontSize: 16 * context.u, fontWeight: FontWeight.w800))),
        ]),
      );
}

class _Bar extends StatelessWidget {
  const _Bar(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final u = context.u;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5 * u),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: TextStyle(fontSize: 16 * u, fontWeight: FontWeight.w700))),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: value, minHeight: 14 * u, color: color, backgroundColor: Colors.black12),
          ),
        ),
        SizedBox(width: 8 * u),
        Text('${(value * 100).round()}%', style: TextStyle(fontSize: 16 * u, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: 12 * context.u),
        padding: EdgeInsets.all(12 * context.u),
        decoration: BoxDecoration(color: const Color(0xFFFFF3C4), borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: TextStyle(fontSize: 16 * context.u)),
      );
}
