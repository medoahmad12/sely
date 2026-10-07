import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/child_profile.dart';
import '../storage/storage_service.dart';

class LessonResult {
  const LessonResult({required this.isNew, required this.starsAwarded, required this.categoryBonus});
  final bool isNew;
  final int starsAwarded;
  final bool categoryBonus;
}

/// Everything the app remembers about the child, persisted locally as JSON.
class ProgressController extends ChangeNotifier {
  ProgressController({required this.storage, required this.totals, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const storageKey = 'sely_progress_v1';

  final StorageService storage;
  final Map<String, int> totals;
  final DateTime Function() _clock;

  ChildProfile? profile;
  int stars = 0;
  final Set<String> completed = {};
  final Map<String, int> gamesPlayed = {};
  final Map<String, List<bool>> results = {};
  String hat = 'none';
  String background = 'sky';
  bool voiceOn = true;
  bool sfxOn = true;
  bool musicOn = true;
  String locale = 'ar';
  int dailyLimitMinutes = 0;
  final Map<String, int> usage = {};
  String? lastActivityTitle;
  DateTime? lastActivityTime;
  bool loadFailed = false;
  int _unsavedUsage = 0;

  // ---------------------------------------------------------------- derived
  int get level => 1 + stars ~/ 20;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get todaySeconds => usage[dateKey(_clock())] ?? 0;
  int get totalSeconds => usage.values.fold(0, (a, b) => a + b);
  int get completedLessons => completed.where((e) => !e.startsWith('bonus:')).length;

  int _count(String cat) => completed.where((e) => e.startsWith('$cat:')).length;

  /// 0..1 progress over one or more lesson categories.
  double percent(List<String> categories) {
    var done = 0, total = 0;
    for (final c in categories) {
      total += totals[c] ?? 0;
      done += _count(c).clamp(0, totals[c] ?? 0).toInt();
    }
    return total == 0 ? 0 : done / total;
  }

  bool isDone(String id) => completed.contains(id);

  // ---------------------------------------------------------------- persistence
  Future<void> load() async {
    try {
      final raw = await storage.read(storageKey);
      if (raw != null) {
        final m = jsonDecode(raw);
        if (m is! Map<String, dynamic>) throw const FormatException('bad progress');
        _apply(m);
      }
    } catch (_) {
      loadFailed = true;
      _clearProgress();
      profile = null;
    }
    notifyListeners();
  }

  void _apply(Map<String, dynamic> m) {
    final p = m['profile'];
    profile = p is Map<String, dynamic> ? ChildProfile.fromJson(p) : null;
    stars = ((m['stars'] as num?)?.toInt() ?? 0).clamp(0, 1000000).toInt();
    completed
      ..clear()
      ..addAll((m['completed'] as List? ?? const []).whereType<String>());
    gamesPlayed
      ..clear()
      ..addAll((m['games'] as Map? ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())));
    results
      ..clear()
      ..addAll((m['results'] as Map? ?? const {}).map(
        (k, v) => MapEntry(k as String, (v as List).whereType<bool>().toList()),
      ));
    usage
      ..clear()
      ..addAll((m['usage'] as Map? ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())));
    hat = (m['hat'] as String?) ?? 'none';
    background = (m['bg'] as String?) ?? 'sky';
    voiceOn = (m['voice'] as bool?) ?? true;
    sfxOn = (m['sfx'] as bool?) ?? true;
    musicOn = (m['music'] as bool?) ?? true;
    final loc = (m['locale'] as String?) ?? 'ar';
    locale = loc == 'en' ? 'en' : 'ar';
    dailyLimitMinutes = ((m['limit'] as num?)?.toInt() ?? 0).clamp(0, 600).toInt();
    lastActivityTitle = m['lastTitle'] as String?;
    final t = m['lastTime'] as String?;
    lastActivityTime = t == null ? null : DateTime.tryParse(t);
  }

  Map<String, dynamic> toJson() => {
        'profile': profile?.toJson(),
        'stars': stars,
        'completed': completed.toList(),
        'games': gamesPlayed,
        'results': results,
        'usage': usage,
        'hat': hat,
        'bg': background,
        'voice': voiceOn,
        'sfx': sfxOn,
        'music': musicOn,
        'locale': locale,
        'limit': dailyLimitMinutes,
        'lastTitle': lastActivityTitle,
        'lastTime': lastActivityTime?.toIso8601String(),
      };

  Future<void> save() async {
    try {
      await storage.write(storageKey, jsonEncode(toJson()));
      _unsavedUsage = 0;
    } catch (_) {/* storage errors must never crash the app */}
  }

  void _persist() {
    notifyListeners();
    unawaited(save());
  }

  void _touch(String title) {
    lastActivityTitle = title;
    lastActivityTime = _clock();
  }

  void _clearProgress() {
    stars = 0;
    completed.clear();
    gamesPlayed.clear();
    results.clear();
    hat = 'none';
    background = 'sky';
    usage.clear();
    lastActivityTitle = null;
    lastActivityTime = null;
  }

  // ---------------------------------------------------------------- mutations
  void setProfile(ChildProfile p) {
    profile = p;
    _persist();
  }

  void addStars(int n, {String? activity}) {
    if (n <= 0) return;
    stars += n;
    if (activity != null) _touch(activity);
    _persist();
  }

  /// Marks a lesson done. First completion = 2 stars, finishing a whole category = +3 bonus.
  LessonResult completeLesson(String id, {String? activity}) {
    final isNew = completed.add(id);
    var award = 0;
    var bonus = false;
    if (isNew) {
      award = 2;
      final cat = id.split(':').first;
      final total = totals[cat] ?? 0;
      if (total > 0 && _count(cat) >= total && completed.add('bonus:$cat')) {
        award += 3;
        bonus = true;
      }
    }
    stars += award;
    _touch(activity ?? id);
    _persist();
    return LessonResult(isNew: isNew, starsAwarded: award, categoryBonus: bonus);
  }

  void recordAnswer(String skill, bool correct) {
    final list = results.putIfAbsent(skill, () => []);
    list.add(correct);
    if (list.length > 10) list.removeRange(0, list.length - 10);
    unawaited(save());
  }

  void recordGame(String gameId, {String? activity}) {
    gamesPlayed[gameId] = (gamesPlayed[gameId] ?? 0) + 1;
    _touch(activity ?? gameId);
    _persist();
  }

  /// Adds foreground play time. Does not notify (called every few seconds).
  void addUsage(int seconds) {
    final k = dateKey(_clock());
    usage[k] = (usage[k] ?? 0) + seconds;
    _unsavedUsage += seconds;
    if (_unsavedUsage >= 30) unawaited(save());
  }

  void equipHat(String id) {
    hat = id;
    _persist();
  }

  void equipBackground(String id) {
    background = id;
    _persist();
  }

  void setVoice(bool v) {
    voiceOn = v;
    _persist();
  }

  void setSfx(bool v) {
    sfxOn = v;
    _persist();
  }

  void setMusic(bool v) {
    musicOn = v;
    _persist();
  }

  void setLocale(String code) {
    locale = code == 'en' ? 'en' : 'ar';
    _persist();
  }

  void setDailyLimit(int minutes) {
    dailyLimitMinutes = minutes.clamp(0, 600).toInt();
    _persist();
  }

  /// Parent action: wipe stars/lessons/stats, keep child profile and settings.
  void resetProgress() {
    _clearProgress();
    _persist();
  }
}
