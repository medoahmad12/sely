import 'package:flutter_test/flutter_test.dart';
import 'package:sely_kids/models/child_profile.dart';
import 'package:sely_kids/services/adaptive_service.dart';
import 'package:sely_kids/services/progress_controller.dart';
import 'package:sely_kids/storage/storage_service.dart';

ProgressController make(MemoryStorage s, {Map<String, int>? totals, DateTime Function()? clock}) =>
    ProgressController(storage: s, totals: totals ?? {'ar': 2, 'num': 3}, clock: clock);

void main() {
  test('stars accumulate and level rises', () {
    final p = make(MemoryStorage());
    p.addStars(1);
    p.addStars(2);
    expect(p.stars, 3);
    expect(p.level, 1);
    p.addStars(20);
    expect(p.level, 2);
    p.addStars(0);
    p.addStars(-5);
    expect(p.stars, 23);
  });

  test('completing a lesson awards 2 stars once; finishing a category gives +3 bonus', () {
    final p = make(MemoryStorage());
    var r = p.completeLesson('ar:alef');
    expect(r.isNew, isTrue);
    expect(r.starsAwarded, 2);
    r = p.completeLesson('ar:alef');
    expect(r.isNew, isFalse);
    expect(r.starsAwarded, 0);
    r = p.completeLesson('ar:ba');
    expect(r.categoryBonus, isTrue);
    expect(r.starsAwarded, 5);
    expect(p.stars, 7);
    expect(p.percent(['ar']), 1.0);
    expect(p.completedLessons, 2);
  });

  test('progress survives a restart (save + load)', () async {
    final storage = MemoryStorage();
    final a = make(storage);
    a.setProfile(const ChildProfile(name: 'سلمى', age: 4, colorIndex: 2));
    a.completeLesson('num:3', activity: 'رقم 3');
    a.recordAnswer('count', true);
    a.recordGame('memory');
    a.equipHat('party');
    a.setLocale('en');
    a.addUsage(45);
    await a.save();

    final b = make(storage);
    await b.load();
    expect(b.profile?.name, 'سلمى');
    expect(b.profile?.age, 4);
    expect(b.isDone('num:3'), isTrue);
    expect(b.stars, 2);
    expect(b.results['count'], [true]);
    expect(b.gamesPlayed['memory'], 1);
    expect(b.hat, 'party');
    expect(b.locale, 'en');
    expect(b.todaySeconds, 45);
    expect(b.lastActivityTitle, 'memory');
    expect(b.loadFailed, isFalse);
  });

  test('corrupted storage does not crash and starts fresh', () async {
    final storage = MemoryStorage()..data[ProgressController.storageKey] = '{not json';
    final p = make(storage);
    await p.load();
    expect(p.loadFailed, isTrue);
    expect(p.stars, 0);
    expect(p.profile, isNull);

    storage.data[ProgressController.storageKey] = '[1,2,3]';
    final q = make(storage);
    await q.load();
    expect(q.loadFailed, isTrue);
  });

  test('storage write failures are swallowed', () async {
    final p = ProgressController(storage: _FailingStorage(), totals: const {});
    p.addStars(3);
    await p.save();
    expect(p.stars, 3);
  });

  test('reset clears progress but keeps profile and settings', () {
    final p = make(MemoryStorage());
    p.setProfile(const ChildProfile(name: 'A', age: 3, colorIndex: 0));
    p.completeLesson('ar:alef');
    p.setVoice(false);
    p.resetProgress();
    expect(p.stars, 0);
    expect(p.completed, isEmpty);
    expect(p.profile?.name, 'A');
    expect(p.voiceOn, isFalse);
  });

  test('daily usage is tracked per day', () {
    var now = DateTime(2026, 10, 5, 10);
    final p = make(MemoryStorage(), clock: () => now);
    p.addUsage(60);
    expect(p.todaySeconds, 60);
    now = DateTime(2026, 10, 6, 10);
    expect(p.todaySeconds, 0);
    p.addUsage(10);
    expect(p.totalSeconds, 70);
  });

  test('adaptive level follows recent accuracy and offers support after mistakes', () {
    final p = make(MemoryStorage());
    final a = AdaptiveService(p);
    expect(a.levelFor('x'), 1);
    for (var i = 0; i < 5; i++) {
      p.recordAnswer('x', true);
    }
    expect(a.levelFor('x'), 3);
    expect(a.needsSupport('x'), isFalse);
    p.recordAnswer('x', false);
    p.recordAnswer('x', false);
    expect(a.needsSupport('x'), isTrue);
    for (var i = 0; i < 12; i++) {
      p.recordAnswer('y', i % 2 == 0);
    }
    expect(p.results['y']!.length, 10);
    expect(a.levelFor('y'), 1);
  });
}

class _FailingStorage implements StorageService {
  @override
  Future<String?> read(String key) async => throw Exception('disk');
  @override
  Future<void> write(String key, String value) async => throw Exception('disk');
  @override
  Future<void> remove(String key) async => throw Exception('disk');
}
