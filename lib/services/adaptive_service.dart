import 'dart:math' as math;
import 'progress_controller.dart';

/// Chooses difficulty from the child's recent answers (never punishes: it only
/// holds the level back and offers simpler presentations).
class AdaptiveService {
  AdaptiveService(this.progress);
  final ProgressController progress;

  List<bool> _r(String skill) => progress.results[skill] ?? const [];

  double accuracy(String skill) {
    final r = _r(skill);
    if (r.isEmpty) return 0;
    return r.where((e) => e).length / r.length;
  }

  /// 1..3. Needs at least 5 recent answers before moving above level 1.
  int levelFor(String skill) {
    final r = _r(skill);
    if (r.length < 5) return 1;
    final acc = accuracy(skill);
    if (acc >= 0.9) return 3;
    if (acc >= 0.75) return 2;
    return 1;
  }

  /// True when 2 of the last 3 answers were wrong: show the simpler version.
  bool needsSupport(String skill) {
    final r = _r(skill);
    if (r.length < 2) return false;
    final last = r.sublist(math.max(0, r.length - 3));
    return last.where((e) => !e).length >= 2;
  }
}
